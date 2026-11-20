# MoonOperator

A MoonBit-native Kubernetes Operator development framework.

Experimental, unreleased 0.1.0. The source and examples are usable from this
checkout; no Mooncakes package or stable production support is claimed.

Module: `miik-su/moonoperator` (unpublished; migrated from the development
namespace `mik1e80/moonoperator`). GitHub source: [miik-su/MoonOperator](https://github.com/miik-su/MoonOperator).

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

## Capabilities and boundaries

- Dynamic CRUD/status/merge PATCH, response identity checks, bounded pagination
  and verified bearer/CA transport.
- LIST/WATCH recovery, UID-safe cache updates, bounded queues and cooperative controllers.
- Finalizer/ownership helpers, constrained CRD/RBAC generation and the MoonApp example.
- Fixed-cardinality metrics, safe events and optional bounded scalar WASM validation.

One cooperative event loop and one replica; no HA/Lease election or OS-thread-safe
shared stores. Separate Stores are required for independent namespace watches of
the same GVK. No generated complete Kubernetes SDK, discovery, exec/OIDC or
client-certificate authentication, admission/conversion webhooks, or general JSON
guest ABI is provided. ResourcesApplied does not mean Pod Ready. See the
[scope contract](docs/project-scope.md) and [CRD/RBAC subset](docs/crd-rbac.md).

## Start without a cluster

Use the pinned MoonBit toolchain below, clone this repository and enter its root.
The separate consumer module resolves the unpublished library from a local
workspace; it needs no credentials, Kubernetes, Docker or Wasmtime:

```sh
moon update
cd examples/consumer
moon check --target native
moon run cmd/main --target native
```

Expected result: two reconciles, one annotation update, unrelated annotation
preserved, pending=0. This is Fake-transport evidence, not real API admission.
See [the example](examples/consumer/README.md) and
[developing your own controller](docs/developing-controllers.md).
Return to the repository root before the commands below.

## Test data and results

See [测试数据与结果展示 / Test inputs and results](docs/test-results.md) for
benchmark tables, ten-second load observations, WASM case outcomes, archived
Kind reports and reproducible synthetic input models. Each CI run also displays
its own Markdown summary and downloadable raw reports.
The [November 13 review follow-up](docs/review-followup-20261113.md) links retained
Linux container memory limits, actual Calico/RBAC decisions, TLS rejection and
queue-scale evidence, and states the remaining release checks.
The [test model catalog](docs/test-models.md) distinguishes input provenance,
invariants, actual evidence and untested scope. A historical green source revision
does not mean newer code was rerun. Full regression and 1h/24h soak remain manual
and unexecuted in this maintenance pass.

## MoonApp on a development cluster

MoonBit 0.10.17+d971670cd / moon 0.1.20261023, native target; kubectl and a
disposable development cluster are required. Linux and Windows native have
bounded evidence; macOS and other Kubernetes versions are not verified. The
current kubectl context and default namespace are used below. An authorized
administrator installs the cluster-scoped CRD; the runtime can use a dedicated
ServiceAccount as described in [deployment](docs/deployment.md).

```sh
moon check --target native
moon run cmd/manifests --target native > install.json
kubectl --namespace default apply -f install.json
kubectl wait --for=condition=Established crd/moonapps.moonoperator.dev --timeout=60s
kubectl proxy --port=8001
```

In separate terminals:

```sh
moon run cmd/moonapp --target native
kubectl --namespace default apply -f config/moonapp.yaml
kubectl --namespace default get deployment,service demo-app
```

Default namespace is `default`; set `MOONOPERATOR_NAMESPACE` to override both
the manifest generator and operator. MoonApp creates owned Deployment/Service
resources, updates spec/status idempotently and repairs drift every 30 seconds.
Deleting the MoonApp lets Kubernetes garbage-collect its owned children.
Existing same-name children are never adopted by default. The generated workload
requires a non-root image and applies seccomp, dropped capabilities, disabled
privilege escalation and resource limits. The bundled example uses a pinned
non-root NGINX image on port 8080; arbitrary images must meet this contract.
Set the same namespace in kubectl, manifest generation and the operator. Deleting
the test MoonApp removes its owned children via Kubernetes GC. Stop the local
operator/proxy when finished; CRD removal is an administrator operation affecting
all instances, so it is not part of routine example cleanup.

Local development uses an explicitly enabled loopback kubectl proxy. Set
`MOONOPERATOR_KUBECONFIG` to a JSON or restricted YAML kubeconfig file for HTTPS
bearer authentication (`MOONOPERATOR_KUBECONFIG_JSON` remains an alias). Relative
CA/tokenFile paths resolve against that file. In-cluster ServiceAccount config
is selected via `KUBERNETES_SERVICE_HOST/PORT`; mounted tokens are reread per
request. YAML aliases/custom tags/duplicate keys, exec auth, client certificates
and embedded CA data are unsupported. TLS verification cannot be disabled.

Diagnostics default to `127.0.0.1:8080/healthz`, `/readyz`, `/metrics`; readiness
waits for cache synchronization and degrades after a known watch disconnect
longer than 180000 ms by default (`MOONOPERATOR_MAX_DISCONNECTED_MS=0` disables
this extra threshold). A quiet connected Watch is not considered stale.
See public `pkg.generated.mbti` files for exact package APIs.
Metrics include reconcile outcomes/durations, retries, watch reconnects and API
duration/counts, bounded latency buckets and fixed error categories.
Structured event logs exclude raw server errors and credentials. Metric timing
is defined in [diagnostics](docs/observability.md); it excludes queue wait.
The cluster manifest explicitly exposes port 8080 on the pod interface. Apply
`config/diagnostics-networkpolicy.yaml` in the operator namespace. For monitoring,
label both the monitoring namespace `moonoperator.dev/diagnostics-access=true`
and its client pod `moonoperator.dev/diagnostics-client=true`. A NetworkPolicy
capable CNI is required; default Kind does not prove traffic enforcement.
The dedicated acceptance workflow uses Calico 3.33.0 and records actual
allow/deny/recovery; this does not prove other CNI enforcement.
See [review changes and migration](docs/review-followup-20261108.md).

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
moonbit-community/yaml 0.0.8 (MIT). See [licensing/distribution scope](LICENSING.md),
[third-party notices](THIRD_PARTY_NOTICES.md), [security policy](SECURITY.md) and
[maintenance gates](docs/maintenance.md). Test models are synthetic Kubernetes
resources/events and WAT fixtures; no AI weights are distributed.
