FROM python:3.9-slim
COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin/

RUN uv pip install --system pandas pyarrow fastparquet

WORKDIR /code
COPY pipeline.py /code/pipeline.py


ENTRYPOINT ["uv", "run", "pipeline.py"]