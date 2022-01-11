# Notes for contributors

1. Python hooks are supported now too. All you have to do is:
    1. add a line to the `console_scripts` array in `entry_points` in `setup.py`
    2. Put your python script in the `pre_commit_hooks` folder

Enjoy the clean, valid, and documented code!

* [Run and debug hooks locally](#run-and-debug-hooks-locally)
* [Run hook performance test](#run-hook-performance-test)
  * [Run via BASH](#run-via-bash)
  * [Run via Docker](#run-via-docker)
  * [Check results](#check-results)
  * [Cleanup](#cleanup)
* [Add new hook](#add-new-hook)
  * [Before write code](#before-write-code)
  * [Prepare basic documentation](#prepare-basic-documentation)
  * [Add code](#add-code)
  * [Finish with the documentation](#finish-with-the-documentation)

## Run and debug hooks locally

```bash
pre-commit try-repo {-a} /path/to/local/pre-commit-terraform/repo {hook_name}
```

I.e.

```bash
pre-commit try-repo /mnt/c/Users/tf/pre-commit-terraform terraform_fmt # Run only `terraform_fmt` check
pre-commit try-repo -a ~/pre-commit-terraform # run all existing checks from repo
```

Running `pre-commit` with `try-repo` ignores all arguments specified in `.pre-commit-config.yaml`.

If you need to test hook with arguments, follow [pre-commit doc](https://pre-commit.com/#arguments-pattern-in-hooks) to test hooks.

For example, to test that the [`terraform_fmt`](../README.md#terraform_fmt) hook works fine with arguments:

```bash
/tmp/pre-commit-terraform/terraform_fmt.sh --args=-diff --args=-write=false test-dir/main.tf test-dir/vars.tf
```

## Run hook performance test

To check is your improvement not violate performance, we have dummy execution time tests.

Script accept next options:
<!-- markdownlint-disable no-inline-html -->
| #   | Name                               | Example value                                                            | Description                                          |
| --- | ---------------------------------- | ------------------------------------------------------------------------ | ---------------------------------------------------- |
| 1   | `TEST_NUM`                         | `200`                                                                   | How many times need repeat test                      |
| 2   | `TEST_COMMAND`                     | `'pre-commit try-repo -a /tmp/159/pre-commit-terraform terraform_tfsec'` | Valid pre-commit command                             |
| 3   | `TEST_DIR`                         | `'/tmp/infrastructure'`                                                  | Dir on what you run tests.                           |
| 4   | `TEST_DESCRIPTION`                 | ```'`terraform_tfsec` PR #123:'```                                       | Text that you'd like to see in result                |
| 5   | `RAW_TEST_`<br>`RESULTS_FILE_NAME` | `terraform_tfsec_pr123`                                                  | (Temporary) File where all test data will be stored. |
<!-- markdownlint-enable no-inline-html -->

> **Note:** To make test results repeatable and comparable, be sure that on the test machine nothing generates an unstable workload. During tests good to stop any other apps and do not interact with the test machine.
>
> Otherwise, for eg, when you watch Youtube videos during one test and not during other, test results can differ up to 30% for the same test.

### Run via BASH

```bash
# Install deps
sudo apt install -y datamash
# Run tests
./hooks_performance_test.sh 200 'pre-commit try-repo -a /tmp/159/pre-commit-terraform terraform_tfsec' '/tmp/infrastructure' '`terraform_tfsec` v1.51.0:' 'terraform_tfsec_pr159'
```

### Run via Docker

```bash
# Build `pre-commit-terraform` image
docker build -t pre-commit-terraform --build-arg INSTALL_ALL=true .
# Build test image
docker build -t pre-commit-tests tests/
# Run
TEST_NUM=1
TEST_DIR='/tmp/infrastructure'
PRE_COMMIT_DIR="$(pwd)"
TEST_COMMAND='pre-commit try-repo -a /pct terraform_tfsec'
TEST_DESCRIPTION='`terraform_tfsec` v1.51.0:'
RAW_TEST_RESULTS_FILE_NAME='terraform_tfsec_pr159'

docker run -v "$PRE_COMMIT_DIR:/pct:rw" -v "$TEST_DIR:/lint:ro" pre-commit-tests \
    $TEST_NUM "$TEST_COMMAND" '/lint' "$RAW_TEST_RESULTS_FILE_NAME" "$RAW_TEST_RESULTS_FILE_NAME"
```

### Check results

Results will be located at `./test/results` dir.

### Cleanup

```bash
sudo rm -rf tests/results
```

## Add new hook

You can use [this PR](https://github.com/antonbabenko/pre-commit-terraform/pull/252) as an example.

### Before write code

1. Try to figure out future hook usage.
2. Confirm the concept with [Anton Babenko](https://github.com/antonbabenko).

### Prepare basic documentation

1. Identify and describe dependencies in [Install dependencies](../README.md#1-install-dependencies) and [Available Hooks](../README.md#available-hooks) sections

### Add code

1. Based on prev. block, add hook dependencies installation to [Dockerfile](../Dockerfile).  
    Check that works:
    * `docker build -t pre-commit --build-arg INSTALL_ALL=true .`
    * `docker build -t pre-commit --build-arg <NEW_HOOK>_VERSION=latest .`
    * `docker build -t pre-commit --build-arg <NEW_HOOK>_VERSION=<1.2.3> .`
2. Add new hook to [`.pre-commit-hooks.yaml`](../.pre-commit-hooks.yaml)
3. Create hook file. Don't forget to make it executable via `chmod +x /path/to/hook/file`.
4. Test hook. How to do it is described in [Run and debug hooks locally](#run-and-debug-hooks-locally) section.
5. Test hook one more time.
    1. Push commit with hook file to GitHub
    2. Grab SHA hash of the commit
    3. Test hook using `.pre-commit-config.yaml`:

        ```yaml
        repos:
        - repo: https://github.com/antonbabenko/pre-commit-terraform # Your repo
        rev: 3d76da3885e6a33d59527eff3a57d246dfb66620 # Your commit SHA
        hooks:
          - id: terraform_docs # New hook name
            args:
              - --args=--config=.terraform-docs.yml # Some args that you'd like to test
        ```

### Finish with the documentation

1. Add hook description to [Available Hooks](../README.md#available-hooks).
2. Create and populate a new hook section in [Hooks usage notes and examples](../README.md#hooks-usage-notes-and-examples).
