# pre-commit-terraform hook

[![Github tag](https://img.shields.io/github/tag/antonbabenko/pre-commit-terraform.svg)](https://github.com/antonbabenko/pre-commit-terraform/releases) ![](https://img.shields.io/maintenance/yes/2018.svg) [![Help Contribute to Open Source](https://www.codetriage.com/antonbabenko/pre-commit-terraform/badges/users.svg)](https://www.codetriage.com/antonbabenko/pre-commit-terraform)

Several [pre-commit](http://pre-commit.com/) hooks to keep Terraform configurations (both `*.tf` and `*.tfvars`) in a good shape:
* `terraform_fmt` - Rewrites all Terraform configuration files to a canonical format.
* `terraform_validate_no_variables` - Validates all Terraform configuration files without checking whether all required variables were set.
* `terraform_validate_with_variables` - Validates all Terraform configuration files and checks whether all required variables were specified.

Note that `terraform_validate_no_variables` and `terraform_validate_with_variables` will not work if variables are being set dynamically (eg, when using [Terragrunt](https://github.com/gruntwork-io/terragrunt)). Use `terragrunt validate` command instead.

An example `.pre-commit-config.yaml`:

```yaml
- repo: git://github.com/antonbabenko/pre-commit-terraform
  sha: v1.4.0
  hooks:
    - id: terraform_fmt
```

Enjoy the clean code!
