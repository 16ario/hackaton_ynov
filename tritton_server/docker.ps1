param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("build", "start", "health", "logs", "stop", "clean")]
    [string]$Command
)

$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$ComposeFile = Join-Path $ProjectRoot "tritton_server\docker-compose.yml"
$ContainerName = "techcorp-triton"

function Write-Section {
    param([string]$Text)

    Write-Host ""
    Write-Host "==================================================" -ForegroundColor DarkCyan
    Write-Host $Text -ForegroundColor Cyan
    Write-Host "==================================================" -ForegroundColor DarkCyan
}

function Test-Docker {
    try {
        docker --version | Out-Null
    } catch {
        Write-Host "Docker est introuvable. Installe Docker Desktop." -ForegroundColor Red
        exit 1
    }

    try {
        docker info | Out-Null
    } catch {
        Write-Host "Docker ne répond pas. Lance Docker Desktop." -ForegroundColor Red
        exit 1
    }
}

switch ($Command) {
    "build" {
        Write-Section "Build de l'image Triton TechCorp"
        Test-Docker
        docker compose -f $ComposeFile build
    }

    "start" {
        Write-Section "Démarrage du serveur Triton"
        Test-Docker
        docker compose -f $ComposeFile up -d
        Write-Host "Triton lancé sur http://localhost:8000" -ForegroundColor Green
    }

    "health" {
        Write-Section "Test de santé Triton"
        Test-Docker

        try {
            Invoke-RestMethod http://localhost:8000/v2/health/ready
            Write-Host "Triton est prêt." -ForegroundColor Green
        } catch {
            Write-Host "Triton ne répond pas encore ou le modèle n'est pas prêt." -ForegroundColor Red
            Write-Host "Consulte les logs avec : .\tritton_server\docker.ps1 logs"
        }
    }

    "logs" {
        Write-Section "Logs Triton"
        Test-Docker
        docker logs -f $ContainerName
    }

    "stop" {
        Write-Section "Arrêt Triton"
        Test-Docker
        docker compose -f $ComposeFile down
    }

    "clean" {
        Write-Section "Nettoyage Triton"
        Test-Docker
        docker compose -f $ComposeFile down -v
        docker image rm tritton_server-triton -f 2>$null
        Write-Host "Nettoyage terminé." -ForegroundColor Green
    }
}