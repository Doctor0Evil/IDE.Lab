# Contributing to SAFE_RESOLUTION Matrix

Guidance for maintainers and matrix authors:

1. Edit the matrix body (everything before the '---TRAILER---' marker) only.
2. Run the sign-and-seal tool (local or via a secure CI step) to compute the SHA256 of the body and sign it with a DID:ION key:

   - Local (recommended in HSM environment):
     aln run compliance/matrix/tools/matrix_sign_and_seal.aln --path compliance/matrix/safe_resolution_matrix.aln --author did:ion:YOUR_DID

   This tool will:
   - strip the trailer, compute the SHA256 hex digest of the body,
   - sign the hex digest using your DID key via the configured DID bridge,
   - inject a new trailer with SHA256_Matrix, Author_Signature, Author_DID, Signing_Timestamp_UTC,
   - lock the file to prevent accidental edits without re-signing.

3. Push a branch with the sealed matrix and open a PR. CI will run:
   - validate_safe_resolution_matrix.aln - ensure header, schema, hash, and signature sanity
   - security scans - run security ruleset and may block

# Git Hooks / Local Pre-Commit
To enable a pre-commit validation for SAFE_RESOLUTION, run:

```bash
git config core.hooksPath .githooks
./scripts/install-hooks.sh
```

This maps `.githooks/pre-commit` to your local git hooks. The pre-commit script runs the `validate_safe_resolution_matrix.aln` validation and will abort the commit if validation fails.

Windows (PowerShell):

```powershell
# Configure git to use .githooks
git config core.hooksPath .githooks
# Run this once to ensure you have the script installed
./scripts/install-hooks.sh
# If on Windows, use the PowerShell wrapper in scripts/pre-commit-aln.ps1
```

Pre-commit hook behavior:
- If no `.aln` files are staged: commit proceeds.
- If `.aln` files are staged: the pre-commit runs `validate_safe_resolution_matrix.aln` either via `aln` binary (if present) or via Docker `ide-lab/aln-runner:precommit` image.
- To bypass locally (emergency): use `git commit --no-verify`. This should be used sparingly and requires documented emergency procedures.


4. If CI fails: inspect WORM logs via the audit stream and fix issues:
   - For signature/hash issues: re-run the sign tool using your DID
   - For schema issues: fix the module config or the schema
   - For plaintext secret exposure: remove plaintext values and wire through sealed_secret_vault

5. For emergency rollbacks or incidents, see /security/rollback/rollback_playbook.aln and /security/rollback/incident_checklist.aln.

# Developer Tips
- Use the `raptor_prompts/aln_macros.aln` macros to validate or regenerate artifacts.
- For local testing, enable the mock runtime by passing `--runtime=mock` to the ALN runner.
- Do not commit private keys or plaintext secrets; Vault handles revocation and rotation.
