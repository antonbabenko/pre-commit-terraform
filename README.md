# Collection of git hooks for Terraform to be used with [pre-commit framework](http://pre-commit.com/)

[![Github tag](https://img.shields.io/github/tag/antonbabenko/pre-commit-terraform.svg)](https://github.com/antonbabenko/pre-commit-terraform/releases) ![maintenance status](https://img.shields.io/maintenance/yes/2021.svg) [![Help Contribute to Open Source](https://www.codetriage.com/antonbabenko/pre-commit-terraform/badges/users.svg)](https://www.codetriage.com/antonbabenko/pre-commit-terraform)

Want to Contribute? Check [open issues](https://github.com/antonbabenko/pre-commit-terraform/issues?q=label%3A%22good+first+issue%22+is%3Aopen+sort%3Aupdated-desc) and [contributing notes](/.github/CONTRIBUTING.md).

* [How to install](#how-to-install)
  * [1. Install dependencies](#1-install-dependencies)
  * [2. Install the pre-commit hook globally](#2-install-the-pre-commit-hook-globally)
  * [3. Add configs and hooks](#3-add-configs-and-hooks)
  * [4. Run](#4-run)
* [Available Hooks](#available-hooks)
* [Hooks usage notes and examples](#hooks-usage-notes-and-examples)
  * [checkov](#checkov)
  * [terraform_docs](#terraform_docs)
  * [terraform_docs_replace](#terraform_docs_replace)
  * [terraform_tflint](#terraform_tflint)
  * [terraform_tfsec](#terraform_tfsec)
  * [terraform_validate](#terraform_validate)
* [Authors](#authors)
* [License](#license)

## How to install

### 1. Install dependencies

<!-- markdownlint-disable no-inline-html -->

* [`pre-commit`](https://pre-commit.com/#install),
  <sub><sup>[`terraform`](https://www.terraform.io/downloads.html),
  <sub><sup>[`git`](https://git-scm.com/downloads),
  <sub><sup>POSIX compatible shell,
  <sub><sup>Internet connection (on first run),
  <sub><sup>x86_64 compatible operation system,
  <sub><sup>Some hardware where this OS will run,
  <sub><sup>Electricity for hardware and internet connection,
  <sub><sup>Some basic physical laws,
  <sub><sup>Hope that it all will works.
  </sup></sub></sup></sub></sup></sub></sup></sub></sup></sub></sup></sub></sup></sub></sup></sub></sup></sub><br><br>
* [`checkov`](https://github.com/bridgecrewio/checkov) required for `checkov` hook.
* [`terraform-docs`](https://github.com/terraform-docs/terraform-docs) required for `terraform_docs` hooks.
* [`terragrunt`](https://terragrunt.gruntwork.io/docs/getting-started/install/) required for `terragrunt_validate` hook.
* [`terrascan`](https://github.com/accurics/terrascan) required for `terrascan` hook.
* [`TFLint`](https://github.com/terraform-linters/tflint) required for `terraform_tflint` hook.
* [`TFSec`](https://github.com/liamg/tfsec) required for `terraform_tfsec` hook.

<details><summary><b>Docker</b></summary><br>

If no `--build-arg` is specified, then the latest versions of `pre-commit` and `terraform` will be installed.

```bash
git clone git@github.com:antonbabenko/pre-commit-terraform.git
cd pre-commit-terraform
# Install all tools with latest versions:
docker build -t pre-commit --build-arg INSTALL_ALL=true .
```

You can specify needed tool versions by providing `--build-arg`'s.  
If you'd like you can use the `latest` versions:

```bash
docker build -t pre-commit \
    --build-arg PRE_COMMIT_VERSION=latest \
    --build-arg TERRAFORM_VERSION=latest \
    --build-arg CHECKOV_VERSION=2.0.405 \
    --build-arg TERRAFORM_DOCS_VERSION=0.15.0 \
    --build-arg TERRAGRUNT_VERSION=latest \
    --build-arg TERRASCAN_VERSION=1.10.0 \
    --build-arg TFLINT_VERSION=0.31.0 \
    --build-arg TFSEC_VERSION=latest \
    .
```

To disable pre-commit color output set `-e PRE_COMMIT_COLOR=never`.

</details>


<details><summary><b>MacOS</b></summary><br>

[`coreutils`](https://formulae.brew.sh/formula/coreutils) required for `terraform_validate` hook on macOS (due to use of `realpath`).

```bash
brew install pre-commit terraform-docs tflint tfsec coreutils checkov terrascan
terrascan init
```

</details>

<details><summary><b>Ubuntu 18.04</b></summary><br>

```bash
sudo apt update
sudo apt install -y unzip software-properties-common
sudo add-apt-repository ppa:deadsnakes/ppa
sudo apt install -y python3.7 python3-pip
python3 -m pip install --upgrade pip
pip3 install --no-cache-dir pre-commit
python3.7 -m pip install -U checkov
curl -L "$(curl -s https://api.github.com/repos/terraform-docs/terraform-docs/releases/latest | grep -o -E -m 1 "https://.+?-linux-amd64.tar.gz")" > terraform-docs.tgz && tar -xzf terraform-docs.tgz && rm terraform-docs.tgz && chmod +x terraform-docs && sudo mv terraform-docs /usr/bin/
curl -L "$(curl -s https://api.github.com/repos/terraform-linters/tflint/releases/latest | grep -o -E -m 1 "https://.+?_linux_amd64.zip")" > tflint.zip && unzip tflint.zip && rm tflint.zip && sudo mv tflint /usr/bin/
curl -L "$(curl -s https://api.github.com/repos/aquasecurity/tfsec/releases/latest | grep -o -E -m 1 "https://.+?tfsec-linux-amd64")" > tfsec && chmod +x tfsec && sudo mv tfsec /usr/bin/
curl -L "$(curl -s https://api.github.com/repos/accurics/terrascan/releases/latest | grep -o -E -m 1"https://.+?_Linux_x86_64.tar.gz")" > terrascan.tar.gz && tar -xzf terrascan.tar.gz terrascan && rm terrascan.tar.gz && sudo mv terrascan /usr/bin/ && terrascan init
```

</details>


<details><summary><b>Ubuntu 20.04</b></summary><br>

```bash
sudo apt update
sudo apt install -y unzip software-properties-common python3 python3-pip
python3 -m pip install --upgrade pip
pip3 install --no-cache-dir pre-commit
pip3 install --no-cache-dir checkov
curl -L "$(curl -s https://api.github.com/repos/terraform-docs/terraform-docs/releases/latest | grep -o -E -m 1 "https://.+?-linux-amd64.tar.gz")" > terraform-docs.tgz && tar -xzf terraform-docs.tgz terraform-docs && rm terraform-docs.tgz && chmod +x terraform-docs && sudo mv terraform-docs /usr/bin/
curl -L "$(curl -s https://api.github.com/repos/accurics/terrascan/releases/latest | grep -o -E -m 1"https://.+?_Linux_x86_64.tar.gz")" > terrascan.tar.gz && tar -xzf terrascan.tar.gz terrascan && rm terrascan.tar.gz && sudo mv terrascan /usr/bin/ && terrascan init
curl -L "$(curl -s https://api.github.com/repos/terraform-linters/tflint/releases/latest | grep -o -E -m 1 "https://.+?_linux_amd64.zip")" > tflint.zip && unzip tflint.zip && rm tflint.zip && sudo mv tflint /usr/bin/
curl -L "$(curl -s https://api.github.com/repos/aquasecurity/tfsec/releases/latest | grep -o -E -m 1 "https://.+?tfsec-linux-amd64")" > tfsec && chmod +x tfsec && sudo mv tfsec /usr/bin/
```

</details>

<!-- markdownlint-enable no-inline-html -->

### 2. Install the pre-commit hook globally

> Note: not needed if you use the Docker image

```bash
DIR=~/.git-template
git config --global init.templateDir ${DIR}
pre-commit init-templatedir -t pre-commit ${DIR}
```

### 3. Add configs and hooks

Step into the repository you want to have the pre-commit hooks installed and run:

```bash
git init
cat <<EOF > .pre-commit-config.yaml
repos:
- repo: git://github.com/antonbabenko/pre-commit-terraform
  rev: <VERSION> # Get the latest from: https://github.com/antonbabenko/pre-commit-terraform/releases
  hooks:
    - id: terraform_fmt
    - id: terraform_docs
EOF
```

### 4. Run

After pre-commit hook has been installed you can run it manually on all files in the repository.

Local installation:

```bash
pre-commit run -a
```

Docker:

```bash
docker run -v $(pwd):/lint -w /lint pre-commit run -a
```

> You be able list tools versions when needed
>
> ```bash
> TAG=latest && docker run --entrypoint cat pre-commit:$TAG /usr/bin/tools_versions_info
> ```

## Available Hooks

There are several [pre-commit](https://pre-commit.com/) hooks to keep Terraform configurations (both `*.tf` and `*.tfvars`) and Terragrunt configurations (`*.hcl`) in a good shape:

| Hook name                                        | Description                                                                                                                                                                                                                                  |
| ------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `checkov`                                        | [checkov](https://github.com/bridgecrewio/checkov) static analysis of terraform templates to spot potential security issues. [Hook notes](#checkov)                                                                                          |
| `terraform_docs_replace`                         | Runs `terraform-docs` and pipes the output directly to README.md                                                                                                                                                                             |
| `terraform_docs_without_aggregate_type_defaults` | Inserts input and output documentation into `README.md` without aggregate type defaults. Hook notes same as for [terraform_docs](#terraform_docs)                                                                                            |
| `terraform_docs`                                 | Inserts input and output documentation into `README.md`. Recommended. [Hook notes](#terraform_docs)                                                                                                                                          |
| `terraform_fmt`                                  | Rewrites all Terraform configuration files to a canonical format. [Hook notes](#terraform_docs)                                                                                                                                              |
| `terraform_tflint`                               | Validates all Terraform configuration files with [TFLint](https://github.com/terraform-linters/tflint). [Available TFLint rules](https://github.com/terraform-linters/tflint/tree/master/docs/rules#rules). [Hook notes](#terraform_tflint). |
| `terraform_tfsec`                                | [TFSec](https://github.com/liamg/tfsec) static analysis of terraform templates to spot potential security issues. [Hook notes](#terraform_tfsec)                                                                                             |
| `terraform_validate`                             | Validates all Terraform configuration files. [Hook notes](#terraform_validate)                                                                                                                                                               |
| `terragrunt_fmt`                                 | Rewrites all [Terragrunt](https://github.com/gruntwork-io/terragrunt) configuration files (`*.hcl`) to a canonical format.                                                                                                                   |
| `terragrunt_validate`                            | Validates all [Terragrunt](https://github.com/gruntwork-io/terragrunt) configuration files (`*.hcl`)                                                                                                                                         |
| `terrascan`                                      | [terrascan](https://github.com/accurics/terrascan) Detect compliance and security violations.                                                                                                                                                |

Check the [source file](https://github.com/antonbabenko/pre-commit-terraform/blob/master/.pre-commit-hooks.yaml) to know arguments used for each hook.

## Hooks usage notes and examples

### checkov

For [checkov](https://github.com/bridgecrewio/checkov) you need to specify each argument separately:

```yaml
- id: checkov
  args: [
    "-d", ".",
    "--skip-check", "CKV2_AWS_8",
  ]
```

### terraform_docs

1. `terraform_docs` and `terraform_docs_without_aggregate_type_defaults` will insert/update documentation generated by [terraform-docs](https://github.com/terraform-docs/terraform-docs) framed by markers:

    ```txt
    <!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

    <!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
    ```

    if they are present in `README.md`.

2. It is possible to pass additional arguments to shell scripts when using `terraform_docs` and `terraform_docs_without_aggregate_type_defaults`. Send pull-request with the new hook if there is something missing.

For these hooks you need to specify all arguments as one:

```yaml
- id: terraform_docs
  args:
    - tfvars hcl --output-file terraform.tfvars.model .
```

### terraform_docs_replace

`terraform_docs_replace` replaces the entire README.md rather than doing string replacement between markers. Put your additional documentation at the top of your `main.tf` for it to be pulled in. The optional `--dest` argument lets you change the name of the file that gets created/modified.

Example:

```yaml
- id: terraform_docs_replace
  args:
    - --sort-by-required
    - --dest=TEST.md
```

### terraform_tflint

1. `terraform_tflint` supports custom arguments so you can enable module inspection, deep check mode etc.

    Example:

    ```yaml
    - id: terraform_tflint
      args:
        - --args=--deep
        - --args=--enable-rule=terraform_documented_variables
    ```

2. When you have multiple directories and want to run `tflint` in all of them and share single config file it is impractical to hard-code the path to `.tflint.hcl` file. The solution is to use `__GIT_WORKING_DIR__` placeholder which will be replaced by `terraform_tflint` hooks with Git working directory (repo root) at run time. For example:

    ```yaml
    - id: terraform_tflint
      args:
        - --args=--config=__GIT_WORKING_DIR__/.tflint.hcl
    ```


### terraform_tfsec

1. `terraform_tfsec` will consume modified files that pre-commit
    passes to it, so you can perform whitelisting of directories
    or files to run against via [files](https://pre-commit.com/#config-files)
    pre-commit flag

    Example:

    ```yaml
    - id: terraform_tfsec
      files: ^prd-infra/
    ```

    The above will tell pre-commit to pass down files from the `prd-infra/` folder
    only such that the underlying `tfsec` tool can run against changed files in this
    directory, ignoring any other folders at the root level

2. To ignore specific warnings, follow the convention from the
[documentation](https://github.com/liamg/tfsec#ignoring-warnings).

    Example:

    ```hcl
    resource "aws_security_group_rule" "my-rule" {
        type = "ingress"
        cidr_blocks = ["0.0.0.0/0"] #tfsec:ignore:AWS006
    }
    ```

3. `terraform_tfsec` supports custom arguments so you can pass supported `--no-color` or `--format` (output), `-e` (exclude checks) flags:

    ```yaml
     - id: terraform_tfsec
       args:
         - >
           --args=--format json
           --no-color
           -e aws-s3-enable-bucket-logging,aws-s3-specify-public-access-block
    ```


### terraform_validate

1. `terraform_validate` supports custom arguments so you can pass supported `-no-color` or `-json` flags:

    ```yaml
     - id: terraform_validate
       args:
         - --args=-json
         - --args=-no-color
    ```

2. `terraform_validate` also supports custom environment variables passed to the pre-commit runtime:

    ```yaml
    - id: terraform_validate
      args:
        - --envs=AWS_DEFAULT_REGION="us-west-2"
        - --envs=AWS_ACCESS_KEY_ID="anaccesskey"
        - --envs=AWS_SECRET_ACCESS_KEY="asecretkey"
    ```

3. It may happen that Terraform working directory (`.terraform`) already exists but not in the best condition (eg, not initialized modules, wrong version of Terraform, etc). To solve this problem you can find and delete all `.terraform` directories in your repository:

    ```bash
    echo "
    function rm_terraform {
        find . -name ".terraform*" -print0 | xargs -0 rm -r
    }
    " >>~/.bashrc

    # Reload shell and use `rm_terraform` command in repo root
    ```

   `terraform_validate` hook will try to reinitialize them before running `terraform validate` command.

    **Warning:** If you use Terraform workspaces, DO NOT use this workaround ([details](https://github.com/antonbabenko/pre-commit-terraform/issues/203#issuecomment-918791847)). Wait to [`force-init`](https://github.com/antonbabenko/pre-commit-terraform/issues/224) option implementation


## Authors

This repository is managed by [Anton Babenko](https://github.com/antonbabenko) with help from these awesome contributors:

<a href="https://github.com/antonbabenko/pre-commit-terraform/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=antonbabenko/pre-commit-terraform" />
</a>

## License

MIT licensed. See LICENSE for full details.
