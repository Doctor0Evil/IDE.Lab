# PR: ALN CI: Add ALN modules, guard workflow, and ALN-first migration docs

Short summary
- Adds ALN-first CI pipeline with ALN modules replacing Node/PowerShell tooling where feasible.
- Adds a guard workflow to enforce “no Python in CI” and a matrix-based ALN lint/test workflow with caching.
- Updates package.json scripts, README, and docs with an ALN-centric developer quickstart and pre-commit hook.

What changed
- New ALN tools (replacing Node/PowerShell scripts):
  - aln/tools/to_json_projection.aln
  - aln/tools/ajv_mesh_sweep.aln
  - aln/tools/severity_gate.aln
  - aln/tools/copilot_metatest.aln
  - aln/tools/autofix_npm.aln
  - aln/tools/platform_improvements.aln
  - aln/tools/inspect_wasm.aln

- New ALN CI entrypoint:
  - aln/ci/core.aln (ALN CI pipeline module, executed via aln run ci.core).

- Updated workflows:
  - .github/workflows/aln-ci-core.yml – uses aln run tools.* instead of Node scripts for CI tooling.
  - .github/workflows/aln-lint-tests.yml – ALN lint/test workflow with strategy.matrix on ALN versions and actions/cache for ALN deps, plus a "Show cache status" step.
  - .github/workflows/aln-copilot-governance.yml – invokes aln run tools.copilot_metatest.
  - .github/workflows/guard-no-python.yml – new guard that fails if workflows/scripts contain python, python3, or pip.

- Developer UX and docs:
  - README.md – adds ALN CI quickstart and git config core.hooksPath .githooks instructions.
  - .githooks/pre-commit – runs aln lint before commits once hooksPath is set.
  - docs/aln-migration.md – ALN migration checklist and verification notes.
  - docs/ci-issues-top10.md – top CI hotspot files/areas to inspect first.

---

## Review checklist (paste under the PR body)

- Files and modules
  - [ ] aln/tools/*.aln tools and aln/ci/core.aln exist in the PR diff.
  - [ ] package.json scripts call aln run (e.g., aln run tools.to_json_projection, aln run tools.ajv_mesh_sweep, aln run tools.severity_gate, aln run tools.copilot_metatest, aln run ci.core).

- Workflows and ALN wiring
  - [ ] .github/workflows/aln-ci-core.yml uses aln run tools.to_json_projection, aln run tools.ajv_mesh_sweep, and aln run tools.severity_gate.
  - [ ] .github/workflows/aln-copilot-governance.yml uses aln run tools.copilot_metatest.
  - [ ] .github/workflows/aln-lint-tests.yml has:
    - strategy.matrix.aln-version defined (e.g., ["1.0.x", "1.1.x", "1.2.x"]).
    - actions/cache@v4 caching ALN deps keyed by OS + ALN version + lock file.
    - a “Show cache status” step printing ALN deps cache hit: ${{ steps.deps-cache.outputs.cache-hit }}.
  - [ ] .github/workflows/guard-no-python.yml scans workflows and top-level scripts for python, python3, and pip and fails on matches.

- CI runtime behavior
  - [ ] On the PR’s Actions tab:
    - One job per ALN version appears (matrix).
    - From the second run, at least one job logs ALN deps cache hit: true.
    - The “Guard — No Python in CI” job runs and passes (or fails with clear offending files).
    - The CI job from aln-ci-core.yml includes “Enforce non-Python environment” and passes.

- Developer UX and docs
  - [ ] README.md documents git config core.hooksPath .githooks and the ALN quickstart (aln deps sync / aln lint / aln test / aln run ci.core).
  - [ ] docs/aln-migration.md and docs/ci-issues-top10.md exist and describe migration steps and CI hotspots.
  - [ ] .githooks/pre-commit exists and is referenced in README.

- Optional local checks (for maintainers with ALN installed)
  - [ ] On a clean checkout of this branch:
    - aln deps sync
    - aln lint
    - aln test
    - aln run ci.core
    all succeed.

Security note (for reviewers)
- This PR does not introduce any GitHub PATs or Secrets.
- Future automation (e.g., auto-PR bots) should integrate with the organization Web5 DID and DID-based authorization (did:ion:EiD8J2b3K8k9Q8x9L7m2n4p1q5r6s7t8u9v0w1x2y3z4A5B6C7D8E9F0) instead of storing tokens in GitHub.

## DID/Web5 tokenless CI wiring
This repo includes `aln/tools/did_proxy.aln` as a safe ALN-first stub for DID-based automation.
- Ensure `DID_PROXY_URL` is configured in `.github/workflows/aln-ci-core.yml` job-level env (or repo variables).
- The DID proxy should return a JSON capability object; ALN modules use this capability to call backend proxies for GitHub operations without embedding PATs into the repo.
