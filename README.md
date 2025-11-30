![ALN Compliance Charter](https://img.shields.io/badge/ALN%20Compliance-Enforced-brightgreen)
![KYC/DID Verified](https://img.shields.io/badge/KYC%20Verified-DID%20Required-blue)
![Immutable Ledger](https://img.shields.io/badge/Ledger-Blockchain%20Secured-orange)
![Audit-Ready](https://img.shields.io/badge/Audit-Continuous%20Monitoring-yellow)
![No Neural Networking](https://img.shields.io/badge/No%20Neural%20Networking-Deterministic%20Only-red)
![Asset-Backed](https://img.shields.io/badge/Asset%20Backed-Terra%20Blockchain-lightgrey)


<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>


***

# IDE.Lab

IDE.Lab is a cutting-edge solution datacenter dedicated to building and developing Integrated Development Environment (IDE) and GitHub enhancements using ALN—a blockchain-technology based programming language. Our mission is to provide a comprehensive array of fixes, patches, and innovative alternatives for secrets management across diverse platforms and systems. These solutions leverage Web5 alternative Decentralized Identifier (DID) credentials to deliver secure, decentralized identity and access management.

## Core Architecture

- **`aln/`** — Central repository for source ALN bundles and governance documentation, defining rules and policies for ALN language compliance.
- **`aln-json/`** — Auto-generated JSON schema projections derived from ALN sources for validation and interoperability.
- **`schemas/`** — JSON Schema definitions used by the Ajv library for rigorous data validation across ALN projects.
- **`scripts/`** — Collection of Node.js and PowerShell helper scripts:
  - ALN-to-JSON projection and mesh validation tooling.
  - Severity gate enforcement to ensure compliance thresholds.
  - Copilot metaprompt governance validation.
  - WASM inspection and environment bootstrap utilities.
  - NOTE: These scripts are legacy developer tools and must NOT be invoked in CI; prefer `aln/tools/*` ALN modules for automated pipelines.
- **`.github/workflows/`** — GitHub Actions workflows for ALN validation, firmware simulation, VM validation, copilot governance, telemetry export, and staged firmware rollouts.
- **`aln/`**  
  The main hub containing source ALN bundles and governance documentation, which define the compliance rules and policies for ALN language projects.

- **`aln-json/`**  
  Automatically generated JSON schema representations derived from ALN sources to enable validation and ensure interoperability.

- **`schemas/`**  
  JSON Schema files used with Ajv for strict data validation across ALN-related workflows.

- **`scripts/`**  
  A suite of Node.js and PowerShell utilities supporting:  
  - ALN-to-JSON projection and mesh validation tooling  
  - Severity gate enforcement for compliance thresholds  
  - Copilot metaprompt governance validation  
  - WASM inspection and environment bootstrap

- **`.github/workflows/`**  
  GitHub Actions workflows automating:  
  - ALN language validation  
  - Firmware simulation and device twin VM validation  
  - Copilot governance enforcement  
  - Telemetry export aggregation  
  - Controlled staged firmware rollouts

## Local Development & Automation

### Quickstart with Node.js

Use the minimal `package.json` scripts to:

```bash
npm install
npm run aln:projection
npm run aln:validate
npm run aln:severity-gate
npm run aln:metatest
```

### PowerShell Utilities

- **AutoFix-Npm.ps1:** Installs dependencies and runs core ALN validations.
- **GitHub-Platform-Improvements.ps1:** Bootstraps git, Node.js, .NET, GitHub CLI, and adds development helper functions.
- **Inspect-Wasm.ps1:** Inspects WebAssembly binaries for validation pipeline inclusion.

## Continuous Integration

Pre-configured GitHub workflows ensure:

- Strict ALN language validation and restrictions on certain runtime usage.
- Firmware and VM simulation for device twins.
- Repository policy checks and governance for Copilot prompts.
- Secure telemetry collection with immutable audit trails.

## Governance & Security

- No Python runtime allowed in CI to avoid unpredictable behavior.
- Severity gates enforce fails on critical violations.
- Copilot governance mandates safe, compliant metaprompt usage.
- Immutable blockchain-anchored logs provide tamper-proof audit trails.

## Recommended Workflow

1. Bootstrap environment setup with GitHub-Platform-Improvements.ps1.
2. Install dependencies and run ALN projection, validation, and severity gates.
3. Execute metaprompt governance tests to ensure compliance.

## Troubleshooting & Future Enhancements

## Developer UX (Quickstart)

Enable local git hooks (pre-commit) to run ALN linter before committing:

```powershell
git config core.hooksPath .githooks
```

ALN CI Quickstart:

- `aln/ci/core.aln` — ALN CI module scaffold (entrypoint: `aln run ci.core`).
- `.github/workflows/aln-lint-tests.yml` — Workflow running ALN lint, tests, and build. The job uses a matrix of ALN versions and caches dependencies.
- `docs/aln-migration.md` — Migration guide and checklist for porting Python/Node tooling into ALN modules.

Run these steps locally to validate a PR:

```powershell
# Optional: install ALN runtime
curl -sSL https://get.aln.sh/install | bash
aln deps sync
aln lint
aln test
aln run ci.core
```

For more, explore GitHub's built-in collaboration features, advanced security integrations, and automation tools that support agile, secure development and deployment [GitHub Overview].[14][15][17]
- Restart PowerShell if npm commands fail post-install.
- View detailed Ajv validation reports in `reports/aln-constraint-report.json`.
- WASM binary issues can be debugged with the Inspect-Wasm script.
- Planned features include artifact uploads, advanced ALN parsing, and secure signing for firmware.

***
