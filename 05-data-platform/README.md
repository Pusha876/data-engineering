## Bruin Validation Correction

When validating the sample pipeline in `my-first-pipeline`, run validation from inside the folder with:

```bash
bruin validate .
```

Common mistake:

```bash
bruin validate my-first-pipeline
```

If you are already in `my-first-pipeline`, Bruin treats that argument as an asset selector and returns:

```text
failed to find an asset with the path or name 'my-first-pipeline'
```

## Troubleshooting Check Failures

If this check fails:

```text
dataset.player_stats:name.not_null - column 'name' has 1 null values
```

the upstream `dataset.players` asset contains at least one row where `name` is null.

Use this query pattern in `my-first-pipeline/assets/player_stats.sql`:

```sql
SELECT name, count(*) AS player_count
FROM dataset.players
WHERE name IS NOT NULL
GROUP BY 1
```

Then rerun the asset:

```bash
cd "C:/WORKSPACE/data-engineering/05-data-platform/my-first-pipeline"
bruin run --environment default "assets/player_stats.sql"
```
