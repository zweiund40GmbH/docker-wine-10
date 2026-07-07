FROM debian:trixie
LABEL org.opencontainers.image.authors="Nicolas Wilms"

ENV DEBIAN_FRONTEND=noninteractive
ARG TINI_VERSION=0.19.0
ADD https://github.com/krallin/tini/releases/download/v${TINI_VERSION}/tini /tini
RUN chmod +x /tini

COPY apt /etc/apt
COPY fix-xvfb.sh deps.txt /tmp/

RUN \
	dpkg --add-architecture i386 \
	&& apt-get install -y --update --no-install-recommends \
		ca-certificates \
		curl \
		unzip \
		xauth \
		xvfb \
	&& apt-get install -y --no-install-recommends --mark-auto \
		$(cat /tmp/deps.txt) \
	&& rm /tmp/deps.txt \
	&& /tmp/fix-xvfb.sh \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*


RUN \
	sed -i '/^Enabled:/ s/no/yes/' /etc/apt/sources.list.d/*

RUN apt-get install -y --update --no-install-recommends \
        winehq-stable=10.0.0.0~trixie-1 \
		wine-stable=10.0.0.0~trixie-1 \
		wine-stable-amd64=10.0.0.0~trixie-1 \
		wine-stable-i386=10.0.0.0~trixie-1 \
    && apt-mark hold winehq-stable wine-stable \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

ENV WINEDEBUG=fixme-all

#RUN /bin/sh -c wine --help
RUN apt update && apt install -y wget cabextract xz-utils \
    && mkdir -p /var/winetricks && cd /var/winetricks \
    && wget https://raw.githubusercontent.com/Winetricks/winetricks/20260125/src/winetricks \
    && chmod +x winetricks \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV WINEPREFIX=/root/.wine

RUN /var/winetricks/winetricks && xvfb-run /var/winetricks/winetricks -q dotnetdesktop9
RUN /var/winetricks/winetricks && xvfb-run /var/winetricks/winetricks -q corefonts
RUN /var/winetricks/winetricks && xvfb-run /var/winetricks/winetricks -q gdiplus
RUN rm -rf /root/.wine/drive_c/windows/Installer/*
RUN rm -rf /root/.wine/drive_c/ProgramData/Package\ Cache/*
RUN rm -rf /root/.cache/winetricks/dotnetdesktop9/*
RUN rm -rf /root/.cache/winetricks/corefonts/*
RUN rm -rf /root/.cache/winetricks/gdiplus/*



COPY fonts/ /tmp/win-fonts/

RUN mkdir -p "/root/.wine/drive_c/windows/Fonts" \
    && mkdir -p /usr/local/share/fonts/windows \
    && mkdir -p /data/fonts \
    && find /tmp/win-fonts -type f \( -iname 'calibri*' -o -iname 'verdana*' \) -print0 \
        | while IFS= read -r -d '' font; do \
            filename="$(basename "$font" | tr '[:upper:]' '[:lower:]')"; \
            cp "$font" "/root/.wine/drive_c/windows/Fonts/$filename"; \
            cp "$font" "/usr/local/share/fonts/windows/$filename"; \
            cp "$font" "/data/fonts/$filename"; \
        done \
    && fc-cache -f -v

RUN cat > /tmp/fonts.reg <<'EOF'
    Windows Registry Editor Version 5.00

    [HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\Fonts]
    "Calibri (TrueType)"="calibri.ttf"
    "Calibri Bold (TrueType)"="calibrib.ttf"
    "Calibri Italic (TrueType)"="calibrii.ttf"
    "Calibri Bold Italic (TrueType)"="calibriz.ttf"
    "Calibri Light (TrueType)"="calibril.ttf"
    "Calibri Light Italic (TrueType)"="calibrili.ttf"
    "Verdana (TrueType)"="verdana.ttf"
    "Verdana Bold (TrueType)"="verdanab.ttf"
    "Verdana Italic (TrueType)"="verdanai.ttf"
    "Verdana Bold Italic (TrueType)"="verdanaz.ttf"
EOF

RUN wine reg import /tmp/fonts.reg \
    && wine reg query "HKLM\\Software\\Microsoft\\Windows NT\\CurrentVersion\\Fonts" | grep -Ei 'calibri|verdana'


ENTRYPOINT ["/tini", "--"]
CMD ["/bin/bash"]
