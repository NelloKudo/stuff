#!/bin/bash

# Helper script to quickly install vkd3d-proton
# and dxvk-nvapi for Sleepy Launcher, due to
# DLSS and DX12 coming in ZZZ 2.3

# Relies on 'curl' and 'tar'.

LAUNCHER_PATHS=("$HOME/.var/app/moe.launcher.sleepy-launcher/data/sleepy-launcher"
                "$HOME/.local/share/sleepy-launcher")

DXVK_NVAPI_VER="0.9.0"
VKD3D_PROTON_VER="2.14.1"

DXVK_NVAPI_LINK="https://github.com/jp7677/dxvk-nvapi/releases/download/v${DXVK_NVAPI_VER}/dxvk-nvapi-v${DXVK_NVAPI_VER}.tar.gz"
VKD3D_PROTON_LINK="https://github.com/HansKristian-Work/vkd3d-proton/releases/download/v${VKD3D_PROTON_VER}/vkd3d-proton-${VKD3D_PROTON_VER}.tar.zst"

### ------

# Only run the script for the 'first' launcher folder found, at least for now.
if [ -z "$LAUNCHER_DIR" ]; then
    for path in "${LAUNCHER_PATHS[@]}"; do
        if [ -d "$path" ]; then
            LAUNCHER_DIR="$path"
            break
        fi
    done
fi

if [ -z "$LAUNCHER_DIR" ]; then
    echo "Sleepy Launcher directory not found."
    echo "If you're using a custom install (ex. on your SD card), please set the launcher dir with LAUNCHER_DIR=/path/to/sleepy-launcher"
    exit 1
fi

echo "Using launcher directory: $LAUNCHER_DIR"
echo "------"

### ------

TMPDIR="$(mktemp -d)"
cd "$TMPDIR"

echo "Downloading dxvk-nvapi ${DXVK_NVAPI_VER}..."
curl -L "$DXVK_NVAPI_LINK" -o dxvk-nvapi.tar.gz
tar -xf dxvk-nvapi.tar.gz
echo "------"

echo "Downloading vkd3d-proton ${VKD3D_PROTON_VER}..."
curl -L "$VKD3D_PROTON_LINK" -o vkd3d-proton.tar.zst
tar -xf vkd3d-proton.tar.zst
echo "------"

### ------

PREFIX_PATH="${PREFIX_PATH:-$LAUNCHER_DIR/prefix}"
if [ ! -d "$PREFIX_PATH" ]; then
    echo "Prefix folder not found, please specify it with PREFIX_PATH=/path/to/prefix if using some custom path."
    exit 1
fi

export WINEPREFIX="$PREFIX_PATH"

# Try to get the first Wine runner from the script, any should do..
if [ -z "$WINE_PATH" ]; then
    for dir in "$LAUNCHER_DIR"/runners/*; do
        if [ -d "$dir" ]; then
            WINE_PATH="$dir"
            break
        fi
    done
fi

if [ -z "$WINE_PATH" ]; then
    echo "Wine folder not found, please specify it with WINE_PATH=/path/to/wine if using some custom path."
    exit 1
fi

WINE_BIN="$WINE_PATH/bin/wine"

### ------

# All this assumes dxvk (dxgi) is already installed in the prefix, like the launchers do.

echo "Installing dxvk-nvapi.."
cp -v dxvk-nvapi*/x64/*.dll "$PREFIX_PATH/drive_c/windows/system32/" 2>/dev/null || true
cp -v dxvk-nvapi*/x32/*.dll "$PREFIX_PATH/drive_c/windows/syswow64/" 2>/dev/null || true

for dll in nvapi nvapi64 nvofapi64; do 
    "$WINE_BIN" reg add "HKEY_CURRENT_USER\Software\Wine\DllOverrides" /v "$dll" /d native /f
done

echo "------"

echo "Installing vkd3d-proton.."
cp -v vkd3d-proton*/x64/*.dll "$PREFIX_PATH/drive_c/windows/system32/" 2>/dev/null || true
cp -v vkd3d-proton*/x86/*.dll "$PREFIX_PATH/drive_c/windows/syswow64/" 2>/dev/null || true

for dll in d3d12 d3d12core; do
    "$WINE_BIN" reg add "HKEY_CURRENT_USER\\Software\\Wine\\DllOverrides" /v "$dll" /d native /f
done

### ------

echo "------"

echo "Installation complete!"
echo "Open ZZZ and check if everything's working as expected."