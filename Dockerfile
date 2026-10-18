# CI supplies an immutable digest resolved from the official latest image.
ARG BASE_IMAGE=jellyfin/jellyfin:latest
FROM ${BASE_IMAGE}

RUN set -eu; \
    . /etc/os-release; \
    test "$ID" = debian; \
    test "$VERSION_CODENAME" = trixie; \
    test "$(dpkg --print-architecture)" = amd64; \
    printf '%s\n' \
      'Types: deb' \
      'URIs: https://deb.debian.org/debian' \
      "Suites: ${VERSION_CODENAME} ${VERSION_CODENAME}-updates" \
      'Components: non-free' \
      'Signed-By: /usr/share/keyrings/debian-archive-keyring.pgp' \
      '' \
      'Types: deb' \
      'URIs: https://deb.debian.org/debian-security' \
      "Suites: ${VERSION_CODENAME}-security" \
      'Components: non-free' \
      'Signed-By: /usr/share/keyrings/debian-archive-keyring.pgp' \
      > /etc/apt/sources.list.d/custom-non-free.sources; \
    apt-get update -o APT::Update::Error-Mode=any; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      intel-media-va-driver-non-free vainfo fonts-noto-cjk-extra; \
    fc-cache -f; \
    fc-list :lang=zh family | grep -q 'Noto.*CJK'; \
    rm -rf /var/lib/apt/lists/*
