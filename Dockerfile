FROM ubuntu:24.04
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates libssl3t64 && rm -rf /var/lib/apt/lists/*
COPY _build/native/debug/build/cmd/moonapp/moonapp.exe /usr/local/bin/moonoperator
USER 65532:65532
ENTRYPOINT ["/usr/local/bin/moonoperator"]
