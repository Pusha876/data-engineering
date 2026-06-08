-- SELECT THE COLUMNS INTERESTED FOR YOU
CREATE OR REPLACE TABLE `kestra-sandbox-497720.zoomcamp.yellow_tripdata_2019_02` (
  passenger_count INTEGER,
  trip_distance FLOAT64,
  PULocationID STRING,
  DOLocationID STRING,
  payment_type STRING,
  fare_amount FLOAT64,
  tolls_amount FLOAT64,
  tip_amount FLOAT64
) AS
SELECT
  passenger_count,
  CAST(trip_distance AS FLOAT64) AS trip_distance,
  PULocationID,
  DOLocationID,
  CAST(payment_type AS STRING) AS payment_type,
  CAST(fare_amount AS FLOAT64) AS fare_amount,
  CAST(tolls_amount AS FLOAT64) AS tolls_amount,
  CAST(tip_amount AS FLOAT64) AS tip_amount
FROM `kestra-sandbox-497720.zoomcamp.yellow_tripdata`
WHERE fare_amount != 0
  AND DATE(tpep_pickup_datetime) >= DATE "2019-02-01"
  AND DATE(tpep_pickup_datetime) < DATE "2019-03-01";

-- CREATE A ML TABLE WITH APPROPRIATE TYPES FOR THE COLUMNS
SELECT
  passenger_count, trip_distance, PULocationID, DOLocationID,
  payment_type, fare_amount, tolls_amount, tip_amount
FROM `kestra-sandbox-497720.zoomcamp.yellow_tripdata_2019_02`
WHERE fare_amount != 0;

CREATE OR REPLACE MODEL zoomcamp.tip_model
OPTIONS(
  model_type='linear_reg',
  input_label_cols=['tip_amount'],
  data_split_method='AUTO_SPLIT'
) AS
SELECT
  passenger_count,
  trip_distance,
  PULocationID,
  DOLocationID,
  payment_type,
  fare_amount,
  tolls_amount,
  tip_amount
FROM zoomcamp.yellow_tripdata_2019_02
WHERE tip_amount IS NOT NULL;