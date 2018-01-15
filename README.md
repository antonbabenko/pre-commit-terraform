# pre-commit-terraform hook

[![Github tag](https://img.shields.io/github/tag/antonbabenko/pre-commit-terraform.svg)](https://github.com/antonbabenko/pre-commit-terraform/releases) ![](https://img.shields.io/maintenance/yes/2018.svg) [![Help Contribute to Open Source](https://www.codetriage.com/antonbabenko/pre-commit-terraform/badges/users.svg)](https://www.codetriage.com/antonbabenko/pre-commit-terraform)

Single [pre-commit](http://pre-commit.com/) hook which runs `terraform fmt` on Terraform configuration files (both `*.tf` and `*.tfvars`).

An example `.pre-commit-config.yaml`:

```yaml
- repo: git://github.com/antonbabenko/pre-commit-terraform
  sha: v1.3.0
  hooks:
    - id: terraform_fmt
```

Enjoy the clean code!
