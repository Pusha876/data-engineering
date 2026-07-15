"""@bruin

# Raw ingestion asset for NYC Taxi parquet files.
name: ingestion.trips

type: python

image: python:3.11

connection: duckdb-default

materialization:
  type: table
  strategy: append

columns:
  - name: vendorid
    type: integer
    description: Vendor identifier from the source parquet.
  - name: pickup_datetime
    type: timestamp
    description: Trip pickup timestamp from yellow/green source files.
  - name: dropoff_datetime
    type: timestamp
    description: Trip dropoff timestamp from yellow/green source files.
  - name: passenger_count
    type: double
    description: Number of passengers reported for the trip.
  - name: trip_distance
    type: double
    description: Trip distance in miles.
  - name: ratecodeid
    type: integer
    description: TLC rate code identifier.
  - name: store_and_fwd_flag
    type: string
    description: Store-and-forward flag from source data.
  - name: pulocationid
    type: integer
    description: Pickup location zone identifier.
  - name: dolocationid
    type: integer
    description: Dropoff location zone identifier.
  - name: payment_type
    type: integer
    description: Payment type identifier from source data.
  - name: fare_amount
    type: double
    description: Fare amount for the trip.
  - name: extra
    type: double
    description: Extra charges.
  - name: mta_tax
    type: double
    description: MTA tax amount.
  - name: tip_amount
    type: double
    description: Tip amount.
  - name: tolls_amount
    type: double
    description: Tolls amount.
  - name: improvement_surcharge
    type: double
    description: Improvement surcharge amount.
  - name: total_amount
    type: double
    description: Total charged amount.
  - name: congestion_surcharge
    type: double
    description: Congestion surcharge amount.
  - name: airport_fee
    type: double
    description: Airport fee amount.
  - name: ehail_fee
    type: double
    description: E-hail fee amount (green taxi only).
  - name: trip_type
    type: integer
    description: Green taxi trip type code.
  - name: taxi_type
    type: string
    description: Taxi type derived from pipeline variable.
    checks:
      - name: not_null
  - name: source_file
    type: string
    description: Source parquet file name used for ingestion.
    checks:
      - name: not_null
  - name: extracted_at
    type: timestamp
    description: UTC timestamp when this record was ingested.

@bruin"""

import io
import json
import os
from datetime import datetime, timezone

import pandas as pd
import requests
from dateutil.relativedelta import relativedelta

BASE_URL = "https://d37ci6vzurychx.cloudfront.net/trip-data"

TARGET_COLUMNS = [
    "vendorid",
    "pickup_datetime",
    "dropoff_datetime",
    "passenger_count",
    "trip_distance",
    "ratecodeid",
    "store_and_fwd_flag",
    "pulocationid",
    "dolocationid",
    "payment_type",
    "fare_amount",
    "extra",
    "mta_tax",
    "tip_amount",
    "tolls_amount",
    "improvement_surcharge",
    "total_amount",
    "congestion_surcharge",
    "airport_fee",
    "ehail_fee",
    "trip_type",
    "taxi_type",
    "source_file",
    "extracted_at",
]


def _get_taxi_types() -> list[str]:
    vars_payload = os.environ.get("BRUIN_VARS", "{}")
    parsed = json.loads(vars_payload)
    taxi_types = parsed.get("taxi_types", ["yellow", "green"])
    return [str(t).strip().lower() for t in taxi_types if str(t).strip()]


def _month_starts(start_date: str, end_date: str) -> list[datetime]:
    start = datetime.strptime(start_date, "%Y-%m-%d")
    end = datetime.strptime(end_date, "%Y-%m-%d")
    current = start.replace(day=1)
    months = []
    while current < end:
        months.append(current)
        current = current + relativedelta(months=1)
    return months


def _download_parquet(url: str) -> pd.DataFrame:
    response = requests.get(url, timeout=120)
    response.raise_for_status()
    return pd.read_parquet(io.BytesIO(response.content), engine="pyarrow")


def _normalize_frame(
    df: pd.DataFrame,
    taxi_type: str,
    file_name: str,
    extracted_at: datetime,
) -> pd.DataFrame:
    rename_map = {
        "VendorID": "vendorid",
        "vendorid": "vendorid",
        "tpep_pickup_datetime": "pickup_datetime",
        "lpep_pickup_datetime": "pickup_datetime",
        "tpep_dropoff_datetime": "dropoff_datetime",
        "lpep_dropoff_datetime": "dropoff_datetime",
        "RatecodeID": "ratecodeid",
        "ratecodeid": "ratecodeid",
        "PULocationID": "pulocationid",
        "DOLocationID": "dolocationid",
    }
    normalized = df.rename(columns=rename_map).copy()
    normalized["pickup_datetime"] = pd.to_datetime(
        normalized.get("pickup_datetime"),
        errors="coerce",
    )
    normalized["dropoff_datetime"] = pd.to_datetime(
        normalized.get("dropoff_datetime"),
        errors="coerce",
    )
    normalized["taxi_type"] = taxi_type
    normalized["source_file"] = file_name
    normalized["extracted_at"] = extracted_at

    for col in TARGET_COLUMNS:
        if col not in normalized.columns:
            normalized[col] = pd.NA

    return normalized[TARGET_COLUMNS]


def materialize() -> pd.DataFrame:
    start_date = os.environ["BRUIN_START_DATE"]
    end_date = os.environ["BRUIN_END_DATE"]
    taxi_types = _get_taxi_types()
    extracted_at = datetime.now(timezone.utc)

    frames = []
    for month_start in _month_starts(start_date, end_date):
        month_str = month_start.strftime("%Y-%m")
        for taxi_type in taxi_types:
            file_name = f"{taxi_type}_tripdata_{month_str}.parquet"
            url = f"{BASE_URL}/{file_name}"
            try:
                raw_df = _download_parquet(url)
            except requests.HTTPError as exc:
                if (
                    exc.response is not None
                    and exc.response.status_code == 404
                ):
                    continue
                raise

            frames.append(
                _normalize_frame(raw_df, taxi_type, file_name, extracted_at)
            )

    if not frames:
        return pd.DataFrame(columns=TARGET_COLUMNS)

    return pd.concat(frames, ignore_index=True)
