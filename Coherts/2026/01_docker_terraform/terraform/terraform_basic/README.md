# Terraform Basic: Dual-Cloud Temporary Storage Lab

This folder is a small Terraform lab for homework testing.
It contains two independent examples to create temporary storage resources:

- GCP example: creates a GCS bucket for pipeline output
- Azure example: creates a Resource Group + Storage Account + Container

Think of this folder as a two-lane runway: same Terraform workflow, different cloud providers.

## Folder layout

```text
terraform_basic/
|- gcp_storage_example/
|  |- main.tf
|  |- variables.tf
|  |- terraform.tfvars.example
|  `- .gitignore
|- azure_storage_example/
|  |- main.tf
|  |- variables.tf
|  `- terraform.tfvars.example
`- READMME.md
```

## Flight plan: common Terraform workflow

Run these in either example folder:

```bash
terraform init
terraform plan
terraform apply
terraform destroy
```

If you created the alias earlier, you can use `tf` instead of `terraform`.

## GCP quickstart

1. Move into the GCP example folder.
2. Create your local var file.
3. Authenticate with Google Cloud ADC.
4. Run Terraform.

```bash
cd gcp_storage_example
cp terraform.tfvars.example terraform.tfvars

# edit terraform.tfvars and set project_id

gcloud auth login
gcloud auth application-default login
gcloud auth application-default set-quota-project YOUR_PROJECT_ID

terraform init
terraform plan
terraform apply
```

What it creates:

- One GCS bucket with a random suffix
- Uniform bucket-level access enabled
- Lifecycle rule to delete objects older than 7 days
- `force_destroy = true` for easier cleanup in homework testing

## Azure quickstart

1. Move into the Azure example folder.
2. Create your local var file.
3. Authenticate with Azure CLI.
4. Run Terraform.

```bash
cd azure_storage_example
cp terraform.tfvars.example terraform.tfvars

# edit terraform.tfvars and set subscription_id

az login

terraform init
terraform plan
terraform apply
```

What it creates:

- One Resource Group
- One Storage Account (randomized suffix)
- One private Blob container for pipeline data

## Safety rails before pushing to GitHub

- Do not commit `terraform.tfvars`
- Do not commit `*.tfstate` files
- Do not commit provider cache folders like `.terraform/`

The GCP example already includes a Terraform-focused `.gitignore`.

## Homework note

For local testing, Workload Identity Federation is not required.
Use user login + ADC for GCP and `az login` for Azure, then destroy resources after validation.