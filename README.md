# MoonOperator

A MoonBit-native Kubernetes Operator development framework.

Experimental framework for single-replica development and testing. The source and
examples are usable from this checkout.

MoonBit module: [miik-su/moonoperator](https://mooncakes.io/docs/miik-su/moonoperator).
GitHub source: [miik-su/MoonOperator](https://github.com/miik-su/MoonOperator).

An independent community project, with no claimed endorsement by Kubernetes or
MoonBit. Third-party names and trademarks belong to their respective owners.
See [security reporting](SECURITY.md), [contributing](CONTRIBUTING.md),
[module boundaries](docs/module-boundaries.md) and the
[security remediation record](docs/security-audit-20261108.md).

## Download the Linux amd64 image

[GitHub Release v0.1.2](https://github.com/miik-su/MoonOperator/releases/tag/v0.1.2)
provides the Docker image archive, matching project and runtime sources,
matching system and compiler sources, and SHA-256 checksums.

Place all five release assets in one directory, then verify and load the image.

```sh
sha256sum --check --strict SHA256SUMS
docker load -i moonoperator-v0.1.2-linux-amd64-image.tar.gz
```

The archive loads as `moonoperator:0.1.2`. Two independent clean Linux amd64
runners produced the same image ID before publication. After publication, a
fresh Linux runner downloaded the public assets, reproduced the published
image ID from the source archive and deployed the downloaded image to Kind.
See the
[deployment instructions](docs/deployment.md#in-cluster-process),
[reproducible build instructions](docs/deployment.md#reproduce-the-image-id)
and the [v0.1.2 release and public acceptance results](docs/evidence/20261125-v0.1.2/README.md).
[Earlier releases](https://github.com/miik-su/MoonOperator/releases) remain available.

The [v0.1.3 draft verification](docs/evidence/20261125-v0.1.3-draft/README.md)
records the independent builds and the five verified draft assets. The public
download above is v0.1.2.

For future versions, see [release packaging and GitHub drafts](docs/deployment.md#prepare-a-new-release)
and [public release acceptance](docs/deployment.md#reproduce-the-image-id).

The implementation follows the linked MoonOperator design: dynamic resources,
an injectable Kubernetes client, LIST/WATCH recovery, a bounded cache and work
queue, and idempotent reconciliation. See [the roadmap](docs/roadmap.md).

This is an early implementation, single replica only. See
[compatibility and verification](docs/compatibility.md) before deployment.

## Capabilities and boundaries

- Dynamic CRUD/status/merge PATCH, response identity checks, bounded pagination
  and verified bearer/CA transport.
- Scope-checked LIST/WATCH recovery, UID-safe cache updates, bounded queues and cooperative controllers.
- Finalizer/ownership helpers, constrained CRD/RBAC generation and the MoonApp example.
- Fixed-cardinality metrics, safe events and optional bounded scalar WASM validation.

One cooperative event loop and one replica; no HA/Lease election or OS-thread-safe
shared stores. Independent watches of the same GVK require separate Stores.
A namespaced informer checks LIST objects and Watch events against its configured
namespace before cache or queue admission. An empty namespace selects all
namespaces for namespaced resources. Kubernetes RBAC defines what the credentials
may access. No generated complete Kubernetes SDK, discovery, exec/OIDC or
client-certificate authentication, admission/conversion webhooks, or general JSON
guest ABI is provided. ResourcesApplied does not mean Pod Ready. See the
[scope contract](docs/project-scope.md) and [CRD/RBAC subset](docs/crd-rbac.md).

## Use the library in another project

In the root of a separate MoonBit module, add the native library dependency.

```sh
moon add miik-su/moonoperator@0.1.3
moon check --target native
```

See [developing your own controller](docs/developing-controllers.md) for public
API imports and [the consumer example](examples/consumer/README.md) for a runnable
ConfigMap reconciliation.

## Start without a cluster

Use the pinned MoonBit toolchain below, clone this repository and enter its root.
The separate consumer module resolves the library from a local
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
its own Markdown summary and downloadable raw reports. The
[scope and license checks](docs/evidence/20261121-scope-license/README.md) record
the source revision, targeted model results and actual source ZIP checks.
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
bounded evidence. Kind passed with Kubernetes 1.36.4 and 1.37.0 on amd64,
using Calico 3.33.0. macOS and other cluster combinations remain unverified. The
commands below use the `default` namespace on a disposable development cluster.
Check the active context before applying the bundle. An authorized administrator
installs the cluster-scoped CRD. The in-cluster path uses a dedicated
ServiceAccount as described in [deployment](docs/deployment.md#in-cluster-process).

```sh
kubectl config current-context
moon update
moon check --target native
MOONOPERATOR_NAMESPACE=default moon run cmd/manifests --target native > install.json
kubectl --namespace default apply -f install.json
kubectl wait --for=condition=Established crd/moonapps.moonoperator.dev --timeout=60s
kubectl proxy --address=127.0.0.1 --port=8001
```

In separate terminals:

```sh
MOONOPERATOR_NAMESPACE=default moon run cmd/moonapp --target native
```

Apply and verify from the other terminal.

```sh
kubectl --namespace default apply -f config/moonapp.yaml
kubectl --namespace default wait --for=condition=ResourcesApplied moonapp/demo-app --timeout=90s
kubectl --namespace default get deployment/demo-app service/demo-app
```

MoonApp creates owned Deployment/Service resources, updates spec/status
idempotently and repairs drift every 30 seconds. `ResourcesApplied=True` checks
the resource reconciliation. To check the workload too, run
`kubectl --namespace default rollout status deployment/demo-app --timeout=120s`.
Existing same-name children are never adopted by default. The generated workload
requires a non-root image and applies seccomp, dropped capabilities, disabled
privilege escalation and resource limits. The bundled example uses a pinned
non-root NGINX image on port 8080; arbitrary images must meet this contract.
For a different namespace or PowerShell syntax, see the [local deployment guide](docs/deployment.md#local-process).
To clean up the example, run `kubectl --namespace default delete moonapp/demo-app`
and stop the local operator and proxy. Kubernetes garbage-collects the owned
children. CRD removal affects all instances and requires a separate administrator
operation.

The local process uses the loopback proxy when neither a kubeconfig override
nor in-cluster configuration is present. Set `MOONOPERATOR_KUBECONFIG` to a JSON
or restricted YAML kubeconfig file for HTTPS
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
The in-cluster example exposes port 8080 on the pod interface. The generated
bundle includes the diagnostics NetworkPolicy. For monitoring,
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
resources/events and WAT fixtures. No AI model weights are distributed.
The source ZIP audit checks included notices
byte for byte and compares the bundled async and YAML licenses with the resolved
dependencies. The [container security and redistribution guide](docs/container-distribution.md)
describes the OS scan, binary linkage evidence, source-package versions and
remaining obligations for distributing a built image. The
[image and compatibility evidence](docs/evidence/20261121-container/README.md)
identifies the earlier CI image, package findings and both Kind test results.
The [redistribution evidence](docs/evidence/20261121-redistribution/README.md)
records verified Ubuntu source signatures, the observed Linux linker inputs,
the bundled license checks and the Canonical CVE status recheck. The
[Ubuntu source manifest and linker map](docs/evidence/20261122-source-link/README.md)
cover the 94 installed packages and distinguish selected archive members
from unused linker inputs. The [single-layer production evidence](docs/evidence/20261122-production-layers/README.md)
records the final filesystem export and the verified Ubuntu source bundle.
The Linux amd64 release profile uses the pinned scalar UTF runtime and system
allocator. The [release rebuild instructions](docs/deployment.md#rebuild-the-release-image)
show how to build the same profile.
