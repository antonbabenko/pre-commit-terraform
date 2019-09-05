# Collection of git hooks for Terraform to be used with [pre-commit framework](http://pre-commit.com/)

[![Github tag](https://img.shields.io/github/tag/antonbabenko/pre-commit-terraform.svg)](https://github.com/antonbabenko/pre-commit-terraform/releases) ![](https://img.shields.io/maintenance/yes/2019.svg) [![Help Contribute to Open Source](https://www.codetriage.com/antonbabenko/pre-commit-terraform/badges/users.svg)](https://www.codetriage.com/antonbabenko/pre-commit-terraform)

## How to install

### Step 1

On MacOSX install the `pre-commit` and `awk` (required for Terraform 0.12) package

```bash
brew install pre-commit awk
```

For other operating systems check the [official documentation](http://pre-commit.com/#install)

### Step 2

Step into the repository you want to have the pre-commit hooks installed and run:

```bash
cat <<EOF > .pre-commit-config.yaml
- repo: git://github.com/antonbabenko/pre-commit-terraform
  rev: v1.19.0
  hooks:
    - id: terraform_fmt
    - id: terraform_docs
    - id: terraform_validate
      args: ['-var-file=terraform/dev.tfvars']
EOF
```

### Step 3

Install the pre-commit hook

```bash
pre-commit install
```

### Step 4

After pre-commit hook has been installed you can run it manually on all files in the repository

```bash
pre-commit run --all-files
```

## Available Hooks

There are several [pre-commit](http://pre-commit.com/) hooks to keep Terraform configurations (both `*.tf` and `*.tfvars`) and Terragrunt configurations (`*.hcl`) in a good shape:
* `terraform_fmt` - Rewrites all Terraform configuration files to a canonical format.
* `terraform_validate` - Validates all Terraform configuration files.
  * validate with a variable file: `args: ['-var-file=dev.tfvars']`
* `terraform_tflint` - Validates all Terraform configuration files with [TFLint](https://github.com/wata727/tflint).
  * lint with a variable file: `args: ['-var-file=staging.tfvars']`
* `terraform_docs` - Runs `terraform-docs` and inserts input and output documentation into `README.md`. Recommended.
* `terraform_docs_without_aggregate_type_defaults` - Sames as above without aggregate type defaults.
* `terraform_docs_replace` - Runs `terraform-docs` and pipes the output directly to README.md
* `terragrunt_fmt` - Rewrites all Terragrunt configuration files (`*.hcl`) to a canonical format.

Check the [source file](https://github.com/antonbabenko/pre-commit-terraform/blob/master/.pre-commit-hooks.yaml) to know arguments used for each hook.

## Notes about hooks

1. `terraform_docs` and `terraform_docs_without_aggregate_type_defaults` will insert/update documentation into your `README.md`

   Make sure that you have [terraform-docs](https://github.com/segmentio/terraform-docs) installed.

   They will look for two markers inside `README.md`:
   - `<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->`
   - `<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->`

1. `terraform_docs_replace` replaces the entire `README.md` rather than doing string replacement between markers.

    Put your additional documentation at the top of your `main.tf` for it to be pulled in.
    The optional `--dest` argument lets you change the name of the file that gets created/modified.

    1. Example:
    ```yaml
    hooks:
      - id: terraform_docs_replace
        args: ['--with-aggregate-type-defaults', '--sort-inputs-by-required', '--dest=TEST.md']
    ```

1. It is possible to pass additional arguments to shell scripts when using `terraform_docs`, `terraform_docs_without_aggregate_type_defaults`
   `terraform_validate` and `terraform_tflint`.
   Send pull-request with the new hook if there is something missing.

1. `terraform-docs` works with Terraform 0.12 but support is hackish (it requires `awk` to be installed) and may contain bugs.
    You can follow the native support of Terraform 0.12 in `terraform-docs` in [issue #62](https://github.com/segmentio/terraform-docs/issues/62).

## Notes for developers

1. Python hooks are supported now too. All you have to do is:
    1. Add a line to the `console_scripts` array in `entry_points` in `setup.py`
    1. Put your python script in the `pre_commit_hooks` folder

Enjoy the clean and documented code!

## Authors

This repository is managed by [Anton Babenko](https://github.com/antonbabenko) with help from [these awesome contributors](https://github.com/antonbabenko/pre-commit-terraform/graphs/contributors).

## License

MIT licensed. See LICENSE for full details.
