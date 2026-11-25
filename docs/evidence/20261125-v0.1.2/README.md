# MoonOperator v0.1.2 release verification

The [candidate workflow](https://github.com/miik-su/MoonOperator/actions/runs/45622423043)
built commit `cbf02c9f393d032e943452ce76aa7148ca7b061a` on two separate
GitHub-hosted Ubuntu 24.04 amd64 runners without Docker build cache. The
comparison job passed for the image identity, module source digest, runtime
and builder package records, and candidate archive hashes.

| Check | Observed result |
| --- | --- |
| [Runner A](candidate/image-a.json) and [runner B](candidate/image-b.json) | Image ID `sha256:6a38a6bede181438c8ef4a4c0281a1a7306224c615707aee325a45ac2c4209b1` and the single filesystem layer digest matched. |
| Executable | SHA-256 matched across both jobs and matched the [previous native linkage audit](../20261123-release/native-link-provenance.json). |
| [Candidate deployment](candidate/release-candidate.json) | The exported and reloaded image became ready on Kubernetes 1.37.0 in Kind and reconciled the Service target port from 8080 to 8081. |
| [Runtime package scan](candidate/trivy.json) | Trivy returned zero findings for the three package records in this image. |

The project archive identifies the tested commit and includes resolved module
sources, generated MoonApp C and the pinned MoonBit runtime and core. The
system archive provides the recorded glibc, OpenSSL, CA and GCC source
revisions. The signed Ubuntu index and all 12 corresponding source files
were verified after repacking the system archive.
See the [release manifest](release-manifest.json) and [asset hashes](SHA256SUMS).

## Public release acceptance

The [v0.1.2 release](https://github.com/miik-su/MoonOperator/releases/tag/v0.1.2)
offers the image, both corresponding source archives, the manifest and
checksums. The [v0.1.0](https://github.com/miik-su/MoonOperator/releases/tag/v0.1.0)
and [v0.1.1](https://github.com/miik-su/MoonOperator/releases/tag/v0.1.1)
asset IDs and digests were verified before and after publication.

The [successful public acceptance run](https://github.com/miik-su/MoonOperator/actions/runs/45624215787)
downloaded the five files anonymously and [verified their hashes](published/downloads.txt).
The [four matching system source packages](published/system-unpack.txt)
unpacked after Ubuntu's archive signature, source index and file hashes were
verified. The clean runner rebuilt the application image without Docker
cache from the downloaded project archive and pinned build profile. The
[downloaded image](published/public-image.json) and
[rebuilt image](published/rebuilt-image.json) matched the published image ID
and layer digest, and [both executables matched](published/image-comparison.txt).
The [downloaded image](published/release-candidate.json) also passed readiness
and MoonApp Service reconciliation on Kubernetes 1.37.0 in Kind.

The [initial run](https://github.com/miik-su/MoonOperator/actions/runs/45624014493)
received HTTP 403 from GitHub's anonymous metadata API. The workflow now
uses its read-only token for release and commit metadata lookups. The assets
are still downloaded through their public URLs. This release ran the focused
build, integrity and deployment checks.
