#!/usr/bin/env bash

TEST_NUM=$1                            # 1000
TEST_COMMAND=$2                        # 'pre-commit try-repo -a /tmp/159/pre-commit-terraform terraform_tfsec'
TEST_DIR=$3                            # '/tmp/infrastructure'
TEST_DESCRIPTION="$TEST_NUM runs '$4'" # '`terraform_tfsec` PR #123:'
RAW_TEST_RESULTS_FILE_NAME=$5          # terraform_tfsec_pr123

function run_tests {
  local TEST_NUM=$1
  local TEST_DIR=$2
  local TEST_COMMAND
  IFS=" " read -r -a TEST_COMMAND <<< "$3"
  local FILE_NAME_TO_SAVE_TEST_RESULTS=$4

  local RESULTS_DIR
  RESULTS_DIR="$(pwd)/tests/results"

  cd "$TEST_DIR" || { echo "Specified TEST_DIR does not exist" && exit 1; }
  # Cleanup
  rm "$RESULTS_DIR/$FILE_NAME_TO_SAVE_TEST_RESULTS"

  for ((i = 1; i <= TEST_NUM; i++)); do
    {
      echo -e "\n\nTest run $i times\n\n"
      /usr/bin/time --quiet -f '%U user %S system %P cpu %e total' \
        "${TEST_COMMAND[@]}"
    } 2>> "$RESULTS_DIR/$FILE_NAME_TO_SAVE_TEST_RESULTS"
  done
  # shellcheck disable=2164 # Always exist
  cd - > /dev/null
}

function generate_table {
  local FILE_PATH="tests/results/$1"

  local users_seconds system_seconds cpu total_time
  users_seconds=$(awk '{ print $1; }' "$FILE_PATH")
  system_seconds=$(awk '{ print $3; }' "$FILE_PATH")
  cpu=$(awk '{ gsub("%","",$5); print $5; }' "$FILE_PATH")
  total_time=$(awk '{ print $7; }' "$FILE_PATH")

  echo "
| time command   | max    | min    | mean     | median |
| -------------- | ------ | ------ | -------- | ------ |
| users seconds  | $(
    printf %"s\n" "$users_seconds" | datamash max 1
  ) | $(
    printf %"s\n" "$users_seconds" | datamash min 1
  ) | $(
    printf %"s\n" "$users_seconds" | datamash mean 1
  ) | $(printf %"s\n" "$users_seconds" | datamash median 1) |
| system seconds | $(
    printf %"s\n" "$system_seconds" | datamash max 1
  ) | $(
    printf %"s\n" "$system_seconds" | datamash min 1
  ) | $(
    printf %"s\n" "$system_seconds" | datamash mean 1
  ) | $(printf %"s\n" "$system_seconds" | datamash median 1) |
| CPU %          | $(
    printf %"s\n" "$cpu" | datamash max 1
  ) | $(
    printf %"s\n" "$cpu" | datamash min 1
  ) | $(
    printf %"s\n" "$cpu" | datamash mean 1
  ) | $(printf %"s\n" "$cpu" | datamash median 1) |
| Total time     | $(
    printf %"s\n" "$total_time" | datamash max 1
  ) | $(
    printf %"s\n" "$total_time" | datamash min 1
  ) | $(
    printf %"s\n" "$total_time" | datamash mean 1
  ) | $(printf %"s\n" "$total_time" | datamash median 1) |
"
}

function save_result {
  local DESCRIPTION=$1
  local TABLE=$2
  local TEST_RUN_START_TIME=$3
  local TEST_RUN_END_TIME=$4

  local FILE_NAME=${5:-"tests_result.md"}

  echo -e "\n$DESCRIPTION\n$TABLE" >> "tests/results/$FILE_NAME"
  # shellcheck disable=SC2016,SC2128 # Irrelevant
  echo -e '
<details><summary>Run details</summary>

* Test Start: '"$TEST_RUN_START_TIME"'
* Test End: '"$TEST_RUN_END_TIME"'

| Variable name                | Value |
| ---------------------------- | --- |
| `TEST_NUM`                   | <code>'"$TEST_NUM"'</code> |
| `TEST_COMMAND`               | <code>'"$TEST_COMMAND"'</code> |
| `TEST_DIR`                   | <code>'"$TEST_DIR"'</code> |
| `TEST_DESCRIPTION`           | <code>'"$TEST_DESCRIPTION"'</code> |
| `RAW_TEST_RESULTS_FILE_NAME` | <code>'"$RAW_TEST_RESULTS_FILE_NAME"'</code> |

Memory info (`head -n 6 /proc/meminfo`):

```bash
'"$(head -n 6 /proc/meminfo)"'
```

CPU info:

```bash
Real procs: '"$(grep ^cpu\\scores /proc/cpuinfo | uniq | awk '{print $4}')"'
Virtual (hyper-threading) procs: '"$(grep -c ^processor /proc/cpuinfo)"'
'"$(tail -n 28 /proc/cpuinfo)"'
```

</details>
' >> "tests/results/$FILE_NAME"

}

mkdir -p tests/results
TEST_RUN_START_TIME=$(date -u)
# shellcheck disable=SC2128 # Irrelevant
run_tests "$TEST_NUM" "$TEST_DIR" "$TEST_COMMAND" "$RAW_TEST_RESULTS_FILE_NAME"
TEST_RUN_END_TIME=$(date -u)

TABLE=$(generate_table "$RAW_TEST_RESULTS_FILE_NAME")
save_result "$TEST_DESCRIPTION" "$TABLE" "$TEST_RUN_START_TIME" "$TEST_RUN_END_TIME"
