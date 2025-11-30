# Top 10 Repo Files/Patterns Likely to Cause CI Failures

This list is ranked by likely impact to CI stability in an ALN-first repo like this one.

1. `.github/workflows/*.yml` — Misconfigured or referencing deprecated runnables (Python/`pip`) or missing ALN steps.
2. `scripts/*` (Node/Powershell) — Broken script exits or missing dependencies in CI; convert to ALN modules where required.
3. `package.json` — Node scripts used by CI may interfere with ALN dependency management or place non-ALN steps into the build.
4. `aln/*` — Misconfigured ALN files without `export fn main()` for CI entrypoints; malformed ALN docs.
5. `SmartCityStack/` — Domain code that may contain runtime assumptions about toolchains.
6. `Dockerfile` (if present) — Using Python for entrypoints; need an ALN runtime or Node wrapper.
7. `Makefile` / `justfile` — Targets invoking `python` or unpinned tools; prefer `aln` targets.
8. `*.ps1` scripts — Local-only PowerShell helpers used by CI; either port to ALN or call them conditionally.
9. `.pre-commit-config.yaml` / `tox.ini` — Can trigger Python flows during PRs and confuse ALN-only CI.
10. `README.md` / docs — Out-of-date contributor instructions causing local setups to run Python for CI tasks.

For each of these files/areas we recommend the ALN-focused fix listed in the ALN migration plan and the examples produced in `aln/ci/core.aln` and `.github/workflows/aln-lint-tests.yml`.