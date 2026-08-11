#!/usr/bin/env bash

# This is where we run the initial launcher
WARFRAME_DIR="${WINEPREFIX}/drive_c/Program Files/Warframe"
BOOTSTRAP_LAUNCHER="${WARFRAME_DIR}/Downloaded/Public/Tools/Launcher.exe"
EULA="${WARFRAME_DIR}/Downloaded/Public/Lotus/Language/EULA_en.rtf"

# This is where the launcher actually copies/installs itself to, and where the game
# keeps its configs (EE.cfg/DS.cfg)
APPDATA_DIR="${WINEPREFIX}/drive_c/users/steamuser/AppData/Local/Warframe"
LAUNCHER_DIR="${APPDATA_DIR}/Downloaded/Public/Tools"
LAUNCHER_LOG="${APPDATA_DIR}/Launcher.log"
LAUNCHER="${LAUNCHER_DIR}/Launcher.exe"

# Where umu-run unpacks the Proton builds it downloads
COMPAT_DIR="${HOME}/.local/share/Steam/compatibilitytools.d"

# Colors for pretty printing, The $ makes them work through %s interpolation
MAGENTA=$'\033[35m'
RED=$'\033[31m'
RESET=$'\033[0m'

log() {
    local current_date
    current_date="$(date +'%Y-%m-%d %H:%M:%S')"
    printf "${MAGENTA}[ARCATA]${RESET} [${current_date}] %s\n" "$1"
}

kill_warframe() {
    # We're being aggressive here because Proton is annoyingly robust.
    # Parallel graceful shutdowns can end up in deadlocks.

    local names=(
        'Launcher.exe'
        'Warframe.x64.exe'
        'RemoteCrashSender.exe'
        'xalia.exe'
        'services.exe'
        'explorer.exe'
        'winedevice.exe'
        'svchost.exe'
        'plugplay.exe'
        'rpcss.exe'
        'tabtip.exe'
    )

    # We're aggressive but not cruel, we're giving the processes a chance with TERM

    for n in "${names[@]}"; do pkill -TERM -f "$n" 2>/dev/null || true; done
    pkill -TERM -x wineserver 2>/dev/null || true
    pkill -TERM -f 'umu-run wineserver' 2>/dev/null || true
    pkill -TERM -f 'proton waitforexitandrun' 2>/dev/null || true
    sleep 5

    # Whoever takes to long takes the bullet to the head, however...

    for n in "${names[@]}"; do pkill -KILL -f "$n" 2>/dev/null || true; done
    pkill -KILL -x wineserver 2>/dev/null || true
    pkill -KILL -f 'umu-run wineserver' 2>/dev/null || true
    pkill -KILL -f 'proton waitforexitandrun' 2>/dev/null || true
    sleep 1
}

