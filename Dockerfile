FROM debian:bookworm-slim

# See https://github.com/Open-Wine-Components/umu-launcher/releases
ARG UMU_VERSION=1.4.4

# Dropped from apt, ugh. See https://github.com/mikefarah/yq
ARG YQ_VERSION=4.53.3

# GE-Proton caused the launcher to crash. Migrate with caution.
ARG PROTON_VERSION=UMU-Proton

ARG DEBIAN_FRONTEND=noninteractive
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV WINEDEBUG=err+all,fixme-all,warn-all,-err+ntoskrnl,-err+service,-err+kerberos,-err+ntlm,-err+openxr

RUN ARCH=$(dpkg --print-architecture) \
    # Install 32-bit libraries for WoW64
    && dpkg --add-architecture i386 \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        wget \
        gnupg2 \
        tini \
        procps \
        vim \
        btop \
        locales \
        # VNC for troubleshooting
        tigervnc-standalone-server \
        tigervnc-tools \
        # Interaction with windows (e.g. graceful shotdown using Q)
        xdotool \
        x11-utils \
        # Vulkan + lavapipe (rasterizer)
        # Allows Proton to init a Vulkan device without GPU
        libvulkan1 \
        libvulkan1:i386 \
        mesa-vulkan-drivers \
        mesa-vulkan-drivers:i386 \
    && echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
    && locale-gen \
    # Install yq
    && wget --progress=dot:giga -O /usr/local/bin/yq \
        "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_${ARCH}" \
    && chmod 0755 /usr/local/bin/yq \
    # Download UMU
    && wget --progress=dot:giga -O /tmp/umu-launcher.deb \
        "https://github.com/Open-Wine-Components/umu-launcher/releases/download/${UMU_VERSION}/umu-launcher_${UMU_VERSION}-1_all_debian-12.deb" \
    && wget --progress=dot:giga -O /tmp/python3-umu-launcher.deb \
        "https://github.com/Open-Wine-Components/umu-launcher/releases/download/${UMU_VERSION}/python3-umu-launcher_${UMU_VERSION}-1_${ARCH}_debian-12.deb" \
    # Install UMU
    && apt-get install -y --no-install-recommends \
        /tmp/umu-launcher.deb \
        /tmp/python3-umu-launcher.deb \
    # Clean up
    && rm /tmp/umu-launcher.deb /tmp/python3-umu-launcher.deb \
    && rm -rf /var/lib/apt/lists/*

# Who likes being root anyway
ARG TENNO_UID=1000
ARG TENNO_GID=1000
RUN groupadd -g ${TENNO_GID} tenno \
    && useradd -l -m -u ${TENNO_UID} -g tenno -s /bin/bash tenno

# No session = no good. Proton needs an XDG_RUNTIME_DIR
ENV XDG_RUNTIME_DIR=/run/user/${TENNO_UID}
RUN mkdir -p ${XDG_RUNTIME_DIR} \
    && chown ${TENNO_UID}:${TENNO_GID} ${XDG_RUNTIME_DIR} \
    && chmod 700 ${XDG_RUNTIME_DIR}

ENV WINEPREFIX=/home/tenno/.wine/pfx

# See https://umu.openwinecomponents.org/umu_api.php?title=Warframe
ENV GAMEID=umu-230410
ENV STORE=none

# Using DISPLAY=:1 (or other low numbers) could conflict with your host's actual display, if you have one
ENV DISPLAY=:90
ENV PROTONPATH=${PROTON_VERSION}

# Headless driver for Xalia
ENV SDL_VIDEODRIVER=dummy

USER tenno

RUN mkdir -p \
    "${WINEPREFIX}" \
    /home/tenno/.local/share/Steam/compatibilitytools.d

# Keep Xvnc's display alive
COPY --chown=tenno:tenno --chmod=0755 src/xstartup /home/tenno/.vnc/xstartup

COPY assets/ /opt/arcata/assets/
COPY --chmod=0755 arcata.sh /opt/arcata/arcata.sh
COPY --chmod=0755 src/ /opt/arcata/src/

WORKDIR /opt/arcata

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/opt/arcata/arcata.sh"]

