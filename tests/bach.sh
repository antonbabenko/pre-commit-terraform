# -*- mode: sh -*-
# Bach Testing Framework, https://bach.sh
# Copyright (C) 2019  Chai Feng <chaifeng@chaifeng.com>
#
# Bach Testing Framework is dual licensed under:
# - GNU General Public License v3.0
# - Mozilla Public License 2.0
set -euo pipefail
shopt -s expand_aliases

export BACH_COLOR="${BACH_COLOR:-auto}"
export PS4='+(${BASH_SOURCE##*/}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'

BACH_OS_NAME="$(uname)"
declare -gxr BACH_OS_NAME

declare -gxa bach_origin_paths=()
while builtin read -r -d: folder; do
    bach_origin_paths+=("$folder")
done <<< "${PATH}:"

function @out() {
    if [[ "${1:-}" == "-" || ! -t 0 ]]; then
        [[ "${1:-}" == "-" ]] && shift
        while IFS=$'\n' read -r line; do
            builtin printf "%s\n" "${*}$line"
        done
    elif [[ "$#" -gt 0 ]]; then
        builtin printf "%s\n" "$*"
    else
        builtin printf "\n"
    fi
} 8>/dev/null
export -f @out

function @err() {
    @out "$@"
} >&2
export -f @err

function @die() {
    @out "$@"
    exit 1
} >&2
export -f @die

if [[ -z "${BASH_VERSION:-}" ]] || [[ "${BASH_VERSINFO[0]}" -lt 4 ]]; then
    @die "Bach Testing Framework only support Bash v4+!"
fi

if [[ "${BACH_DEBUG:-}" != true ]]; then
    function @debug() {
        :
    }
else
    exec 8>&2
    function @debug() {
        builtin printf '[DEBUG] %s\n' "$*"
    } >&8
fi
export -f @debug

function bach-real-path() {
    declare folder name="$1"
    declare altname="${name#*|}"
    name="${name%|*}"
    for folder in "${bach_origin_paths[@]}"; do
        if [[ -x "$folder/$name" ]]; then
           builtin echo "$folder/$name"
           return 0
        elif [[ "$name" != "$altname" && -x "$folder/$altname" ]]; then
            builtin echo "$folder/$altname"
            return 0
        fi
    done
    return 1
}
export -f bach-real-path

export BACH_DEV_STDIN=""

function bach_restore_stdin() {
    if [[ ! -t 0 ]]; then
        declare name
        [[ -n "$BACH_DEV_STDIN" ]] || for name in /dev/ptmx /dev/pts/ptmx /dev/ttyv[0-9a-f]; do
            if [[ -r "$name" && -c "$name" ]]; then
                ls -l "$name" >&2
                BACH_DEV_STDIN="$name"
                break
            fi
        done
        exec 0<&-
        exec 0<"$BACH_DEV_STDIN"
    fi
}

function bach_initialize(){
    enable -n alias bg bind dirs disown fc fg hash help history jobs kill suspend times ulimit umask unalias wait

    declare util name util_path

    declare -a bash_builtin_cmds=(cd echo enable popd pushd pwd shopt test trap type)

    for name in . command exec false set true unset "${bash_builtin_cmds[@]}"; do
        eval "function @${name}() { builtin $name \"\$@\"; } 8>/dev/null; export -f @${name}"
    done

    for name in eval; do
        eval "function @${name}() { builtin $name \"\$@\"; }; export -f @${name}"
    done

    function @source() {
        declare script="$1"
        shift
        builtin source "$script" "$@"
    }

    declare -a bach_core_utils=(cat chmod cut diff find env grep ls "shasum|sha1sum" mkdir mktemp rm rmdir sed sort tee touch which xargs)

    for util in "${bach_core_utils[@]}"; do
        if [[ "$util" == "shasum|"* && "$BACH_OS_NAME" == FreeBSD ]]; then
            util="shasum|sha1"
        fi
        name="${util%|*}"
        util_path="$(bach-real-path "$util")"
        eval "[[ -n \"${util_path}\" ]] || @die \"Fatal, CAN NOT find '$name' in \\\$PATH\"; function @${name}() { \"${util_path}\" \"\$@\"; } 8>/dev/null; export -f @${name}"
    done

    bach_restore_stdin
    @mockall "${bash_builtin_cmds[@]}" source .

    eval "$(builtin export | while read -rs name; do
        name="${name%%=*}"
        name="${name##* }"
        [[ "${name^^}" != BACH_* ]] || continue
        builtin echo "unset '$name' || builtin true"
    done)"
    builtin export LANG=C TERM=vt100
    unset name util_path
}

