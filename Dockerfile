FROM ubuntu:26.04@sha256:d66b366dac61b575bee2aef07e9c26e8070096fbe84a3d4d3eb0da069b5d76db AS base

# APT verifies signed repository metadata; only this fixed CA data package is
# extracted here. No package scripts or moving bootstrap dependencies execute.
FROM base AS trust-bootstrap
RUN apt-get update && apt-get download ca-certificates=20240203 && dpkg-deb -x ca-certificates_20240203_all.deb /bootstrap && cat /bootstrap/usr/share/ca-certificates/mozilla/*.crt > /bootstrap/ca-certificates.crt

FROM base AS runtime
# Use bootstrap trust only during APT setup. Package installation owns runtime trust.
RUN --mount=type=bind,from=trust-bootstrap,source=/bootstrap/ca-certificates.crt,target=/tmp/bootstrap-ca.crt \
    apt-get -o Acquire::https::CaInfo=/tmp/bootstrap-ca.crt update --snapshot 20261120T000000Z \
    && apt-get -o Acquire::https::CaInfo=/tmp/bootstrap-ca.crt upgrade -y --no-install-recommends --snapshot 20261120T000000Z \
    && apt-get -o Acquire::https::CaInfo=/tmp/bootstrap-ca.crt install -y --no-install-recommends --snapshot 20261120T000000Z ca-certificates libssl3t64 \
    && dpkg --compare-versions "$(dpkg-query -W -f='${Version}' libc6)" ge 2.39-0ubuntu8.12 \
    && dpkg-query -W > /usr/share/moonoperator-runtime-packages.txt \
    && rm -rf /var/lib/apt/lists/*
COPY _build/native/release/build/cmd/moonapp/moonapp.exe /usr/local/bin/moonoperator
COPY LICENSE NOTICE THIRD_PARTY_NOTICES.md LICENSING.md /usr/share/doc/moonoperator/
COPY third_party/ /usr/share/doc/moonoperator/third_party/
USER 65532:65532
ENTRYPOINT ["/usr/local/bin/moonoperator"]

FROM runtime AS acceptance
COPY _build/native/release/build/tests/cluster_client/cluster_client.exe /usr/local/bin/client-probe
COPY _build/native/release/build/cmd/diagnostic_probe/diagnostic_probe.exe /usr/local/bin/diagnostic-probe
COPY _build/native/release/build/tests/memory_profile/memory_profile.exe /usr/local/bin/memory-probe

# Export the final filesystem into one layer. The old Ubuntu and bootstrap
# files from intermediate layers are not carried in the production artifact.
FROM scratch AS production
COPY --from=runtime / /
USER 65532:65532
ENTRYPOINT ["/usr/local/bin/moonoperator"]

# The downloadable application image contains only selected runtime
# components and their notices. The Ubuntu filesystem stays in CI.
FROM runtime AS distribution-files
USER 0:0
ARG SOURCE_DATE_EPOCH=0
RUN set -eu; \
    mkdir -p /distribution/lib64 /distribution/etc /distribution/var/lib/dpkg; \
    for name in libc.so.6 libnss_dns.so.2 libnss_files.so.2 libcrypto.so.3 libssl.so.3; do \
      cp -L --parents "/lib/x86_64-linux-gnu/$name" /distribution; \
    done; \
    cp -L /lib64/ld-linux-x86-64.so.2 /distribution/lib64/; \
    cp -L --parents /etc/ssl/certs/ca-certificates.crt /usr/local/bin/moonoperator /distribution; \
    cp -a --parents /usr/share/doc/moonoperator /usr/share/common-licenses /distribution; \
    for package in libc6 libssl3t64 ca-certificates; do \
      cp -L --parents "/usr/share/doc/$package/copyright" /distribution; \
    done; \
    dpkg-query --status libc6 libssl3t64 ca-certificates > /distribution/var/lib/dpkg/status; \
    dpkg-query -W libc6 libssl3t64 ca-certificates > /distribution/usr/share/moonoperator-runtime-packages.txt; \
    dpkg-query -W -f='${binary:Package}\t${Version}\t${source:Package}\t${source:Version}\t${Architecture}\n' \
      libc6 libssl3t64 ca-certificates > /distribution/usr/share/doc/moonoperator/binary-source-packages.tsv; \
    printf 'root:x:0:0:root:/root:/sbin/nologin\nmoonoperator:x:65532:65532:MoonOperator:/:/sbin/nologin\n' > /distribution/etc/passwd; \
    printf 'root:x:0:\nmoonoperator:x:65532:\n' > /distribution/etc/group; \
    printf 'passwd: files\ngroup: files\nhosts: files dns\n' > /distribution/etc/nsswitch.conf; \
    find /distribution -exec touch -h -d "@$SOURCE_DATE_EPOCH" {} +

FROM scratch AS distribution
COPY --from=distribution-files /distribution /
USER 65532:65532
ENTRYPOINT ["/usr/local/bin/moonoperator"]
