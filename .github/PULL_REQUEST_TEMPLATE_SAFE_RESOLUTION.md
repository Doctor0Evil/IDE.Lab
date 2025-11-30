# SAFE_RESOLUTION Matrix change checklist

When you change the SAFE_RESOLUTION matrix, please ensure the following checks are completed before requesting review:

- [ ] I changed only the matrix body (before the `---TRAILER---` marker) and did not edit the trailer.
- [ ] I ran `compliance/matrix/tools/matrix_sign_and_seal.aln` in a secure environment and attached the `Author_DID` in the PR description.
- [ ] I included the WORM audit ID produced by the sealing process in the PR body (example: WORM: <audit-id>).
- [ ] I confirmed that `raptor_mini_capacity.aln` and `raptor_mini_qos_profile.aln` remain satisfied or updated (if changing quantization, sparsity, or context limits).
- [ ] I ran `aln-runner` locally with the `mock` runtime (`docker run ...` or `aln run`) and resolved any failing checks.
- [ ] At least one SecOps DID-verified approval is present for this change.
 - [ ] I ran or scheduled the Security Automation Suite (`cicd/hooks/security_automation_suite.aln`) for this change and verified results.
 - [ ] If I modified Windows/Cluster/GitHub security policies, I added/updated tests under `tests/security/`.

Additional notes:
- If you changed the sealed_secret_vault configuration, update `secrets/integrations/hashicorp_vault_bridge.aln` and verify that no secrets appear in plaintext.
- For production signing workflows, use a secure HSM or Vault AppRole for the author key.

Thanks for doing the right thing — SAFE_RESOLUTION must remain cryptographically sound!
