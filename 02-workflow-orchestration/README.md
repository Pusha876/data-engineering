# Workflow Orchestration

## Docker Compose naming issue

If `docker compose up -d` fails with an error like:

`Conflict. The container name "/pg-database" is already in use`

the cause is usually a hardcoded `container_name` in `docker-compose.yml`.

### Why it happens

`container_name` forces Docker to reuse the same global container name every time.
That bypasses Compose project scoping, so an existing container from a previous run
can block startup.

### How to fix it

Remove `container_name` from the service definitions and let Docker Compose generate
project-scoped names automatically. For this project, the `postgres` and `pgadmin`
services should not set `container_name`.

### Future reference

If you ever need to clear an old container manually, you can inspect and remove it:

```bash
docker ps -a
docker rm -f pg-database
```

In general, avoid `container_name` unless you truly need a fixed global name.

## Next step Summary (2026-05-27)

Today we debugged and fixed the Postgres connectivity issues for the taxi ingestion flows.

### What we changed

- Updated JDBC host in both Kestra Postgres flows from `pgdatabase` to `postgres`:
	- `Flow/04_postgres_taxi.yaml`
	- `Flow/05_postgres_taxi_scheduled.yaml`
- Updated `docker-compose.yml` so the `kestra` service joins both networks:
	- `default` (for `kestra_postgres`)
	- `pg-network` (for app `postgres`)

### Why this was needed

- Error root cause was network/DNS resolution (`UnknownHostException`), not a missing green table.
- The flows already contain `CREATE TABLE IF NOT EXISTS` for green taxi and will create target tables during execution.

### Notes about green taxi ingestion

- Green ingestion is supported by the Kestra flow input (`taxi=green`).
- Flow target table naming is based on `public.{{inputs.taxi}}_tripdata` by default.
- The standalone ingest container is not required to fix this Kestra connectivity issue.

### Operational reminders

- After flow YAML changes, ensure the running flow definition in Kestra UI is updated/re-imported.
- Recreate/restart services after compose networking changes so containers pick up new network attachments.

## GCP Keyless Auth Runbook (2026-05-28)

We removed `serviceAccount` from these flow files so Kestra can use Application Default Credentials (ADC):

- `Flow/07_gcp_setup.yaml`
- `Flow/08_gcp_taxi.yaml`
- `Flow/09_gcp_taxi_scheduled.yaml`

### Option 1: Kestra running on GCP with attached Service Account (recommended for production)

Use this when Kestra runs on GCE/GKE/Cloud Run and can use a workload identity natively.

1. Set variables.

```bash
export PROJECT_ID="your-project-id"
export PROJECT_NUMBER="$(gcloud projects describe "$PROJECT_ID" --format='value(projectNumber)')"
export REGION="europe-west2"
export KESTRA_SA="kestra-runtime-sa"
```

2. Create runtime service account.

```bash
gcloud iam service-accounts create "$KESTRA_SA" \
	--project "$PROJECT_ID" \
	--display-name "Kestra runtime service account"
```

3. Grant minimum required roles.

```bash
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
	--member "serviceAccount:${KESTRA_SA}@${PROJECT_ID}.iam.gserviceaccount.com" \
	--role "roles/bigquery.jobUser"

gcloud projects add-iam-policy-binding "$PROJECT_ID" \
	--member "serviceAccount:${KESTRA_SA}@${PROJECT_ID}.iam.gserviceaccount.com" \
	--role "roles/storage.objectAdmin"

gcloud projects add-iam-policy-binding "$PROJECT_ID" \
	--member "serviceAccount:${KESTRA_SA}@${PROJECT_ID}.iam.gserviceaccount.com" \
	--role "roles/bigquery.dataEditor"
```

4. Attach that service account to your Kestra runtime (GCE/GKE/Cloud Run).

```bash
# GCE example
gcloud compute instances set-service-account YOUR_VM_NAME \
	--zone YOUR_ZONE \
	--service-account "${KESTRA_SA}@${PROJECT_ID}.iam.gserviceaccount.com" \
	--scopes https://www.googleapis.com/auth/cloud-platform
```

5. Run flows in order after importing latest YAML.

```text
06_gcp_kv -> 07_gcp_setup -> 08_gcp_taxi
```

### Option 2: Local Docker Kestra with Workload Identity Federation (keyless, recommended for local)

Use this when Kestra runs locally in Docker but must access GCP without JSON private keys.

1. Set variables.

```bash
export PROJECT_ID="your-project-id"
export PROJECT_NUMBER="$(gcloud projects describe "$PROJECT_ID" --format='value(projectNumber)')"
export REGION="global"
export POOL_ID="kestra-local-pool"
export PROVIDER_ID="azure-or-oidc"
export KESTRA_SA="kestra-runtime-sa"
```

2. Create service account for GCP access.

```bash
gcloud iam service-accounts create "$KESTRA_SA" \
	--project "$PROJECT_ID" \
	--display-name "Kestra local runtime SA"
```

