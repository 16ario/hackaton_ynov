param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("install", "run", "health", "freeze", "clean")]
    [string]$Command
)

$PYTHON = "C:\Users\cesar\AppData\Local\Programs\Python\Python312\python.exe"

if (!(Test-Path $PYTHON)) {
    Write-Host "Python introuvable : $PYTHON" -ForegroundColor Red
    exit 1
}

switch ($Command) {
    "install" {
        Write-Host "Installation des dépendances Python..." -ForegroundColor Cyan
        & $PYTHON -m pip install -r requirements.txt
    }

    "run" {
        Write-Host "Lancement de l'interface Flask..." -ForegroundColor Cyan
        & $PYTHON app.py
    }

    "health" {
        Write-Host "Test du backend Flask..." -ForegroundColor Cyan
        Invoke-RestMethod -Uri "http://localhost:5000/health" -Method Get
    }

    "freeze" {
        Write-Host "Export des dépendances installées..." -ForegroundColor Cyan
        & $PYTHON -m pip freeze | Set-Content requirements-lock.txt
    }

    "clean" {
        Write-Host "Nettoyage..." -ForegroundColor Cyan
        Remove-Item -Recurse -Force __pycache__ -ErrorAction SilentlyContinue
        Remove-Item -Recurse -Force .pytest_cache -ErrorAction SilentlyContinue
    }
}