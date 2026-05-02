ARG BUILD_FROM=ghcr.io/home-assistant/aarch64-base:latest
FROM ${BUILD_FROM}

RUN apk add --no-cache -q \
    bash openssl jq curl git xxd \
    python3 py3-pip

COPY run.sh /run.sh
RUN chmod a+x /run.sh && mkdir -p /data/tg-ws-proxy

HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
    CMD netstat -tln | awk 'NR>2 && $4 ~ /:/ {found=1} END {exit !found}'

CMD [ "/run.sh" ]