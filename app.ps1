param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("install", "run", "stop", "health", "freeze", "clean")]
    [string]$Command,

    [switch]$NoTunnels,
    [switch]$NoWebTunnel,
    [switch]$NoOllamaTunnel
)

$ErrorActionPreference = "Stop"

# ==================================================
# Configuration générale
# ==================================================

$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

$WebDir = Join-Path $ProjectRoot "webapp"
$WebApp = Join-Path $WebDir "app.py"
$Requirements = Join-Path $WebDir "requirements.txt"

$RuntimeDir = Join-Path $ProjectRoot "runtime"
$TunnelFile = Join-Path $RuntimeDir "tunnels.txt"

$OllamaPort = 11434
$WebPort = 5000

$OllamaHost = "0.0.0.0:$OllamaPort"
$OllamaLocalUrl = "http://127.0.0.1:$OllamaPort"
$WebLocalUrl = "http://127.0.0.1:$WebPort"

$ModelName = "techcorp-phi-financial"
$ModelNameLatest = "$ModelName`:latest"
$BaseModel = "phi3:3.8b-mini-4k-instruct-q4_0"
$ModelfilePath = Join-Path $ProjectRoot "ollama_server\Modelfile"

$DefaultPython = "C:\Users\cesar\AppData\Local\Programs\Python\Python312\python.exe"

$ProgramFilesX86 = [Environment]::GetEnvironmentVariable("ProgramFiles(x86)")
$LocalAppData = [Environment]::GetEnvironmentVariable("LOCALAPPDATA")

New-Item -ItemType Directory -Force -Path $RuntimeDir | Out-Null

# ==================================================
# Fonctions utilitaires
# ==================================================

function Write-Section {
    param([string]$Text)

    Write-Host ""
    Write-Host "==================================================" -ForegroundColor DarkCyan
    Write-Host $Text -ForegroundColor Cyan
    Write-Host "==================================================" -ForegroundColor DarkCyan
}

function Find-Executable {
    param(
        [string]$CommandName,
        [string[]]$Candidates
    )

    foreach ($candidate in $Candidates) {
        if ($candidate -and (Test-Path $candidate)) {
            return $candidate
        }
    }

    $fromPath = Get-Command $CommandName -ErrorAction SilentlyContinue

    if ($fromPath -and $fromPath.Source -notlike "*WindowsApps*") {
        return $fromPath.Source
    }

    return $null
}

function Get-PythonExe {
    $candidates = @(
        $DefaultPython,
        "C:\Users\cesar\AppData\Local\Programs\Python\Python312\python.exe",
        "$LocalAppData\Programs\Python\Python312\python.exe",
        "$LocalAppData\Programs\Python\Python311\python.exe"
    )

    foreach ($candidate in $candidates) {
        if ($candidate -and (Test-Path $candidate)) {
            try {
                & $candidate --version | Out-Null

                if ($LASTEXITCODE -eq 0) {
                    return $candidate
                }
            } catch {
                continue
            }
        }
    }

    $fromPath = Get-Command python.exe -ErrorAction SilentlyContinue

    if ($fromPath -and $fromPath.Source -notlike "*WindowsApps*") {
        return $fromPath.Source
    }

    Write-Host "Python est introuvable ou Windows utilise le faux raccourci Microsoft Store." -ForegroundColor Red
    Write-Host "Chemin attendu : C:\Users\cesar\AppData\Local\Programs\Python\Python312\python.exe"
    exit 1
}

function Get-OllamaExe {
    $ollama = Find-Executable `
        -CommandName "ollama.exe" `
        -Candidates @(
            "$LocalAppData\Programs\Ollama\ollama.exe",
            "$env:ProgramFiles\Ollama\ollama.exe"
        )

    if (-not $ollama) {
        Write-Host "Ollama est introuvable." -ForegroundColor Red
        Write-Host "Installe Ollama avant de lancer ce script."
        exit 1
    }

    return $ollama
}

