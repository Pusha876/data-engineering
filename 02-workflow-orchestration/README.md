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
