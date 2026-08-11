#!/usr/bin/env bash
source "$(dirname "${0}")/lib.sh"

log "Entering run phase"

ARCATA_DIR="$(cd "$(dirname "${0}")/.." && pwd)"
ASSETS_DIR="${ARCATA_DIR}/assets"
CONFIG="${ARCATA_CONFIG:-${ARCATA_DIR}/arcata.yaml}"

EE_CFG="${APPDATA_DIR}/EE.cfg"
DS_CFG="${APPDATA_DIR}/DS.cfg"
ARCATA_CFG="${APPDATA_DIR}/Arcata.cfg"

if [ ! -f "${CONFIG}" ]; then
    log "${RED}FATAL${RESET}: no config file at ${CONFIG}. Did you bind-mount arcata.yaml?"
    exit 1
fi

if [ "$(yq -r '.servers | length' "${CONFIG}")" = "0" ]; then
    log "${RED}FATAL${RESET}: no servers defined in ${CONFIG}, nothing to host"
    exit 1
fi

# CONFIG GENERATION
#
# All final configs are rebuilt on every start.
# Anything the game writes back into EE.cfg/DS.cfg will be disposed.

log "Generating configs from ${CONFIG}"

# EE.cfg

mkdir -p "${APPDATA_DIR}" "${LAUNCHER_DIR}"
EMAIL="$(yq -r '.email // ""' "${CONFIG}")"

cp "${ASSETS_DIR}/EE.default.cfg" "${EE_CFG}"

if [ -z "${EMAIL}" ]; then
    log "No email set in ${CONFIG}, the servers won't be credited to your account."
else
    printf 'email=%s\n' "${EMAIL}" >> "${EE_CFG}"
fi

# DS.cfg

cp "${ASSETS_DIR}/DS.default.cfg" "${DS_CFG}"

yq -r '.servers[] |
    "\n[\(.name),LotusDedicatedServerSettings]" + "\n" +
    ((.settings // {}) | to_entries | map("\(.key)=\(.value)") | join("\n"))' \
    "${CONFIG}" >> "${DS_CFG}"

# Arcata.cfg

yq -r '[.servers[] | "\"\(.name)\": \(.instances // 1)"] | join(",\n")' \
    "${CONFIG}" > "${ARCATA_CFG}"

log "Hosting: $(yq -r '[.servers[] | "\(.name) x\(.instances // 1)"] | join(", ")' "${CONFIG}")"

# Time to launch!

if [ ! -f "${LAUNCHER}" ]; then
    log "${RED}FATAL${RESET}: ${LAUNCHER} not found, something in the installation went wrong."
    exit 1
fi

log "Starting the dedicated servers"

umu-run "${LAUNCHER}" -headless -dedicated -dscfg:"${ARCATA_CFG}"
STATUS="$?"

# In case the launcher exits, we try to keep the container alive for debugging.

log "Launcher exited with status ${STATUS}. Holding the container open for VNC."
tail -f /dev/null

