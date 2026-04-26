Param(
    [string]$Branch = "main",
    [switch]$SkipPull,
    [switch]$ForceSync,
    [string]$NginxRoot = "C:\nginx"
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$deployLog = Join-Path $projectRoot "biz-home.deploy.log"
$requiredFiles = @(
    "index.html",
    "invite.html",
    "app.js",
    "invite.js",
    "styles.css",
    "config.js"
)

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

function Reload-Nginx {
    param(
        [Parameter(Mandatory = $true)][string]$RootPath
    )

    $nginxExe = Join-Path $RootPath "nginx.exe"
    if (-not (Test-Path $nginxExe)) {
        Write-Host "==> nginx.exe not found at $nginxExe. Skipping reload." -ForegroundColor Yellow
        return
    }

    Write-Host "==> Reloading nginx" -ForegroundColor Yellow
    Invoke-Step -Command $nginxExe -Arguments @("-s", "reload") -FailureMessage "nginx reload failed."
}

Write-Host "==> Biz home production deploy started" -ForegroundColor Cyan
Write-Host "Project root: $projectRoot"

Set-Location $projectRoot

if (Test-Path $deployLog) { Remove-Item $deployLog -Force }
Start-Transcript -Path $deployLog -Force

try {
    if (-not $SkipPull) {
        Write-Host "==> Pulling latest code from origin/$Branch" -ForegroundColor Yellow
        if ($ForceSync) {
            $statusOutput = git status --porcelain
            if ($LASTEXITCODE -ne 0) {
                throw "git status failed."
            }

            if (-not [string]::IsNullOrWhiteSpace(($statusOutput | Out-String))) {
                $stashMessage = "auto-stash before biz-home deploy " + (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
                Write-Host "==> Local changes detected. Creating stash backup before pull." -ForegroundColor Yellow
                Invoke-Step -Command "git" -Arguments @("stash", "push", "-u", "-m", $stashMessage) -FailureMessage "git stash failed."
                Write-Host "==> Stashed local changes: $stashMessage" -ForegroundColor Yellow
            }
        }

        Invoke-Step -Command "git" -Arguments @("fetch", "origin", $Branch) -FailureMessage "git fetch failed."
        Invoke-Step -Command "git" -Arguments @("checkout", $Branch) -FailureMessage "git checkout failed."
        Invoke-Step -Command "git" -Arguments @("pull", "origin", $Branch) -FailureMessage "git pull failed."
    }

    $currentCommit = (git rev-parse HEAD).Trim()
    if (-not $currentCommit) {
        throw "Could not resolve current git commit."
    }

    Write-Host "==> Deploying commit: $currentCommit" -ForegroundColor Yellow

    foreach ($file in $requiredFiles) {
        $path = Join-Path $projectRoot $file
        if (-not (Test-Path $path)) {
            throw "Required file is missing: $path"
        }
    }

    Reload-Nginx -RootPath $NginxRoot

    Write-Host "==> Biz home production deploy finished" -ForegroundColor Green
    Write-Host "Deployed commit: $currentCommit"
    Write-Host "Site URL: https://biz.hsft.io.kr"
    Write-Host "Deploy log: $deployLog"
}
finally {
    Stop-Transcript | Out-Null
}