function Get-CloudflaredExe {
    $cloudflared = Find-Executable `
        -CommandName "cloudflared.exe" `
        -Candidates @(
            "$env:ProgramFiles\cloudflared\cloudflared.exe",
            "$ProgramFilesX86\cloudflared\cloudflared.exe",
            "$LocalAppData\Microsoft\WinGet\Links\cloudflared.exe"
        )

    return $cloudflared
}

function Wait-Http {
    param(
        [string]$Url,
        [string]$Name,
        [int]$Seconds = 60
    )

    Write-Host "Attente de $Name : $Url"

    for ($i = 0; $i -lt $Seconds; $i++) {
        try {
            $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 3

            if ($response.StatusCode -ge 200 -and $response.StatusCode -lt 300) {
                Write-Host "$Name est disponible." -ForegroundColor Green
                return $true
            }
        } catch {
            Start-Sleep -Seconds 1
        }
    }

    Write-Host "$Name ne répond pas après $Seconds secondes." -ForegroundColor Yellow
    return $false
}

function Wait-TunnelUrl {
    param(
        [string[]]$LogFiles,
        [int]$Seconds = 90
    )

    $regex = "https://[a-zA-Z0-9-]+\.trycloudflare\.com"

    for ($i = 0; $i -lt $Seconds; $i++) {
        foreach ($logFile in $LogFiles) {
            if (Test-Path $logFile) {
                $content = Get-Content $logFile -Raw -ErrorAction SilentlyContinue

                if ($content -match $regex) {
                    return $Matches[0]
                }
            }
        }

        Start-Sleep -Seconds 1
    }

    return $null
}

# ==================================================
# Arrêt
# ==================================================

function Stop-TechCorp {
    Write-Section "Arrêt de TechCorp"

    Get-Process cloudflared -ErrorAction SilentlyContinue |
        Stop-Process -Force -ErrorAction SilentlyContinue

    Get-Process ollama -ErrorAction SilentlyContinue |
        Stop-Process -Force -ErrorAction SilentlyContinue

    $pythonProcesses = Get-CimInstance Win32_Process |
        Where-Object {
            $_.Name -match "python" -and
            $_.CommandLine -like "*app.py*"
        }

    foreach ($process in $pythonProcesses) {
        Stop-Process -Id $process.ProcessId -Force -ErrorAction SilentlyContinue
    }

    Write-Host "Ollama, Flask et Cloudflare Tunnel sont arrêtés." -ForegroundColor Green
}

# ==================================================
# Installation
# ==================================================

function Install-TechCorp {
    Write-Section "Installation des dépendances"

    $PythonExe = Get-PythonExe

    if (-not (Test-Path $Requirements)) {
        Write-Host "requirements.txt introuvable : $Requirements" -ForegroundColor Red
        exit 1
    }

    Push-Location $WebDir

    Write-Host "Python utilisé : $PythonExe" -ForegroundColor Green
    Write-Host "Installation des dépendances Flask..."

    & $PythonExe -m pip install -r requirements.txt

    if ($LASTEXITCODE -ne 0) {
        Pop-Location
        Write-Host "Erreur pendant l'installation des dépendances Python." -ForegroundColor Red
        exit 1
    }

    Pop-Location

    Write-Host "Dépendances Python installées." -ForegroundColor Green

    $CloudflaredExe = Get-CloudflaredExe

    if ($CloudflaredExe) {
        Write-Host "cloudflared trouvé : $CloudflaredExe" -ForegroundColor Green
    } else {
        Write-Host "cloudflared introuvable." -ForegroundColor Yellow
        Write-Host "Installe-le avec : winget install --id Cloudflare.cloudflared"
    }
}

# ==================================================
# Ollama
# ==================================================

