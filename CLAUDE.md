# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This project provisions a complete Azure Business Intelligence infrastructure using Terraform. It creates and configures Azure Analysis Services for OLAP data modeling, backed by Azure Storage (for backups), Azure Automation Account (for scheduled PowerShell runbooks), and Azure Log Analytics. All PowerShell runbooks and TMSL scripts are dynamically generated from a single config file (`set_variables.tfvars`) via a Python script.

## Terraform Commands

All Terraform operations are run from the `main/` directory:

```powershell
cd main
terraform init
terraform plan -var-file="..\set_variables.tfvars" -out plan.out
terraform apply -var-file="..\set_variables.tfvars" -auto-approve -parallelism=1
terraform destroy -var-file="..\set_variables.tfvars"
```

> Use `-parallelism=1` on apply because schedules in the Automation Account use `timeadd(timestamp(), ...)` and must be created sequentially in the correct order.

## Documentation (MkDocs)

```bash
pip install mkdocs==1.0.4 mkdocs-material pymdown-extensions pygments
mkdocs build    # build static site into /site
mkdocs serve    # live-preview at http://127.0.0.1:8000
```

The CI pipeline (`.github/workflows/ci.yml`) runs `mkdocs build` on every push/PR to `master`.

## Script Generation

`scripts/generate_scripts.py` reads template files and replaces placeholder tags (e.g., `<PRODUCT_NAME>`, `<CLIENT_NAME>`) to produce client-specific scripts. It can be run directly for testing:

```bash
python scripts/generate_scripts.py \
  --subscritpion_id <uuid> \
  --data_source oracle \   # or postgresql
  --product_name PRODUCT_NAME \
  --client_name ClientAA \
  --location brazilsouth \
  --list_admins "user@domain.com" \
  --list_readers "user@domain.com" \
  --large_volume_table fact_historic \
  --column_to_split id_column_name \
  --total_month 18 \
  --email_from smtp@company.com \
  --email_to admin@company.com \
  --smtp_server email-smtp.us-east-1.amazonaws.com \
  --smtp_port 587
```

Terraform invokes this script automatically via the `null_resource.generate_scripts` in `scripts/scripts.tf`.

## Architecture

### Module Dependency Flow

```
set_variables.tfvars
        │
        ▼
   main/main.tf  (orchestrates all modules)
        │
        ├──► scripts/          → generates PS1 runbooks & TMSL JSON files
        │         ↓ outputs to:
        │    azure_automatiom_account/runbooks/   (generated *.ps1)
        │    azure_analysis_services/tmsl/        (generated *.json)
        │
        ├──► azure_storage_account/   → outputs SAS token
        │         ↓ sas_token passed to:
        ├──► azure_analysis_services/ → uses SAS for backup blob URI
        ├──► azure_automatiom_account/
        └──► azure_log_analytics/
```

### Key Design Decisions

- **Script generation before apply**: The `scripts` module runs first (using `null_resource` + `local-exec`) and writes generated files into `azure_automatiom_account/runbooks/` and `azure_analysis_services/tmsl/`. Those modules then read them with `data "local_file"`.
- **Template placeholders**: Source templates live in `scripts/runbooks/` and `scripts/tmsl_mp/` using `PRODUCT_NAME` and `CLIENT_NAME` as literal placeholders. Generated files go to `azure_automatiom_account/runbooks/` and `azure_analysis_services/tmsl/`.
- **Partition SQL files**: `azure_analysis_services/partitions/*.sql` define Analysis Services table partitions. The `large_volume_table` variable names the one partition that is excluded from daily processing and handled separately.
- **SAS token cross-module**: `azure_storage_account` outputs a SAS URL (`output.tf`) that `azure_analysis_services` consumes as `backup_blob_container_uri`.
- **Naming convention**: Resources follow `<product_name><client_name_lower>` (no separator) for Azure resource names, and `<product_client_name>` / `<product_client_name_lower>` for resource group names and runbook prefixes.

### Runbook Scheduling Sequence (Automation Account)

Schedules are set relative to `terraform apply` time using `timeadd(timestamp(), "Nm")`:

| Offset | Purpose |
|--------|---------|
| +20m   | Update PowerShell modules |
| +35m   | Create Analysis Services database |
| +45m   | Start Analysis Services (daily, weekdays) |
| +55m   | Process daily partitions |
| +65m   | Process large volume table (one-time) |
| +70m   | Process monthly partitions |
| +85m–95m | Backup & stop Analysis Services |

### Variables Reference (`set_variables.tfvars`)

| Variable | Purpose |
|----------|---------|
| `subscription_id`, `client_id`, `client_secret`, `tenant_id` | Azure service principal credentials |
| `application_user_login` / `application_user_password` | Portal user (not the Terraform SP) stored as Automation credential |
| `product_client_name` / `product_client_name_lower` | Used as resource group names and runbook prefixes |
| `data_source` | `oracle` or `postgresql` — selects which TMSL `create_db_*.json` template to use |
| `large_volume_table` | Name of the fact table to partition by month |
| `column_to_split` | Date/ID column used in partition WHERE clause |
| `list_admins` / `list_readers` | Comma-separated emails (no spaces) for Analysis Services roles |
| `list_admins_global` | List of admin users set directly on the AS server resource |
