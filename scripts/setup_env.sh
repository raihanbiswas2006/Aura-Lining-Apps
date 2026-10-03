#!/usr/bin/env bash
# ==============================================================================
# Aura Living Apps - Environment Hydration & Setup Script (Bash / POSIX)
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
MOBILE_DIR="$ROOT_DIR/Aura Living Mobile App"
ADMIN_DIR="$ROOT_DIR/Aura Living Admin App"

echo "=========================================================="
echo " Aura Living Apps - Environment Hydration Script (Bash)"
echo "=========================================================="

copy_if_missing() {
  local src="$1"
  local dest="$2"
  local name="$3"

  if [ -f "$dest" ]; then
    echo "[EXISTS] $name already exists."
  elif [ -f "$src" ]; then
    cp "$src" "$dest"
    echo "[CREATED] $name successfully hydrated from template."
  else
    echo "[WARNING] Template missing: $src"
  fi
}

copy_if_missing "$ROOT_DIR/.firebaserc.example" "$ROOT_DIR/.firebaserc" ".firebaserc"
copy_if_missing "$ROOT_DIR/firebase.json.example" "$ROOT_DIR/firebase.json" "firebase.json"
copy_if_missing "$ROOT_DIR/.env.example" "$ROOT_DIR/.env" "Root .env"
copy_if_missing "$ROOT_DIR/.env.json.example" "$ROOT_DIR/.env.json" "Root .env.json"

copy_if_missing "$MOBILE_DIR/.env.json.example" "$MOBILE_DIR/.env.json" "Mobile .env.json"
copy_if_missing "$MOBILE_DIR/firebase.json.example" "$MOBILE_DIR/firebase.json" "Mobile firebase.json"
copy_if_missing "$MOBILE_DIR/android/app/google-services.json.example" "$MOBILE_DIR/android/app/google-services.json" "Mobile google-services.json"
copy_if_missing "$MOBILE_DIR/ios/Runner/GoogleService-Info.plist.example" "$MOBILE_DIR/ios/Runner/GoogleService-Info.plist" "Mobile GoogleService-Info.plist"

copy_if_missing "$ADMIN_DIR/.env.json.example" "$ADMIN_DIR/.env.json" "Admin .env.json"
copy_if_missing "$ADMIN_DIR/firebase.json.example" "$ADMIN_DIR/firebase.json" "Admin firebase.json"
copy_if_missing "$ADMIN_DIR/android/app/google-services.json.example" "$ADMIN_DIR/android/app/google-services.json" "Admin google-services.json"
copy_if_missing "$ADMIN_DIR/ios/Runner/GoogleService-Info.plist.example" "$ADMIN_DIR/ios/Runner/GoogleService-Info.plist" "Admin GoogleService-Info.plist"

echo "=========================================================="
echo " Environment hydration complete!"
echo "=========================================================="
