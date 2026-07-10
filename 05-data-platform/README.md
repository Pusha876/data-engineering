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
