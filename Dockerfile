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


#RUN xvfb-run -a sh -c 'wineboot --init; wineserver -w'
RUN /var/winetricks/winetricks
RUN xvfb-run /var/winetricks/winetricks -q dotnetdesktop9
RUN xvfb-run /var/winetricks/winetricks -q corefonts
RUN xvfb-run /var/winetricks/winetricks fonts allfonts
RUN rm -rf /root/.wine/drive_c/windows/Installer/*
RUN rm -rf /root/.wine/drive_c/ProgramData/Package\ Cache/*
RUN rm -rf /root/.cache/winetricks/dotnetdesktop9/*
RUN rm -rf /root/.cache/winetricks/corefonts/*


#COPY fonts/calibri* /root/.wine/drive_c/windows/Fonts/
#
#RUN xvfb-run -a wine reg add "HKLM\\Software\\Microsoft\\Windows NT\\CurrentVersion\\Fonts" /v "Calibri (TrueType)" /t REG_SZ /d "calibri.ttf" /f \
#    && xvfb-run -a wine reg add "HKLM\\Software\\Microsoft\\Windows NT\\CurrentVersion\\Fonts" /v "Calibri Bold (TrueType)" /t REG_SZ /d "calibrib.ttf" /f \
#    && xvfb-run -a wine reg add "HKLM\\Software\\Microsoft\\Windows NT\\CurrentVersion\\Fonts" /v "Calibri Italic (TrueType)" /t REG_SZ /d "calibrii.ttf" /f \
#    && xvfb-run -a wine reg add "HKLM\\Software\\Microsoft\\Windows NT\\CurrentVersion\\Fonts" /v "Calibri Bold Italic (TrueType)" /t REG_SZ /d "calibriz.ttf" /f \
#    && xvfb-run -a wine reg add "HKLM\\Software\\Microsoft\\Windows NT\\CurrentVersion\\Fonts" /v "Calibri Light (TrueType)" /t REG_SZ /d "calibril.ttf" /f \
#    && xvfb-run -a wine reg add "HKLM\\Software\\Microsoft\\Windows NT\\CurrentVersion\\Fonts" /v "Calibri Light Italic (TrueType)" /t REG_SZ /d "calibrili.ttf" /f \
#    && xvfb-run -a wineboot -u
RUN xvfb-run -a wineboot -u

ENTRYPOINT ["/tini", "--"]
CMD ["/bin/bash"]
