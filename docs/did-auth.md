Keep this document public; do not place keys or secrets in repository files.

## How to wire the DID proxy in CI
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

## How to wire the DID proxy in CI
- In `.github/workflows/aln-ci-core.yml` add a job-level env var `DID_PROXY_URL` pointing to your DID proxy endpoint (non-secret).
- Ensure the DID proxy validates requests and returns a one-shot `capability` JSON value.
- Call `aln run ci.core`, which internally calls `tools.did_proxy.request_ci_capability` before performing sensitive operations.

Ensure your DID proxy responds with JSON like:
```
{
	"capability": "<opaque-value>",
	"expires_at": "2025-12-01T10:00:00Z",
	"scope": "github:repo:IDE.Lab:ci"
}
```

## Mock mode for CI demos
Use the `did-proxy-mock.yml` workflow to validate DID tokenless flows in CI without external network calls.

1. The mock workflow sets:
	- `DID_PROXY_MOCK=true`
	- `DID_PROXY_URL=mock://ci`
2. `aln run tools.did_proxy` will use the local mock generator to return a deterministic capability JSON; this avoids external network calls and proves the capability exchange flow.
3. For demos, the mock capability uses the scope `github:repo:IDE.Lab:ci:test` and a short expiry (5 minutes).

This mock mode is for demonstration and reviewer validation only; real deployments must use a secure DID proxy with DID proof verification and proper audit logs.

Example CI wiring
1. Runner obtains DID token (did-jwt) from the local agent.
2. Runner posts assertion to your DID proxy to obtain one-shot token.
3. Runner uses the one-shot token to call the backend API that interacts with GitHub (proxying calls, auditing requests). The backend has an internal credential to perform restricted GitHub actions and is not exposed as a secret in the repository.

Security considerations
- Audit logs: Proxy should store the request context (job id, branch, repo, signer DID), preventing unscoped token abuse.
- Revocation: Proxy supports immediate revocation and short token TTLs to limit exposure.
- Least privilege: Token only permits necessary operations (post a comment, create a PR, limited to certain labels or checks).

This server-side DID-based approach keeps sensitive key material outside GitHub while enabling automation similar to PAT-based flows without static secrets.

## Enabling a real DID proxy in production
Follow these steps to move from the mock demo to a secure production DID proxy.

1) Requirements & architecture
- DID agent: your organization's DID agent must be able to sign a DID-JWT or issue a Verifiable Credential (VC) proving the runner is authorized for CI duties.
- DID proxy: a hardened backend service that verifies DID proofs and issues short-lived CI capabilities; logs and audits requests; optionally uses mTLS.
- Backend GitHub access: the proxy backend may hold a minimal credential and act as a gateway for limited GitHub API calls; these credentials are not stored in GitHub Secrets.

2) Environment variables & repo wiring
- `DID_PROXY_URL` (repo variable, non-secret): `https://did-proxy.example.org/ci/issue`
- `DID_PROXY_MTLS_CA` (repo secret or provider-managed, optional): CA certificate for validating proxy mTLS connections.
- `ORG_DID` (public DID in repo or config): e.g., `did:ion:EiD...` (public DID doc, not private key material).

3) Proxy API contract (expected input)
- POST JSON body with fields: `did`, `pipeline`, `branch`, `runner_id`, `requested_at`, and a DID-JWT proof under `proof` or via mTLS client cert.

4) Proxy response (expected output)
- The proxy must return a JSON object with fields:
	```json
	{
		"capability": "<opaque-value>",
		"expires_at": "2025-12-01T10:00:00Z",
		"scope": "github:repo:IDE.Lab:ci"
	}
	```

5) Proxy security & policies
- Token TTL: Keep TTLs short (few minutes) and bind tokens to `repo` + `branch` + `jobid`.
- Revocation: Proxy must allow immediate revocation and maintain audit logs of requests with `did` and `runner_id`.
- Auditing: All capability issues and downstream GitHub calls routed via the proxy must be logged for later review.
- Least privilege: Proxy must limit operations (e.g., PR comment, label, or status update) based on the requested `scope`.
- mTLS & DID-JWT: Prefer mTLS or DID-JWT-based authenticated channels to the proxy; do not rely on long-lived secrets in repo settings.

6) ALN wiring in production
- In the ALN pipeline (`aln/ci/core.aln`), call `tools.did_proxy.request_ci_capability(...)` at job start; treat it as a gating step that must return a non-empty `capability`.
- Use the capability only by passing it to trusted backend services or by setting an ephemeral environment variable for subsequent internal steps; do not log the capability value.

7) Dev & local testing
- Keep `DID_PROXY_MOCK` and the mock workflow for PR demos. Replace the mocked capability with the real DID proxy endpoint for integration testing, using ephemeral test proxies and short-lived credentials.

8) Implementation notes for maintainers
- Implement CI-side retries and clear error messages if the proxy is not reachable or the proof validation fails.
- Keep the DID root and keys off-platform in a secure KMS or an HSM-backed DID agent; use a trusted operator to sign and issue VCs for runners.

This section is a practical, production-ready reference for enabling the DID proxy securely and transitioning from mock demos to live CI tokenless flows.
