System Exec Adapter (Runner Binding)

Overview

- The ALN `prod_runtime` expects a host-provided `system_exec` binding to perform system-level commands with strict policies governed by `policy_kernel.guard_exec`.
- A sample wrapper `docker/system_exec_wrapper.sh` is provided for staging use and can be used by the docker ALN runner to exercise runtime-level exec guards and output redaction.

How to wire the wrapper

1. The real ALN runtime/runner must implement a binding for `system_exec` defined in `runtime/runtime_interfaces.aln`.
2. The binding should accept the `ExecOptions` JSON structure and return `ExecResult` JSON. The wrapper provided shows an example with expected JSON conventions.
3. In prod mode, the runner should call the wrapper rather than running `exec` inline in ALN to centralize sanitization and to prevent secret leaks.

Security notes

- Always run commands inside isolated execution contexts; for production we recommend using containerization, AppArmor, seccomp, or other kernel-native sandboxing mechanisms.
- The wrapper alone does not guarantee full isolation or prevention of privilege escalation. Secure production-grade runners must implement further process controls, auditing, and monitoring.

Operational notes

- Include `jq` on the runtime image to parse JSON safely.
- Ensure the wrapper runs under a non-privileged runtime user with minimal host capabilities.
- Audit logs from `write_worm_entry` should include only metadata and `redacted_log` (never include sensitive secrets in plaintext).

Example: local test

1. Build the runner image:
   docker build -f docker/Dockerfile.aln-runner -t aln-runner:local .
2. Run the wrapper tests in the image:
   docker run --rm -e ALN_RUNTIME=prod aln-runner:local tests/runtime/system_exec_wrapper_test.sh

This will exercise: timeout, truncation, env allowlist behavior, and redaction rules.


