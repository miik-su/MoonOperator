# Production image layers and Ubuntu source bundle

The [production build and Kind run](https://github.com/miik-su/MoonOperator/actions/runs/44986391709)
records source `a66ca59`. Production copies the final filesystem into a
single layer and explicitly sets the non-root user and entrypoint. APT uses
the bootstrap certificate file through a read-only build mount. The bootstrap
stage and inherited Ubuntu layers remain in the build process. The production
image carries the exported final filesystem.

The [intermediate Ubuntu package inventory](intermediate-base-packages.tsv)
has 92 packages. The [verified comparison](layer-comparison.json) records
eight upgraded versions, two added packages and 94 final packages. In
particular, the intermediate layer had glibc `2.39-0ubuntu8.9` and production
has `2.39-0ubuntu8.12`. All 94 final package identities exactly match the
[authenticated source manifest](../20261122-source-link/ubuntu-source-manifest.json).
The final image has one filesystem layer. Ten notice files matched the
checkout. No package copyright files were missing from the collection.

The production executable retains its previous SHA-256. The independent
[link audit](https://github.com/miik-su/MoonOperator/actions/runs/44986391725)
matched the executable in its own build's image and the linker map build.
[Link provenance](link-provenance.json)

| Artifact | ID | Verified ZIP SHA-256 |
| --- | ---: | --- |
| runtime-distribution-inventory | 14740131897 | `ed4596206835835fd08629d5bbeec842691cae56f7cb1cf09d6bda31ef6f8932` |
| native-link-evidence | 14739503978 | `7853d3a501411a6b25a806bbb063c87e2b1f68fb01fb05bb6d235634b94d2bbe` |

## Portable Ubuntu corresponding source

The local tar contains the exact 67 source package versions referenced by
the manifest, all 212 source files, six signed-index or compressed-index
files, and the audit manifests. Each of the 212 payloads was read back
from the tar and hashed against the source manifest.
[Source bundle metadata](source-bundle.json)

For binary distribution, associate the exact image digest and source archive
digest with the same release. Place the verified source archive, manifests,
notices and any remaining required build inputs and sources in the distribution
location. Follow the applicable component terms for availability and retention.
The local tar currently covers the Ubuntu-installed portion.
[Distribution guide](../../container-distribution.md)

## Remaining SDK provenance

The exact pinned SDK archive provides `lib/simdutf.o` and
`lib/moonbit_simdutf.o`. Inspecting the first object's ELF sections and
embedded version labels did not identify its exact upstream source revision.
Its known object digest and compiler comment are recorded.
The [selected members](../20261122-source-link/archive-selection.txt) and the
[MIT attribution](../../../third_party/simdutf-LICENSE-MIT) remain available.
An exact upstream snapshot for these SDK bytes remains to be established.
[SDK object observation](simdutf-provenance.json)

## Focused verification

On source `a66ca59`, both Kind jobs passed with Kubernetes 1.36.4 and 1.37.0.
The [production Trivy rescan](rescan.json) recorded the same 23 package-level
findings on 94 installed packages. This database listed no fixed Ubuntu
version for any of those findings. The
[focused native checks](https://github.com/miik-su/MoonOperator/actions/runs/44986391716)
and [optional WASM checks](https://github.com/miik-su/MoonOperator/actions/runs/44986391711)
also passed on this revision.
