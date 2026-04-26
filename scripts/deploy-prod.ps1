Param(
    [string]$Branch = "main",
    [switch]$SkipPull,
    [switch]$ForceSync,
    [string]$NginxRoot = "C:\nginx",
    [int]$Port = 4174
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$deployLog = Join-Path $projectRoot "biz-home.deploy.log"
$outLog = Join-Path $projectRoot "biz-home.out.log"
$errLog = Join-Path $projectRoot "biz-home.err.log"
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

function Resolve-NpxCommand {
    $npxCommand = Get-Command "npx.cmd" -ErrorAction SilentlyContinue
    if ($npxCommand) {
        return $npxCommand.Source
    }

    $npxCommand = Get-Command "npx" -ErrorAction SilentlyContinue
    if ($npxCommand) {
        return $npxCommand.Source
    }

    throw "npx command not found. Please install Node.js on this machine."
}

function Stop-ExistingStaticServer {
    param(
        [Parameter(Mandatory = $true)][int]$ListenPort
    )

    $connectionLines = netstat -ano -p tcp | Select-String ":$ListenPort\s+.*LISTENING\s+(\d+)$"
    foreach ($line in $connectionLines) {
        if ($line.Matches.Count -eq 0) {
            continue
        }

        $processId = [int]$line.Matches[0].Groups[1].Value
        if ($processId -gt 0) {
            Write-Host "==> Stopping existing static server on port $ListenPort (PID $processId)" -ForegroundColor Yellow
            Stop-Process -Id $processId -Force -ErrorAction SilentlyContinue
        }
    }
}

function Start-StaticServer {
    param(
        [Parameter(Mandatory = $true)][string]$RootPath,
        [Parameter(Mandatory = $true)][int]$ListenPort,
        [Parameter(Mandatory = $true)][string]$StdOutLog,
        [Parameter(Mandatory = $true)][string]$StdErrLog
    )

    Stop-ExistingStaticServer -ListenPort $ListenPort

    if (Test-Path $StdOutLog) { Remove-Item $StdOutLog -Force }
    if (Test-Path $StdErrLog) { Remove-Item $StdErrLog -Force }

    $npxExecutable = Resolve-NpxCommand

    Write-Host "==> Starting static server on port $ListenPort" -ForegroundColor Yellow
    Start-Process -FilePath $npxExecutable `
        -ArgumentList @("serve", "-s", ".", "-l", $ListenPort.ToString()) `
        -WorkingDirectory $RootPath `
        -WindowStyle Hidden `
        -RedirectStandardOutput $StdOutLog `
        -RedirectStandardError $StdErrLog | Out-Null

    Start-Sleep -Seconds 3

    $portCheck = netstat -ano -p tcp | Select-String ":$ListenPort\s+.*LISTENING\s+"
    if (-not $portCheck) {
        throw "Static server did not start on port $ListenPort. Check logs: $StdOutLog / $StdErrLog"
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

    Start-StaticServer -RootPath $projectRoot -ListenPort $Port -StdOutLog $outLog -StdErrLog $errLog
    Reload-Nginx -RootPath $NginxRoot

    Write-Host "==> Biz home production deploy finished" -ForegroundColor Green
    Write-Host "Deployed commit: $currentCommit"
    Write-Host "Site URL: https://biz.hsft.io.kr"
    Write-Host "Local URL: http://localhost:$Port"
    Write-Host "Output log: $outLog"
    Write-Host "Error log: $errLog"
    Write-Host "Deploy log: $deployLog"
}
finally {
    Stop-Transcript | Out-Null
}
