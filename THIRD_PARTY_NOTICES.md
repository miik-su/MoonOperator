# Third-party notices

moonbitlang/async 0.22.5 is Apache-2.0: https://github.com/moonbitlang/async.
moonbit-community/yaml 0.0.8 is MIT: https://github.com/moonbit-community/yaml.mbt.
Its complete bundled license/attribution is retained under third_party/yaml-LICENSE.
Wasmtime 50.0.3 is an optional external executable, Apache-2.0 WITH LLVM-exception:
https://github.com/bytecodealliance/wasmtime. It is not vendored into this repository.
MoonBit core/runtime are toolchain components. The native runtime source
headers attribute International Digital Economy Academy under Apache-2.0,
and the upstream runtime attributes some code to musl.
The audited Linux amd64 image builds MoonBit's scalar UTF runtime from source
and uses the system allocator. Stock SDK builds can link mimalloc and simdutf.
The Linux amd64 executable includes a GCC runtime helper under GPL-3.0-or-later
with the GCC Runtime Library Exception 3.1. See the corresponding GCC source
for its notices and the exception text.
We retain the MIT notices in `third_party/mimalloc-LICENSE` and
`third_party/simdutf-LICENSE-MIT`. We also retain the pinned SDK's BSD-style
libbacktrace header notice in `third_party/libbacktrace-LICENSE` for that
linker input. These copies complement the build-specific component review.
Async uses platform TLS (SChannel or OpenSSL). Distributors must
include the notices appropriate to their selected runtime. Kubernetes client-go
and controller-runtime are architecture references, not vendored dependencies.
Both references use Apache-2.0; their source links and reference scope are in
docs/architecture.md and LICENSING.md. The project license does not replace any
third-party license. See LICENSING.md for source, binary, image and fixture scope.

The production container uses the digest-pinned Ubuntu 24.04 base in Dockerfile
and upgrades inherited packages from the dated Ubuntu archive snapshot. The image contains its
installed package/version inventory at /usr/share/moonoperator-runtime-packages.txt;
CI retains that inventory. Package copyright/license metadata remains separate
from this repository's Apache-2.0 source license. The fixed ca-certificates
bootstrap stage extracts trust data only; runtime CA/TLS packages are installed
from the pinned snapshot. The example manifest references an external NGINX
unprivileged image by digest; that image is not vendored into MoonOperator.
See the [container distribution guide](docs/container-distribution.md) for
package-specific notices, startup dynamic linkage and source-package provenance.
