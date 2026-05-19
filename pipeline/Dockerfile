FROM python:3.12-slim
COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin/

WORKDIR /code
ENV PATH="/code/.venv/bin:$PATH"

COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-dev

COPY ingest_data.py ./


ENTRYPOINT ["python", "ingest_data.py"]
CMD ["12"]