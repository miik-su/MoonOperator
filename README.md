# MoonOperator

A MoonBit-native Kubernetes Operator development framework.

An independent community project, with no claimed endorsement by Kubernetes or
MoonBit. Third-party names and trademarks belong to their respective owners.
See [security reporting](SECURITY.md), [contributing](CONTRIBUTING.md),
[module boundaries](docs/module-boundaries.md) and the
[security remediation record](docs/security-audit-20261108.md).

The implementation follows the linked MoonOperator design: dynamic resources,
an injectable Kubernetes client, LIST/WATCH recovery, a bounded cache and work
queue, and idempotent reconciliation. See [the roadmap](docs/roadmap.md).

This is an early implementation, single replica only. See
[compatibility and verification](docs/compatibility.md) before deployment.

## Quick start

MoonBit 0.10.17+d971670cd / moon 0.1.20261023, native target:

```sh
moon check --target native
moon run cmd/manifests --target native > install.json
kubectl apply -f install.json
kubectl wait --for=condition=Established crd/moonapps.moonoperator.dev --timeout=60s
kubectl proxy --port=8001
```

In separate terminals:

```sh
moon run cmd/moonapp --target native
kubectl apply -f config/moonapp.yaml
kubectl get deployment,service demo-app
```

Default namespace is `default`; set `MOONOPERATOR_NAMESPACE` to override both
the manifest generator and operator. MoonApp creates owned Deployment/Service
resources, updates spec/status idempotently and repairs drift every 30 seconds.
Deleting the MoonApp lets Kubernetes garbage-collect its owned children.

Local development uses an explicitly enabled loopback kubectl proxy. Set
`MOONOPERATOR_KUBECONFIG` to a JSON or restricted YAML kubeconfig file for HTTPS
bearer authentication (`MOONOPERATOR_KUBECONFIG_JSON` remains an alias). Relative
CA/tokenFile paths resolve against that file. In-cluster ServiceAccount config
is selected via `KUBERNETES_SERVICE_HOST/PORT`; mounted tokens are reread per
request. YAML aliases/custom tags/duplicate keys, exec auth, client certificates
and embedded CA data are unsupported. TLS verification cannot be disabled.

Diagnostics: `:8080/healthz`, `/readyz`, `/metrics`; readiness waits for cache
synchronization. See public `pkg.generated.mbti` files for exact package APIs.
Metrics include reconcile outcomes/durations, retries, watch reconnects and API
duration/counts. Structured event logs exclude raw server errors and credentials.

The [experimental WASM host](wasm/README.mbt.md) executes a compiled MoonBit
validator under pinned Wasmtime limits. [Benchmark and load probes](docs/benchmarks.md)
are explicit opt-in commands. See [release status](docs/release-status.md) for
verified CI evidence and remaining production release gates.

Only focused tests are necessary for a change, for example:

```sh
moon test queue/queue_test.mbt --target native
moon test transport/http_test.mbt --target native
moon test examples/moonapp/operator_test.mbt --target native
```

License: Apache-2.0. Dependencies: moonbitlang/async 0.22.5 (Apache-2.0) and
moonbit-community/yaml 0.0.8 (MIT). See THIRD_PARTY_NOTICES.md.
