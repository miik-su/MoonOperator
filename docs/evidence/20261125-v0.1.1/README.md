# MoonOperator v0.1.1 release verification

[Two independent GitHub-hosted Ubuntu 24.04 amd64 jobs](https://github.com/miik-su/MoonOperator/actions/runs/45558048132)
built the same staged source commit, `6a7eb2ee0e3fba7631ea185982d6ce3ec46cb4ca`.
The jobs used separate physical directories, a stable logical compiler path,
the pinned scalar UTF SDK, the system allocator and reviewed GCC/glibc versions.
Neither Docker build used a build cache. The commit timestamp fixed the image
configuration, history and layer file timestamps.

| Check | Observed result |
| --- | --- |
| [Runner A](runner-a.json) and [runner B](runner-b.json) | Separate hosted jobs and source directories. |
| [Image A](image-a.json) and [image B](image-b.json) | Identical image ID `sha256:756fbf1ba23d245dc013941f2ebe85c83b5e1f091f7b889641094b0ea7385d59` and single filesystem layer digest. |
| Executable | SHA-256 `9b8a55f7cb737363765bcb9a62c5e6a5d81eba59376499874a47f0ae455a6119`, identical to the [previously audited executable](../20261123-release/native-link-provenance.json). |
| [Deployment](release-candidate.json) | The exported archive was reloaded and deployed to Kind on Kubernetes 1.37.0. The operator became ready and reconciled the Service target port from 8080 to 8081. |
| [Trivy](trivy.json) | Zero findings for the three released Ubuntu runtime package records using the recorded database. |

The project archive records the tested commit and includes the pinned SDK
runtime and headers, core, resolved module sources and generated MoonApp C.
The [runtime](runtime-source-packages.tsv) and [builder](builder-packages.tsv)
package records matched across the two jobs and correspond to the signed glibc,
OpenSSL, CA and GCC source versions. The repacked system archive was extracted
and checked again against the signed Ubuntu source index and all 12 file
digests. The [release manifest](release-manifest.json) records all archive
checksums and the acceptance scope.

The [v0.1.1 release](https://github.com/miik-su/MoonOperator/releases/tag/v0.1.1)
ships the tested image with both source archives. The previous
[v0.1.0 release](https://github.com/miik-su/MoonOperator/releases/tag/v0.1.0)
remains available with its original asset checksums. The verification was
limited to release identity, source and runtime package checks, and the focused
cluster deployment. No full regression or long soak was run.
