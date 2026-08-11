#!/usr/bin/env bash
source "$(dirname "${0}")/lib.sh"

log "Entering install phase"

for dir in "${WINEPREFIX}" "${COMPAT_DIR}"; do
    if [ ! -w "${dir}" ]; then
        log "${RED}FATAL${RESET}: ${dir} is not writable by user $(id -un). If that is a bind mount, create the host directory yourself before starting the container."
        exit 1
    fi
done

log "Initializing Proton prefix"
umu-run wineboot -i

# INSTALLATION STEP 1: Download & extract Launcher MSI
#
# This is where the fun begins!

if [ -z "$(ls -A "${WARFRAME_DIR}" 2>/dev/null)" ]; then
    log "No Warframe install found in ${WARFRAME_DIR}, installing"

    wget -O /tmp/Warframe.msi https://content.warframe.com/dl/Warframe.msi

    # We're using /a instead of /i so the launcher doesn't auto-open itself after installation
    umu-run msiexec /a 'Z:\tmp\Warframe.msi' /qn TARGETDIR='C:\wf'

    # Move the extracted files to the correct location
    mkdir -p "${WARFRAME_DIR}"
    shopt -s dotglob
    mv "${WINEPREFIX}/drive_c/wf/LocalAppDataFolder/Warframe/"* "${WARFRAME_DIR}/"
    shopt -u dotglob

    rm -rf "${WINEPREFIX}/drive_c/wf"
    rm -f /tmp/Warframe.msi
fi

# INSTALLATION STEP 2: Set the installatin directory in the registry
#
# So the launcher does this funny thing where, on its first launch, it prompts you to enter the installation directory.
# We want this container headless, so that is a no-go.
# However, we can just set the registry key ourselves to avoid the picker from appearing in the first place!
# This can be done safely on every startup.
#
# That takes care of one nuisance.

log "Setting installation directory"
umu-run \
    reg add 'HKEY_CURRENT_USER\Software\Digital Extremes\Warframe\Launcher' \
    /v DownloadDir /t REG_SZ /d 'C:\Program Files\Warframe\Downloaded' /f

# INSTALLATION STEP 3: Accept the EULA
#
# Another slightly unfortunate mechanic of the launcher is the EULA prompt.
# The EULA cannot be accepted via arguments, so the launcher must run as non-headless to download the EULA and to accept it.
#
# However, we can do the following:
#
# 1. Launch the launcher non-headless and let it download the EULA.
#    The launcher will relaunch, but we don't care about that.
#    It will re-fetch new EULA automatically.
# 2. Wait for Launcher to go idle, which indicates no more downloads are happening.
# 3. MD5-hash the EULA_en.rtf file and write it into the registry if the hash in there doesn't match the file.
# 4. Kill all Warframe/Proton processes.
# 5. Grofit! The EULA is now recognized as accepted.
#
# Auto-accepting the EULA on a person's behalf is a legal grey area.
# Because of that, this step is gated behind an opt-in flag.
# It will (as far as I've tested) automatically handle EULA updates too!

AUTO_ACCEPT_EULA="${AUTO_ACCEPT_EULA:-0}"

if [ "${AUTO_ACCEPT_EULA}" = "0" ]; then
    log "AUTO_ACCEPT_EULA is disabled, skipping EULA acceptance. You will need to manually accept the EULA via VNC. The headless launcher will stop crashing after you accept the EULA and restart it."
fi

if [ "${AUTO_ACCEPT_EULA}" = "1" ] && [ ! -f "${EULA}" ]; then
    log "Forcing the launcher to download the EULA"

    (cd "$(dirname "${BOOTSTRAP_LAUNCHER}")" && umu-run "${BOOTSTRAP_LAUNCHER}") &
    LAUNCHER_PID=$!

    log "Waiting for EULA to appear"
    for _ in $(seq 1 300); do
        [ -f "${EULA}" ] && break
        sleep 1
    done

    log "Waiting for launcher to go idle"
    last_mtime=""
    idle_count=0

    # Capped at 120*5 seconds = 10 minutes
    for _ in $(seq 1 120); do
        sleep 5
        cur_mtime=$(stat -c %Y "${LAUNCHER_LOG}" 2>/dev/null || echo "0")

        if [ "${cur_mtime}" = "${last_mtime}" ]; then
            idle_count=$((idle_count + 1))
            [ "${idle_count}" -ge 2 ] && break
        else
            idle_count=0
            last_mtime="${cur_mtime}"
        fi
    done

    # The launcher is a bit annoying with self-reopening, especially on initial install.
    kill -KILL "${LAUNCHER_PID}" 2>/dev/null || true
    wait "${LAUNCHER_PID}" 2>/dev/null || true
    kill_warframe

    if [ ! -f "${EULA}" ]; then
        log "${RED}FATAL${RESET}: EULA_en.rtf never appeared. You may need to manually interact with the launcher via VNC!"
    fi
fi

if [ "${AUTO_ACCEPT_EULA}" = "1" ] && [ -f "${EULA}" ]; then
    # Now we can write the hash to the registry!
    EULA_HASH=$(md5sum "${EULA}" | awk '{print toupper($1)}')
    umu-run \
        reg add 'HKEY_CURRENT_USER\Software\Digital Extremes\Warframe\Launcher' \
        /v ReadEula /t REG_SZ /d "${EULA_HASH}" /f
fi

# The launcher is now installed.
# On its subsequent starts, both headless and not, it will start downloading the game files!

log "${LAUNCHER} is installed and ready for Conclave"

