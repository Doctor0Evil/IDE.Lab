#!/usr/bin/env bash
# system_exec_wrapper_test.sh - Ad-hoc unit tests for docker/system_exec_wrapper.sh
set -euo pipefail

WRAPPER=./docker/system_exec_wrapper.sh
if [[ ! -x "$WRAPPER" ]]; then
  echo "Wrapper not found or not executable at $WRAPPER" >&2
  exit 2
fi

run_case() {
  name="$1"
  json="$2"
  echo "=== Test: $name ==="
  out=$($WRAPPER - <<<"$json") || true
  echo "$out"
}

# 1. Simple echo
json=$(cat <<'JSON'
{
  "cmd_name": "echo",
  "args": ["hello world"],
  "env_allowlist": ["HOME"],
  "timeout_secs": 5,
  "max_output_kb": 4,
  "redaction_rules": []
}
JSON
)
run_case "echo" "$json"

# 2. Timeout enforcement (sleep 2, timeout 1s)
json=$(cat <<'JSON'
{
  "cmd_name": "bash",
  "args": ["-lc", "sleep 2; echo done"],
  "env_allowlist": [],
  "timeout_secs": 1,
  "max_output_kb": 8,
  "redaction_rules": []
}
JSON
)
run_case "timeout" "$json"

# 3. Truncation: produce many lines; set max_output_kb small
json=$(cat <<'JSON'
{
  "cmd_name": "bash",
  "args": ["-lc", "for i in {1..500}; do printf \"line-%s\\n\" $i; done"],
  "env_allowlist": [],
  "timeout_secs": 10,
  "max_output_kb": 4,
  "redaction_rules": []
}
JSON
)
run_case "truncation" "$json"

# 4. Env allowlist: set MYSECRET and test whether it's passed
export MYSECRET="topsecret"
json=$(cat <<'JSON'
{
  "cmd_name": "bash",
  "args": ["-lc", "echo $MYSECRET"],
  "env_allowlist": ["HOME"],
  "timeout_secs": 5,
  "max_output_kb": 2,
  "redaction_rules": []
}
JSON
)
run_case "env_no_allowlist" "$json"

json=$(cat <<'JSON'
{
  "cmd_name": "bash",
  "args": ["-lc", "echo $MYSECRET"],
  "env_allowlist": ["MYSECRET"],
  "timeout_secs": 5,
  "max_output_kb": 2,
  "redaction_rules": []
}
JSON
)
run_case "env_with_allowlist" "$json"

# 5. Redaction: pattern matches 'tok[digits]+'
json=$(cat <<'JSON'
{
  "cmd_name": "bash",
  "args": ["-lc", "echo 'token tokabc123 and ok'"],
  "env_allowlist": [],
  "timeout_secs": 3,
  "max_output_kb": 4,
  "redaction_rules": ["tok[a-z0-9]+"]
}
JSON
)
run_case "redaction" "$json"

exit 0