function @real() {
    declare name="$1" real_cmd
    if [[ "$name" == */* ]]; then
        @echo "$@"
        return
    fi
    real_cmd="$(bach-real-path "$1" 7>&1)"
    if [[ -z "${real_cmd}" ]]; then
        real_cmd="${name}_not_found"
    fi
    declare -a cmd=("${real_cmd}" "${@:2}")
    @debug "[REAL-CMD]" "${cmd[@]}"
    "${cmd[@]}"
}
export -f @real

function bach-get-all-functions() {
    declare -F
}
export -f bach-get-all-functions

function bach--skip-the-test() {
    declare test="$1" test_filter
    while read -d, test_filter; do
        [[ -n "$test_filter" ]] || continue
        [[ "$test" == $test_filter ]] && return 0
        [[ "$test" == test-$test_filter ]] && return 0
    done <<< "${BACH_TESTS:-},"
}
export -f bach--skip-the-test

function bach-run-tests--get-all-tests() {
    bach-get-all-functions | @sort -R | while read -r _ _ name; do
        [[ "$name" == test?* ]] || continue
        [[ "$name" == *-assert ]] && continue
        bach--skip-the-test "$name" || continue
        builtin printf "%s\n" "$name"
    done
}

for donotpanic in donotpanic dontpanic do-not-panic dont-panic do_not_panic dont_panic; do
    eval "function @${donotpanic}() { builtin printf '\n%s\n  line number: %s\n  script stack: %s\n\n' 'DO NOT PANIC!' \"\${BASH_LINENO}\" \"\${BASH_SOURCE[*]}\"; builtin exit 1; } >&2; export -f @${donotpanic};"
done

function bach--is-function() {
    [[ "$(@type -t "$1")" == function ]]
}
export -f bach--is-function

declare -gr __bach_run_test__ignore_prefix="## BACH:"
function @comment() {
    @out "${__bach_run_test__ignore_prefix}" "$@"
}
export -f @comment

function bach-run-tests() {
    set -euo pipefail

    bach_initialize

    for donotpanic in donotpanic dontpanic do-not-panic dont-panic do_not_panic dont_panic; do
        eval "function @${donotpanic}() { builtin true; }; export -f @${donotpanic}"
    done

    function command() {
        if [[ "$1" != -* ]] && bach--is-function "$1"; then
            "$@"
        else
            mockfunc="$(@generate_mock_function_name command "$@")"
            if bach--is-function "${mockfunc}"; then
                @debug "[BC-func]" "${mockfunc}" "$@"
                "${mockfunc}" "$@"
            else
                command_not_found_handle command "$@"
            fi
        fi
    }
    export -f command

    function xargs() {
        declare param
        declare -a xargs_opts
        while param="${1:-}"; [[ -n "${param:-}" ]]; do
            shift || true
            if [[ "$param" == "--" ]]; then
                xargs_opts+=("${BASH:-bash}" "-c" "$(builtin printf "'%s' " "$@") \$@" "-s")
                break
            else
                xargs_opts+=("$param")
            fi
        done
        @debug "@mock-xargs" "${xargs_opts[@]}"
        if [[ "$#" -gt 0 ]]; then
            @xargs "${xargs_opts[@]}"
        else
            [[ -t 0 ]] || @cat &>/dev/null
            @dryrun xargs "${xargs_opts[@]}"
        fi
    }
    export -f xargs

    if [[ "${BACH_ASSERT_IGNORE_COMMENT}" == true ]]; then
        BACH_ASSERT_DIFF_OPTS+=(-I "^${__bach_run_test__ignore_prefix}")
    fi

    declare color_ok color_err color_end
    if [[ "$BACH_COLOR" == "always" ]] || [[ "$BACH_COLOR" != "no" && -t 1 && -t 2 ]]; then
        color_ok="\e[1;32m"
        color_err="\e[1;31m"
        color_end="\e[0;m"
    else
        color_ok=""
        color_err=""
        color_end=""
    fi
    declare name friendly_name testresult test_name_assert_fail
    declare -i total=0 error=0
    declare -a all_tests
    mapfile -t all_tests < <(bach-run-tests--get-all-tests)
    @echo "1..${#all_tests[@]}"
    for name in "${all_tests[@]}"; do
        # @debug "Running test: $name"
        friendly_name="${name/#test-/}"
        friendly_name="${friendly_name//-/ }"
        friendly_name="${friendly_name//  / -}"
        : $(( ++total ))
        testresult="$(@mktemp)"
        @set +e
        assert-execution "$name" &>"$testresult"; test_retval="$?"
        @set -e
        if [[ "$name" == test-ASSERT-FAIL-* ]]; then
            test_retval="$(( test_retval == 0?1:0 ))"
            test_name_assert_fail="${color_err}ASSERT FAIL${color_end}"
            friendly_name="${friendly_name/#ASSERT FAIL/}"
        else
            test_name_assert_fail=""
        fi
        if [[ "$test_retval" -eq 0 ]]; then
            builtin printf "${color_ok}ok %d - ${test_name_assert_fail}${color_ok}%s${color_end}\n" "$total" "$friendly_name"
        else
            : $(( ++error ))
            builtin printf "${color_err}not ok %d - ${test_name_assert_fail}${color_err}%s${color_end}\n" "$total" "$friendly_name"
            {
                builtin printf "\n"
                @cat "$testresult" >&2
                builtin printf "\n"
            } >&2
        fi
        @rm "$testresult" &>/dev/null
    done

    declare color_result="$color_ok"
    if (( error > 0 )); then
        color_result="$color_err"
    fi
    builtin printf -- "# -----\n#${color_result} All tests: %s, failed: %d, skipped: %d${color_end}\n" \
           "${#all_tests[@]}" "$error" "$(( ${#all_tests[@]} - total ))">&2
    [[ "$error" == 0 ]] && [[ "${#all_tests[@]}" -eq "$total" ]]
}

function bach-on-exit() {
    if [[ -o xtrace ]]; then
        exec 8>&2
        BASH_XTRACEFD=8
    fi
    if [[ "$?" -eq 0 ]]; then
        [[ "${BACH_DISABLED:-false}" == true ]] || bach-run-tests
    else
        builtin printf "Bail out! %s\n" "Couldn't initlize tests."
    fi
}

trap bach-on-exit EXIT

function @generate_mock_function_name() {
    declare name="$1"
    @echo "mock_exec_${name}_$(@dryrun "${@}" | @shasum | @cut -b1-7)"
}
export -f @generate_mock_function_name

function @mock() {
    declare -a param name cmd func body desttype
    name="$1"
    if [[ "$name" == @(builtin|declare|eval|set|unset|true|false|read) ]]; then
        @die "Cannot mock the builtin command: $name"
    fi
    if [[ command == "$name" && "$2" != -* ]]; then
        shift
        name="$1"
    fi
    desttype="$(@type -t "$name" || true)"
    for param; do
        if [[ "$param" == '===' ]]; then
            shift
            break
        fi
        cmd+=("$param")
    done
    shift "${#cmd[@]}"
    if [[ "$name" == /* ]]; then
        @die "Cannot mock an absolute path: $name"
    elif [[ "$name" == */* ]] && [[ -e "$name" ]]; then
        @die "Cannot mock an existed path: $name"
    fi
    @debug "@mock $name"
    if [[ "$#" -gt 0 ]]; then
        @debug "@mock $name $*"
        declare -a params=("$@")
        func="$(declare -p params); \"\${params[@]}\""
        #func="$*"
    elif [[ ! -t 0 ]]; then
        @debug "@mock $name @cat"
        func="$(@cat)"
    fi
    if [[ -z "${func:-}" ]]; then
        @debug "@mock default $name"
        func="if [[ -t 0 ]]; then @dryrun \"${name}\" \"\$@\" >&7; else @cat; fi"
    fi
    if [[ "$name" == */* ]]; then
        [[ -d "${name%/*}" ]] || @mkdir -p "${name%/*}"
        @cat > "$name" <<SCRIPT
#!${BASH:-/bin/bash}
${func}
SCRIPT
        @chmod +x "$name" >&2
    else
        if [[ -z "$desttype" || "$desttype" == builtin ]]; then
            eval "function ${name}() {
                      declare mockfunc=\"\$(@generate_mock_function_name ${name} \"\${@}\")\"
                      if bach--is-function \"\$mockfunc\"; then
                           \"\${mockfunc}\" \"\$@\"
                      else
                           [[ -t 0 ]] || @cat
                           @dryrun ${name} \"\$@\" >&7
                      fi
                  }; export -f ${name}"
        fi
        declare mockfunc
        mockfunc="$(@generate_mock_function_name "${cmd[@]}")"
        #stderr name="$name"
        #body="function ${mockfunc}() { @debug Running mock : '${cmd[*]}' :; $func; }"
        declare mockfunc_seq="${mockfunc//_/__}_SEQ"
        mockfunc_seq="${mockfunc_seq//[-\!+.@\[\]\{\}~]/_}"
        body="function ${mockfunc}() {
            declare -gxi ${mockfunc_seq}=\"\${${mockfunc_seq}:-0}\";
            if bach--is-function \"${mockfunc}_\$(( ${mockfunc_seq} + 1))\"; then
                let ++${mockfunc_seq};
            fi;
            \"${mockfunc}_\${${mockfunc_seq}}\" \"\$@\";
        }; export -f ${mockfunc}"
        @debug "$body"
        eval "$body"
        for (( mockfunc__SEQ=1; mockfunc__SEQ <= ${BACH_MOCK_FUNCTION_MAX_COUNT:-0}; ++mockfunc__SEQ )); do
            bach--is-function "${mockfunc}_${mockfunc__SEQ}" || break
        done
        body="${mockfunc}_${mockfunc__SEQ}() {
            # @mock ${name} ${cmd[@]} ===
            $func
        }; export -f ${mockfunc}_${mockfunc__SEQ}"
        @debug "$body"
        eval "$body"
    fi
}
export -f @mock

function @@mock() {
    BACH_MOCK_FUNCTION_MAX_COUNT=15 @mock "$@"
}
export -f @@mock

function @mocktrue() {
    @mock "$@" === @true
}
export -f @mocktrue

function @mockfalse() {
    @mock "$@" === @false
}
export -f @mockfalse

function @mockall() {
    declare name
    for name; do
        @mock "$name"
    done
}
export -f @mockall


BACH_FRAMEWORK__SETUP_FUNCNAME="_bach_framework_setup_"
alias @setup="function $BACH_FRAMEWORK__SETUP_FUNCNAME"

BACH_FRAMEWORK__PRE_TEST_FUNCNAME='_bach_framework_pre_test_'
alias @setup-test="function $BACH_FRAMEWORK__PRE_TEST_FUNCNAME"

BACH_FRAMEWORK__PRE_ASSERT_FUNCNAME='_bach_framework_pre_assert_'
alias @setup-assert="function $BACH_FRAMEWORK__PRE_ASSERT_FUNCNAME"

function _bach_framework__run_function() {
    declare name="$1"
    if bach--is-function "$name"; then
        "$name"
    fi
}
export -f _bach_framework__run_function

function @dryrun() {
    builtin declare param
    builtin declare -a input
    [[ "$#" -le 1 ]] || {
        for param in "${@:2}"; do
	    if [[ -z "$param" ]]; then input+=($'\x1b[31m\u2205\x1b[0m'); else input+=("$param"); fi
        done
        builtin printf -v param '  %s' "${input[@]}"
    }
    builtin echo "${1}${param:-}"
}
export -f @dryrun

declare -gxa BACH_ASSERT_DIFF_OPTS=(-u)
declare -gx BACH_ASSERT_IGNORE_COMMENT="${BACH_ASSERT_IGNORE_COMMENT:-true}"
declare -gx BACH_ASSERT_DIFF="${BACH_ASSERT_DIFF:-diff}"

function assert-execution() (
    @unset BACH_TESTS
    declare bach_test_name="$1" bach_tmpdir bach_actual_output bach_expected_output
    bach_tmpdir="$(@mktemp -d)"
    #trap '/bin/rm -vrf "$bach_tmpdir"' RETURN
    @mkdir "${bach_tmpdir}/test_root"
    @pushd "${bach_tmpdir}/test_root" &>/dev/null
    declare retval=1

    exec 7>&2

    function command_not_found_handle() {
        declare mockfunc bach_cmd_name="$1"
        [[ -n "$bach_cmd_name" ]] || @out "Error: Bach found an empty command at line ${BASH_LINENO}." >&7
        mockfunc="$(@generate_mock_function_name "$@")"
        # @debug "mockid=$mockid" >&2
        if bach--is-function "${mockfunc}"; then
            @debug "[CNFH-func]" "${mockfunc}" "$@"
            "${mockfunc}" "$@"
        elif [[ "${bach_cmd_name}" == @(cd|command|echo|eval|exec|false|popd|pushd|pwd|source|true|type) ]]; then
            @debug "[CNFH-builtin]" "$@"
            builtin "$@"
        else
            @debug "[CNFH-default]" "$@"
            @dryrun "$@"
        fi
    } >&7 #8>/dev/null
    export -f command_not_found_handle

    function __bach__pre_run_test_and_assert() {
        @trap - EXIT RETURN
        @set +euo pipefail
        declare -gxr PATH=bach-fake-path
        bach_restore_stdin
        _bach_framework__run_function "$BACH_FRAMEWORK__SETUP_FUNCNAME"
    }
    function __bach__run_test() (
        __bach__pre_run_test_and_assert
        _bach_framework__run_function "${BACH_FRAMEWORK__PRE_TEST_FUNCNAME}"
        "${1}"
    ) 7>&1

    function __bach__run_assert() (
        @unset -f @mock @mockall @ignore @setup-test
        __bach__pre_run_test_and_assert
        _bach_framework__run_function "${BACH_FRAMEWORK__PRE_ASSERT_FUNCNAME}"
        "${1}-assert"
    ) 7>&1
    bach_actual_stdout="${bach_tmpdir}/actual-stdout.txt"
    bach_expected_stdout="${bach_tmpdir}/expected-stdout.txt"
    if bach--is-function "${bach_test_name}-assert"; then
        @cat <(
            __bach__run_test "$bach_test_name"
            @echo "# Exit code: $?"
        ) > "${bach_actual_stdout}"
        @cat <(
            __bach__run_assert "$bach_test_name"
            @echo "# Exit code: $?"
        ) > "${bach_expected_stdout}"
        @cd ..
        if @real "${BACH_ASSERT_DIFF}" "${BACH_ASSERT_DIFF_OPTS[@]}" -- \
            "${bach_actual_stdout##*/}" "${bach_expected_stdout##*/}"
        then
            retval=0
        fi
    else
        __bach__run_test "$bach_test_name" |
            @tee /dev/stderr | if [[ "$bach_test_name" = test-ASSERT-FAIL-* ]]; then
                @cat
                @echo "${__bach_run_test__ignore_prefix} Should fail"
            else
                @grep "^${__bach_run_test__ignore_prefix} \\[assert-" >/dev/null
            fi
        retval="$?"
    fi
    @popd &>/dev/null
    @rm -rf "$bach_tmpdir"
    return "$retval"
)

function @ignore() {
    declare name
    for name; do
        if [[ "$name" == @(builtin|declare|eval|set|unset|true|false|read) ]]; then
            @die "Cannot ignore the builtin command: $name"
        fi
        eval "function ${name}() {
              declare mockfunc=\"\$(@generate_mock_function_name ${name} \"\${@}\")\";
              if bach--is-function \"\$mockfunc\"; then
                  \"\${mockfunc}\" \"\$@\";
              else [[ -t 0 ]] || @cat; fi
          }; export -f ${name}"
    done
}
export -f @ignore

function @stderr() {
    builtin printf "%s\n" "$@" >&2
}
export -f @stderr

function @stdout() {
    builtin printf "%s\n" "$@"
}
export -f @stdout

function @load_function() {
    local file="${1:?script filename}"
    local func="${2:?function name}"
    @source <(@sed -Ene "/^function[[:space:]]+${func}([\(\{\[[:space:]]|[[:space:]]*\$)/,/^}\$/p" "$file")
} 8>/dev/null
export -f @load_function

export BACH_STARTUP_PWD="${PWD:-$(pwd)}"
function @run() {
    declare script="${1:?missing script name}"
    shift
    [[ "$script" == /* ]] || script="${BACH_STARTUP_PWD}/${script}"
    @source "$script" "$@"
}
export -f @run

function @fail() {
    declare retval=1
    if [[ "${1:-}" =~ ^[0-9]+$ ]]; then
        retval="$1"
        shift
    fi
    if [[ "$#" -gt 0 ]]; then
        @out "${@}"
    fi
    builtin exit "${retval}"
}
export -f @fail

function @assert-equals() {
    declare expected="${1:?missing the expected result}" actual="${2:?missing the actual result}"

    if [[ "${expected}" == "${actual}" ]]; then
        @out <<EOF
${__bach_run_test__ignore_prefix} [assert-equals] expected: ${expected}
##                         actual: ${actual}
EOF
    else
        @die - 2>&7 <<EOF
Assert Failed:
     Expected: $expected
      But got: $actual
EOF
    fi
} >&7
export -f @assert-equals

function @assert-fail() {
    declare expected="<non-zero>" actual="$?"
    [[ "$actual" -eq 0 ]] || expected="$actual"
    @assert-equals "$expected" "$actual"
}
export -f @assert-fail

function @assert-success() {
    declare expected=0 actual="$?"
    @assert-equals "$expected" "$actual"
}
export -f @assert-success

function @do-nothing() {
    :
}
export -f @do-nothing

function @unmock() {
    declare name="${1:?missing command name}"
    if bach--is-function "$name"; then
        unset -f "$name"
    fi
}
export -f @unmock