function Start-Ollama {
    Write-Section "Démarrage du serveur d'inférence Ollama"

    $OllamaExe = Get-OllamaExe

    if (-not (Test-Path $ModelfilePath)) {
        Write-Host "Modelfile introuvable : $ModelfilePath" -ForegroundColor Red
        exit 1
    }

    Get-Process ollama -ErrorAction SilentlyContinue |
        Stop-Process -Force -ErrorAction SilentlyContinue

    Start-Sleep -Seconds 2

    $env:OLLAMA_HOST = $OllamaHost
    [Environment]::SetEnvironmentVariable("OLLAMA_HOST", $OllamaHost, "User")

    $OllamaCommand = "`$env:OLLAMA_HOST='$OllamaHost'; & '$OllamaExe' serve"

    Start-Process `
        -FilePath "powershell.exe" `
        -ArgumentList @("-NoExit", "-ExecutionPolicy", "Bypass", "-Command", $OllamaCommand) `
        -WindowStyle Minimized

    $ready = Wait-Http `
        -Url "$OllamaLocalUrl/api/tags" `
        -Name "Ollama" `
        -Seconds 60

    if (-not $ready) {
        Write-Host "Impossible de démarrer Ollama." -ForegroundColor Red
        exit 1
    }

    Write-Host "Ollama écoute sur $OllamaHost" -ForegroundColor Green
}

function Ensure-OllamaModel {
    Write-Section "Vérification du modèle TechCorp"

    $OllamaExe = Get-OllamaExe

    $tags = Invoke-RestMethod "$OllamaLocalUrl/api/tags"
    $modelNames = @($tags.models | ForEach-Object { $_.name })

    if ($modelNames -notcontains $BaseModel) {
        Write-Host "Modèle de base absent. Téléchargement : $BaseModel" -ForegroundColor Yellow
        & $OllamaExe pull $BaseModel
    } else {
        Write-Host "Modèle de base déjà présent : $BaseModel" -ForegroundColor Green
    }

    $tags = Invoke-RestMethod "$OllamaLocalUrl/api/tags"
    $modelNames = @($tags.models | ForEach-Object { $_.name })

    if (($modelNames -notcontains $ModelName) -and ($modelNames -notcontains $ModelNameLatest)) {
        Write-Host "Création du modèle TechCorp : $ModelName" -ForegroundColor Yellow
        & $OllamaExe create $ModelName -f $ModelfilePath
    } else {
        Write-Host "Modèle TechCorp déjà présent : $ModelName" -ForegroundColor Green
    }

    Invoke-RestMethod "$OllamaLocalUrl/api/tags" | Out-Null
    Write-Host "API Ollama OK : $OllamaLocalUrl" -ForegroundColor Green
}

# ==================================================
# Flask
# ==================================================

