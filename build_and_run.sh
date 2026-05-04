#!/usr/bin/env bash
set -euo pipefail

# Always run from the repository root (the folder this script is in).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "[1/3] Configuring CMake"
cmake -B build

echo "[2/3] Building webview-app (Debug)"
cmake --build build --target webview-app -j --config Debug

echo "[3/3] Running webview-app"
if [[ -x "./build/webview-app" ]]; then
	./build/webview-app
elif [[ -x "./build/Debug/webview-app" ]]; then
	./build/Debug/webview-app
else
	echo "ERROR: webview-app executable not found in ./build or ./build/Debug."
	exit 1
fi

echo
echo "Success."
