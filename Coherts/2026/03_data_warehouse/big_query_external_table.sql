-- This SQL script creates an external table in BigQuery that references Parquet files stored in a Google Cloud Storage bucket.
CREATE OR REPLACE EXTERNAL TABLE `kestra-sandbox-497720.zoomcamp.yellow_taxi_external`
OPTIONS (
  format = 'PARQUET',
  uris = ['gs://pushtech_bootcamp_hw3_2026/yellow_tripdata_2024-*.parquet']
);

-- After creating the external table, we can query it just like any other table in BigQuery. For example, we can count the total number of rows in the external table:
SELECT COUNT(*) AS total_rows
FROM `kestra-sandbox-497720.zoomcamp.yellow_taxi_external`;

-- Optional: Count records by month for 2024 Yellow Taxi Data
SELECT 
  EXTRACT(MONTH FROM tpep_pickup_datetime) AS month,
  COUNT(*) AS record_count
FROM `kestra-sandbox-497720.zoomcamp.yellow_taxi_external`
GROUP BY month
ORDER BY month;

-- Count distinct PULocationIDs from the external table
SELECT COUNT(DISTINCT PULocationID) AS distinct_pu_locations
FROM `kestra-sandbox-497720.zoomcamp.yellow_taxi_external`;

-- Optional: Create a native table from the external table for better performance
CREATE OR REPLACE TABLE `kestra-sandbox-497720.zoomcamp.yellow_taxi_native` AS
SELECT * FROM `kestra-sandbox-497720.zoomcamp.yellow_taxi_external`;

-- Count distinct PULocationIDs from the native table
SELECT COUNT(DISTINCT PULocationID) AS distinct_pu_locations
FROM `kestra-sandbox-497720.zoomcamp.yellow_taxi_native`;

-- Count the number of trips with a fare amount of zero in the native table
SELECT COUNT(*) AS zero_fare_trips
FROM zoomcamp.yellow_taxi_native
WHERE fare_amount = 0;