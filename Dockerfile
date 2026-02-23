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
	sed -i '/^Enabled:/ s/no/yes/' /etc/apt/sources.list.d/* \
	&& apt-get install -y --update --no-install-recommends \
		winehq-stable=10.0.0.0~trixie-1 \
    && apt-mark hold winehq-stable \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["/tini", "--"]
CMD ["/bin/bash"]