param()
<#
PowerShell pre-commit script for Windows developers.
It uses the Docker ALN runner if native `aln` is not installed.
#>
try {
    $staged = git diff --cached --name-only --diff-filter=ACM | Select-String -Pattern '\.aln$' -Quiet
} catch {
    Write-Host "Error detecting staged files: $_"
    exit 0
}

if (-not $staged) {
    Write-Host "No .aln files staged; skipping SAFE_RESOLUTION validation"
    exit 0
}

Write-Host "Staged ALN changes; running validation"

if (Get-Command aln -ErrorAction SilentlyContinue) {
    Write-Host "Found aln; running native aln validation"
    aln run cicd/hooks/validate_safe_resolution_matrix.aln
    if ($LASTEXITCODE -ne 0) { throw "Validation failed" }
} else {
    Write-Host "Using Docker runner image"
    docker build -f docker/Dockerfile.aln-runner -t ide-lab/aln-runner:precommit .
    docker run --rm -v "${PWD}:/workspace" -w /workspace -e ALN_RUNTIME=mock ide-lab/aln-runner:precommit ./docker/entrypoint_aln_runner.sh cicd/hooks/validate_safe_resolution_matrix.aln
    if ($LASTEXITCODE -ne 0) { throw "Validation failed" }
}

Write-Host "SAFE_RESOLUTION validation passed"
exit 0
