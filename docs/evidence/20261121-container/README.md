# Ubuntu image security, redistribution and Kubernetes compatibility

Tested source [471a658](https://github.com/miik-su/MoonOperator/commit/471a65853b59d198544eb93b14719d1c17493470).
Production image on the Kubernetes 1.37.0 worker:
`sha256:1df9b81495764775dbb59ee8ba753c94d0d575f433d9d82b10a71602d87986f3`.
The [Kind workflow](https://github.com/miik-su/MoonOperator/actions/runs/44918333053)
builds images on each worker. It uploads evidence files only.

## Package and executable provenance

The previous [published inventory](../20261121-protocol/container-packages.tsv)
recorded `libc6 2.39-0ubuntu8.9`. The new image records `libc6` and `libc-bin`
at `2.39-0ubuntu8.12`, Canonical's Noble fix for
[USN-9065-1](https://ubuntu.com/security/notices/USN-9065-1).
The fixed Ubuntu snapshot upgraded inherited packages. OpenSSL remains at
`3.0.13-0ubuntu3.16`, the Noble security revision from
[USN-8847-1](https://ubuntu.com/security/notices/USN-8847-1).

- [Inventory](inventory.json) records 94 installed packages and zero missing
  copyright files. The seven project and bundled notices matched the checkout
  byte for byte. [Binary-to-source package table](binary-source-packages.tsv)
  records versions and architecture.
- [Startup linkage](moonoperator-ldd.txt) records glibc, the loader and the
  kernel vDSO for the [identified executable](moonoperator-sha256.txt).
  Linux async 0.22.5 loads `libssl.so.3` through `dlopen` during TLS setup.
  The Ubuntu scan includes the installed `libssl3t64` package.
  Startup linkage does not enumerate all runtime loads or static objects.
- [Source verification](verified-sources.json) records retrieval of the
  three exact Ubuntu source records for glibc, OpenSSL and ca-certificates.
  All six listed files matched the descriptors' sizes and SHA-256 checksums.
  Descriptor signatures were present. Cryptographic signature verification
  was outside this check. Downloaded source archives stayed local.

The runtime-distribution-inventory artifact (ID 14712671186) contains the
copyright and common-license files. Verified ZIP SHA-256
`bf646dd84941013bcd93f64e787b1265707e91b4fc6c1985a9cd4fc0634cdeb7`.
Publication still requires the exact-image license and corresponding-source
review described in the [redistribution guide](../../container-distribution.md).

## OS advisory scan

Trivy 0.76.2 scanned the same image ID. The 94 package names and versions matched
the installed inventory. It returned 23 package/CVE rows across 14 distinct
CVEs (18 medium, five low, zero high or critical). The Ubuntu data reported
affected status and furnished no fixed package revision for these rows.
The [normalized finding list](ubuntu-vulnerabilities.json) retains the CVE ID,
package, installed and fixed versions, Ubuntu status and original severity.
The [scanner and DB metadata](trivy-version.txt) identify the data used.
The raw Trivy JSON is in the os-vulnerability-observations artifact
(ID 14712596880). Verified ZIP SHA-256
`fb8bc8ba5c17b2208e551f87ab3bd6cf4c20ecd4743b57ae66105cfcf658df1e`.

## Two-version Kind acceptance

Both jobs passed with pinned Kind v0.33.0 node images and Calico 3.33.0.
Kubernetes servers reported their exact expected versions and kubectl was
v1.37.2. Both runs verified real authenticated API CRUD/PATCH, paginated
LIST, 409/403 handling, live Watch, MoonApp lifecycle, scoped RBAC and
ownership admission, and NetworkPolicy allow/deny/recovery.

| Server | Archive ID | Verified ZIP SHA-256 | Archived JSON |
| --- | ---: | --- | --- |
| Kubernetes 1.36.4 | 14713455102 | `fd181f574f9f7089e4a959b17c272b211262535b6dec6c95617fa1f7e219fe64` | [versions](v1.36.4/versions.json), [lifecycle](v1.36.4/lifecycle.json), [client](v1.36.4/client.json), [network](v1.36.4/network-policy.json), [RBAC](v1.36.4/rbac.json), [adoption](v1.36.4/adoption.json) |
| Kubernetes 1.37.0 | 14712791416 | `853cad854db8ac5d08701384cfa0b6e74d0d6fecf0e1689d83f86bb9fce3c7bb` | [versions](v1.37.0/versions.json), [lifecycle](v1.37.0/lifecycle.json), [client](v1.37.0/client.json), [network](v1.37.0/network-policy.json), [RBAC](v1.37.0/rbac.json), [adoption](v1.37.0/adoption.json) |

[Focused native](https://github.com/miik-su/MoonOperator/actions/runs/44918333032)
and [optional WASM](https://github.com/miik-su/MoonOperator/actions/runs/44918333028)
also passed on this source. These observations cover the recorded amd64
images, cluster versions and CNI. Full regressions, long soaks and additional
architecture, Kubernetes and CNI matrices were outside this run.