function Start-Flask {
    Write-Section "Démarrage de l'interface Flask"

    $PythonExe = Get-PythonExe

    if (-not (Test-Path $WebApp)) {
        Write-Host "app.py introuvable : $WebApp" -ForegroundColor Red
        exit 1
    }

    $pythonProcesses = Get-CimInstance Win32_Process |
        Where-Object {
            $_.Name -match "python" -and
            $_.CommandLine -like "*app.py*"
        }

    foreach ($process in $pythonProcesses) {
        Stop-Process -Id $process.ProcessId -Force -ErrorAction SilentlyContinue
    }

    Start-Sleep -Seconds 1

    $flaskOut = Join-Path $RuntimeDir "flask-out.log"
    $flaskErr = Join-Path $RuntimeDir "flask-err.log"

    Remove-Item $flaskOut -Force -ErrorAction SilentlyContinue
    Remove-Item $flaskErr -Force -ErrorAction SilentlyContinue

    Write-Host "Lancement Flask avec : $PythonExe"
    Write-Host "Dossier web : $WebDir"

    $FlaskCommand = "`$env:OLLAMA_URL='$OllamaLocalUrl'; `$env:FLASK_DEBUG='0'; & '$PythonExe' app.py"

    Start-Process `
        -FilePath "powershell.exe" `
        -WorkingDirectory $WebDir `
        -ArgumentList @("-NoExit", "-ExecutionPolicy", "Bypass", "-Command", $FlaskCommand) `
        -RedirectStandardOutput $flaskOut `
        -RedirectStandardError $flaskErr `
        -WindowStyle Minimized

    $ready = Wait-Http `
        -Url "$WebLocalUrl/health" `
        -Name "Flask" `
        -Seconds 60

    if (-not $ready) {
        Write-Host ""
        Write-Host "Flask n'a pas démarré correctement." -ForegroundColor Red
        Write-Host "Logs stdout : $flaskOut"
        Write-Host "Logs stderr : $flaskErr"
        Write-Host ""

        if (Test-Path $flaskOut) {
            Write-Host "----- flask-out.log -----" -ForegroundColor Yellow
            Get-Content $flaskOut -ErrorAction SilentlyContinue
        }

        if (Test-Path $flaskErr) {
            Write-Host "----- flask-err.log -----" -ForegroundColor Yellow
            Get-Content $flaskErr -ErrorAction SilentlyContinue
        }

        exit 1
    }

    Write-Host "Interface Flask disponible : $WebLocalUrl" -ForegroundColor Green
}

# ==================================================
# Cloudflare Tunnel
# ==================================================

function Start-CloudflareTunnel {
    param(
        [string]$Name,
        [string]$TargetUrl
    )

    $CloudflaredExe = Get-CloudflaredExe

    if (-not $CloudflaredExe) {
        Write-Host "cloudflared introuvable. Tunnel $Name ignoré." -ForegroundColor Yellow
        Write-Host "Installe-le avec : winget install --id Cloudflare.cloudflared"
        return $null
    }

    $safeName = $Name.ToLower().Replace(" ", "-")
    $stdoutLog = Join-Path $RuntimeDir "$safeName-cloudflared-out.log"
    $stderrLog = Join-Path $RuntimeDir "$safeName-cloudflared-err.log"

    Remove-Item $stdoutLog -Force -ErrorAction SilentlyContinue
    Remove-Item $stderrLog -Force -ErrorAction SilentlyContinue

    Write-Host "Ouverture du tunnel $Name vers $TargetUrl"

    $process = Start-Process `
        -FilePath $CloudflaredExe `
        -ArgumentList @("tunnel", "--url", $TargetUrl) `
        -RedirectStandardOutput $stdoutLog `
        -RedirectStandardError $stderrLog `
        -WindowStyle Minimized `
        -PassThru

    $publicUrl = Wait-TunnelUrl `
        -LogFiles @($stdoutLog, $stderrLog) `
        -Seconds 90

    if ($publicUrl) {
        Write-Host "$Name disponible : $publicUrl" -ForegroundColor Green
    } else {
        Write-Host "URL publique non trouvée pour $Name." -ForegroundColor Yellow
        $publicUrl = "NON TROUVEE"
    }

    return [PSCustomObject]@{
        Name = $Name
        Target = $TargetUrl
        PublicUrl = $publicUrl
        PID = $process.Id
    }
}

function Start-Tunnels {
    Write-Section "Création des tunnels Cloudflare"

    Remove-Item $TunnelFile -Force -ErrorAction SilentlyContinue

    $results = @()

    if (-not $NoTunnels -and -not $NoOllamaTunnel) {
        $ollamaTunnel = Start-CloudflareTunnel `
            -Name "Ollama inference server" `
            -TargetUrl $OllamaLocalUrl

        if ($ollamaTunnel) {
            $results += $ollamaTunnel
        }
    }

    if (-not $NoTunnels -and -not $NoWebTunnel) {
        $webTunnel = Start-CloudflareTunnel `
            -Name "Flask web interface" `
            -TargetUrl $WebLocalUrl

        if ($webTunnel) {
            $results += $webTunnel
        }
    }

    foreach ($result in $results) {
        Add-Content -Path $TunnelFile -Value "$($result.Name)"
        Add-Content -Path $TunnelFile -Value "Local  : $($result.Target)"
        Add-Content -Path $TunnelFile -Value "Public : $($result.PublicUrl)"
        Add-Content -Path $TunnelFile -Value "PID    : $($result.PID)"
        Add-Content -Path $TunnelFile -Value ""
    }

    if (Test-Path $TunnelFile) {
        Write-Section "URLs publiques"
        Get-Content $TunnelFile
    }

    $ollamaTunnel = $results | Where-Object { $_.Name -eq "Ollama inference server" } | Select-Object -First 1
    $webTunnel = $results | Where-Object { $_.Name -eq "Flask web interface" } | Select-Object -First 1

    Write-Section "Commandes pour le groupe"

    if ($ollamaTunnel -and $ollamaTunnel.PublicUrl -ne "NON TROUVEE") {
        Write-Host "Tester le serveur d'inférence distant :"
        Write-Host "Invoke-RestMethod $($ollamaTunnel.PublicUrl)/api/tags" -ForegroundColor Green
        Write-Host ""
        Write-Host "Configurer une webapp Flask pour utiliser ton Ollama :"
        Write-Host "`$env:OLLAMA_URL=`"$($ollamaTunnel.PublicUrl)`"" -ForegroundColor Green
        Write-Host ".\app.ps1 run -NoOllamaTunnel -NoWebTunnel" -ForegroundColor Green
        Write-Host ""
    }

    if ($webTunnel -and $webTunnel.PublicUrl -ne "NON TROUVEE") {
        Write-Host "Ouvrir ton interface web :"
        Write-Host "$($webTunnel.PublicUrl)" -ForegroundColor Green
        Write-Host ""
    }

    Write-Host "Garde les fenêtres Ollama / Flask / cloudflared ouvertes pendant la démo." -ForegroundColor Yellow
}

