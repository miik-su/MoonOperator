FROM ubuntu:26.04@sha256:6a06111c3b0a8600feadb270aec771dc239bf407b25625f93f44ab00e11f4d3c AS base

# APT verifies signed repository metadata; only this fixed CA data package is
# extracted here. No package scripts or moving bootstrap dependencies execute.
FROM base AS trust-bootstrap
RUN apt-get update && apt-get download ca-certificates=20240203 && dpkg-deb -x ca-certificates_20240203_all.deb /bootstrap && cat /bootstrap/usr/share/ca-certificates/mozilla/*.crt > /bootstrap/ca-certificates.crt

FROM base AS runtime
COPY --from=trust-bootstrap /bootstrap/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
RUN apt-get update --snapshot 20261108T000000Z && apt-get install -y --no-install-recommends --snapshot 20261108T000000Z ca-certificates libssl3t64 && dpkg-query -W > /usr/share/moonoperator-runtime-packages.txt && rm -rf /var/lib/apt/lists/*
COPY _build/native/release/build/cmd/moonapp/moonapp.exe /usr/local/bin/moonoperator
COPY LICENSE NOTICE THIRD_PARTY_NOTICES.md /usr/share/doc/moonoperator/
COPY third_party/ /usr/share/doc/moonoperator/third_party/
USER 65532:65532
ENTRYPOINT ["/usr/local/bin/moonoperator"]

FROM runtime AS acceptance
COPY _build/native/release/build/tests/cluster_client/cluster_client.exe /usr/local/bin/client-probe
COPY _build/native/release/build/cmd/diagnostic_probe/diagnostic_probe.exe /usr/local/bin/diagnostic-probe

# Default builds select production; test-only tooling is in a sibling stage.
FROM runtime AS production
