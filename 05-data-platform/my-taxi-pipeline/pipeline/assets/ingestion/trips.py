"""@bruin
name: ingestion.trips
type: python
image: python:3.11

materialization:
  type: table
  strategy: append
connection: duckdb-default

columns:
  - name: pickup_datetime
    type: timestamp
    description: "When the meter was engaged"
  - name: dropoff_datetime
    type: timestamp
    description: "When the meter was disengaged"
@bruin"""

import os
import json
from io import BytesIO
from datetime import datetime

import pandas as pd
import requests


BASE_URL = "https://d37ci6vzurychx.cloudfront.net/trip-data"
LATEST_AVAILABLE_MONTH = datetime(2025, 11, 1)


def _parse_bruin_date(value: str) -> datetime:
    """Parse Bruin date strings, including ISO timestamps with a trailing Z."""
    return datetime.fromisoformat(value.replace("Z", "+00:00")).replace(
      tzinfo=None
    )


def _iter_month_starts(start_date: datetime, end_date: datetime):
    current = datetime(
      start_date.year, start_date.month, 1, tzinfo=start_date.tzinfo)
    final = datetime(
      end_date.year, end_date.month, 1, tzinfo=end_date.tzinfo)

    while current <= final:
        yield current
        if current.month == 12:
            current = datetime(current.year + 1, 1, 1, tzinfo=current.tzinfo)
        else:
            current = datetime(
              current.year, current.month + 1, 1, tzinfo=current.tzinfo)


def _fetch_month(taxi_type: str, month_start: datetime) -> pd.DataFrame:
    url = (
      f"{BASE_URL}/{taxi_type}_tripdata_"
      f"{month_start.year:04d}-{month_start.month:02d}.parquet"
    )
    response = requests.get(url, timeout=120)
    response.raise_for_status()

    df = pd.read_parquet(BytesIO(response.content), engine="pyarrow")

    # Standardize key fields expected by downstream assets.
    if "pickup_datetime" not in df.columns:
        if "tpep_pickup_datetime" in df.columns:
            df["pickup_datetime"] = df["tpep_pickup_datetime"]
        elif "lpep_pickup_datetime" in df.columns:
            df["pickup_datetime"] = df["lpep_pickup_datetime"]

    if "dropoff_datetime" not in df.columns:
        if "tpep_dropoff_datetime" in df.columns:
            df["dropoff_datetime"] = df["tpep_dropoff_datetime"]
        elif "lpep_dropoff_datetime" in df.columns:
            df["dropoff_datetime"] = df["lpep_dropoff_datetime"]

    if (
      "pickup_location_id" not in df.columns
      and "pu_location_id" in df.columns
    ):
        df["pickup_location_id"] = df["pu_location_id"]

    if (
      "dropoff_location_id" not in df.columns
      and "do_location_id" in df.columns
    ):
        df["dropoff_location_id"] = df["do_location_id"]

    if "taxi_type" not in df.columns:
        df["taxi_type"] = taxi_type

    return df


def materialize():
    start_date = _parse_bruin_date(os.environ["BRUIN_START_DATE"])
    end_date = _parse_bruin_date(os.environ["BRUIN_END_DATE"])
    taxi_types = json.loads(
      os.environ["BRUIN_VARS"]).get("taxi_types", ["yellow"])

    if start_date > LATEST_AVAILABLE_MONTH:
        raise ValueError(
          "NYC TLC trip data is only available through 2025-11. "
          "Adjust BRUIN_START_DATE / BRUIN_END_DATE to an earlier month."
        )

    if end_date > LATEST_AVAILABLE_MONTH:
        end_date = LATEST_AVAILABLE_MONTH

    frames = []

    for taxi_type in taxi_types:
        for month_start in _iter_month_starts(start_date, end_date):
            frames.append(_fetch_month(taxi_type, month_start))

    if not frames:
        return pd.DataFrame()

    final_dataframe = pd.concat(frames, ignore_index=True)
    return final_dataframe
