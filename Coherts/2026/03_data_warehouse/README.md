# Data Warehouse Homework (Cohort 2026)

This folder contains the assets for the data warehouse exercises, including:

- GCS upload helper script: [load_yellow_taxi_data.py](load_yellow_taxi_data.py)
- BigQuery SQL scripts: [big_query_external_table.sql](big_query_external_table.sql), [big_query_ml.sql](../../03-data-warehouse/big_query_ml.sql)
- Homework write-up: [homework.md](homework.md)

## Overview

The script [load_yellow_taxi_data.py](load_yellow_taxi_data.py) does the following:

1. Downloads Yellow Taxi parquet files for months 01 to 06 in 2024.
2. Creates or reuses a Google Cloud Storage bucket.
3. Uploads files to GCS and verifies uploads.

## Prerequisites

1. Python virtual environment is active.
2. Google Cloud SDK is installed.
3. You have access to a GCP project with bucket create and write permissions.

## Install Dependencies

Run from the workspace root (or from any terminal using the same virtual environment):

```bash
uv pip install --python c:/WORKSPACE/data-engineering/.venv/Scripts/python.exe google-cloud-storage
```

## Authentication

Use one of the following options.

### Option A: Application Default Credentials (recommended)

```bash
gcloud auth application-default login
```

The script automatically uses ADC when no local credential file is available.

### Option B: Service Account JSON

Set the credential path before running:

```bash
export GOOGLE_APPLICATION_CREDENTIALS="/c/path/to/service-account.json"
```

## Bucket Configuration

Bucket names must be globally unique.

Set a custom bucket name:

```bash
export BUCKET_NAME="jamie-nyc-taxi-2026-$(date +%s)"
```

If `BUCKET_NAME` is not set, the script defaults to `pushtech_bootcamp_hw3_2026`.

## Run

From this folder:

```bash
cd /c/WORKSPACE/data-engineering/Coherts/2026/03_data_warehouse
python load_yellow_taxi_data.py
```

## Expected Output

Typical successful logs:

1. ADC fallback message (when local JSON is absent).
2. Bucket created or already accessible.
3. Download confirmation for each monthly parquet file.
4. Upload confirmation to GCS.
5. Verification success for each uploaded object.

## Troubleshooting

1. `ModuleNotFoundError: No module named 'google'`
Install dependencies using the command above.

2. `FileNotFoundError` for credentials
Run ADC login or set `GOOGLE_APPLICATION_CREDENTIALS`.

3. Bucket already exists or access denied
Choose a different `BUCKET_NAME` and re-run.
