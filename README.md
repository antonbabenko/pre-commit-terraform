# Collection of git hooks for Terraform to be used with [pre-commit framework](http://pre-commit.com/)

[![Latest Github tag]](https://github.com/antonbabenko/pre-commit-terraform/releases)
![Maintenance status](https://img.shields.io/maintenance/yes/2025.svg)
[![GHA Tests CI/CD Badge]](https://github.com/antonbabenko/pre-commit-terraform/actions/workflows/ci-cd.yml)
[![Codecov pytest Badge]](https://app.codecov.io/gh/antonbabenko/pre-commit-terraform?flags[]=pytest)
[![OpenSSF Scorecard Badge]](https://scorecard.dev/viewer/?uri=github.com/antonbabenko/pre-commit-terraform)
[![OpenSSF Best Practices Badge]](https://www.bestpractices.dev/projects/9963)
[![Codetriage - Help Contribute to Open Source Badge]](https://www.codetriage.com/antonbabenko/pre-commit-terraform)

[![StandWithUkraine Banner]](https://github.com/vshymanskyy/StandWithUkraine/blob/main/docs/README.md)

<!-- markdownlint-disable no-inline-html -->
<p align="center"><img src="assets/pre-commit-terraform-banner.png" alt="pre-commit-terraform logo" width="700"/></p>

[`pre-commit-terraform`](https://github.com/antonbabenko/pre-commit-terraform) provides a collection of [Git Hooks](https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks) for Terraform and related tools and is driven by the [pre-commit framework](https://pre-commit.com). It helps ensure that Terraform, OpenTofu, and Terragrunt configurations are kept in good shape by automatically running various checks and formatting code before committing changes to version control system. This helps maintain code quality and consistency across the project.

It can be run:

* Locally and in CI
* As standalone Git hooks or as a Docker image
* For the entire repository or just for change-related files (e.g., local git stash, last commit, or all changes in a Pull Request)

Want to contribute?
Check [open issues](https://github.com/antonbabenko/pre-commit-terraform/issues?q=label%3A%22good+first+issue%22+is%3Aopen+sort%3Aupdated-desc)
and [contributing notes](/.github/CONTRIBUTING.md).

[Latest Github tag]: https://img.shields.io/github/tag/antonbabenko/pre-commit-terraform.svg
[Codetriage - Help Contribute to Open Source Badge]: https://www.codetriage.com/antonbabenko/pre-commit-terraform/badges/users.svg
[GHA Tests CI/CD Badge]: https://github.com/antonbabenko/pre-commit-terraform/actions/workflows/ci-cd.yml/badge.svg?branch=master
[Codecov Pytest Badge]: https://codecov.io/gh/antonbabenko/pre-commit-terraform/branch/master/graph/badge.svg?flag=pytest
[OpenSSF Scorecard Badge]: https://api.scorecard.dev/projects/github.com/antonbabenko/pre-commit-terraform/badge
[OpenSSF Best Practices Badge]: https://www.bestpractices.dev/projects/9963/badge
[StandWithUkraine Banner]: https://raw.githubusercontent.com/vshymanskyy/StandWithUkraine/main/banner-direct.svg

## Sponsors

If you want to support the development of `pre-commit-terraform` and [many other open-source projects](https://github.com/antonbabenko/terraform-aws-devops), please become a [GitHub Sponsor](https://github.com/sponsors/antonbabenko)!


## Table of content

* [Sponsors](#sponsors)
* [Table of content](#table-of-content)
* [How to install](#how-to-install)
  * [1. Install dependencies](#1-install-dependencies)
    * [1.1 Custom Terraform binaries and OpenTofu support](#11-custom-terraform-binaries-and-opentofu-support)
  * [2. Install the pre-commit hook globally](#2-install-the-pre-commit-hook-globally)
  * [3. Add configs and hooks](#3-add-configs-and-hooks)
  * [4. Run](#4-run)
* [Available Hooks](#available-hooks)
  * [Docker-based hooks (no local tool installation required)](#docker-based-hooks-no-local-tool-installation-required)
* [Hooks usage notes and examples](#hooks-usage-notes-and-examples)
  * [Known limitations](#known-limitations)
  * [All hooks: Usage of environment variables in `--args`](#all-hooks-usage-of-environment-variables-in---args)
  * [All hooks: Set env vars inside hook at runtime](#all-hooks-set-env-vars-inside-hook-at-runtime)
  * [All hooks: Disable color output](#all-hooks-disable-color-output)
  * [All hooks: Log levels](#all-hooks-log-levels)
  * [Many hooks: Parallelism](#many-hooks-parallelism)
  * [checkov (deprecated) and terraform\_checkov](#checkov-deprecated-and-terraform_checkov)
  * [infracost\_breakdown](#infracost_breakdown)
  * [terraform\_docs](#terraform_docs)
  * [terraform\_docs\_replace (deprecated)](#terraform_docs_replace-deprecated)
  * [terraform\_fmt](#terraform_fmt)
  * [terraform\_providers\_lock](#terraform_providers_lock)
  * [terraform\_tflint](#terraform_tflint)
  * [terraform\_tfsec (deprecated)](#terraform_tfsec-deprecated)
  * [terraform\_trivy](#terraform_trivy)
  * [terraform\_validate](#terraform_validate)
  * [terraform\_wrapper\_module\_for\_each](#terraform_wrapper_module_for_each)
  * [terrascan](#terrascan)
  * [tfupdate](#tfupdate)
  * [terragrunt\_providers\_lock](#terragrunt_providers_lock)
  * [terragrunt\_validate\_inputs](#terragrunt_validate_inputs)
* [Docker Usage](#docker-usage)
  * [About Docker image security](#about-docker-image-security)
  * [File Permissions](#file-permissions)
  * [Download Terraform modules from private GitHub repositories](#download-terraform-modules-from-private-github-repositories)
* [GitHub Actions](#github-actions)
* [Authors](#authors)
* [License](#license)
  * [Additional information for users from Russia and Belarus](#additional-information-for-users-from-russia-and-belarus)

## How to install

### 1. Install dependencies

<details><summary><b>Docker</b></summary><br>

**Pull docker image with all hooks**:

```bash
TAG=latest
docker pull ghcr.io/antonbabenko/pre-commit-terraform:$TAG
```

All available tags [here](https://github.com/antonbabenko/pre-commit-terraform/pkgs/container/pre-commit-terraform/versions).

Check [About Docker image security](#about-docker-image-security) section to learn more about possible security issues and why you probably want to build and maintain your own image.


**Build from scratch**:

> **IMPORTANT**  
> To build image you need to have [`docker buildx`](https://docs.docker.com/build/install-buildx/) enabled as default builder.  
> Otherwise - provide `TARGETOS` and `TARGETARCH` as additional `--build-arg`'s to `docker build`.

When hooks-related `--build-arg`s are not specified, only the latest version of `pre-commit` and `terraform` will be installed.

```bash
git clone git@github.com:antonbabenko/pre-commit-terraform.git
cd pre-commit-terraform
# Install the latest versions of all the tools
docker build -t pre-commit-terraform --build-arg INSTALL_ALL=true .
```

To install a specific version of individual tools, define it using `--build-arg` arguments or set it to `latest`:

```bash
docker build -t pre-commit-terraform \
    --build-arg PRE_COMMIT_VERSION=latest \
    --build-arg OPENTOFU_VERSION=latest \
    --build-arg TERRAFORM_VERSION=1.5.7 \
    --build-arg CHECKOV_VERSION=2.0.405 \
    --build-arg HCLEDIT_VERSION=latest \
    --build-arg INFRACOST_VERSION=latest \
    --build-arg TERRAFORM_DOCS_VERSION=0.15.0 \
    --build-arg TERRAGRUNT_VERSION=latest \
    --build-arg TERRASCAN_VERSION=1.10.0 \
    --build-arg TFLINT_VERSION=0.31.0 \
    --build-arg TFSEC_VERSION=latest \
    --build-arg TFUPDATE_VERSION=latest \
    --build-arg TRIVY_VERSION=latest \
    .
```

Set `-e PRE_COMMIT_COLOR=never` to disable the color output in `pre-commit`.

</details>


<details><summary><b>MacOS</b></summary><br>

```bash
brew install pre-commit terraform-docs tflint tfsec trivy checkov terrascan infracost tfupdate minamijoyo/hcledit/hcledit jq
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
curl -L "$(curl -s https://api.github.com/repos/aquasecurity/trivy/releases/latest | grep -o -E -i -m 1 "https://.+?/trivy_.+?_Linux-64bit.tar.gz")" > trivy.tar.gz && tar -xzf trivy.tar.gz trivy && rm trivy.tar.gz && sudo mv trivy /usr/bin
curl -L "$(curl -s https://api.github.com/repos/tenable/terrascan/releases/latest | grep -o -E -m 1 "https://.+?_Linux_x86_64.tar.gz")" > terrascan.tar.gz && tar -xzf terrascan.tar.gz terrascan && rm terrascan.tar.gz && sudo mv terrascan /usr/bin/ && terrascan init
sudo apt install -y jq && \
curl -L "$(curl -s https://api.github.com/repos/infracost/infracost/releases/latest | grep -o -E -m 1 "https://.+?-linux-amd64.tar.gz")" > infracost.tgz && tar -xzf infracost.tgz && rm infracost.tgz && sudo mv infracost-linux-amd64 /usr/bin/infracost && infracost auth login
curl -L "$(curl -s https://api.github.com/repos/minamijoyo/tfupdate/releases/latest | grep -o -E -m 1 "https://.+?_linux_amd64.tar.gz")" > tfupdate.tar.gz && tar -xzf tfupdate.tar.gz tfupdate && rm tfupdate.tar.gz && sudo mv tfupdate /usr/bin/
curl -L "$(curl -s https://api.github.com/repos/minamijoyo/hcledit/releases/latest | grep -o -E -m 1 "https://.+?_linux_amd64.tar.gz")" > hcledit.tar.gz && tar -xzf hcledit.tar.gz hcledit && rm hcledit.tar.gz && sudo mv hcledit /usr/bin/
```

</details>


<details><summary><b>Ubuntu 20.04+</b></summary><br>

```bash
sudo apt update
sudo apt install -y unzip software-properties-common python3 python3-pip python-is-python3
python3 -m pip install --upgrade pip
pip3 install --no-cache-dir pre-commit
pip3 install --no-cache-dir checkov
curl -L "$(curl -s https://api.github.com/repos/terraform-docs/terraform-docs/releases/latest | grep -o -E -m 1 "https://.+?-linux-amd64.tar.gz")" > terraform-docs.tgz && tar -xzf terraform-docs.tgz terraform-docs && rm terraform-docs.tgz && chmod +x terraform-docs && sudo mv terraform-docs /usr/bin/
curl -L "$(curl -s https://api.github.com/repos/tenable/terrascan/releases/latest | grep -o -E -m 1 "https://.+?_Linux_x86_64.tar.gz")" > terrascan.tar.gz && tar -xzf terrascan.tar.gz terrascan && rm terrascan.tar.gz && sudo mv terrascan /usr/bin/ && terrascan init
curl -L "$(curl -s https://api.github.com/repos/terraform-linters/tflint/releases/latest | grep -o -E -m 1 "https://.+?_linux_amd64.zip")" > tflint.zip && unzip tflint.zip && rm tflint.zip && sudo mv tflint /usr/bin/
curl -L "$(curl -s https://api.github.com/repos/aquasecurity/tfsec/releases/latest | grep -o -E -m 1 "https://.+?tfsec-linux-amd64")" > tfsec && chmod +x tfsec && sudo mv tfsec /usr/bin/
curl -L "$(curl -s https://api.github.com/repos/aquasecurity/trivy/releases/latest | grep -o -E -i -m 1 "https://.+?/trivy_.+?_Linux-64bit.tar.gz")" > trivy.tar.gz && tar -xzf trivy.tar.gz trivy && rm trivy.tar.gz && sudo mv trivy /usr/bin
sudo apt install -y jq && \
curl -L "$(curl -s https://api.github.com/repos/infracost/infracost/releases/latest | grep -o -E -m 1 "https://.+?-linux-amd64.tar.gz")" > infracost.tgz && tar -xzf infracost.tgz && rm infracost.tgz && sudo mv infracost-linux-amd64 /usr/bin/infracost && infracost auth login
curl -L "$(curl -s https://api.github.com/repos/minamijoyo/tfupdate/releases/latest | grep -o -E -m 1 "https://.+?_linux_amd64.tar.gz")" > tfupdate.tar.gz && tar -xzf tfupdate.tar.gz tfupdate && rm tfupdate.tar.gz && sudo mv tfupdate /usr/bin/
curl -L "$(curl -s https://api.github.com/repos/minamijoyo/hcledit/releases/latest | grep -o -E -m 1 "https://.+?_linux_amd64.tar.gz")" > hcledit.tar.gz && tar -xzf hcledit.tar.gz hcledit && rm hcledit.tar.gz && sudo mv hcledit /usr/bin/
```

</details>

<details><summary><b>Windows 10/11</b></summary>

We highly recommend using [WSL/WSL2](https://docs.microsoft.com/en-us/windows/wsl/install) with Ubuntu and following the Ubuntu installation guide. Or use Docker.

> **IMPORTANT**  
> We won't be able to help with issues that can't be reproduced in Linux/Mac.  
> So, try to find a working solution and send PR before open an issue.

Otherwise, you can follow [this gist](https://gist.github.com/etiennejeanneaurevolve/1ed387dc73c5d4cb53ab313049587d09):

1. Install [`git`](https://git-scm.com/downloads) and [`gitbash`](https://gitforwindows.org/)
2. Install [Python 3](https://www.python.org/downloads/)
3. Install all prerequisites needed (see above)

Ensure your PATH environment variable looks for `bash.exe` in `C:\Program Files\Git\bin` (the one present in `C:\Windows\System32\bash.exe` does not work with `pre-commit.exe`)

For `checkov`, you may need to also set your `PYTHONPATH` environment variable with the path to your Python modules.  
E.g. `C:\Users\USERNAME\AppData\Local\Programs\Python\Python39\Lib\site-packages`

</details>

Full list of dependencies and where they are used:

<!-- (Do not remove html tags here) -->
* [`pre-commit`](https://pre-commit.com/#install),
  <sub><sup>[`terraform`](https://www.terraform.io/downloads.html) or [`opentofu`](https://opentofu.org/docs/intro/install/),
  <sub><sup>[`git`](https://git-scm.com/downloads),
  <sub><sup>[BASH `3.2.57` or newer](https://www.gnu.org/software/bash/#download),
  <sub><sup>Internet connection (on first run),
  <sub><sup>x86_64 or arm64 compatible operating system,
  <sub><sup>Some hardware where this OS will run,
  <sub><sup>Electricity for hardware and internet connection,
  <sub><sup>Some basic physical laws,
  <sub><sup>Hope that it all will work.
  </sup></sub></sup></sub></sup></sub></sup></sub></sup></sub></sup></sub></sup></sub></sup></sub></sup></sub><br><br>
* [`checkov`][checkov repo] required for `terraform_checkov` hook
* [`terraform-docs`][terraform-docs repo] 0.12.0+ required for `terraform_docs` hook
* [`terragrunt`][terragrunt repo] required for `terragrunt_validate` and `terragrunt_valid_inputs` hooks
* [`terrascan`][terrascan repo] required for `terrascan` hook
* [`TFLint`][tflint repo] required for `terraform_tflint` hook
* [`TFSec`][tfsec repo] required for `terraform_tfsec` hook
* [`Trivy`][trivy repo] required for `terraform_trivy` hook
* [`infracost`][infracost repo] required for `infracost_breakdown` hook
* [`jq`][jq repo] required for `terraform_validate` with `--retry-once-with-cleanup` flag, and for `infracost_breakdown` hook
* [`tfupdate`][tfupdate repo] required for `tfupdate` hook
* [`hcledit`][hcledit repo] required for `terraform_wrapper_module_for_each` hook


#### 1.1 Custom Terraform binaries and OpenTofu support

It is possible to set custom path to `terraform` binary.  
This makes it possible to use [OpenTofu](https://opentofu.org) binary (`tofu`) instead of `terraform`.

How binary discovery works and how you can redefine it (first matched takes precedence):

1. Check if per hook configuration `--hook-config=--tf-path=<path_to_binary_or_binary_name>` is set
2. Check if `PCT_TFPATH=<path_to_binary_or_binary_name>` environment variable is set
3. Check if `TERRAGRUNT_TFPATH=<path_to_binary_or_binary_name>` environment variable is set
4. Check if `terraform` binary can be found in the user's `$PATH`
5. Check if `tofu` binary can be found in the user's `$PATH`


### 2. Install the pre-commit hook globally

> [!NOTE]
> Not needed if you use the Docker image

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
- repo: https://github.com/antonbabenko/pre-commit-terraform
  rev: <VERSION> # Get the latest from: https://github.com/antonbabenko/pre-commit-terraform/releases
  hooks:
    - id: terraform_fmt
    - id: terraform_docs
EOF
```

If this repository was initialized locally via `git init` or `git clone` _before_
you installed the pre-commit hook globally ([step 2](#2-install-the-pre-commit-hook-globally)),
you will need to run:

```bash
pre-commit install
```

### 4. Run

Execute this command to run `pre-commit` on all files in the repository (not only changed files):

```bash
pre-commit run -a
```

Or, using Docker ([available tags](https://github.com/antonbabenko/pre-commit-terraform/pkgs/container/pre-commit-terraform/versions)):

> [!TIP]
> This command uses your user id and group id for the docker container to use to access the local files.  If the files are owned by another user, update the `USERID` environment variable.  See [File Permissions section](#file-permissions) for more information.

```bash
TAG=latest
docker run -e "USERID=$(id -u):$(id -g)" -v "$(pwd):/lint" -w "/lint" "ghcr.io/antonbabenko/pre-commit-terraform:$TAG" run -a
```

Execute this command to list the versions of the tools in Docker:

```bash
TAG=latest
docker run --rm --entrypoint cat ghcr.io/antonbabenko/pre-commit-terraform:$TAG /usr/bin/tools_versions_info
```

## Available Hooks

There are several [pre-commit](https://pre-commit.com/) hooks to keep Terraform configurations (both `*.tf` and `*.tfvars`) and Terragrunt configurations (`*.hcl`) in a good shape:

| Hook name                                              | Description                                                                                                                                                                                                                      | Dependencies<br><sup>[Install instructions here](#1-install-dependencies)</sup>      |
| ------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------ |
| `checkov` and `terraform_checkov`                      | [checkov][checkov repo] static analysis of terraform templates to spot potential security issues. [Hook notes](#checkov-deprecated-and-terraform_checkov)                                                                        | `checkov`<br>Ubuntu deps: `python3`, `python3-pip`                                   |
| `infracost_breakdown`                                  | Check how much your infra costs with [infracost][infracost repo]. [Hook notes](#infracost_breakdown)                                                                                                                             | `infracost`, `jq`, [Infracost API key](https://www.infracost.io/docs/#2-get-api-key) |
| `terraform_docs`                                       | Inserts input and output documentation into `README.md`. [Hook notes](#terraform_docs)                                                                                                                                           | `terraform-docs`                                                                     |
| `terraform_docs_replace`                               | Runs `terraform-docs` and pipes the output directly to README.md. **DEPRECATED**, see [#248](https://github.com/antonbabenko/pre-commit-terraform/issues/248). [Hook notes](#terraform_docs_replace-deprecated)                  | `python3`, `terraform-docs`                                                          |
| `terraform_docs_without_`<br>`aggregate_type_defaults` | Inserts input and output documentation into `README.md` without aggregate type defaults. Hook notes same as for [terraform_docs](#terraform_docs)                                                                                | `terraform-docs`                                                                     |
| `terraform_fmt`                                        | Reformat all Terraform configuration files to a canonical format. [Hook notes](#terraform_fmt)                                                                                                                                   | -                                                                                    |
| `terraform_providers_lock`                             | Updates provider signatures in [dependency lock files](https://www.terraform.io/docs/cli/commands/providers/lock.html). [Hook notes](#terraform_providers_lock)                                                                  | -                                                                                    |
| `terraform_tflint`                                     | Validates all Terraform configuration files with [TFLint][tflint repo]. [Available TFLint rules](https://github.com/terraform-linters/tflint-ruleset-terraform/blob/main/docs/rules/README.md). [Hook notes](#terraform_tflint). | `tflint`                                                                             |
| `terraform_tfsec`                                      | [TFSec][tfsec repo] static analysis of terraform templates to spot potential security issues. **DEPRECATED**, use `terraform_trivy`. [Hook notes](#terraform_tfsec-deprecated)                                                   | `tfsec`                                                                              |
| `terraform_trivy`                                      | [Trivy][trivy repo] static analysis of terraform templates to spot potential security issues. [Hook notes](#terraform_trivy)                                                                                                     | `trivy`                                                                              |
| `terraform_validate`                                   | Validates all Terraform configuration files. [Hook notes](#terraform_validate)                                                                                                                                                   | `jq`, only for `--retry-once-with-cleanup` flag                                      |
| `terragrunt_fmt`                                       | Reformat all [Terragrunt][terragrunt repo] configuration files (`*.hcl`) to a canonical format.                                                                                                                                  | `terragrunt`                                                                         |
| `terragrunt_validate`                                  | Validates all [Terragrunt][terragrunt repo] configuration files (`*.hcl`)                                                                                                                                                        | `terragrunt`                                                                         |
| `terragrunt_validate_inputs`                           | Validates [Terragrunt][terragrunt repo] unused and undefined inputs (`*.hcl`)                                                                                                                                                    |                                                                                      |
| `terragrunt_providers_lock`                            | Generates `.terraform.lock.hcl` files using [Terragrunt][terragrunt repo].                                                                                                                                                       | `terragrunt`                                                                         |
| `terraform_wrapper_module_for_each`                    | Generates Terraform wrappers with `for_each` in module. [Hook notes](#terraform_wrapper_module_for_each)                                                                                                                         | `hcledit`                                                                            |
| `terrascan`                                            | [terrascan][terrascan repo] Detect compliance and security violations. [Hook notes](#terrascan)                                                                                                                                  | `terrascan`                                                                          |
| `tfupdate`                                             | [tfupdate][tfupdate repo] Update version constraints of Terraform core, providers, and modules. [Hook notes](#tfupdate)                                                                                                          | `tfupdate`                                                                           |

Check the [source file](https://github.com/antonbabenko/pre-commit-terraform/blob/master/.pre-commit-hooks.yaml) to know arguments used for each hook.

### Docker-based hooks (no local tool installation required)

For users who prefer not to install tools locally, Docker-based versions are available for most hooks. These hooks use a Docker image with all tools pre-installed and provide the same functionality as their script-based counterparts.

| Docker Hook ID                    | Equivalent Script Hook | Description                                                     |
| --------------------------------- | ---------------------- | --------------------------------------------------------------- |
| `terraform_fmt_docker`            | `terraform_fmt`        | Reformat Terraform files using Docker                          |
| `terraform_validate_docker`       | `terraform_validate`   | Validate Terraform configuration using Docker                  |
| `terraform_docs_docker`           | `terraform_docs`       | Generate documentation using Docker                            |
| `terraform_tflint_docker`         | `terraform_tflint`     | Lint Terraform files with TFLint using Docker                 |
| `terraform_checkov_docker`        | `terraform_checkov`    | Security analysis with Checkov using Docker                   |
| `terraform_trivy_docker`          | `terraform_trivy`      | Security analysis with Trivy using Docker                     |
| `infracost_breakdown_docker`      | `infracost_breakdown`  | Infrastructure cost analysis using Docker                     |

**Benefits of Docker hooks:**

* No need to install individual tools on your local machine
* Consistent tool versions across all environments
* Faster CI/CD execution (tools are pre-installed in the image)
* Simplified dependency management

**Example usage:**

```yaml
repos:
- repo: https://github.com/antonbabenko/pre-commit-terraform
  rev: v1.96.1
  hooks:
    - id: terraform_fmt_docker
    - id: terraform_validate_docker
    - id: terraform_docs_docker
```

See `.pre-commit-config-docker-example.yaml` for a complete example configuration.

## Hooks usage notes and examples

### Known limitations

Terraform operates on a per-dir basis, while `pre-commit` framework only supports files and files that exist. This means if you only remove the TF-related file without any other changes in the same dir, checks will be skipped. Example and details [here](https://github.com/pre-commit/pre-commit/issues/3048).

### All hooks: Usage of environment variables in `--args`

> All, except deprecated hooks: `checkov`, `terraform_docs_replace`

You can use environment variables for the `--args` section.

> [!IMPORTANT]
> You _must_ use the `${ENV_VAR}` definition, `$ENV_VAR` will not expand.

Config example:

```yaml
- id: terraform_tflint
  args:
  - --args=--config=${CONFIG_NAME}.${CONFIG_EXT}
  - --args=--call-module-type="all"
```

If for config above set up `export CONFIG_NAME=.tflint; export CONFIG_EXT=hcl` before `pre-commit run`, args will be expanded to `--config=.tflint.hcl --call-module-type="all"`.

### All hooks: Set env vars inside hook at runtime

> All, except deprecated hooks: `checkov`, `terraform_docs_replace`

You can specify environment variables that will be passed to the hook at runtime.

> [!IMPORTANT]
> Variable values are exported _verbatim_:
> - No interpolation or expansion are applied
> - The enclosing double quotes are removed if they are provided

Config example:

```yaml
- id: terraform_validate
  args:
    - --env-vars=AWS_DEFAULT_REGION="us-west-2"
    - --env-vars=AWS_PROFILE="my-aws-cli-profile"
```

### All hooks: Disable color output

> All, except deprecated hooks: `checkov`, `terraform_docs_replace`

To disable color output for all hooks, set `PRE_COMMIT_COLOR=never` var. Eg:

```bash
PRE_COMMIT_COLOR=never pre-commit run
```

### All hooks: Log levels

In case you need to debug hooks, you can set `PCT_LOG=trace`.

For example:

```bash
PCT_LOG=trace pre-commit run -a
```

Less verbose log levels will be implemented in [#562](https://github.com/antonbabenko/pre-commit-terraform/issues/562).

### Many hooks: Parallelism

> All, except deprecated hooks: `checkov`, `terraform_docs_replace` and hooks which can't be paralleled this way: `infracost_breakdown`, `terraform_wrapper_module_for_each`.  
> Also, there's a chance that parallelism have no effect on `terragrunt_fmt` and `terragrunt_validate` hooks

By default, parallelism is set to `number of logical CPUs - 1`.  
If you'd like to disable parallelism, set it to `1`

```yaml
- id: terragrunt_validate
  args:
    - --hook-config=--parallelism-limit=1
```

In the same way you can set it to any positive integer.

If you'd like to set parallelism value relative to number of CPU logical cores - provide valid Bash arithmetic expression and use `CPU` as a reference to the number of CPU logical cores


```yaml
- id: terraform_providers_lock
  args:
    - --hook-config=--parallelism-limit=CPU*4
```

> [!TIP]
> <details><summary>Info useful for parallelism fine-tunning</summary>
>
> <br>
> Tests below were run on repo with 45 Terraform dirs on laptop with 16 CPUs, SSD and 1Gbit/s network. Laptop was slightly used in the process.
>
> Observed results may vary greatly depending on your repo structure, machine characteristics and their usage.
>
> If during fine-tuning you'll find that your results are very different from provided below and you think that this data could help someone else - feel free to send PR.
>
>
> | Hook                                                                           | Most used resource                 | Comparison of optimization results / Notes                      |
> | ------------------------------------------------------------------------------ | ---------------------------------- | --------------------------------------------------------------- |
> | terraform_checkov                                                              | CPU heavy                          | -                                                               |
> | terraform_fmt                                                                  | CPU heavy                          | -                                                               |
> | terraform_providers_lock (3 platforms,<br>`--mode=always-regenerate-lockfile`) | Network & Disk heavy               | `defaults (CPU-1)` - 3m 39s; `CPU*2` - 3m 19s; `CPU*4` - 2m 56s |
> | terraform_tflint                                                               | CPU heavy                          | -                                                               |
> | terraform_tfsec                                                                | CPU heavy                          | -                                                               |
> | terraform_trivy                                                                | CPU moderate                       | `defaults (CPU-1)` - 32s; `CPU*2` - 30s; `CPU*4` - 31s          |
> | terraform_validate (t validate only)                                           | CPU heavy                          | -                                                               |
> | terraform_validate (t init + t validate)                                       | Network & Disk heavy, CPU moderate | `defaults (CPU-1)` - 1m 30s; `CPU*2` - 1m 25s; `CPU*4` - 1m 41s |
> | terragrunt_fmt                                                                 | CPU heavy                          | N/A? need more info from TG users                               |
> | terragrunt_validate                                                            | CPU heavy                          | N/A? need more info from TG users                               |
> | terrascan                                                                      | CPU moderate-heavy                 | `defaults (CPU-1)` - 8s; `CPU*2` - 6s                           |
> | tfupdate                                                                       | Disk/Network?                      | too quick in any settings. More info needed                     |
>
>
> </details>



```yaml
args:
  - --hook-config=--parallelism-ci-cpu-cores=N
```

If you don't see code above in your `pre-commit-config.yaml` or logs - you don't need it.  
`--parallelism-ci-cpu-cores` used only in edge cases and is ignored in other situations. Check out its usage in [hooks/_common.sh](hooks/_common.sh)

### checkov (deprecated) and terraform_checkov

> `checkov` hook is deprecated, please use `terraform_checkov`.

Note that `terraform_checkov` runs recursively during `-d .` usage. That means, for example, if you change `.tf` file in repo root, all existing `.tf` files in the repo will be checked.

1. You can specify custom arguments. E.g.:

    ```yaml
    - id: terraform_checkov
      args:
        - --args=--quiet
        - --args=--skip-check CKV2_AWS_8
    ```

    Check all available arguments [here](https://www.checkov.io/2.Basics/CLI%20Command%20Reference.html).

    For deprecated hook you need to specify each argument separately:

    ```yaml
    - id: checkov
      args: [
        "-d", ".",
        "--skip-check", "CKV2_AWS_8",
      ]
    ```

2. When you have multiple directories and want to run `terraform_checkov` in all of them and share a single config file - use the `__GIT_WORKING_DIR__` placeholder. It will be replaced by `terraform_checkov` hooks with the Git working directory (repo root) at run time. For example:

    ```yaml
    - id: terraform_checkov
      args:
        - --args=--config-file __GIT_WORKING_DIR__/.checkov.yml
    ```

### infracost_breakdown

`infracost_breakdown` executes `infracost breakdown` command and compare the estimated costs with those specified in the hook-config. `infracost breakdown` parses Terraform HCL code, and calls Infracost Cloud Pricing API (remote version or [self-hosted version](https://www.infracost.io/docs/cloud_pricing_api/self_hosted)).

Unlike most other hooks, this hook triggers once if there are any changed files in the repository.

1. `infracost_breakdown` supports all `infracost breakdown` arguments (run `infracost breakdown --help` to see them). The following example only shows costs:

    ```yaml
    - id: infracost_breakdown
      args:
        - --args=--path=./env/dev
      verbose: true # Always show costs
    ```

    <details><summary>Output</summary>

    ```bash
    Running in "env/dev"

    Summary: {
    "unsupportedResourceCounts": {
        "aws_sns_topic_subscription": 1
      }
    }

    Total Monthly Cost:        86.83 USD
    Total Monthly Cost (diff): 86.83 USD
    ```

    </details>

2. Note that spaces are not allowed in `--args`, so you need to split it, like this:

    ```yaml
    - id: infracost_breakdown
      args:
        - --args=--path=./env/dev
        - --args=--terraform-var-file="terraform.tfvars"
        - --args=--terraform-var-file="../terraform.tfvars"
    ```

3. (Optionally) Define `cost constraints` the hook should evaluate successfully in order to pass:

    ```yaml
    - id: infracost_breakdown
      args:
        - --args=--path=./env/dev
        - --hook-config='.totalHourlyCost|tonumber > 0.1'
        - --hook-config='.totalHourlyCost|tonumber > 1'
        - --hook-config='.projects[].diff.totalMonthlyCost|tonumber != 10000'
        - --hook-config='.currency == "USD"'
    ```

    <details><summary>Output</summary>

    ```bash
    Running in "env/dev"
    Passed: .totalHourlyCost|tonumber > 0.1         0.11894520547945205 >  0.1
    Failed: .totalHourlyCost|tonumber > 1           0.11894520547945205 >  1
    Passed: .projects[].diff.totalMonthlyCost|tonumber !=10000              86.83 != 10000
    Passed: .currency == "USD"              "USD" == "USD"

    Summary: {
    "unsupportedResourceCounts": {
        "aws_sns_topic_subscription": 1
      }
    }

    Total Monthly Cost:        86.83 USD
    Total Monthly Cost (diff): 86.83 USD
    ```

    </details>

    * Only one path per one hook (`- id: infracost_breakdown`) is allowed.
    * Set `verbose: true` to see cost even when the checks are passed.
    * Hook uses `jq` to process the cost estimation report returned by `infracost breakdown` command
    * Expressions defined as `--hook-config` argument should be in a jq-compatible format (e.g. `.totalHourlyCost`, `.totalMonthlyCost`)
    To study json output produced by `infracost`, run the command `infracost breakdown -p PATH_TO_TF_DIR --format json`, and explore it on [jqplay.org](https://jqplay.org/).
    * Supported comparison operators: `<`, `<=`, `==`, `!=`, `>=`, `>`.
    * Most useful paths and checks:
        * `.totalHourlyCost` (same as `.projects[].breakdown.totalHourlyCost`) - show total hourly infra cost
        * `.totalMonthlyCost` (same as `.projects[].breakdown.totalMonthlyCost`) - show total monthly infra cost
        * `.projects[].diff.totalHourlyCost` - show the difference in hourly cost for the existing infra and tf plan
        * `.projects[].diff.totalMonthlyCost` - show the difference in monthly cost for the existing infra and tf plan
        * `.diffTotalHourlyCost` (for Infracost version 0.9.12 or newer) or `[.projects[].diff.totalMonthlyCost | select (.!=null) | tonumber] | add` (for Infracost older than 0.9.12)

4. **Docker usage**. In `docker build` or `docker run` command:
    * You need to provide [Infracost API key](https://www.infracost.io/docs/integrations/environment_variables/#infracost_api_key) via `-e INFRACOST_API_KEY=<your token>`. By default, it is saved in `~/.config/infracost/credentials.yml`
    * Set `-e INFRACOST_SKIP_UPDATE_CHECK=true` to [skip the Infracost update check](https://www.infracost.io/docs/integrations/environment_variables/#infracost_skip_update_check) if you use this hook as part of your CI/CD pipeline.

### terraform_docs

1. `terraform_docs` and `terraform_docs_without_aggregate_type_defaults` will insert/update documentation generated by [terraform-docs][terraform-docs repo] framed by markers:

    ```txt
    <!-- BEGIN_TF_DOCS -->

    <!-- END_TF_DOCS -->
    ```

    if they are present in `README.md`.

2. It is possible to pass additional arguments to shell scripts when using `terraform_docs` and `terraform_docs_without_aggregate_type_defaults`.

3. It is possible to automatically:
    * create a documentation file
    * extend existing documentation file by appending markers to the end of the file (see item 1 above)
    * use different filename for the documentation (default is `README.md`)
    * use the same insertion markers as `terraform-docs`. It's default starting from `v1.93`.  
      To migrate everything to `terraform-docs` insertion markers, run in repo root:

      ```bash
      sed --version &> /dev/null && SED_CMD=(sed -i) || SED_CMD=(sed -i '')
      grep -rl --null 'BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK' . | xargs -0 "${SED_CMD[@]}" -e 's/BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK/BEGIN_TF_DOCS/'
      grep -rl --null 'END OF PRE-COMMIT-TERRAFORM DOCS HOOK' . | xargs -0 "${SED_CMD[@]}" -e 's/END OF PRE-COMMIT-TERRAFORM DOCS HOOK/END_TF_DOCS/'
      ```

    ```yaml
    - id: terraform_docs
      args:
        - --hook-config=--path-to-file=README.md        # Valid UNIX path. I.e. ../TFDOC.md or docs/README.md etc.
        - --hook-config=--add-to-existing-file=true     # Boolean. true or false
        - --hook-config=--create-file-if-not-exist=true # Boolean. true or false
        - --hook-config=--use-standard-markers=true     # Boolean. Defaults to true (v1.93+), false (<v1.93). Set to true for compatibility with terraform-docs
          # The following two options "--custom-marker-begin" and "--custom-marker-end" are ignored if "--use-standard-markers" is set to false
        - --hook-config=--custom-marker-begin=<!-- BEGIN_TF_DOCS -->  # String.
                                                        # Set to use custom marker which helps you with using other formats like asciidoc.
                                                        # For Asciidoc this could be "--hook-config=--custom-marker-begin=// BEGIN_TF_DOCS"
        - --hook-config=--custom-marker-end=<!-- END_TF_DOCS -->  # String.
                                                        # Set to use custom marker which helps you with using other formats like asciidoc.
                                                        # For Asciidoc this could be "--hook-config=--custom-marker-end=// END_TF_DOCS"
        - --hook-config=--custom-doc-header="# "        # String. Defaults to "# "
                                                        # Set to use custom marker which helps you with using other formats like asciidoc.
                                                        # For Asciidoc this could be "--hook-config=--custom-marker-end=\= "
    ```

4. If you want to use a terraform-docs config file, you must supply the path to the file, relative to the git repo root path:

    ```yaml
    - id: terraform_docs
      args:
        - --args=--config=.terraform-docs.yml
    ```

    > **Warning**  
    > Avoid use `recursive.enabled: true` in config file, that can cause unexpected behavior.

5. You can provide [any configuration available in `terraform-docs`](https://terraform-docs.io/user-guide/configuration/) as an argument to `terraform_docs` hook:

    ```yaml
    - id: terraform_docs
      args:
        - --args=--output-mode=replace
    ```

6. If you need some exotic settings, it can be done too. I.e. this one generates HCL files:

    ```yaml
    - id: terraform_docs
      args:
        - tfvars hcl --output-file terraform.tfvars.model .
    ```

### terraform_docs_replace (deprecated)

**DEPRECATED**. Will be merged in [`terraform_docs`](#terraform_docs).

`terraform_docs_replace` replaces the entire `README.md` rather than doing string replacement between markers. Put your additional documentation at the top of your `main.tf` for it to be pulled in.

To replicate functionality in `terraform_docs` hook:

1. Create `.terraform-docs.yml` in the repo root with the following content:

    ```yaml
    formatter: "markdown"

    output:
    file: "README.md"
    mode: replace
    template: |-
        {{/** End of file fixer */}}
    ```

2. Replace `terraform_docs_replace` hook config in `.pre-commit-config.yaml` with:

    ```yaml
    - id: terraform_docs
      args:
        - --args=--config=.terraform-docs.yml
    ```

### terraform_fmt

1. `terraform_fmt` supports custom arguments so you can pass [supported flags](https://www.terraform.io/docs/cli/commands/fmt.html#usage). Eg:

    ```yaml
     - id: terraform_fmt
       args:
         - --args=-no-color
         - --args=-diff
         - --args=-write=false
    ```

### terraform_providers_lock

> [!NOTE]
> The hook requires Terraform 0.14 or later.

> [!NOTE]
> The hook can invoke `terraform providers lock` that can be really slow and requires fetching metadata from remote Terraform registries - not all of that metadata is currently being cached by Terraform.

> [!NOTE]
> <details><summary>Read this if you used this hook before v1.80.0 | Planned breaking changes in v2.0</summary>
> <br>
> We introduced `--mode` flag for this hook. If you'd like to continue using this hook as before, please:
>
> * Specify `--hook-config=--mode=always-regenerate-lockfile` in `args:`
> * Before `terraform_providers_lock`, add `terraform_validate` hook with `--hook-config=--retry-once-with-cleanup=true`
> * Move `--tf-init-args=` to `terraform_validate` hook
>
> In the end, you should get config like this:
>
> ```yaml
> - id: terraform_validate
>   args:
>     - --hook-config=--retry-once-with-cleanup=true
>     # - --tf-init-args=-upgrade
>
> - id: terraform_providers_lock
>   args:
>   - --hook-config=--mode=always-regenerate-lockfile
> ```
>
> Why? When v2.x will be introduced - the default mode will be changed, probably, to `only-check-is-current-lockfile-cross-platform`.
>
> You can check available modes for hook below.
> </details>


1. The hook can work in a few different modes: `only-check-is-current-lockfile-cross-platform` with and without [terraform_validate hook](#terraform_validate) and `always-regenerate-lockfile` - only with terraform_validate hook.

    * `only-check-is-current-lockfile-cross-platform` without terraform_validate - only checks that lockfile has all required SHAs for all providers already added to lockfile.

        ```yaml
        - id: terraform_providers_lock
          args:
          - --hook-config=--mode=only-check-is-current-lockfile-cross-platform
        ```

    * `only-check-is-current-lockfile-cross-platform` with [terraform_validate hook](#terraform_validate) - make up-to-date lockfile by adding/removing providers and only then check that lockfile has all required SHAs.

        > **Important**
        > Next `terraform_validate` flag requires additional dependency to be installed: `jq`. Also, it could run another slow and time consuming command - `terraform init`

        ```yaml
        - id: terraform_validate
          args:
            - --hook-config=--retry-once-with-cleanup=true

        - id: terraform_providers_lock
          args:
          - --hook-config=--mode=only-check-is-current-lockfile-cross-platform
        ```

    * `always-regenerate-lockfile` only with [terraform_validate hook](#terraform_validate) - regenerate lockfile from scratch. Can be useful for upgrading providers in lockfile to latest versions

        ```yaml
        - id: terraform_validate
          args:
            - --hook-config=--retry-once-with-cleanup=true
            - --tf-init-args=-upgrade

        - id: terraform_providers_lock
          args:
          - --hook-config=--mode=always-regenerate-lockfile
        ```

2. `terraform_providers_lock` supports custom arguments:

    ```yaml
     - id: terraform_providers_lock
       args:
          - --args=-platform=windows_amd64
          - --args=-platform=darwin_amd64
    ```

3. It may happen that Terraform working directory (`.terraform`) already exists but not in the best condition (eg, not initialized modules, wrong version of Terraform, etc.). To solve this problem, you can find and delete all `.terraform` directories in your repository:

    ```bash
    echo "
    function rm_terraform {
        find . \( -iname ".terraform*" ! -iname ".terraform-docs*" \) -print0 | xargs -0 rm -r
    }
    " >>~/.bashrc

    # Reload shell and use `rm_terraform` command in the repo root
    ```

    `terraform_providers_lock` hook will try to reinitialize directories before running the `terraform providers lock` command.

4. `terraform_providers_lock` support passing custom arguments to its `terraform init`:

    > **Warning**  
    > DEPRECATION NOTICE: This is available only in `no-mode` mode, which will be removed in v2.0. Please provide this keys to [`terraform_validate`](#terraform_validate) hook, which, to take effect, should be called before `terraform_providers_lock`

    ```yaml
    - id: terraform_providers_lock
      args:
        - --tf-init-args=-upgrade
    ```


### terraform_tflint

1. `terraform_tflint` supports custom arguments so you can enable module inspection, enable / disable rules, etc.

    Example:

    ```yaml
    - id: terraform_tflint
      args:
        - --args=--module
        - --args=--enable-rule=terraform_documented_variables
    ```

2. When you have multiple directories and want to run `tflint` in all of them and share a single config file, it is impractical to hard-code the path to the `.tflint.hcl` file. The solution is to use the `__GIT_WORKING_DIR__` placeholder which will be replaced by `terraform_tflint` hooks with the Git working directory (repo root) at run time. For example:

    ```yaml
    - id: terraform_tflint
      args:
        - --args=--config=__GIT_WORKING_DIR__/.tflint.hcl
    ```

3. By default, pre-commit-terraform performs directory switching into the terraform modules for you. If you want to delegate the directory changing to the binary - this will allow tflint to determine the full paths for error/warning messages, rather than just module relative paths. *Note: this requires `tflint>=0.44.0`.* For example:

    ```yaml
    - id: terraform_tflint
      args:
        - --hook-config=--delegate-chdir
    ```


### terraform_tfsec (deprecated)

**DEPRECATED**. [tfsec was replaced by trivy](https://github.com/aquasecurity/tfsec/discussions/1994), so please use [`terraform_trivy`](#terraform_trivy).

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
[documentation](https://github.com/aquasecurity/tfsec#ignoring-warnings).

    Example:

    ```hcl
    resource "aws_security_group_rule" "my-rule" {
        type = "ingress"
        cidr_blocks = ["0.0.0.0/0"] #tfsec:ignore:AWS006
    }
    ```

3. `terraform_tfsec` supports custom arguments, so you can pass supported `--no-color` or `--format` (output), `-e` (exclude checks) flags:

    ```yaml
     - id: terraform_tfsec
       args:
         - >
           --args=--format json
           --no-color
           -e aws-s3-enable-bucket-logging,aws-s3-specify-public-access-block
    ```

4. When you have multiple directories and want to run `tfsec` in all of them and share a single config file - use the `__GIT_WORKING_DIR__` placeholder. It will be replaced by `terraform_tfsec` hooks with Git working directory (repo root) at run time. For example:

    ```yaml
    - id: terraform_tfsec
      args:
        - --args=--config-file=__GIT_WORKING_DIR__/.tfsec.json
    ```

    Otherwise, will be used files that located in sub-folders:

    ```yaml
    - id: terraform_tfsec
      args:
        - --args=--config-file=.tfsec.json
    ```

### terraform_trivy

1. `terraform_trivy` will consume modified files that pre-commit
    passes to it, so you can perform whitelisting of directories
    or files to run against via [files](https://pre-commit.com/#config-files)
    pre-commit flag

    Example:

    ```yaml
    - id: terraform_trivy
      files: ^prd-infra/
    ```

    The above will tell pre-commit to pass down files from the `prd-infra/` folder
    only such that the underlying `trivy` tool can run against changed files in this
    directory, ignoring any other folders at the root level

2. To ignore specific warnings, follow the convention from the
[documentation](https://aquasecurity.github.io/trivy/latest/docs/configuration/filtering/).

    Example:

    ```hcl
    #trivy:ignore:AVD-AWS-0107
    #trivy:ignore:AVD-AWS-0124
    resource "aws_security_group_rule" "my-rule" {
        type = "ingress"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ```

3. `terraform_trivy` supports custom arguments, so you can pass supported `--format` (output), `--skip-dirs` (exclude directories) and other flags:

    ```yaml
     - id: terraform_trivy
       args:
         - --args=--format=json
         - --args=--skip-dirs="**/.terraform"
    ```

4. When you have multiple directories and want to run `trivy` in all of them and share a single config file - use the `__GIT_WORKING_DIR__` placeholder. It will be replaced by `terraform_trivy` hooks with Git working directory (repo root) at run time. For example:

    ```yaml
    - id: terraform_trivy
      args:
        - --args=--ignorefile=__GIT_WORKING_DIR__/.trivyignore
    ```

### terraform_validate

> [!IMPORTANT]
> If you use [`TF_PLUGIN_CACHE_DIR`](https://developer.hashicorp.com/terraform/cli/config/config-file#provider-plugin-cache), we recommend enabling `--hook-config=--retry-once-with-cleanup=true` or disabling parallelism (`--hook-config=--parallelism-limit=1`) to avoid [race conditions when `terraform init` writes to it](https://github.com/hashicorp/terraform/issues/31964).

1. `terraform_validate` supports custom arguments so you can pass supported `-no-color` or `-json` flags:

    ```yaml
     - id: terraform_validate
       args:
         - --args=-json
         - --args=-no-color
    ```

2. `terraform_validate` also supports passing custom arguments to its `terraform init`:

    ```yaml
    - id: terraform_validate
      args:
        - --tf-init-args=-upgrade
        - --tf-init-args=-lockfile=readonly
    ```

3. It may happen that Terraform working directory (`.terraform`) already exists but not in the best condition (eg, not initialized modules, wrong version of Terraform, etc.). To solve this problem, you can delete broken `.terraform` directories in your repository:

    **Option 1**

    ```yaml
    - id: terraform_validate
      args:
        - --hook-config=--retry-once-with-cleanup=true     # Boolean. true or false
    ```

    > **Important**  
    > The flag requires additional dependency to be installed: `jq`.

    > **Note**  
    > Reinit can be very slow and require downloading data from remote Terraform registries, and not all of that downloaded data or meta-data is currently being cached by Terraform.

    When `--retry-once-with-cleanup=true`, in each failed directory the cached modules and providers from the `.terraform` directory will be deleted, before retrying once more. To avoid unnecessary deletion of this directory, the cleanup and retry will only happen if Terraform produces any of the following error messages:

    * "Missing or corrupted provider plugins"
    * "Module source has changed"
    * "Module version requirements have changed"
    * "Module not installed"
    * "Could not load plugin"

    > **Warning**  
    > When using `--retry-once-with-cleanup=true`, problematic `.terraform/modules/` and `.terraform/providers/` directories will be recursively deleted without prompting for consent. Other files and directories will not be affected, such as the `.terraform/environment` file.

    **Option 2**

    An alternative solution is to find and delete all `.terraform` directories in your repository:

    ```bash
    echo "
    function rm_terraform {
        find . \( -iname ".terraform*" ! -iname ".terraform-docs*" \) -print0 | xargs -0 rm -r
    }
    " >>~/.bashrc

    # Reload shell and use `rm_terraform` command in the repo root
    ```

   `terraform_validate` hook will try to reinitialize them before running the `terraform validate` command.

    > **Caution**  
    > If you use Terraform workspaces, DO NOT use this option ([details](https://github.com/antonbabenko/pre-commit-terraform/issues/203#issuecomment-918791847)). Consider the first option, or wait for [`force-init`](https://github.com/antonbabenko/pre-commit-terraform/issues/224) option implementation.

4. `terraform_validate` in a repo with Terraform module, written using Terraform 0.15+ and which uses provider `configuration_aliases` ([Provider Aliases Within Modules](https://www.terraform.io/language/modules/develop/providers#provider-aliases-within-modules)), errors out.

   When running the hook against Terraform code where you have provider `configuration_aliases` defined in a `required_providers` configuration block, terraform will throw an error like:

   > Error: Provider configuration not present
   > To work with `<resource>` its original provider configuration at provider `["registry.terraform.io/hashicorp/aws"].<provider_alias>` is required, but it has been removed. This occurs when a provider configuration is removed while
   > objects created by that provider still exist in the state. Re-add the provider configuration to destroy `<resource>`, after which you can remove the provider configuration again.

   This is a [known issue](https://github.com/hashicorp/terraform/issues/28490) with Terraform and how providers are initialized in Terraform 0.15 and later. To work around this you can add an `exclude` parameter to the configuration of `terraform_validate` hook like this:

   ```yaml
   - id: terraform_validate
     exclude: '^[^/]+$'
   ```

   This will exclude the root directory from being processed by this hook. Then add a subdirectory like "examples" or "tests" and put an example implementation in place that defines the providers with the proper aliases, and this will give you validation of your module through the example. If instead you are using this with multiple modules in one repository you'll want to set the path prefix in the regular expression, such as `exclude: modules/offendingmodule/[^/]+$`.

   Alternately, you can use [terraform-config-inspect](https://github.com/hashicorp/terraform-config-inspect) and use a variant of [this script](https://github.com/bendrucker/terraform-configuration-aliases-action/blob/main/providers.sh) to generate a providers file at runtime:

   ```bash
   terraform-config-inspect --json . | jq -r '
     [.required_providers[].aliases]
     | flatten
     | del(.[] | select(. == null))
     | reduce .[] as $entry (
       {};
       .provider[$entry.name] //= [] | .provider[$entry.name] += [{"alias": $entry.alias}]
     )
   ' | tee aliased-providers.tf.json
   ```

   Save it as `.generate-providers.sh` in the root of your repository and add a `pre-commit` hook to run it before all other hooks, like so:

   ```yaml
   - repos:
     - repo: local
       hooks:
         - id: generate-terraform-providers
           name: generate-terraform-providers
           require_serial: true
           entry: .generate-providers.sh
           language: script
           files: \.tf(vars)?$
           pass_filenames: false

     - repo: https://github.com/pre-commit/pre-commit-hooks
   ```

    > **Tip**  
    > The latter method will leave an "aliased-providers.tf.json" file in your repo. You will either want to automate a way to clean this up or add it to your `.gitignore` or both.

### terraform_wrapper_module_for_each

`terraform_wrapper_module_for_each` generates module wrappers for Terraform modules (useful for Terragrunt where `for_each` is not supported). When using this hook without arguments it will create wrappers for the root module and all modules available in "modules" directory.

You may want to customize some of the options:

1. `--module-dir=...` - Specify a single directory to process. Values: "." (means just root module), "modules/iam-user" (a single module), or empty (means include all submodules found in "modules/*").
2. `--module-repo-org=...` - Module repository organization (e.g. "terraform-aws-modules").
3. `--module-repo-shortname=...` - Short name of the repository (e.g. "s3-bucket").
4. `--module-repo-provider=...` - Name of the repository provider (e.g. "aws" or "google").

Sample configuration:

```yaml
- id: terraform_wrapper_module_for_each
  args:
    - --args=--module-dir=.   # Process only root module
    - --args=--dry-run        # No files will be created/updated
    - --args=--verbose        # Verbose output
```

**If you use hook inside Docker:**  
The `terraform_wrapper_module_for_each` hook attempts to determine the module's short name to be inserted into the generated `README.md` files for the `source` URLs. Since the container uses a bind mount at a static location, it can cause this short name to be incorrect.  
If the generated name is incorrect, set them by providing the `module-repo-shortname` option to the hook:

```yaml
- id: terraform_wrapper_module_for_each
  args:
    - '--args=--module-repo-shortname=ec2-instance'
```

### terrascan

1. `terrascan` supports custom arguments so you can pass supported flags like `--non-recursive` and `--policy-type` to disable recursive inspection and set the policy type respectively:

    ```yaml
    - id: terrascan
      args:
        - --args=--non-recursive # avoids scan errors on subdirectories without Terraform config files
        - --args=--policy-type=azure
    ```

    See the `terrascan run -h` command line help for available options.

2. Use the `--args=--verbose` parameter to see the rule ID in the scanning output. Useful to skip validations.
3. Use `--skip-rules="ruleID1,ruleID2"` parameter to skip one or more rules globally while scanning (e.g.: `--args=--skip-rules="ruleID1,ruleID2"`).
4. Use the syntax `#ts:skip=RuleID optional_comment` inside a resource to skip the rule for that resource.

### tfupdate

1. Out of the box `tfupdate` will pin the terraform version:

    ```yaml
    - id: tfupdate
      name: Autoupdate Terraform versions
    ```

2. If you'd like to pin providers, etc., use custom arguments, i.e `provider=PROVIDER_NAME`:

    ```yaml
    - id: tfupdate
      name: Autoupdate AWS provider versions
      args:
        - --args=provider aws # Will be pined to latest version

    - id: tfupdate
      name: Autoupdate Helm provider versions
      args:
        - --args=provider helm
        - --args=--version 2.5.0 # Will be pined to specified version
    ```

Check [`tfupdate` usage instructions](https://github.com/minamijoyo/tfupdate#usage) for other available options and usage examples.  
No need to pass `--recursive .` as it is added automatically.

### terragrunt_providers_lock

> [!TIP]
> Use this hook only in infrastructure repos managed solely by `terragrunt` and do not mix with [`terraform_providers_lock`](#terraform_providers_lock) to avoid conflicts.

> [!WARNING]
> Hook _may_ be very slow, because terragrunt invokes `t init` under the hood.

Hook produces same results as [`terraform_providers_lock`](#terraform_providers_lock), but for terragrunt root modules.

It invokes `terragrunt providers lock` under the hood and terragrunt [does its' own magic](https://terragrunt.gruntwork.io/docs/features/lock-file-handling/) for handling lock files.


```yaml
- id: terragrunt_providers_lock
  name: Terragrunt providers lock
  args:
    - --args=-platform=darwin_arm64
    - --args=-platform=darwin_amd64
    - --args=-platform=linux_amd64
```

### terragrunt_validate_inputs

Validates Terragrunt unused and undefined inputs. This is useful for keeping
configs clean when module versions change or if configs are copied.

See the [Terragrunt docs](https://terragrunt.gruntwork.io/docs/reference/cli-options/#validate-inputs) for more details.

Example:

```yaml
- id: terragrunt_validate_inputs
  name: Terragrunt validate inputs
  args:
    # Optionally check for unused inputs
    - --args=--terragrunt-strict-validate
```

> [!NOTE]
> This hook requires authentication to a given account if defined by config to work properly. For example, if you use a third-party tool to store AWS credentials like `aws-vault` you must be authenticated first.
>
> See docs for the [iam_role](https://terragrunt.gruntwork.io/docs/reference/config-blocks-and-attributes/#iam_role) attribute and [--terragrunt-iam-role](https://terragrunt.gruntwork.io/docs/reference/cli-options/#terragrunt-iam-role) flag for more.

## Docker Usage

### About Docker image security

Pre-built Docker images contain the latest versions of tools available at the time of their build and remain unchanged afterward. Tags should be immutable whenever possible, and it is highly recommended to pin them using hash sums for security and reproducibility.

This means that most Docker images will include known CVEs, and the longer an image exists, the more CVEs it may accumulate. This applies even to the latest `vX.Y.Z` tags.
To address this, you can use the `nightly` tag, which rebuilds nightly with the latest versions of all dependencies and latest `pre-commit-terraform` hooks. However, using mutable tags introduces different security concerns.

Note: Currently, we DO NOT test third-party tools or their dependencies for security vulnerabilities, corruption, or injection (including obfuscated content). If you have ideas for introducing image scans or other security improvements, please open an issue or submit a PR. Some ideas are already tracked in [#835](https://github.com/antonbabenko/pre-commit-terraform/issues/835).

From a security perspective, the best approach is to manage the Docker image yourself and update its dependencies as needed. This allows you to remove unnecessary dependencies, reducing the number of potential CVEs and improving overall security.

### File Permissions

A mismatch between the Docker container's user and the local repository file ownership can cause permission issues in the repository where `pre-commit` is run.  The container runs as the `root` user by default, and uses a `tools/entrypoint.sh` script to assume a user ID and group ID if specified by the environment variable `USERID`.

The [recommended command](#4-run) to run the Docker container is:

```bash
TAG=latest
docker run -e "USERID=$(id -u):$(id -g)" -v $(pwd):/lint -w /lint ghcr.io/antonbabenko/pre-commit-terraform:$TAG run -a
```

which uses your current session's user ID and group ID to set the variable in the run command.  Without this setting, you may find files and directories owned by `root` in your local repository.

If the local repository is using a different user or group for permissions, you can modify the `USERID` to the user ID and group ID needed.  **Do not use the username or groupname in the environment variable, as it has no meaning in the container.**  You can get the current directory's owner user ID and group ID from the 3rd (user) and 4th (group) columns in `ls` output:

```bash
$ ls -aldn .
drwxr-xr-x 9 1000 1000 4096 Sep  1 16:23 .
```

### Download Terraform modules from private GitHub repositories

If you use a private Git repository as your Terraform module source, you are required to authenticate to GitHub using a [Personal Access Token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token).

When running pre-commit on Docker, both locally or on CI, you need to configure the [~/.netrc](https://www.gnu.org/software/inetutils/manual/html_node/The-_002enetrc-file.html) file, which contains login and initialization information used by the auto-login process.

This can be achieved by firstly creating the `~/.netrc` file including your `GITHUB_PAT` and `GITHUB_SERVER_HOSTNAME`

```bash
# set GH values (replace with your own values)
GITHUB_PAT=ghp_bl481aBlabl481aBla
GITHUB_SERVER_HOSTNAME=github.com

# create .netrc file
echo -e "machine $GITHUB_SERVER_HOSTNAME\n\tlogin $GITHUB_PAT" >> ~/.netrc
```

The `~/.netrc` file will look similar to the following:

```
machine github.com
  login ghp_bl481aBlabl481aBla
```

> [!TIP]
> The value of `GITHUB_SERVER_HOSTNAME` can also refer to a GitHub Enterprise server (i.e. `github.my-enterprise.com`).

Finally, you can execute `docker run` with an additional volume mount so that the `~/.netrc` is accessible within the container

```bash
# run pre-commit-terraform with docker
# adding volume for .netrc file
# .netrc needs to be in /root/ dir
docker run --rm -e "USERID=$(id -u):$(id -g)" -v ~/.netrc:/root/.netrc -v $(pwd):/lint -w /lint ghcr.io/antonbabenko/pre-commit-terraform:latest run -a
```

## GitHub Actions

You can use this hook in your GitHub Actions workflow together with [pre-commit](https://pre-commit.com). To easy up
dependency management, you can use the managed [docker image](#docker-usage) within your workflow. Make sure to set the
image tag to the version you want to use.

In this repository's pre-commit [workflow file](.github/workflows/pre-commit.yaml) we run pre-commit without the container image.

Here's an example using the container image. It includes caching of pre-commit dependencies and utilizes the pre-commit
command to run checks (Note: Fixes will not be automatically pushed back to your branch, even when possible.):

```yaml
name: pre-commit-terraform

on:
  pull_request:

jobs:
  pre-commit:
    runs-on: ubuntu-latest
    container:
      image: ghcr.io/antonbabenko/pre-commit-terraform:latest # latest used here for simplicity, not recommended
    defaults:
      run:
        shell: bash
    steps:
      - uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683
        with:
          fetch-depth: 0
          ref: ${{ github.event.pull_request.head.sha }}

      - run: |
          git config --global --add safe.directory $GITHUB_WORKSPACE
          git fetch --no-tags --prune --depth=1 origin +refs/heads/*:refs/remotes/origin/*

      - name: Get changed files
        id: file_changes
        run: |
          export DIFF=$(git diff --name-only origin/${{ github.base_ref }} ${{ github.sha }})
          echo "Diff between ${{ github.base_ref }} and ${{ github.sha }}"
          echo "files=$( echo "$DIFF" | xargs echo )" >> $GITHUB_OUTPUT

      - name: fix tar dependency in alpine container image
        run: |
          apk --no-cache add tar
          # check python modules installed versions
          python -m pip freeze --local

      - name: Cache pre-commit since we use pre-commit from container
        uses: actions/cache@v4
        with:
          path: ~/.cache/pre-commit
          key: pre-commit-3|${{ hashFiles('.pre-commit-config.yaml') }}

      - name: Execute pre-commit
        run: |
          pre-commit run --color=always --show-diff-on-failure --files ${{ steps.file_changes.outputs.files }}
```

## Authors

This repository is managed by [Anton Babenko](https://github.com/antonbabenko) with help from these awesome contributors:

<a href="https://github.com/antonbabenko/pre-commit-terraform/graphs/contributors">
  <img alt="Contributors" src="https://contrib.rocks/image?repo=antonbabenko/pre-commit-terraform" />
</a>


<a href="https://star-history.com/#antonbabenko/pre-commit-terraform&Date">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=antonbabenko/pre-commit-terraform&type=Date&theme=dark" />
    <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=antonbabenko/pre-commit-terraform&type=Date" />
    <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=antonbabenko/pre-commit-terraform&type=Date" />
  </picture>
</a>

## License

MIT licensed. See [LICENSE](LICENSE) for full details.

### Additional information for users from Russia and Belarus

* Russia has [illegally annexed Crimea in 2014](https://en.wikipedia.org/wiki/Annexation_of_Crimea_by_the_Russian_Federation) and [brought the war in Donbas](https://en.wikipedia.org/wiki/War_in_Donbas) followed by [full-scale invasion of Ukraine in 2022](https://en.wikipedia.org/wiki/2022_Russian_invasion_of_Ukraine).
* Russia has brought sorrow and devastations to millions of Ukrainians, killed hundreds of innocent people, damaged thousands of buildings, and forced several million people to flee.
* [Putin khuylo!](https://en.wikipedia.org/wiki/Putin_khuylo!)


<!-- Tools links -->
[checkov repo]: https://github.com/bridgecrewio/checkov
[terraform-docs repo]: https://github.com/terraform-docs/terraform-docs
[terragrunt repo]: https://github.com/gruntwork-io/terragrunt
[terrascan repo]: https://github.com/tenable/terrascan
[tflint repo]: https://github.com/terraform-linters/tflint
[tfsec repo]: https://github.com/aquasecurity/tfsec
[trivy repo]: https://github.com/aquasecurity/trivy
[infracost repo]: https://github.com/infracost/infracost
[jq repo]: https://github.com/stedolan/jq
[tfupdate repo]: https://github.com/minamijoyo/tfupdate
[hcledit repo]: https://github.com/minamijoyo/hcledit
