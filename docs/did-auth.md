# DID/Web5 Tokenless CI – Overview

This document describes how to adopt a tokenless, DID/Web5-based approach for CI automation in the IDE.Lab repository.

Key idea
- Use the Organization DID as the root of trust and a DID-aware proxy to exchange short-lived, constrained capabilities for CI jobs rather than relying on long-lived PATs.

Organization DID
- did:ion:EiD8J2b3K8k9Q8x9L7m2n4p1q5r6s7t8u9v0w1x2y3z4A5B6C7D8E9F0

Flows
1. Runner starts the CI job and requests a DID-signed assertion from a local DID agent owned by the organization.
2. The local agent signs a DID-JWT, which is sent to your DID proxy with a request for a short-lived CI capability specifically scoped to the repo + branch + job id.
3. The proxy validates the assertion and returns a constrained token that can be used for the remainder of the job (e.g., to create PR comments or call the GitHub API through a backend service).
4. The proxy enforces policy: least privilege, audit logging, and time-limited tokens.

Implementation notes
- The ALN CI modules should call the DID proxy endpoint via a secure channel to obtain the one-shot capability for actions that require elevated permissions (e.g., PR creation, comment posting, or write access to the repo).
- The DID signing keys are never stored in GitHub Secrets. Access to key material is governed by your DID agent and the Web5 identity platform.
- CI run-time secrets (short-lived tokens) are created on the fly and are not persisted beyond the scope of the job.

ALN adaptor
- A minimal ALN scaffold `aln/tools/did_proxy.aln` provides a placeholder abstraction. Replace the `request_ci_token` function with calls to your DID agent proxy.

Example CI wiring
1. Runner obtains DID token (did-jwt) from the local agent.
2. Runner posts assertion to your DID proxy to obtain one-shot token.
3. Runner uses the one-shot token to call the backend API that interacts with GitHub (proxying calls, auditing requests). The backend has an internal credential to perform restricted GitHub actions and is not exposed as a secret in the repository.

Security considerations
- Audit logs: Proxy should store the request context (job id, branch, repo, signer DID), preventing unscoped token abuse.
- Revocation: Proxy supports immediate revocation and short token TTLs to limit exposure.
- Least privilege: Token only permits necessary operations (post a comment, create a PR, limited to certain labels or checks).

This server-side DID-based approach keeps sensitive key material outside GitHub while enabling automation similar to PAT-based flows without static secrets.
