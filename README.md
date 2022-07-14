# Collection of git hooks for Terraform to be used with [pre-commit framework](http://pre-commit.com/)

[![Github tag](https://img.shields.io/github/tag/antonbabenko/pre-commit-terraform.svg)](https://github.com/antonbabenko/pre-commit-terraform/releases) ![maintenance status](https://img.shields.io/maintenance/yes/2022.svg) [![Help Contribute to Open Source](https://www.codetriage.com/antonbabenko/pre-commit-terraform/badges/users.svg)](https://www.codetriage.com/antonbabenko/pre-commit-terraform)

[![SWUbanner](https://raw.githubusercontent.com/vshymanskyy/StandWithUkraine/main/banner-direct.svg)](https://github.com/vshymanskyy/StandWithUkraine/blob/main/docs/README.md)

Want to contribute? Check [open issues](https://github.com/antonbabenko/pre-commit-terraform/issues?q=label%3A%22good+first+issue%22+is%3Aopen+sort%3Aupdated-desc) and [contributing notes](/.github/CONTRIBUTING.md).

## Sponsors

<!-- markdownlint-disable no-inline-html -->

<br />
<a href="https://www.env0.com/?utm_campaign=pre-commit-terraform&utm_source=sponsorship&utm_medium=social"><img src="https://raw.githubusercontent.com/antonbabenko/pre-commit-terraform/master/assets/env0.png" alt="env0" width="180" height="44" />

Automated provisioning of Terraform workflows and Infrastructure as Code.</a>

<br />
<a href="https://www.infracost.io/?utm_campaign=pre-commit-terraform&utm_source=sponsorship&utm_medium=social"><img src="https://raw.githubusercontent.com/antonbabenko/pre-commit-terraform/master/assets/infracost.png" alt="infracost" width="200" height="38" />

<!-- markdownlint-enable no-inline-html -->

Cloud cost estimates for Terraform.</a>

If you are using `pre-commit-terraform` already or want to support its development and [many other open-source projects](https://github.com/antonbabenko/terraform-aws-devops), please become a [GitHub Sponsor](https://github.com/sponsors/antonbabenko)!


## Table of content

* [Sponsors](#sponsors)
* [Table of content](#table-of-content)
* [How to install](#how-to-install)
  * [1. Install dependencies](#1-install-dependencies)
  * [2. Install the pre-commit hook globally](#2-install-the-pre-commit-hook-globally)
  * [3. Add configs and hooks](#3-add-configs-and-hooks)
  * [4. Run](#4-run)
* [Available Hooks](#available-hooks)
* [Hooks usage notes and examples](#hooks-usage-notes-and-examples)
  * [All hooks: Usage of environment variables in `--args`](#all-hooks-usage-of-environment-variables-in---args)
  * [All hooks: Set env vars inside hook at runtime](#all-hooks-set-env-vars-inside-hook-at-runtime)
  * [All hooks: Disable color output](#all-hooks-disable-color-output)
  * [checkov (deprecated) and terraform_checkov](#checkov-deprecated-and-terraform_checkov)
  * [infracost_breakdown](#infracost_breakdown)
  * [terraform_docs](#terraform_docs)
  * [terraform_docs_replace (deprecated)](#terraform_docs_replace-deprecated)
  * [terraform_fmt](#terraform_fmt)
  * [terraform_providers_lock](#terraform_providers_lock)
  * [terraform_tflint](#terraform_tflint)
  * [terraform_tfsec](#terraform_tfsec)
  * [terraform_validate](#terraform_validate)
  * [terraform_wrapper_module_for_each](#terraform_wrapper_module_for_each)
  * [terrascan](#terrascan)
  * [tfupdate](#tfupdate)
* [Authors](#authors)
* [License](#license)
  * [Additional information for users from Russia and Belarus](#additional-information-for-users-from-russia-and-belarus)

## How to install

### 1. Install dependencies

<!-- markdownlint-disable no-inline-html -->

* [`pre-commit`](https://pre-commit.com/#install)
* [`checkov`](https://github.com/bridgecrewio/checkov) required for `checkov` hook.
* [`terraform-docs`](https://github.com/terraform-docs/terraform-docs) required for `terraform_docs` hook.
* [`terragrunt`](https://terragrunt.gruntwork.io/docs/getting-started/install/) required for `terragrunt_validate` hook.
* [`terrascan`](https://github.com/tenable/terrascan) required for `terrascan` hook.
* [`TFLint`](https://github.com/terraform-linters/tflint) required for `terraform_tflint` hook.
* [`TFSec`](https://github.com/liamg/tfsec) required for `terraform_tfsec` hook.
* [`infracost`](https://github.com/infracost/infracost) required for `infracost_breakdown` hook.
* [`jq`](https://github.com/stedolan/jq) required for `infracost_breakdown` hook.
* [`tfupdate`](https://github.com/minamijoyo/tfupdate) required for `tfupdate` hook.
* [`hcledit`](https://github.com/minamijoyo/hcledit) required for `terraform_wrapper_module_for_each` hook.

<details><summary><b>Docker</b></summary><br>

**Pull docker image with all hooks**:

```bash
TAG=latest
docker pull ghcr.io/antonbabenko/pre-commit-terraform:$TAG
```

All available tags [here](https://github.com/antonbabenko/pre-commit-terraform/pkgs/container/pre-commit-terraform/versions).

**Build from scratch**:

When `--build-arg` is not specified, the latest version of `pre-commit` and `terraform` will be only installed.

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
    --build-arg TERRAFORM_VERSION=latest \
    --build-arg CHECKOV_VERSION=2.0.405 \
    --build-arg INFRACOST_VERSION=latest \
    --build-arg TERRAFORM_DOCS_VERSION=0.15.0 \
    --build-arg TERRAGRUNT_VERSION=latest \
    --build-arg TERRASCAN_VERSION=1.10.0 \
    --build-arg TFLINT_VERSION=0.31.0 \
    --build-arg TFSEC_VERSION=latest \
    --build-arg TFUPDATE_VERSION=latest \
    --build-arg HCLEDIT_VERSION=latest \
    .
```

Set `-e PRE_COMMIT_COLOR=never` to disable the color output in `pre-commit`.

</details>


<details><summary><b>MacOS</b></summary><br>

```bash
brew install pre-commit terraform-docs tflint tfsec checkov terrascan infracost tfupdate minamijoyo/hcledit/hcledit jq
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
curl -L "$(curl -s https://api.github.com/repos/tenable/terrascan/releases/latest | grep -o -E -m 1 "https://.+?_Linux_x86_64.tar.gz")" > terrascan.tar.gz && tar -xzf terrascan.tar.gz terrascan && rm terrascan.tar.gz && sudo mv terrascan /usr/bin/ && terrascan init
sudo apt install -y jq && \
curl -L "$(curl -s https://api.github.com/repos/infracost/infracost/releases/latest | grep -o -E -m 1 "https://.+?-linux-amd64.tar.gz")" > infracost.tgz && tar -xzf infracost.tgz && rm infracost.tgz && sudo mv infracost-linux-amd64 /usr/bin/infracost && infracost register
curl -L "$(curl -s https://api.github.com/repos/minamijoyo/tfupdate/releases/latest | grep -o -E -m 1 "https://.+?_linux_amd64.tar.gz")" > tfupdate.tar.gz && tar -xzf tfupdate.tar.gz tfupdate && rm tfupdate.tar.gz && sudo mv tfupdate /usr/bin/
curl -L "$(curl -s https://api.github.com/repos/minamijoyo/hcledit/releases/latest | grep -o -E -m 1 "https://.+?_linux_amd64.tar.gz")" > hcledit.tar.gz && tar -xzf hcledit.tar.gz hcledit && rm hcledit.tar.gz && sudo mv hcledit /usr/bin/
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
curl -L "$(curl -s https://api.github.com/repos/tenable/terrascan/releases/latest | grep -o -E -m 1 "https://.+?_Linux_x86_64.tar.gz")" > terrascan.tar.gz && tar -xzf terrascan.tar.gz terrascan && rm terrascan.tar.gz && sudo mv terrascan /usr/bin/ && terrascan init
curl -L "$(curl -s https://api.github.com/repos/terraform-linters/tflint/releases/latest | grep -o -E -m 1 "https://.+?_linux_amd64.zip")" > tflint.zip && unzip tflint.zip && rm tflint.zip && sudo mv tflint /usr/bin/
curl -L "$(curl -s https://api.github.com/repos/aquasecurity/tfsec/releases/latest | grep -o -E -m 1 "https://.+?tfsec-linux-amd64")" > tfsec && chmod +x tfsec && sudo mv tfsec /usr/bin/
sudo apt install -y jq && \
curl -L "$(curl -s https://api.github.com/repos/infracost/infracost/releases/latest | grep -o -E -m 1 "https://.+?-linux-amd64.tar.gz")" > infracost.tgz && tar -xzf infracost.tgz && rm infracost.tgz && sudo mv infracost-linux-amd64 /usr/bin/infracost && infracost register
curl -L "$(curl -s https://api.github.com/repos/minamijoyo/tfupdate/releases/latest | grep -o -E -m 1 "https://.+?_linux_amd64.tar.gz")" > tfupdate.tar.gz && tar -xzf tfupdate.tar.gz tfupdate && rm tfupdate.tar.gz && sudo mv tfupdate /usr/bin/
curl -L "$(curl -s https://api.github.com/repos/minamijoyo/hcledit/releases/latest | grep -o -E -m 1 "https://.+?_linux_amd64.tar.gz")" > hcledit.tar.gz && tar -xzf hcledit.tar.gz hcledit && rm hcledit.tar.gz && sudo mv hcledit /usr/bin/
```

</details>

<details><summary><b>Windows 10/11</b></summary>

We highly recommend using [WSL/WSL2](https://docs.microsoft.com/en-us/windows/wsl/install) with Ubuntu and following the Ubuntu installation guide. Or use Docker.

> Note: We won't be able to help with issues that can't be reproduced in Linux/Mac.
> So, try to find a working solution and send PR before open an issue.

Otherwise, you can follow [this gist](https://gist.github.com/etiennejeanneaurevolve/1ed387dc73c5d4cb53ab313049587d09):

1. Install [`git`](https://git-scm.com/downloads) and [`gitbash`](https://gitforwindows.org/)
2. Install [Python 3](https://www.python.org/downloads/)
3. Install all prerequisites needed (see above)

Ensure your PATH environment variable looks for `bash.exe` in `C:\Program Files\Git\bin` (the one present in `C:\Windows\System32\bash.exe` does not work with `pre-commit.exe`)

For `checkov`, you may need to also set your `PYTHONPATH` environment variable with the path to your Python modules.  
E.g. `C:\Users\USERNAME\AppData\Local\Programs\Python\Python39\Lib\site-packages`

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
- repo: https://github.com/antonbabenko/pre-commit-terraform
  rev: <VERSION> # Get the latest from: https://github.com/antonbabenko/pre-commit-terraform/releases
  hooks:
    - id: terraform_fmt
    - id: terraform_docs
EOF
```

### 4. Run

Execute this command to run `pre-commit` on all files in the repository (not only changed files):

```bash
pre-commit run -a
```

Or, using Docker ([available tags](https://github.com/antonbabenko/pre-commit-terraform/pkgs/container/pre-commit-terraform/versions)):

```bash
TAG=latest
docker run -v $(pwd):/lint -w /lint ghcr.io/antonbabenko/pre-commit-terraform:$TAG run -a
```

Execute this command to list the versions of the tools in Docker:

```bash
TAG=latest
docker run --entrypoint cat ghcr.io/antonbabenko/pre-commit-terraform:$TAG /usr/bin/tools_versions_info
```

## Available Hooks

There are several [pre-commit](https://pre-commit.com/) hooks to keep Terraform configurations (both `*.tf` and `*.tfvars`) and Terragrunt configurations (`*.hcl`) in a good shape:

<!-- markdownlint-disable no-inline-html -->
| Hook name                                              | Description                                                                                                                                                                                                                                  | Dependencies<br><sup>[Install instructions here](#1-install-dependencies)</sup>      |
| ------------------------------------------------------ |----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------|
| `checkov` and `terraform_checkov`                      | [checkov](https://github.com/bridgecrewio/checkov) static analysis of terraform templates to spot potential security issues. [Hook notes](#checkov-deprecated-and-terraform_checkov)                                                         | `checkov`<br>Ubuntu deps: `python3`, `python3-pip`                                   |
| `infracost_breakdown`                                  | Check how much your infra costs with [infracost](https://github.com/infracost/infracost). [Hook notes](#infracost_breakdown)                                                                                                                 | `infracost`, `jq`, [Infracost API key](https://www.infracost.io/docs/#2-get-api-key) |
| `terraform_docs`                                       | Inserts input and output documentation into `README.md`. Recommended. [Hook notes](#terraform_docs)                                                                                                                                          | `terraform-docs`                                                                     |
| `terraform_docs_replace`                               | Runs `terraform-docs` and pipes the output directly to README.md. **DEPRECATED**, see [#248](https://github.com/antonbabenko/pre-commit-terraform/issues/248). [Hook notes](#terraform_docs_replace-deprecated)                              | `python3`, `terraform-docs`                                                          |
| `terraform_docs_without_`<br>`aggregate_type_defaults` | Inserts input and output documentation into `README.md` without aggregate type defaults. Hook notes same as for [terraform_docs](#terraform_docs)                                                                                            | `terraform-docs`                                                                     |
| `terraform_fmt`                                        | Reformat all Terraform configuration files to a canonical format. [Hook notes](#terraform_fmt)                                                                                                                                               | -                                                                                    |
| `terraform_providers_lock`                             | Updates provider signatures in [dependency lock files](https://www.terraform.io/docs/cli/commands/providers/lock.html). [Hook notes](#terraform_providers_lock)                                                                              | -                                                                                    |
| `terraform_tflint`                                     | Validates all Terraform configuration files with [TFLint](https://github.com/terraform-linters/tflint). [Available TFLint rules](https://github.com/terraform-linters/tflint/tree/master/docs/rules#rules). [Hook notes](#terraform_tflint). | `tflint`                                                                             |
| `terraform_tfsec`                                      | [TFSec](https://github.com/aquasecurity/tfsec) static analysis of terraform templates to spot potential security issues. [Hook notes](#terraform_tfsec)                                                                                      | `tfsec`                                                                              |
| `terraform_validate`                                   | Validates all Terraform configuration files. [Hook notes](#terraform_validate)                                                                                                                                                               | -                                                                                    |
| `terragrunt_fmt`                                       | Reformat all [Terragrunt](https://github.com/gruntwork-io/terragrunt) configuration files (`*.hcl`) to a canonical format.                                                                                                                   | `terragrunt`                                                                         |
| `terragrunt_validate`                                  | Validates all [Terragrunt](https://github.com/gruntwork-io/terragrunt) configuration files (`*.hcl`)                                                                                                                                         | `terragrunt`                                                                         |
| `terraform_wrapper_module_for_each`                    | Generates Terraform wrappers with `for_each` in module. [Hook notes](#terraform_wrapper_module_for_each)                                                                                                                                     | `hcledit`                                                                            |
| `terrascan`                                            | [terrascan](https://github.com/tenable/terrascan) Detect compliance and security violations. [Hook notes](#terrascan)                                                                                                                       | `terrascan`                                                                          |
| `tfupdate`                                             | [tfupdate](https://github.com/minamijoyo/tfupdate) Update version constraints of Terraform core, providers, and modules. [Hook notes](#tfupdate)                                                                                             | `tfupdate`                                                                           |
<!-- markdownlint-enable no-inline-html -->

Check the [source file](https://github.com/antonbabenko/pre-commit-terraform/blob/master/.pre-commit-hooks.yaml) to know arguments used for each hook.

## Hooks usage notes and examples

### All hooks: Usage of environment variables in `--args`

> All, except deprecated hooks: `checkov`, `terraform_docs_replace`

You can use environment variables for the `--args` section.  
Note: You _must_ use the `${ENV_VAR}` definition, `$ENV_VAR` will not expand.

Config example:

```yaml
- id: terraform_tflint
  args:
  - --args=--config=${CONFIG_NAME}.${CONFIG_EXT}
  - --args=--module
```

If for config above set up `export CONFIG_NAME=.tflint; export CONFIG_EXT=hcl` before `pre-commit run`, args will be expanded to `--config=.tflint.hcl --module`.

### All hooks: Set env vars inside hook at runtime

> All, except deprecated hooks: `checkov`, `terraform_docs_replace`

You can specify environment variables that will be passed to the hook at runtime.

Config example:

```yaml
- id: terraform_validate
  args:
    - --env-vars=AWS_DEFAULT_REGION="us-west-2"
    - --env-vars=AWS_ACCESS_KEY_ID="anaccesskey"
    - --env-vars=AWS_SECRET_ACCESS_KEY="asecretkey"
```

### All hooks: Disable color output

> All, except deprecated hooks: `checkov`, `terraform_docs_replace`

To disable color output for all hooks, set `PRE_COMMIT_COLOR=never` var. Eg:

```bash
PRE_COMMIT_COLOR=never pre-commit run
```

### checkov (deprecated) and terraform_checkov

> `checkov` hook is deprecated, please use `terraform_checkov`.

Note that `terraform_checkov` runs recursively during `-d .` usage. That means, for example, if you change `.tf` file in repo root, all existing `.tf` files in repo will be checked.

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

2. When you have multiple directories and want to run `terraform_checkov` in all of them and share a single config file - use the `__GIT_WORKING_DIR__` placeholder. It will be replaced by `terraform_checkov` hooks with Git working directory (repo root) at run time. For example:

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
    <!-- markdownlint-disable-next-line no-inline-html -->
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
    <!-- markdownlint-disable-next-line no-inline-html -->
    </details>

2. Note that spaces are not allowed in `--args`, so you need to split it, like this:

    ```yaml
    - id: infracost_breakdown
      args:
        - --args=--path=./env/dev
        - --args=--terraform-var-file="terraform.tfvars"
        - --args=--terraform-var-file="../terraform.tfvars"
    ```

3. (Optionally) Define `cost constrains` the hook should evaluate successfully in order to pass:

    ```yaml
    - id: infracost_breakdown
      args:
        - --args=--path=./env/dev
        - --hook-config='.totalHourlyCost|tonumber > 0.1'
        - --hook-config='.totalHourlyCost|tonumber > 1'
        - --hook-config='.projects[].diff.totalMonthlyCost|tonumber != 10000'
        - --hook-config='.currency == "USD"'
    ```
    <!-- markdownlint-disable-next-line no-inline-html -->
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
    <!-- markdownlint-disable-next-line no-inline-html -->
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

1. `terraform_docs` and `terraform_docs_without_aggregate_type_defaults` will insert/update documentation generated by [terraform-docs](https://github.com/terraform-docs/terraform-docs) framed by markers:

    ```txt
    <!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

    <!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
    ```

    if they are present in `README.md`.

2. It is possible to pass additional arguments to shell scripts when using `terraform_docs` and `terraform_docs_without_aggregate_type_defaults`.

3. It is possible to automatically:
    * create a documentation file
    * extend existing documentation file by appending markers to the end of the file (see item 1 above)
    * use different filename for the documentation (default is `README.md`)

    ```yaml
    - id: terraform_docs
      args:
        - --hook-config=--path-to-file=README.md        # Valid UNIX path. I.e. ../TFDOC.md or docs/README.md etc.
        - --hook-config=--add-to-existing-file=true     # Boolean. true or false
        - --hook-config=--create-file-if-not-exist=true # Boolean. true or false
    ```

4. You can provide [any configuration available in `terraform-docs`](https://terraform-docs.io/user-guide/configuration/) as an argument to `terraform_doc` hook, for example:

    ```yaml
    - id: terraform_docs
      args:
        - --args=--config=.terraform-docs.yml
    ```

    Note: Avoid use `recursive.enabled: true` in config file, that can cause unexpected behavior.

5. If you need some exotic settings, it can be done too. I.e. this one generates HCL files:

    ```yaml
    - id: terraform_docs
      args:
        - tfvars hcl --output-file terraform.tfvars.model .
    ```

### terraform_docs_replace (deprecated)

**DEPRECATED**. Will be merged in [`terraform_docs`](#terraform_docs). See [#248](https://github.com/antonbabenko/pre-commit-terraform/issues/248) for details.

`terraform_docs_replace` replaces the entire README.md rather than doing string replacement between markers. Put your additional documentation at the top of your `main.tf` for it to be pulled in. The optional `--dest` argument lets you change the filename that gets created/modified.

Example:

```yaml
- id: terraform_docs_replace
  args:
    - --sort-by-required
    - --dest=TEST.md
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

1. The hook requires Terraform 0.14 or later.
2. The hook invokes two operations that can be really slow:
    * `terraform init` (in case `.terraform` directory is not initialised)
    * `terraform providers lock`

    Both operations require downloading data from remote Terraform registries, and not all of that downloaded data or meta-data is currently being cached by Terraform.

3. `terraform_providers_lock` supports custom arguments:

    ```yaml
     - id: terraform_providers_lock
       args:
          - --args=-platform=windows_amd64
          - --args=-platform=darwin_amd64
    ```

4. It may happen that Terraform working directory (`.terraform`) already exists but not in the best condition (eg, not initialized modules, wrong version of Terraform, etc.). To solve this problem, you can find and delete all `.terraform` directories in your repository:

    ```bash
    echo "
    function rm_terraform {
        find . \( -iname ".terraform*" ! -iname ".terraform-docs*" \) -print0 | xargs -0 rm -r
    }
    " >>~/.bashrc

    # Reload shell and use `rm_terraform` command in the repo root
    ```

    `terraform_providers_lock` hook will try to reinitialize directories before running the `terraform providers lock` command.

5. `terraform_providers_lock` support passing custom arguments to its `terraform init`:

    ```yaml
    - id: terraform_providers_lock
      args:
        - --tf-init-args=-upgrade
    ```


### terraform_tflint

1. `terraform_tflint` supports custom arguments so you can enable module inspection, deep check mode, etc.

    Example:

    ```yaml
    - id: terraform_tflint
      args:
        - --args=--deep
        - --args=--enable-rule=terraform_documented_variables
    ```

2. When you have multiple directories and want to run `tflint` in all of them and share a single config file, it is impractical to hard-code the path to the `.tflint.hcl` file. The solution is to use the `__GIT_WORKING_DIR__` placeholder which will be replaced by `terraform_tflint` hooks with Git working directory (repo root) at run time. For example:

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

### terraform_validate

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
        - --tf-init-args=-lockfile=readonly
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

   `terraform_validate` hook will try to reinitialize them before running the `terraform validate` command.

    **Warning:** If you use Terraform workspaces, DO NOT use this workaround ([details](https://github.com/antonbabenko/pre-commit-terraform/issues/203#issuecomment-918791847)). Wait to [`force-init`](https://github.com/antonbabenko/pre-commit-terraform/issues/224) option implementation.

4. `terraform_validate` in a repo with Terraform module, written using Terraform 0.15+ and which uses provider `configuration_aliases` ([Provider Aliases Within Modules](https://www.terraform.io/language/modules/develop/providers#provider-aliases-within-modules)), errors out.

   When running the hook against Terraform code where you have provider `configuration_aliases` defined in a `required_providers` configuration block, terraform will throw an error like:
   >
   >
   > Error: Provider configuration not present
   > To work with <resource> its original provider configuration at provider["registry.terraform.io/hashicorp/aws"].<provider_alias> is required, but it has been removed. This occurs when a provider configuration is removed while
   > objects created by that provider still exist in the state. Re-add the provider configuration to destroy <resource>, after which you can remove the provider configuration again.

   This is a [known issue](https://github.com/hashicorp/terraform/issues/28490) with Terraform and how providers are initialized in Terraform 0.15 and later. To work around this you can add an `exclude` parameter to the configuration of `terraform_validate` hook like this:
   ```yaml
   - id: terraform_validate
     exclude: [^/]+$
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
   [...]
   ```

   **Note:** The latter method will leave an "aliased-providers.tf.json" file in your repo. You will either want to automate a way to clean this up or add it to your `.gitignore` or both.

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

### terrascan

1. `terrascan` supports custom arguments so you can pass supported flags like `--non-recursive` and `--policy-type` to disable recursive inspection and set the policy type respectively:

    ```yaml
    - id: terrascan
      args:
        - --args=--non-recursive # avoids scan errors on subdirectories without Terraform config files
        - --args=--policy-type=azure
    ```

    See the `terrascan run -h` command line help for available options.

2. Use the `--args=--verbose` parameter to see the rule ID in the scaning output. Usuful to skip validations.
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

## Authors

This repository is managed by [Anton Babenko](https://github.com/antonbabenko) with help from these awesome contributors:

<!-- markdownlint-disable no-inline-html -->
<a href="https://github.com/antonbabenko/pre-commit-terraform/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=antonbabenko/pre-commit-terraform" />
</a>
<!-- markdownlint-enable no-inline-html -->

## License

MIT licensed. See [LICENSE](LICENSE) for full details.

### Additional information for users from Russia and Belarus

* Russia has [illegally annexed Crimea in 2014](https://en.wikipedia.org/wiki/Annexation_of_Crimea_by_the_Russian_Federation) and [brought the war in Donbas](https://en.wikipedia.org/wiki/War_in_Donbas) followed by [full-scale invasion of Ukraine in 2022](https://en.wikipedia.org/wiki/2022_Russian_invasion_of_Ukraine).
* Russia has brought sorrow and devastations to millions of Ukrainians, killed hundreds of innocent people, damaged thousands of buildings, and forced several million people to flee.
* [Putin khuylo!](https://en.wikipedia.org/wiki/Putin_khuylo!)
