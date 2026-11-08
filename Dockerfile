FROM ubuntu:24.04@sha256:fe81560990fae86dc4743202b2cb4d3df98d0bcf949173cecef15ce1127ef852 AS runtime
RUN apt-get update --snapshot 20261108T000000Z && apt-get install -y --no-install-recommends --snapshot 20261108T000000Z ca-certificates libssl3t64 && dpkg-query -W > /usr/share/moonoperator-runtime-packages.txt && rm -rf /var/lib/apt/lists/*
COPY _build/native/release/build/cmd/moonapp/moonapp.exe /usr/local/bin/moonoperator
USER 65532:65532
ENTRYPOINT ["/usr/local/bin/moonoperator"]

FROM runtime AS acceptance
COPY _build/native/release/build/tests/cluster_client/cluster_client.exe /usr/local/bin/client-probe

# Default builds select production; test-only tooling is in a sibling stage.
FROM runtime AS production
