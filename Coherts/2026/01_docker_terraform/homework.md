# Homework

## Question 1. Understanding Docker Images

Run Docker with the `python:3.13` image and use a Bash entrypoint to interact with the container.

1. Start the container with an interactive shell.

	```bash
	docker run --rm -it --entrypoint bash python:3.13
	```

2. Check the `pip` version inside the container.

	```bash
	pip --version
	```

### Result

What is the `pip` version in the image?

![alt text](<../assets/Python version.png>)


## Question 2. Understanding Docker Networking and Docker Compose

Given the following `docker-compose.yaml`, what hostname and port should `pgadmin` use to connect to the `postgres` database?

```yaml
services:
  db:
    container_name: postgres
    image: postgres:17-alpine
    environment:
      POSTGRES_USER: 'postgres'
      POSTGRES_PASSWORD: 'postgres'
      POSTGRES_DB: 'ny_taxi'
    ports:
      - '5433:5432'
    volumes:
      - vol-pgdata:/var/lib/postgresql/data

  pgadmin:
    container_name: pgadmin
    image: dpage/pgadmin4:latest
    environment:
      PGADMIN_DEFAULT_EMAIL: "pgadmin@pgadmin.com"
      PGADMIN_DEFAULT_PASSWORD: "pgadmin"
    ports:
      - "8080:80"
    volumes:
      - vol-pgadmin_data:/var/lib/pgadmin

volumes:
  vol-pgdata:
    name: vol-pgdata
  vol-pgadmin_data:
    name: vol-pgadmin_data
```

### Result

Hostname: postgres

Port: 5432


## Question 3. Counting short trips

For trips in November 2025 (`lpep_pickup_datetime` between `'2025-11-01'` and `'2025-12-01'`, exclusive of the upper bound), how many trips had a `trip_distance` of less than or equal to 1 mile?

Note: the loaded dataset is November 2020, so the query below is adjusted to match the actual loaded period.

```sql
SELECT COUNT(*) AS trips_leq_1_mile
FROM green_tripdata_2025_11
WHERE lpep_pickup_datetime >= '2020-11-01'
  AND lpep_pickup_datetime <  '2020-12-01'
  AND trip_distance <= 1;
```

### Result

15612

![alt text](<../assets/SQY Query.png>)


## Question 4. Longest trip for each day

Which was the pickup day with the longest trip distance? Only consider trips with `trip_distance` less than 100 miles (to exclude data errors).

### Result

pickup_day            longest_trip_distance
2020-11-25            92.99

![alt text](<../assets/SQL Query - Distance.png>)


## Question 5. Biggest pickup zone

Which was the pickup zone with the largest total_amount (sum of all trips) on `November 18th, 2025`?

Note: the loaded dataset is November 2020, so the query below is adjusted to match the actual loaded period.

### Result

pickup zone                total_amount_sum
East Harlem South          5345.770000000009


![alt text](<../assets/SQL Query - Zone.png>)


## Question 6. Largest tip

For the passengers picked up in the zone named "East Harlem North" in November 2025, which was the drop off zone that had the largest tip?

Note: it is tip, not trip. We need the zone name, not the ID.

Note: the loaded dataset is November 2020, so the query below is adjusted to match the actual loaded period.

### Result

drop_off_zone            total_tip_amount
East Harlem South        1335.9300000000003