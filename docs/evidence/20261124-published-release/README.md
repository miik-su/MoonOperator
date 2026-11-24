# v0.1.0 public release acceptance

The [public release page](https://github.com/miik-su/MoonOperator/releases/tag/v0.1.0)
was the source of all downloads. The [independent download receipt](public-downloads.json)
records all five public assets. Four content hashes matched `SHA256SUMS`, and
the checksum file itself matched the digest reported by the GitHub release API.

The [clean Ubuntu 24.04 amd64 run](https://github.com/miik-su/MoonOperator/actions/runs/45403261125)
verified the Noble archive signature, matched 12 source files to the signed
source index and unpacked the four source packages with `dpkg-source`.
It rebuilt MoonApp and the manifest generator from the published MoonBit
source archive and built the application image without a Docker build cache.
The compiler was acquired separately from the pinned SDK URL. The compiler
used the archived core and both archived Mooncakes modules. `moon update`
initialized the registry index and the frozen build preserved the local module
sources byte for byte. The image used binary runtime packages from the pinned
Ubuntu snapshot. The acceptance run verified and unpacked their corresponding
source packages without compiling those packages.

| Check | Result |
| --- | --- |
| [Public image deployment](fresh-directory/release-public.json) | Operator ready and reconciled a MoonApp in Kubernetes 1.37.0. |
| [Rebuilt image deployment](fresh-directory/release-rebuilt.json) | Operator ready and reconciled the same MoonApp in a second namespace. |
| Watch and update | Both images applied the initial resources and reconciled the Service target port from 8080 to 8081. The fixture used zero workload replicas. |
| [Runtime package versions](fresh-directory/packages.tsv) | Exact match across both images. |
| [Build identity](fresh-directory/image-comparison.txt) | The public image and executable matched the release manifest. The rebuild in a different source directory produced a different image ID and executable hash. |

The [first run](https://github.com/miik-su/MoonOperator/actions/runs/45402884138)
found that the extracted SDK binaries needed executable permissions. The
[second run](https://github.com/miik-su/MoonOperator/actions/runs/45403069615)
found that frozen dependency resolution still required registry metadata.
Both setup issues were fixed before the successful run. The release assets
keep their published checksums.
