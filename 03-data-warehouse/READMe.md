# Health check script

Use this in Git Bash from anywhere before the export:
```text
proj="kestra-sandbox-497720"; model="zoomcamp.tip_model"; bucket="gs://taxi_ml_model/tip_model"; set -euo pipefail; echo "== gcloud =="; gcloud --version >/dev/null; echo "ok: gcloud loads"; echo "== bq =="; bq version >/dev/null; echo "ok: bq loads"; echo "== auth =="; acct="$(gcloud auth list --filter=status:ACTIVE --format='value(account)')"; [[ -n "$acct" ]] || { echo "fail: no active gcloud account"; exit 1; }; echo "ok: active account $acct"; echo "== project =="; active_proj="$(gcloud config get-value project 2>/dev/null)"; [[ "$active_proj" == "$proj" ]] || { echo "fail: active project is '$active_proj' expected '$proj'"; exit 1; }; echo "ok: project $active_proj"; echo "== model =="; bq --project_id="$proj" ls --models zoomcamp | grep -qx 'tip_model' || { echo "fail: model $model not found"; exit 1; }; echo "ok: model $model exists"; echo "== bucket =="; gsutil ls "$bucket" >/dev/null 2>&1 || echo "warn: bucket path $bucket not accessible yet (this may be expected before first export)"; echo "HEALTH CHECK PASSED"
```
If it prints HEALTH CHECK PASSED, you’re clear to run the export.

# Windows + Git Bash: GCS to Local to Docker

Use these steps from the 03-data-warehouse folder to copy the exported model from Google Cloud Storage to your local machine and then mount it into a Docker container.

## 1) Move into the project folder

```bash
cd /c/WORKSPACE/data-engineering/03-data-warehouse
```

## 2) Prepare local folders (project-local, not /tmp)

```bash
mkdir -p ./tmp/model
mkdir -p ./serving_dir/tip_model/1
```

Expected local structure:

```text
03-data-warehouse/
	tmp/
		model/
	serving_dir/
		tip_model/
			1/
```

## 3) Copy model files from GCS to local

Replace <YOUR-BUCKET-NAME-HERE> with your bucket name.

```bash
gcloud storage cp -r gs://<YOUR-BUCKET-NAME-HERE>/tip_model ./tmp/model
```

## 4) Copy model artifacts into TensorFlow Serving versioned folder

```bash
cp -r ./tmp/model/tip_model/* ./serving_dir/tip_model/1
```

## 5) Run TensorFlow Serving container

```bash
docker run -p 8501:8501 --mount type=bind,source="$(pwd)/serving_dir/tip_model",target=/models/tip_model -e MODEL_NAME=tip_model -t tensorflow/serving
```

Note: Keep this terminal open while serving.

## 6) Test prediction from a second terminal

```bash
curl -d '{"instances":[{"passenger_count":1,"trip_distance":12.2,"PULocationID":"193","DOLocationID":"264","payment_type":"2","fare_amount":20.4,"tolls_amount":0.0}]}' -X POST http://localhost:8501/v1/models/tip_model:predict
```

## 7) Stop the container when done

Press Ctrl+C in the terminal where docker run is active.