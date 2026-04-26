Param(
    [string]$NginxRoot = "C:\nginx"
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$restartLog = Join-Path $projectRoot "biz-home.restart.log"

function Invoke-Step {
    param(
        [Parameter(Mandatory = $true)][string]$Command,
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [Parameter(Mandatory = $true)][string]$FailureMessage
    )

    & $Command @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw $FailureMessage
    }
}

Write-Host "==> Biz home production restart started" -ForegroundColor Cyan
Write-Host "Project root: $projectRoot"

Set-Location $projectRoot

if (Test-Path $restartLog) { Remove-Item $restartLog -Force }
Start-Transcript -Path $restartLog -Force

try {
    $currentCommit = (git rev-parse HEAD).Trim()
    if (-not $currentCommit) {
        throw "Could not resolve current git commit."
    }

    Write-Host "==> Restarting current commit: $currentCommit" -ForegroundColor Yellow

    $nginxExe = Join-Path $NginxRoot "nginx.exe"
    if (-not (Test-Path $nginxExe)) {
        throw "nginx.exe not found: $nginxExe"
    }

    Write-Host "==> Reloading nginx" -ForegroundColor Yellow
    Invoke-Step -Command $nginxExe -Arguments @("-s", "reload") -FailureMessage "nginx reload failed."

    Write-Host "==> Biz home production restart finished" -ForegroundColor Green
    Write-Host "Current commit: $currentCommit"
    Write-Host "Site URL: https://biz.hsft.io.kr"
    Write-Host "Restart log: $restartLog"
}
finally {
    Stop-Transcript | Out-Null
}
