# SAFE_RESOLUTION: Matrix Definition, Signing, Validation, and Audit

Overview:
- The SAFE_RESOLUTION matrix defines the security and compliance settings used by the IDE.Lab project.
- All matrices are defined in ALN and must include the required header fields, modules, and a tamper-proof trailer.

Key Concepts:
- Matrix Body: Contains version, author_did, legal_refs, modules, and module-specific configuration.
- Trailer: Contains SHA256_Matrix, Author_Signature, Author_DID, and Signing_Timestamp_UTC. The trailer is appended after a marker `---TRAILER---`.
- Signing Flow: Authors compute the SHA256 of the matrix body and sign it with a DID (did:ion) private key. The signature and hash are injected into the trailer.

Validation:
- CI/CD pipelines run `validate_safe_resolution_matrix.aln` which validates headers, schema compliance, hash correctness, signature validation, and no-plaintext-secrets.
- Validation failures are recorded in a WORM audit stream and cause the pipeline to fail and block merges.

Sealed Secret Vault (HashiCorp integration):
- The `sealed_secret_vault` module uses `secrets/integrations/hashicorp_vault_bridge.aln` to provision ephemeral secrets via Approles or other auth flows.
- Secret handles are injected into builds and tests as masked environment variables. No plaintext secrets are logged.

Rollback and Quarantine:
- Rollback playbooks exist under `/security/rollback/rollback_playbook.aln`. They cover token revocation, disabling CI/CD gates, quarantining workloads, and DID-based notifications.
- High severity security violations (e.g., hardcoded tokens) will trigger a `block_and_rollback` enforcement.

Governance & DID Controls:
- Matrix authors are expected to use DID:ION key material for signing matrices.
- At least one SecOps DID-verified approval is required for any matrix changes.

Developer Notes:
- All ALN artifacts are executable and must obey strict type constraints as defined in `/schemas/aln/safe_resolution_schema.aln`.
- Use `matrix_sign_and_seal.aln` to create a sealed matrix: compute hash, sign, and write immutable trailer entries.

For further details on DID signing and the responsibilities of CI, SecOps, and Release roles, see `/compliance/matrix/did_signing_workflow.aln`.

Deployment Tools & Checks:
- Use `deployment/raptor_mini_check.aln` to compute T_max, latency estimates, and to verify WORM sizing and policy checks.
- Use the `tests/compliance/run_tests.aln` runner with the mock runtime for local policy validation.

Pre-commit SAFE_RESOLUTION Check
--------------------------------
- We provide a pre-commit hook to validate SAFE_RESOLUTION when ALN files are modified.
- To enable it locally, set your hooks path and install the hook:

```bash
git config core.hooksPath .githooks
./scripts/install-hooks.sh
```

On Windows, run the PowerShell wrapper `./scripts/pre-commit-aln.ps1` or configure `core.hooksPath` and invoke the script manually.

The pre-commit runs `cicd/hooks/validate_safe_resolution_matrix.aln` and will abort the commit if validation fails.

Production runtime (ALN_RUNTIME=prod)
------------------------------------
- The `prod` runtime maps ALN runtime interfaces to live bindings in `runtime/prod_runtime.aln`.
- To run the minimal PROD checks, set the following environment vars (example) and run the prod test runner:

```bash
export ALN_RUNTIME=prod
export GITHUB_TOKEN="${{ secrets.GITHUB_TOKEN }}"
export KUBECONFIG="/path/to/kubeconfig"
export VAULT_ADDR="https://vault.example"
export VAULT_TOKEN="${{ secrets.VAULT_TOKEN }}"
docker run --rm -v "$PWD":/workspace -w /workspace ide-lab/aln-runner:local tests/runtime/run_prod_tests.aln
```

Note: Prod tests should be run against staging or limited pre-production resources and NOT against production resources without prior authorization.

Example (local, using ALN runner):
```bash
aln run deployment/raptor_mini_check.aln --inputs '{"P_total":7000000000, "b_w":8, "b_a":16, "d_model":4096, "B":1, "k_act":4, "M_GPU":24, "M_other":2, "L_layers":32, "H_heads":32, "d_k":64, "G_peak":181e12, "eta_overhead":3, "T_ctx":200000}'
```

This command computes the capacity metrics and writes a WORM entry for audit.
