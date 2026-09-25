FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    DBT_PROFILES_DIR=/app

WORKDIR /app

RUN pip install --no-cache-dir "dbt-core>=1.10,<1.11" "dbt-postgres==1.10.2"

COPY . .

ENTRYPOINT ["dbt"]
CMD ["build"]