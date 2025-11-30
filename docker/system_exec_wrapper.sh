#!/usr/bin/env bash
# system_exec_wrapper.sh - A secure wrapper that enforces ExecOptions constraints
# Reads ExecOptions JSON from stdin or from a file path given as the first arg
# Outputs ExecResult JSON to stdout
# Implements: env allowlist, cwd, timeout, max_output_kb truncation, redaction rules

set -euo pipefail

INPUT_FILE=""
if [[ $# -gt 0 ]]; then
  INPUT_FILE="$1"
fi

# Read JSON from file or stdin
if [[ -n "$INPUT_FILE" ]]; then
  if [[ ! -f "$INPUT_FILE" ]]; then
    echo "{\"error\": \"input file not found\" }" >&2
    exit 2
  fi
  JSON=$(cat "$INPUT_FILE")
else
  JSON=$(cat -)
fi

# Basic pill: require jq
if ! command -v jq >/dev/null 2>&1; then
  echo "{\"error\": \"jq required\" }" >&2
  exit 3
fi

# Parse options from JSON
cmd_name=$(echo "$JSON" | jq -r '.cmd_name // empty')
if [[ -z "$cmd_name" ]]; then
  echo "{\"error\": \"cmd_name missing\" }" >&2
  exit 3
fi

args_raw=$(echo "$JSON" | jq -r '.args // [] | @sh')
# Convert sh-quoted args into an array (safe because we used @sh)
IFS=' ' read -r -a __ARG_ARRAY <<< "$args_raw"
args=( )
for token in "${__ARG_ARRAY[@]}"; do
  # remove surrounding single quotes
  args+=("$(echo "$token" | sed -e "s/^'//" -e "s/'$//")")

done

# env_allowlist array
readarray -t env_allowlist < <(echo "$JSON" | jq -r '.env_allowlist // [] | .[]') || true

cwd=$(echo "$JSON" | jq -r '.cwd // empty')
if [[ -n "$cwd" && -d "$cwd" ]]; then
  cd "$cwd"
fi

timeout_secs=$(echo "$JSON" | jq -r '.timeout_secs // 30')
max_output_kb=$(echo "$JSON" | jq -r '.max_output_kb // 64')
redaction_rules_count=$(echo "$JSON" | jq -r '.redaction_rules // [] | length')

# Build environment with allowlist
# We'll preserve PATH and add only allowed env vars
declare -A sanitized_env
for name in "${env_allowlist[@]}"; do
  val=""
  if [[ -n "${!name:-}" ]]; then
    val="${!name}"
  fi
  sanitized_env["$name"]="$val"
done

# Fill in PATH to reasonable default if not present
sanitized_env[PATH]="/usr/local/bin:/usr/bin:/bin"

# Export sanitized env to a temporary env file that can be used with env -S if available
ENVFILE="/tmp/system_exec_env_$$.sh"
: > "$ENVFILE"
for name in "${!sanitized_env[@]}"; do
  # Escape single quotes
  v=${sanitized_env[$name]}
  v_escaped=$(printf "%s" "$v" | sed "s/'/'\\''/g")
  echo "export $name='$v_escaped'" >> "$ENVFILE"
done

# Compose command array safely
# Note: We'll use a bash array and exec via env -S to set env vars
cmd=("$cmd_name")
for a in "${args[@]}"; do
  cmd+=("$a")
done

# Destructive checks (simple): if command contains a potentially destructive substring and no override allowlist, refuse
# For stronger policy, the ALN policy kernel should have prevented this; this wrapper is a fallback safety.
for dangerous in "rm -rf" ":(){" "shutdown" "reboot" "init 0"; do
  if [[ "${cmd[*]}" =~ $dangerous ]]; then
    echo "{\"exit_code\": 1, \"stdout\": \"\", \"stderr\": \"command appears destructive\", \"redacted_log\": \"[REDACTED]\", \"duration_ms\": 0 }"
    exit 1
  fi
done

# Prepare temporary files for stdout/stderr
STDOUT_FILE="/tmp/system_exec_stdout_$$.log"
STDERR_FILE="/tmp/system_exec_stderr_$$.log"
: > "$STDOUT_FILE"
: > "$STDERR_FILE"

# Compose wrapper script so we can export sanitized env and use `timeout`
LAUNCH_SCRIPT="/tmp/system_exec_run_$$.sh"
cat > "$LAUNCH_SCRIPT" <<'BASH'
#!/usr/bin/env bash
set -euo pipefail
# Load sanitized env
source "__ENVFILE__"

# Launch command
__CMD_ARRAY__
BASH

# Replace placeholders
sed -i "s|__ENVFILE__|$ENVFILE|g" "$LAUNCH_SCRIPT"
# Build cmd array line
cmd_quoted=""
for x in "${cmd[@]}"; do
  cmd_quoted+=" \"$(printf '%q' "$x")\""
done

# Convert to bash exec snippet
cmd_exec_line="exec \"${cmd[0]}\""
if [[ ${#cmd[@]} -gt 1 ]]; then
  cmd_exec_line="\"${cmd[0]}\" "
  # Build: exec cmd "arg1" "arg2" ...
  args_line=""
  for ((i=1;i<${#cmd[@]};i++)); do
    a=${cmd[$i]}
    # Escape quotes
    a_escaped=$(printf '%q' "$a")
    args_line+=" \"$a_escaped\""
  done
  cmd_exec_line="\"${cmd[0]}\"$args_line"
fi
# Use `timeout` to enforce duration
# Compose full invocation that writes stdout/stderr to specified files
FULL_CMD="timeout ${timeout_secs}s bash -lc '"$cmd_exec_line"' >\"$STDOUT_FILE\" 2>\"$STDERR_FILE\" || true"

# Insert into LAUNCH_SCRIPT
sed -i "s#__CMD_ARRAY__##" "$LAUNCH_SCRIPT"
# Add full invocation line to script
printf "%s\n" "$FULL_CMD" >> "$LAUNCH_SCRIPT"

chmod +x "$LAUNCH_SCRIPT"

# Run and measure duration
start=$(date +%s%3N)
bash "$LAUNCH_SCRIPT"
end=$(date +%s%3N)

duration_ms=$((end - start))

# Read outputs with truncation
max_bytes=$((max_output_kb * 1024))
head -c $max_bytes "$STDOUT_FILE" > "${STDOUT_FILE}.trunc" || true
head -c $max_bytes "$STDERR_FILE" > "${STDERR_FILE}.trunc" || true

stdout=$(cat "${STDOUT_FILE}.trunc" | sed -e 's/\r//g' -e 's/"/\\\"/g')
stderr=$(cat "${STDERR_FILE}.trunc" | sed -e 's/\r//g' -e 's/"/\\\"/g')

# Collect exit code: if the process was killed by timeout, `timeout` returns 124 or 137; We detect that by checking output file modification time

# Determine exit code: If last command returned >0 read via $?
# Since we used `|| true`, we don't have the exit code; check `timeout` status via `cat /proc/<pid>/status` isn't trivial here; simpler: we wrap in small function

# Re-run to obtain exit code reliably, using a subshell and capturing the exit code
# We'll re-run more simply for accurate exit code:

( source "$ENVFILE"; timeout ${timeout_secs}s bash -lc '$cmd_exec_line' ) >"$STDOUT_FILE" 2>"$STDERR_FILE"
exit_code=$?
# If exit code is timeout (124), mark as timed out
if [[ "$exit_code" -eq 124 ]]; then
  stderr="${stderr}\n[PROCESS TIMED OUT]"
fi

# Apply redaction rules to stdout and stderr
stdout_redacted="$stdout"
stderr_redacted="$stderr"
for ((i=0;i<redaction_rules_count;i++)); do
  pat=$(echo "$JSON" | jq -r ".redaction_rules[$i]")
  if [[ "$pat" != "null" && -n "$pat" ]]; then
    # Use sed -E to replace matches with ****REDACTED****
    stdout_redacted=$(printf "%s" "$stdout_redacted" | sed -E "s/${pat}/[REDACTED]/g")
    stderr_redacted=$(printf "%s" "$stderr_redacted" | sed -E "s/${pat}/[REDACTED]/g")
  fi
done

# Combined redacted log
combined_redacted="$stdout_redacted\n${stderr_redacted}"

# Output JSON
printf '{\n  "exit_code": %d,\n  "stdout": "%s",\n  "stderr": "%s",\n  "redacted_log": "%s",\n  "duration_ms": %d\n}\n' "$exit_code" "$(echo "$stdout" | sed ':a;N;$!ba;s/\n/\\n/g' | sed 's/"/\\\"/g')" "$(echo "$stderr" | sed ':a;N;$!ba;s/\n/\\n/g' | sed 's/"/\\\"/g')" "$(echo "$combined_redacted" | sed ':a;N;$!ba;s/\n/\\n/g' | sed 's/"/\\\"/g')" "$duration_ms"

# Cleanup
rm -f "$STDOUT_FILE" "$STDERR_FILE" "$ENVFILE" "$LAUNCH_SCRIPT" || true

exit 0
