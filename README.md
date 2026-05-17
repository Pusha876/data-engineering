# data-engineering
docker-workshop

## Mount folders/files into a Docker container (Windows)

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

## Common mistakes

- Missing leading `/` on container path (use `/app/test`, not `app/test`).
- Using backslashes for container path (always use `/` in container paths).
- In Git Bash, prefer `$(pwd -W)` for host paths.
