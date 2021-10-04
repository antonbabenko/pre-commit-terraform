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

## Run hook performance test

To check is your improvement not violate performance, we have dummy execution time tests.

Script accept next options:

| #   | Name                               | Example value                                                            | Description                                          |
| --- | ---------------------------------- | ------------------------------------------------------------------------ | ---------------------------------------------------- |
| 1   | `TEST_NUM`                         | `200`                                                                   | How many times need repeat test                      |
| 2   | `TEST_COMMAND`                     | `'pre-commit try-repo -a /tmp/159/pre-commit-terraform terraform_tfsec'` | Valid pre-commit command                             |
| 3   | `TEST_DIR`                         | `'/tmp/infrastructure'`                                                  | Dir on what you run tests.                           |
| 4   | `TEST_DESCRIPTION`                 | ```'`terraform_tfsec` PR #123:'```                                       | Text that you'd like to see in result                |
| 5   | `RAW_TEST_`<br>`RESULTS_FILE_NAME` | `terraform_tfsec_pr123`                                                  | (Temporary) File where all test data will be stored. |

### Run via BASH

```bash
# Install deps
sudo apt install -y datamash
# Run tests
./hooks_performance_test.sh 200 'pre-commit try-repo -a /tmp/159/pre-commit-terraform terraform_tfsec' '/tmp/infrastructure' '`terraform_tfsec` v1.51.0:' 'terraform_tfsec_pr159'
```

### Run via Docker

```bash
# Build `pre-commit` image
docker build -t pre-commit --build-arg INSTALL_ALL=true .
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
