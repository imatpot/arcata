#!/usr/bin/env bash
source "$(dirname "${0}")/lib.sh"

VNC_PORT="${VNC_PORT:-5900}"

if [ -z "${VNC_PASSWORD:-}" ]; then
    log "Starting VNC without authentication on port ${VNC_PORT}"

    # Yes. That is a real flag.
    vncserver "${DISPLAY}" -rfbport "${VNC_PORT}" -geometry 1280x800 -depth 24 \
        -localhost no -SecurityTypes None --I-KNOW-THIS-IS-INSECURE

else
    log "Starting VNC with password on port ${VNC_PORT}"

    mkdir -p ~/.vnc
    echo "${VNC_PASSWORD}" | vncpasswd -f > ~/.vnc/passwd
    chmod 600 ~/.vnc/passwd
    vncserver "${DISPLAY}" -rfbport "${VNC_PORT}" -geometry 1280x800 -depth 24 -localhost no
fi

