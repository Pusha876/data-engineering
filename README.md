# Data Engineering

**A hands-on, container-first data engineering sandbox** — ingesting NYC Taxi data into Postgres, browsing it with pgAdmin, and orchestrating everything with Docker Compose.

---

## Docker for Data Engineering

### Why Docker?

Running databases and tooling locally creates "works on my machine" problems. Docker solves this by packaging each service — Postgres, pgAdmin, the ingest script — into isolated containers with pinned versions and explicit configuration. The result is a reproducible environment anyone can spin up with a single command.

### What Is Docker Compose?

Docker Compose lets you define a multi-container application in one YAML file (`docker-compose.yaml`). Instead of running long `docker run` commands by hand, Compose handles:

- Starting services in the right order (`pgadmin` waits for `postgres`)
- Wiring containers together on a shared network (`pg-network`)
- Managing named volumes so database data survives container restarts
- Exposing the right host ports (`5432` for Postgres, `8085` for pgAdmin)

### Real-World Workflow

1. `docker compose up -d` — bring up Postgres and pgAdmin in the background.
2. Run `ingest_data.py` (locally with `uv` or as its own container) to pull NYC Taxi Parquet data and load it into the `ny_taxi` database.
3. Open pgAdmin at `http://localhost:8085` to query and explore the loaded data.
4. `docker compose down` — tear everything down. Named volumes keep the data intact for next time.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        Host Machine                         │
│                                                             │
│   ┌─────────────────────────────────────────────────────┐  │
│   │                   Docker Engine                     │  │
│   │                                                     │  │
│   │   ┌──────────────────────┐                          │  │
│   │   │   ingest_data.py     │  (Python / uv or Docker) │  │
│   │   │   - Reads Parquet    │                          │  │
│   │   │   - Chunks to SQL    │                          │  │
│   │   └──────────┬───────────┘                          │  │
│   │              │ SQLAlchemy / psycopg2                 │  │
│   │   ┌──────────▼───────────────────────────────────┐  │  │
│   │   │              pg-network (bridge)              │  │  │
│   │   │                                              │  │  │
│   │   │  ┌─────────────────────┐  ┌───────────────┐  │  │  │
│   │   │  │  pg-database        │  │   pgadmin     │  │  │  │
│   │   │  │  postgres:18        │  │  pgadmin4     │  │  │  │
│   │   │  │                     │  │               │  │  │  │
│   │   │  │  db:    ny_taxi     │  │  :80 (int)    │  │  │  │
│   │   │  │  port:  5432 (int)  │  └──────┬────────┘  │  │  │
│   │   │  │                     │         │            │  │  │
│   │   │  │  [named volume]     │         │            │  │  │
│   │   │  │  /var/lib/          │         │            │  │  │
│   │   │  │    postgresql       │         │            │  │  │
│   │   │  └─────────────────────┘         │            │  │  │
│   │   └──────────────────────────────────┘            │  │  │
│   └─────────────────────────────────────────────────── ┘  │
│                          │                    │            │
│                     localhost:5432       localhost:8085     │
└─────────────────────────────────────────────────────────────┘
```

| Component | Image | Port | Purpose |
|---|---|---|---|
| `pg-database` | `postgres:18` | `5432` | Stores ingested NYC Taxi data |
| `pgadmin` | `dpage/pgadmin4` | `8085` | Web UI to query and explore the DB |
| `ingest_data.py` | `python:3.12-slim` | — | Pulls Parquet data, loads into Postgres |

---

## What This Repo Demonstrates

- Local execution in a project-scoped virtual environment (`pipeline/.venv`) using `uv`.
- Containerized pipeline runs with explicit, repeatable Docker commands.
- Multi-service orchestration with Docker Compose (Postgres + pgAdmin on a shared network).
- Named volume strategy for Postgres 18+: mounting `/var/lib/postgresql` rather than `/var/lib/postgresql/data`.
- Practical Windows mount patterns for files and folders when working with Docker.

## Start Here

- Pipeline setup and run commands: `pipeline/README.md`
- Ingest script: `pipeline/ingest_data.py`
- Compose stack: `pipeline/docker-compose.yaml`
- Container setup: `pipeline/Dockerfile`
