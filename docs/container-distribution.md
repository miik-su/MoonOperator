# Production image security and redistribution

The Dockerfile builds a Linux image for single-replica development and test
deployments. CI builds and uses images on their runners and archives evidence
files. The source tree and test reports are available on GitHub. There is no
official production image release or written source offer from this project.

## Package security and scope

APT uses an explicitly dated Ubuntu snapshot to update inherited packages
and to install the CA and TLS packages. The production target exports the
merged final filesystem into one OCI layer and sets the runtime user and
entrypoint explicitly. The CI acceptance image remains a separate build
target with probes. The image build checks the Ubuntu
`libc6` version is at least 2.39-0ubuntu8.12, the Noble security update for
[USN-9065-1](https://ubuntu.com/security/notices/USN-9065-1). Ubuntu versions
include distribution backports. Use vendor package revisions when evaluating
[OpenSSL advisories](https://ubuntu.com/security/notices/USN-8847-1).

The scan uses the locally built production image and a checksum-verified
Trivy release. It records the image ID, source commit, scanner version and
database metadata. Its scope is installed OS packages in the effective image
filesystem. The host kernel, intermediate build layers, Windows
SChannel, libraries loaded only at runtime, static code and the sample's
external NGINX image require separate evidence. Findings with no fixed Ubuntu
revision remain visible. Wasmtime is separately checked by exact package
version and the optional executable is outside the production image.

## Notices and corresponding source

Image evidence verifies the required project and bundled notice files against the
checkout. It records available Ubuntu package copyright files and common
licenses and lists missing copyright files explicitly. The five columns in
`binary-source-packages.tsv` are binary package, binary version, Ubuntu source
package, source version and architecture. The binary SHA-256 and startup
dynamic-loader output describe the specific built executable.

| Component | What the distributor must account for |
| --- | --- |
| MoonOperator, MoonBit core, async and YAML | Keep project and bundled license texts and attribution. Runtime source headers in the pinned SDK identify International Digital Economy Academy and Apache-2.0. Review toolchain startup and all compiler-supplied objects for the exact binary build. |
| glibc and utilities | Review the installed package copyright and common licenses. The library is principally LGPL-2.1-or-later and package utilities and other files can carry separate terms. Track the precise glibc source revision for the shipped packages. |
| OpenSSL libraries and CLI | Review Ubuntu's per-file attribution. OpenSSL 3 uses Apache-2.0 upstream. Keep the installed package copyright, license and applicable notices. [Upstream license](https://openssl-library.org/source/license/index.html) |
| CA trust data and helper packages | Consult the installed copyright. Ubuntu records GPL-2-or-later for distribution helpers and MPL-2.0 for the Mozilla trust data. |
| Other Ubuntu base and runtime packages | Apply each package's terms. Retain license and copyright files, match any required complete corresponding sources to the exact packages shipped, and review Ubuntu trademark usage under Canonical's policy. |
| Optional Wasmtime, external workload and CI tools | Review their terms separately when redistributing them in a different bundle. They are outside this production image. |

Before offering a binary image publicly, use the package-to-source table to
resolve exact signed source records and files in the Ubuntu archive. Retain
the matching source, packaging changes and build materials when required,
including source for independently distributed GPL-covered utilities. Choose a
source delivery mechanism that satisfies each relevant license and retain it
for the required period. The generated TSV locates versions for this review.
The [verified source manifest](evidence/20261122-source-link/README.md) records
download and integrity checks for all source files indexed for the 94 installed
package versions of the audited amd64 image. The files are retained locally. The
[verified Ubuntu bundle and single-layer evidence](evidence/20261122-production-layers/README.md)
record a portable source archive and the final filesystem of the new
production image. For a public release, attach the matching sources and
notices alongside the image or supply another license-appropriate delivery
mechanism. Include applicable SDK and compiler source and notice obligations.
See [Ubuntu's archive documentation](https://ubuntu.com/project/docs/how-ubuntu-is-made/concepts/package-archive/),
[GPL v2 section 3](https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)
and [Canonical's intellectual property policy](https://canonical.com/legal/intellectual-property-policy).

The project license ([Apache-2.0](../LICENSE)) applies to project-authored
source and examples. Third-party terms remain attached to their components.
See [licensing boundaries](../LICENSING.md) and [third-party notices](../THIRD_PARTY_NOTICES.md).
The [distribution evidence](evidence/20261121-redistribution/README.md) verifies
the archive and uploader signatures for three source packages along with the
required notice bytes. It records static mimalloc and simdutf code, additional
link inputs and remaining component source gaps. The
[dated production scan](evidence/20261121-container/README.md) retains the
initial findings. The follow-up matches each remaining CVE to Canonical's
Noble source-package status. A subsequent
[GNU link-map audit](evidence/20261122-source-link/README.md#native-archive-member-selection)
records the actual selected archive members of a byte-matched executable.
