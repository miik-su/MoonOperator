# Third-party notices

moonbitlang/async 0.22.5 is Apache-2.0: https://github.com/moonbitlang/async.
moonbit-community/yaml 0.0.8 is MIT: https://github.com/moonbit-community/yaml.mbt.
Its complete bundled license/attribution is retained under third_party/yaml-LICENSE.
Wasmtime 50.0.1 is an optional external executable, Apache-2.0 WITH LLVM-exception:
https://github.com/bytecodealliance/wasmtime. It is not vendored into this repository.
MoonBit core/runtime are toolchain components; preserve their notices in binary
distribution. async uses platform TLS (SChannel or OpenSSL); distributors must
include the notices appropriate to their selected runtime. Kubernetes client-go
and controller-runtime are architecture references, not vendored dependencies.

The production container uses the digest-pinned Ubuntu 24.04 base in Dockerfile
and packages from the dated Ubuntu archive snapshot. The image contains its
installed package/version inventory at /usr/share/moonoperator-runtime-packages.txt;
CI retains that inventory. Package copyright/license metadata remains separate
from this repository's Apache-2.0 source license. The fixed ca-certificates
bootstrap stage extracts trust data only; runtime CA/TLS packages are installed
from the pinned snapshot. The example manifest references an external NGINX
unprivileged image by digest; that image is not vendored into MoonOperator.
