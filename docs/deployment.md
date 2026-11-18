# MoonApp deployment and cleanup

The README's kubectl-proxy path is local development using the current kubeconfig
identity. It does not prove least-privilege runtime access. Use a disposable
context and ensure the same namespace is used for the generated bundle, MoonApp
and operator. The default is default; the scripts/kind-e2e.mbtx acceptance uses
only the explicitly named disposable kind-moonoperator-e2e context.

## Local process

Install the README's pinned MoonBit toolchain, kubectl and a development cluster.
Run moon update at the repository root. An authorized administrator generates
and applies the bundle, then waits for moonapps.moonoperator.dev Established.
Start kubectl proxy on loopback port 8001 and run cmd/moonapp in another terminal.
Apply config/moonapp.yaml and inspect Deployment/Service and MoonApp conditions.
No Docker/Wasmtime is required for this path; the cluster pulls the example image.

To change namespaces, set MOONOPERATOR_NAMESPACE before both manifest generation
and operator execution, and pass that same namespace to kubectl. Environment
syntax differs between PowerShell (`$env:MOONOPERATOR_NAMESPACE='demo'`) and
POSIX shells (`export MOONOPERATOR_NAMESPACE=demo`). Create the namespace before
applying namespaced objects. MOONOPERATOR_KUBECONFIG selects a restricted HTTPS
bearer/CA-file kubeconfig instead of the loopback proxy. Supported fields and
explicit exclusions are in project-scope.md and transport/config.mbt.

## In-cluster process

Build on a Linux host with the pinned toolchain:

```sh
moon build cmd/moonapp --target native --release
docker build --target production -t moonoperator:dev .
```

config/operator.yaml uses a local image and imagePullPolicy Never for disposable
Kind acceptance. Load that Linux image into Kind before applying the deployment,
or adapt the image reference/pull policy for a reviewed registry artifact. There
is no published production image/release implied by that development tag.

Install the generated CRD/RBAC, then apply config/operator.yaml and
config/diagnostics-networkpolicy.yaml in the same namespace. The runtime reads
the projected ServiceAccount CA/token. The example runs as UID 65532 with a
read-only root, dropped capabilities, seccomp and 128 MiB memory limit. Keep
replicas=1. Additional replicas have no leader-election protection.

Diagnostics on the pod interface need an enforcing CNI and BOTH the allowed
monitoring namespace label and client-pod label. They have no built-in auth.
The supplied Calico acceptance checks actual deny/recovery; it is not proof for
default Kind or another CNI. Keep an authenticated proxy for broader exposure.

## Observe and clean up

ResourcesApplied=True confirms desired API operations at the observed generation;
it does not promise Pods are ready. The example Ready condition remains Unknown.
/healthz is a process response; /readyz additionally gates cache sync and a known
disconnect threshold. Neither is a universal cluster-health signal.

Delete the test MoonApp in the selected namespace to exercise owned child GC.
Stop local operator/proxy processes, or delete only the named example deployment
and namespaced resources you installed. Removing the CRD deletes its instances
cluster-wide and is a separate administrator decision. Runtime shutdown is
cooperative, queue/cache state is not persisted, and restart begins with LIST.
