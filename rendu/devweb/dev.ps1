param(
    [ValidateSet("run", "install", "health", "clean")]
    [string]$Command = "run"
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

$DefaultPython = "C:\Users\cesar\AppData\Local\Programs\Python\Python312\python.exe"
$OllamaUrl = "http://127.0.0.1:11434"
$WebUrl = "http://127.0.0.1:5000"

function Get-PythonExe {
    if (Test-Path $DefaultPython) {
        return $DefaultPython
    }

    $python = Get-Command python.exe -ErrorAction SilentlyContinue

    if ($python -and $python.Source -notlike "*WindowsApps*") {
        return $python.Source
    }

    Write-Host "Python introuvable." -ForegroundColor Red
    Write-Host "Chemin attendu : $DefaultPython"
    exit 1
}

function Install-Dependencies {
    $PythonExe = Get-PythonExe

    if (!(Test-Path ".\requirements.txt")) {
        Write-Host "requirements.txt introuvable." -ForegroundColor Red
        exit 1
    }

    Write-Host "Installation des dépendances Python..." -ForegroundColor Cyan
    & $PythonExe -m pip install -r requirements.txt
}

function Start-WebApp {
    $PythonExe = Get-PythonExe

    if (!(Test-Path ".\app.py")) {
        Write-Host "app.py introuvable." -ForegroundColor Red
        exit 1
    }

    Write-Host "Vérification des dépendances..." -ForegroundColor Cyan
    & $PythonExe -m pip install -r requirements.txt

    $env:OLLAMA_URL = $OllamaUrl

    Write-Host ""
    Write-Host "Lancement de l'interface DEV WEB TechCorp..." -ForegroundColor Green
    Write-Host "Interface web : $WebUrl"
    Write-Host "Serveur Ollama attendu : $OllamaUrl"
    Write-Host ""

    & $PythonExe app.py
}

function Test-Health {
    Write-Host "Test du backend Flask..." -ForegroundColor Cyan
    Invoke-RestMethod -Uri "$WebUrl/health" -Method Get
}

function Clean-WebApp {
    Write-Host "Nettoyage..." -ForegroundColor Cyan
    Remove-Item -Recurse -Force __pycache__ -ErrorAction SilentlyContinue
    Remove-Item -Recurse -Force .pytest_cache -ErrorAction SilentlyContinue
}

switch ($Command) {
    "install" {
        Install-Dependencies
    }

    "run" {
        Start-WebApp
    }

    "health" {
        Test-Health
    }

    "clean" {
        Clean-WebApp
    }
}