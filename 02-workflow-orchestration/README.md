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
