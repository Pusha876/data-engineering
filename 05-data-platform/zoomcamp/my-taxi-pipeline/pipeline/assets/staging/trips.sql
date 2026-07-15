/* @bruin

name: staging.trips
type: duckdb.sql

materialization:
  type: table
  strategy: time_interval
  incremental_key: pickup_datetime
  time_granularity: timestamp

depends:
  - ingestion.trips
  - ingestion.payment_lookup

columns:
  - name: pickup_datetime
    type: timestamp
    description: Trip pickup timestamp.
    primary_key: true
    nullable: false
    checks:
      - name: not_null
  - name: dropoff_datetime
    type: timestamp
    description: Trip dropoff timestamp.
    nullable: false
    checks:
      - name: not_null
  - name: pulocationid
    type: integer
    description: Pickup location identifier.
    primary_key: true
    nullable: false
    checks:
      - name: not_null
  - name: dolocationid
    type: integer
    description: Dropoff location identifier.
    primary_key: true
    nullable: false
    checks:
      - name: not_null
  - name: taxi_type
    type: string
    description: Taxi type from ingestion variable set.
    primary_key: true
    nullable: false
    checks:
      - name: not_null
  - name: payment_type_id
    type: integer
    description: Payment type identifier.
    checks:
      - name: not_null
  - name: payment_type_name
    type: string
    description: Enriched payment type label.
    checks:
      - name: not_null
  - name: vendorid
    type: integer
    description: Vendor identifier from source data.
    checks:
      - name: not_null
  - name: fare_amount
    type: double
    description: Fare amount in USD.
    checks:
      - name: non_negative
  - name: trip_distance
    type: double
    description: Trip distance in miles.
    checks:
      - name: non_negative
  - name: total_amount
    type: double
    description: Total charged amount in USD.
    checks:
      - name: non_negative

custom_checks:
  - name: no_duplicate_trips_in_window
    description: Composite trip key must be unique in staged output.
    value: 0
    query: |
      SELECT COUNT(*)
      FROM (
        SELECT
          pickup_datetime,
          dropoff_datetime,
          pulocationid,
          dolocationid,
          fare_amount,
          taxi_type,
          COUNT(*) AS row_count
        FROM staging.trips
        GROUP BY 1,2,3,4,5,6
        HAVING COUNT(*) > 1
      ) AS duplicates

@bruin */

-- TODO: Write the staging SELECT query.
--
-- Purpose of staging:
-- - Clean and normalize schema from ingestion
-- - Deduplicate records (important if ingestion uses append strategy)
-- - Enrich with lookup tables (JOINs)
-- - Filter invalid rows (null PKs, negative values, etc.)
--
-- Why filter by {{ start_datetime }} / {{ end_datetime }}?
-- When using `time_interval` strategy, Bruin:
--   1. DELETES rows where `incremental_key` falls within the run's time window
--   2. INSERTS the result of your query
-- Therefore, your query MUST filter to the same time window so only that subset is inserted.
-- If you don't filter, you'll insert ALL data but only delete the window's data = duplicates.

WITH source_filtered AS (
  SELECT
    vendorid,
    pickup_datetime,
    dropoff_datetime,
    passenger_count,
    trip_distance,
    ratecodeid,
    store_and_fwd_flag,
    pulocationid,
    dolocationid,
    payment_type AS payment_type_id,
    fare_amount,
    extra,
    mta_tax,
    tip_amount,
    tolls_amount,
    improvement_surcharge,
    total_amount,
    congestion_surcharge,
    airport_fee,
    ehail_fee,
    trip_type,
    taxi_type,
    source_file,
    extracted_at
  FROM ingestion.trips
  WHERE pickup_datetime >= '{{ start_datetime }}'
    AND pickup_datetime < '{{ end_datetime }}'
),
enriched AS (
  SELECT
    s.vendorid,
    s.pickup_datetime,
    s.dropoff_datetime,
    s.passenger_count,
    s.trip_distance,
    s.ratecodeid,
    s.store_and_fwd_flag,
    s.pulocationid,
    s.dolocationid,
    COALESCE(s.payment_type_id, 5) AS payment_type_id,
    COALESCE(p.payment_type_name, 'unknown') AS payment_type_name,
    s.fare_amount,
    s.extra,
    s.mta_tax,
    s.tip_amount,
    s.tolls_amount,
    s.improvement_surcharge,
    s.total_amount,
    s.congestion_surcharge,
    s.airport_fee,
    s.ehail_fee,
    s.trip_type,
    s.taxi_type,
    s.source_file,
    s.extracted_at
  FROM source_filtered s
  LEFT JOIN ingestion.payment_lookup p
    ON COALESCE(s.payment_type_id, 5) = p.payment_type_id
),
deduped AS (
  SELECT
    *,
    ROW_NUMBER() OVER (
      PARTITION BY pickup_datetime, dropoff_datetime, pulocationid, dolocationid, fare_amount, taxi_type
      ORDER BY extracted_at DESC
    ) AS rn
  FROM enriched
  WHERE pickup_datetime IS NOT NULL
    AND dropoff_datetime IS NOT NULL
    AND pulocationid IS NOT NULL
    AND dolocationid IS NOT NULL
    AND fare_amount >= 0
    AND total_amount >= 0
)
SELECT
  vendorid,
  pickup_datetime,
  dropoff_datetime,
  passenger_count,
  trip_distance,
  ratecodeid,
  store_and_fwd_flag,
  pulocationid,
  dolocationid,
  payment_type_id,
  payment_type_name,
  fare_amount,
  extra,
  mta_tax,
  tip_amount,
  tolls_amount,
  improvement_surcharge,
  total_amount,
  congestion_surcharge,
  airport_fee,
  ehail_fee,
  trip_type,
  taxi_type,
  source_file,
  extracted_at
FROM deduped
WHERE rn = 1
