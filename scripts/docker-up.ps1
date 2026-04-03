param(
    [switch]$NoBuild,
    [switch]$Foreground
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$dockerConfigPath = Join-Path $repoRoot ".docker-local"

New-Item -ItemType Directory -Force -Path $dockerConfigPath | Out-Null

$env:DOCKER_CONFIG = $dockerConfigPath
$env:DOCKER_BUILDKIT = "0"
$env:COMPOSE_DOCKER_CLI_BUILD = "0"

function Wait-ForDocker {
    param(
        [int]$TimeoutSeconds = 180
    )

    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    while ((Get-Date) -lt $deadline) {
        cmd /c "docker version >nul 2>nul"
        if ($LASTEXITCODE -eq 0) {
            return
        }
        Start-Sleep -Seconds 2
    }

    throw "Docker is not ready. Start Docker Desktop and rerun this script."
}

$dockerService = Get-Service -Name "com.docker.service" -ErrorAction SilentlyContinue
if ($null -eq $dockerService) {
    throw "Docker Desktop Service is not installed on this machine."
}

if ($dockerService.Status -ne "Running") {
    $dockerDesktopExe = Join-Path ${env:ProgramFiles} "Docker\\Docker\\Docker Desktop.exe"
    if (Test-Path $dockerDesktopExe) {
        Write-Host "Starting Docker Desktop..."
        Start-Process -FilePath $dockerDesktopExe | Out-Null
    } else {
        throw "Docker Desktop is not running. Start it manually and rerun this script."
    }
}

Wait-ForDocker

$composeArgs = @("compose", "up", "--remove-orphans")
if (-not $NoBuild) {
    $composeArgs += "--build"
}
if (-not $Foreground) {
    $composeArgs += "-d"
}

Write-Host "Using DOCKER_CONFIG=$dockerConfigPath"
docker @composeArgs