# ==================================================
# Health
# ==================================================

function Health-TechCorp {
    Write-Section "État des services"

    try {
        Invoke-RestMethod "$OllamaLocalUrl/api/tags" | Out-Null
        Write-Host "Ollama : OK — $OllamaLocalUrl" -ForegroundColor Green
    } catch {
        Write-Host "Ollama : indisponible" -ForegroundColor Red
    }

    try {
        Invoke-RestMethod "$WebLocalUrl/health" | Out-Null
        Write-Host "Flask : OK — $WebLocalUrl" -ForegroundColor Green
    } catch {
        Write-Host "Flask : indisponible" -ForegroundColor Red
    }

    if (Test-Path $TunnelFile) {
        Write-Host ""
        Write-Host "Dernières URLs Cloudflare :"
        Get-Content $TunnelFile
    }

    Write-Host ""
    Write-Host "Ports actifs :"
    netstat -ano | findstr ":11434"
    netstat -ano | findstr ":5000"
}

# ==================================================
# Freeze / Clean
# ==================================================

function Freeze-TechCorp {
    Write-Section "Export des dépendances"

    $PythonExe = Get-PythonExe

    Push-Location $WebDir
    & $PythonExe -m pip freeze | Set-Content requirements-lock.txt
    Pop-Location

    Write-Host "Fichier généré : webapp\requirements-lock.txt" -ForegroundColor Green
}

function Clean-TechCorp {
    Write-Section "Nettoyage"

    Remove-Item -Recurse -Force (Join-Path $WebDir "__pycache__") -ErrorAction SilentlyContinue
    Remove-Item -Recurse -Force (Join-Path $WebDir ".pytest_cache") -ErrorAction SilentlyContinue
    Remove-Item -Recurse -Force $RuntimeDir -ErrorAction SilentlyContinue

    New-Item -ItemType Directory -Force -Path $RuntimeDir | Out-Null

    Write-Host "Nettoyage terminé." -ForegroundColor Green
}

# ==================================================
# Run complet
# ==================================================

function Run-TechCorp {
    Write-Section "Lancement complet TechCorp"

    Install-TechCorp
    Start-Ollama
    Ensure-OllamaModel
    Start-Flask
    Start-Tunnels

    Write-Section "Lancement terminé"

    Write-Host "Serveur Ollama local : $OllamaLocalUrl" -ForegroundColor Green
    Write-Host "Interface Flask locale : $WebLocalUrl" -ForegroundColor Green
    Write-Host ""
    Write-Host "Pour arrêter :"
    Write-Host ".\app.ps1 stop" -ForegroundColor Yellow
}

# ==================================================
# Router
# ==================================================

switch ($Command) {
    "install" {
        Install-TechCorp
    }

    "run" {
        Run-TechCorp
    }

    "stop" {
        Stop-TechCorp
    }

    "health" {
        Health-TechCorp
    }

    "freeze" {
        Freeze-TechCorp
    }

    "clean" {
        Clean-TechCorp
    }
}