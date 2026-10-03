<#
.SYNOPSIS
  Aura Living Apps - Environment Hydration & Setup Script (PowerShell)
.DESCRIPTION
  Hydrates local environment configurations (.env.json, google-services.json, GoogleService-Info.plist, firebase_options.dart)
  from environment variables or template files so local builds and CI/CD pipelines compile without checking secrets into Git.
#>

[CmdletBinding()]
param (
    [switch]$Force
)

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " Aura Living Apps - Environment Hydration Script " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

$RootPath = Split-Path -Parent $PSScriptRoot
$MobilePath = Join-Path $RootPath "Aura Living Mobile App"
$AdminPath = Join-Path $RootPath "Aura Living Admin App"

function Copy-IfMissing {
    param (
        [string]$Source,
        [string]$Destination,
        [string]$Name
    )
    if (Test-Path $Destination) {
        if ($Force) {
            Copy-Item -Path $Source -Destination $Destination -Force
            Write-Host "[OVERWRITTEN] $Name hydrated from template." -ForegroundColor Yellow
        } else {
            Write-Host "[EXISTS] $Name already exists (Use -Force to overwrite)." -ForegroundColor Green
        }
    } else {
        if (Test-Path $Source) {
            Copy-Item -Path $Source -Destination $Destination
            Write-Host "[CREATED] $Name successfully hydrated from template." -ForegroundColor Green
        } else {
            Write-Host "[WARNING] Template source missing: $Source" -ForegroundColor Red
        }
    }
}

# 1. Hydrate .firebaserc and firebase.json at root
Copy-IfMissing (Join-Path $RootPath ".firebaserc.example") (Join-Path $RootPath ".firebaserc") ".firebaserc"
Copy-IfMissing (Join-Path $RootPath "firebase.json.example") (Join-Path $RootPath "firebase.json") "firebase.json"

# 2. Hydrate .env and .env.json at root
Copy-IfMissing (Join-Path $RootPath ".env.example") (Join-Path $RootPath ".env") "Root .env"
Copy-IfMissing (Join-Path $RootPath ".env.json.example") (Join-Path $RootPath ".env.json") "Root .env.json"

# 3. Hydrate Mobile App configs
Copy-IfMissing (Join-Path $MobilePath ".env.json.example") (Join-Path $MobilePath ".env.json") "Mobile .env.json"
Copy-IfMissing (Join-Path $MobilePath "firebase.json.example") (Join-Path $MobilePath "firebase.json") "Mobile firebase.json"
Copy-IfMissing (Join-Path $MobilePath "android/app/google-services.json.example") (Join-Path $MobilePath "android/app/google-services.json") "Mobile google-services.json"
Copy-IfMissing (Join-Path $MobilePath "ios/Runner/GoogleService-Info.plist.example") (Join-Path $MobilePath "ios/Runner/GoogleService-Info.plist") "Mobile GoogleService-Info.plist"

# 4. Hydrate Admin App configs
Copy-IfMissing (Join-Path $AdminPath ".env.json.example") (Join-Path $AdminPath ".env.json") "Admin .env.json"
Copy-IfMissing (Join-Path $AdminPath "firebase.json.example") (Join-Path $AdminPath "firebase.json") "Admin firebase.json"
Copy-IfMissing (Join-Path $AdminPath "android/app/google-services.json.example") (Join-Path $AdminPath "android/app/google-services.json") "Admin google-services.json"
Copy-IfMissing (Join-Path $AdminPath "ios/Runner/GoogleService-Info.plist.example") (Join-Path $AdminPath "ios/Runner/GoogleService-Info.plist") "Admin GoogleService-Info.plist"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " Environment hydration complete! " -ForegroundColor Green
Write-Host " To run mobile: flutter run --dart-define-from-file=.env.json" -ForegroundColor Cyan
Write-Host " To run admin:  flutter run --dart-define-from-file=.env.json" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
