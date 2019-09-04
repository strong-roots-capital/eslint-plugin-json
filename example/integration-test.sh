#!/bin/bash

JSON_PLUGIN_NAME=json-beta
COUNT_FILE=$(mktemp)

echo 0 > $COUNT_FILE
function increment_error_count() {
    local current_value=$(< $COUNT_FILE)
    echo $((current_value + 1)) > $COUNT_FILE
}
function s() {
    [ "$1" -le 1 ]|| echo s
}

function lint_file() {
    local file="$1"
    if [ ! -f "$file" ]; then return 1; fi
    npm run lint -- $file 2> /dev/null
}
function check() {
    local type=$1
    local error_code=$2
    local expected_error_count=$3
    local filename=${4:-'<input>'}
    local actual_error_count=$(while read line; do echo "$line"; done | grep " $type " | grep $error_code | wc -l)
    if [ "$actual_error_count" -ne "$expected_error_count" ]; then
        echo "Expected $expected_error_count $error_code $type$(s $expected_error_count) in $filename but got $actual_error_count"
        increment_error_count
        return 1
    fi
}
function check_file() {
    local file="samples/$1.json" type="$2" error_name="$JSON_PLUGIN_NAME/$3" count="$4"
    if [ ! -f "$file" ]; then
        echo "Unexisting file $1 ($file)"
        increment_error_count
        return 1
    fi
    lint_file "$file" | check "$type" "$error_name" "$count" "'$file'"
}

check_file good-json warning "$ANY" 0
check_file good-json warning "$ANY" 0
check_file duplicate-keys error "duplicate-key" 2
check_file wrong-syntax warning "*" 1
check_file whole-mess error "duplicate-key" 2
check_file whole-mess error "trailing-comma" 1
check_file whole-mess warning "*" 1 # as comment-not-permitted
check_file jsonc "*" "json" 0 # comment allowed

error_count=$(< $COUNT_FILE)
echo
if [ "$error_count" -gt 0 ]; then
    echo "Integration test, in total $error_count error$(s $error_count) occured"
    exit 1;
else
    echo "All integrations tests passed! \\o/"
fi
