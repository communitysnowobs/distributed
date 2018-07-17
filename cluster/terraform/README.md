# Terraform Setup

## Setting up terraform for the first time

When setting up terraform for the first time, make sure that your credentials (gcloud or aws) are setup on your computer, so that terraform can find them.

1. Navigate to source folder
```bash
cd ./aws
```
2. Change the default values of `variables.tf` if desired
3. Initialize Terraform
```bash
terraform init
```
4. Apply configuration
```bash
terraform apply
```

To update the configuration, run `terraform apply` again.

To tear down the configuration, run `terraform destroy`. This will not change the config files, but will remove all infrastructure defined in them.
