system_exec_wrapper - Secure Exec Adapter Wrapper

Purpose:
- A minimal host-side script for implementing `system_exec` runtime binding used by `runtime/prod_runtime.aln`.
- Enforces environment variable allowlist, timeouts, output truncation, redaction rules, and returns a JSON ExecResult.

Usage:
- The wrapper takes ExecOptions JSON as stdin or a file argument and writes ExecResult JSON to stdout.
- Example:
  cat <<'JSON' | /usr/local/bin/system_exec_wrapper.sh
  { "cmd_name": "echo", "args": ["hello"], "env_allowlist": ["HOME"], "timeout_secs": 5 }
  JSON

Integration guidance:
- The production aln-runner should bind `system_exec` to a host callable that executes the JSON payload via this wrapper and returns the ExecResult.
- The runner should ensure the wrapper is only callable by the ALN runtime and that input/output is isolated to prevent secrets from leaking to logs.

Security considerations:
- The wrapper is a minimal example and does not isolate processes into containers or use a secure sandbox.
- For production, use a hardened runtime with process isolation, seccomp/AppArmor, or run the commands within temporary namespaces.
- Ensure that ALN's policy kernel `guard_exec` runs and blocks dangerous commands before calling the wrapper.
- The wrapper should be used as a sparse fallback to enforce additional runtime constraints.

Testing:
- Run `tests/runtime/system_exec_wrapper_test.sh` to validate basic wrapper behaviors (timeout, truncation, env allowlist, redaction).

Limitations:
- This wrapper is designed for testing and staging environments.
- Do not use in production until further hardening, process isolation, and logging controls have been applied.
