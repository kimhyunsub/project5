Param(
    [string]$NginxRoot = "C:\nginx",
    [int]$Port = 4174
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$restartLog = Join-Path $projectRoot "biz-home.restart.log"
$outLog = Join-Path $projectRoot "biz-home.out.log"
$errLog = Join-Path $projectRoot "biz-home.err.log"

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

    Start-StaticServer -RootPath $projectRoot -ListenPort $Port -StdOutLog $outLog -StdErrLog $errLog

    $nginxExe = Join-Path $NginxRoot "nginx.exe"
    if (-not (Test-Path $nginxExe)) {
        throw "nginx.exe not found: $nginxExe"
    }

    Write-Host "==> Reloading nginx" -ForegroundColor Yellow
    Invoke-Step -Command $nginxExe -Arguments @("-s", "reload") -FailureMessage "nginx reload failed."

    Write-Host "==> Biz home production restart finished" -ForegroundColor Green
    Write-Host "Current commit: $currentCommit"
    Write-Host "Site URL: https://biz.hsft.io.kr"
    Write-Host "Local URL: http://localhost:$Port"
    Write-Host "Output log: $outLog"
    Write-Host "Error log: $errLog"
    Write-Host "Restart log: $restartLog"
}
finally {
    Stop-Transcript | Out-Null
}
