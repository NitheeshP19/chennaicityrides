$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$dockerConfigPath = Join-Path $repoRoot ".docker-local"

New-Item -ItemType Directory -Force -Path $dockerConfigPath | Out-Null

$env:DOCKER_CONFIG = $dockerConfigPath
$env:DOCKER_BUILDKIT = "0"
$env:COMPOSE_DOCKER_CLI_BUILD = "0"

docker compose down --remove-orphans