3. Grant minimum required roles to that service account.

```bash
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
	--member "serviceAccount:${KESTRA_SA}@${PROJECT_ID}.iam.gserviceaccount.com" \
	--role "roles/bigquery.jobUser"

gcloud projects add-iam-policy-binding "$PROJECT_ID" \
	--member "serviceAccount:${KESTRA_SA}@${PROJECT_ID}.iam.gserviceaccount.com" \
	--role "roles/bigquery.dataEditor"

gcloud projects add-iam-policy-binding "$PROJECT_ID" \
	--member "serviceAccount:${KESTRA_SA}@${PROJECT_ID}.iam.gserviceaccount.com" \
	--role "roles/storage.objectAdmin"
```

4. Create workload identity pool.

```bash
gcloud iam workload-identity-pools create "$POOL_ID" \
	--project "$PROJECT_ID" \
	--location "global" \
	--display-name "Kestra local pool"
```

5. Create provider in the pool.

```bash
# Example for OIDC provider. Replace issuer URI and attribute mapping to match your IdP.
gcloud iam workload-identity-pools providers create-oidc "$PROVIDER_ID" \
	--project "$PROJECT_ID" \
	--location "global" \
	--workload-identity-pool "$POOL_ID" \
	--display-name "Kestra local provider" \
	--issuer-uri "https://YOUR_ISSUER" \
	--attribute-mapping "google.subject=assertion.sub"
```

6. Allow identities from that pool/provider to impersonate the service account.

```bash
gcloud iam service-accounts add-iam-policy-binding \
	"${KESTRA_SA}@${PROJECT_ID}.iam.gserviceaccount.com" \
	--project "$PROJECT_ID" \
	--role roles/iam.workloadIdentityUser \
	--member "principalSet://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${POOL_ID}/*"
```

If this command shows `projects//locations/...`, then `PROJECT_NUMBER` is empty. Confirm it before running IAM bindings:

```bash
echo "$PROJECT_ID"
echo "$PROJECT_NUMBER"
gcloud auth list
gcloud config get-value account
gcloud projects describe "$PROJECT_ID" --format='value(projectNumber)'
```

7. Generate (or refresh) external account credential config file (no private key).

You already generated `.secrets/gcp-wif-cred.json`. For your OIDC provider (`azure-or-oidc`), the correct pattern is file-sourced JWT. The only requirement is that `credential_source.file` points to a real token file that exists.

```bash
cd /c/WORKSPACE/data-engineering/02-workflow-orchestration
mkdir -p .secrets

# Choose a real local path where your IdP token will exist.
export IDP_TOKEN_FILE="$(pwd)/.secrets/idp-token.jwt"

# Recreate the WIF config so it references the real token file path.
gcloud iam workload-identity-pools create-cred-config \
	"projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${POOL_ID}/providers/${PROVIDER_ID}" \
	--service-account "${KESTRA_SA}@${PROJECT_ID}.iam.gserviceaccount.com" \
	--credential-source-file "$IDP_TOKEN_FILE" \
	--output-file "$(pwd)/.secrets/gcp-wif-cred.json"

# Quick check: this path must not be a placeholder.
grep -n '"file"' .secrets/gcp-wif-cred.json
```

If `idp-token.jwt` is missing, authentication fails with `Invalid credential location`.

Optional: auto-refresh the token file before each Kestra run.

```bash
cd /c/WORKSPACE/data-engineering/02-workflow-orchestration
chmod +x ./.secrets/refresh-idp-token.sh

# Run this before executing 07_gcp_setup / 08_gcp_taxi.
IDP_MODE=google ./.secrets/refresh-idp-token.sh
```

If you want to choose provider mode at runtime, use one of these commands:

```bash
# Azure Entra ID mode
cd /c/WORKSPACE/data-engineering/02-workflow-orchestration
IDP_MODE=azure ./.secrets/refresh-idp-token.sh

# Google OIDC mode
cd /c/WORKSPACE/data-engineering/02-workflow-orchestration
export PROJECT_NUMBER="1073318522517"
export POOL_ID="kestra-local-pool"
export PROVIDER_ID="azure-or-oidc"
IDP_MODE=google ./.secrets/refresh-idp-token.sh
```

For production, prefer executable-sourced credentials in the WIF config so Google auth libraries can refresh tokens automatically.

8. Mount the credential config into Kestra and point ADC to it.

```yaml
# docker-compose.yml (kestra service)
volumes:
	- ./.secrets/gcp-wif-cred.json:/etc/gcp/gcp-wif-cred.json:ro
environment:
	GOOGLE_APPLICATION_CREDENTIALS: /etc/gcp/gcp-wif-cred.json
```

9. Restart Kestra so env/volume changes apply.

```bash
cd /c/WORKSPACE/data-engineering/02-workflow-orchestration
docker compose up -d --force-recreate kestra
```

10. In Kestra UI, import/reload latest flow YAML and run in order.

```text
06_gcp_kv -> 07_gcp_setup -> 08_gcp_taxi
```
