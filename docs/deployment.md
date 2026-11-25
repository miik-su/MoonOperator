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

To use the Linux amd64 release archive on a development cluster, download the
image, both source archives, `release-manifest.json` and `SHA256SUMS` from
[GitHub Release v0.1.1](https://github.com/miik-su/MoonOperator/releases/tag/v0.1.1),
verify the archive, and load it. The development manifest uses
`moonoperator:dev`, so tag the loaded image with that name before importing
it into your Kind cluster.

```sh
sha256sum --check --strict SHA256SUMS
docker load -i moonoperator-v0.1.1-linux-amd64-image.tar.gz
docker tag moonoperator:0.1.1 moonoperator:dev
```

## Rebuild the release image

Use Linux amd64 with GCC, OpenSSL development headers and Docker. After
verifying the release downloads, extract the project and its supplied
dependencies into a fresh directory. The core archive is also supplied.

```sh
mkdir release-source
tar -xzf moonoperator-v0.1.1-project-runtime-sources.tar.gz -C release-source
tar -xzf release-source/project.tar.gz -C release-source
cp -a release-source/mooncakes release-source/MoonOperator/.mooncakes
cp release-source/moonbit-core.tar.gz /tmp/core.tar.gz
cd release-source/MoonOperator
```

Download the pinned Linux SDK to `/tmp/moonbit.tar.gz` using the URL in
[the setup action](../.github/actions/setup-moonbit/action.yml). For a Git
checkout, also download the core archive from the action. Use the same
isolated scalar UTF SDK and system allocator as the release build.

```sh
sha256sum --check tools/moonbit-linux.sha256
sdk="$(mktemp -d)"
mkdir -p "$sdk/lib"
tar --exclude=./lib/simdutf.o --exclude=./lib/moonbit_simdutf.o -xzf /tmp/moonbit.tar.gz -C "$sdk"
tar -xzf /tmp/core.tar.gz -C "$sdk/lib"
test ! -e "$sdk/lib/simdutf.o"
test ! -e "$sdk/lib/moonbit_simdutf.o"
chmod +x "$sdk/bin/"* "$sdk/bin/internal/tcc"
export PATH="$sdk/bin:$PATH"
export MOON_TOOLCHAIN_ROOT="$sdk" MOONBIT_ALLOCATOR=system
moon -C "$sdk/lib/core" bundle --warn-list -a --all
moon update
```

For the extracted release source, `moon update` supplies the registry index.
The frozen build uses the module sources already copied into `.mooncakes`.

```sh
moon build --frozen cmd/moonapp cmd/manifests --target native --release
docker build --no-cache --target distribution -t moonoperator:dev .
```

For a Git checkout without the bundled module sources, omit `--frozen`.
The image build installs binary packages from the pinned Ubuntu snapshot.
The paired system source archive contains their source and packaging, plus the
compiler source for the linked runtime helper and startup objects.

### Reproduce the image ID

Run the [independent Linux amd64 release workflow](https://github.com/miik-su/MoonOperator/actions/workflows/release-candidate.yml)
at the `v0.1.1` tag, for example with GitHub CLI:

```sh
gh workflow run release-candidate.yml --ref v0.1.1 --repo miik-su/MoonOperator
```

The two clean runners build at a stable logical source path with the pinned
SDK and reviewed GCC/glibc development package revisions. The workflow passes
the source commit time as `SOURCE_DATE_EPOCH` to fix the configuration,
history and layer timestamps. Compare the two `image.json` receipts with
`release-manifest.json` from the published release. The earlier commands in
this guide cover a functional local build. Matching the released image ID
also requires the recorded toolchain paths, package versions and timestamp.
See the [v0.1.1 release evidence](evidence/20261125-v0.1.1/README.md).

## Install on Kind

config/operator.yaml uses a local image and imagePullPolicy Never for disposable
Kind acceptance. Load that Linux image into Kind before applying the deployment,
or adapt the image reference and pull policy for a reviewed registry artifact.
`distribution` assembles the application and the selected Linux amd64
runtime files. The broader `production` and `acceptance` targets are used for
internal CI.

From the project directory, set `cluster` to the name of your disposable Kind
cluster. Generate the CRD and namespaced RBAC before deploying the operator.

```sh
cluster=moonoperator-demo
namespace=moonoperator-demo
kind load docker-image moonoperator:dev --name "$cluster"
kubectl --context "kind-$cluster" create namespace "$namespace"
MOONOPERATOR_NAMESPACE="$namespace" moon run cmd/manifests --target native > bundle.json
kubectl --context "kind-$cluster" -n "$namespace" apply -f bundle.json
kubectl --context "kind-$cluster" wait --for=condition=Established crd/moonapps.moonoperator.dev --timeout=60s
kubectl --context "kind-$cluster" -n "$namespace" apply -f config/operator.yaml
kubectl --context "kind-$cluster" -n "$namespace" rollout status deployment/moonoperator --timeout=120s
```

The manifest generator also emits the diagnostics NetworkPolicy. The runtime reads
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
