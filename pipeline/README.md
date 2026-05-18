# Pipeline Quickstart

## Run Locally with .venv and uv

1. Go to the pipeline folder.

	```bash
	cd /c/WORKSPACE/data-engineering/pipeline
	```

2. Run the pipeline with uv from the project virtual environment.

	```bash
	.venv/Scripts/uv.exe run pipeline.py 12
	```

3. Optional checks.

	```bash
	.venv/Scripts/uv.exe --version
	.venv/Scripts/python.exe -m pip list
	```

## Build and Run with Docker

1. Build from the repository root using the pipeline directory as context.

	```bash
	cd /c/WORKSPACE/data-engineering
	docker build -t test:pandas ./pipeline
	```

2. Run the pipeline in the container.

	```bash
	docker run --rm test:pandas 12
	```

3. Open a shell in the same image (overrides entrypoint).

	```bash
	docker run -it --rm --entrypoint bash test:pandas
	```

## Common Gotchas

- Use `-it`, not `--it`.
- Running `docker run --rm test:pandas` without a month argument will fail.
- Running `docker run -it --rm test:pandas bash` fails because `bash` is passed to `pipeline.py` unless entrypoint is overridden.

## Docker Mounting Guide (Windows)

Use bind mounts with `-v <host_path>:<container_path>`.

### 1) Mount a folder (Git Bash)

```bash
cd /c/WORKSPACE/data-engineering
docker run --rm -it -v "$(pwd -W)/test:/app/test" ubuntu bash
```

Verify inside container:

```bash
ls -la /app/test
```

### 2) Mount a folder (PowerShell)

```powershell
cd C:\WORKSPACE\data-engineering
docker run --rm -it -v "${PWD}\test:/app/test" ubuntu bash
```

### 3) Mount a single file

Git Bash:

```bash
docker run --rm -it -v "$(pwd -W)/test/script.py:/app/script.py" ubuntu bash
```

PowerShell:

```powershell
docker run --rm -it -v "${PWD}\test\script.py:/app/script.py" ubuntu bash
```

Verify file inside container:

```bash
ls -la /app/script.py
```

### Common mount mistakes

- Missing leading `/` on container path (use `/app/test`, not `app/test`).
- Using backslashes for container path (always use `/` in container paths).
- In Git Bash, prefer `$(pwd -W)` for host paths.

### Named Volume vs Bind Mount

- Named volume (`name:/path`): Managed by Docker, easier.
- Bind mount (`/host/path:/container/path`): Direct mapping to host filesystem, more control.
