# MoonOperator v0.1.1 post-release acceptance

The [public release](https://github.com/miik-su/MoonOperator/releases/tag/v0.1.1)
supplied the Linux amd64 image, project and runtime sources, corresponding
system sources, release manifest and checksum file. An
[independent download](public-downloads.json) used no credentials, and all
five files matched the digests recorded by GitHub. A
[fresh Ubuntu 24.04 amd64 runner](https://github.com/miik-su/MoonOperator/actions/runs/45559130286)
downloaded the same public files and [verified all five hashes](downloads.txt).

| Check | Observed result |
| --- | --- |
| [Published image](public-image.json) and [rebuilt image](rebuilt-image.json) | Both matched the published Docker image ID `sha256:756fbf1ba23d245dc013941f2ebe85c83b5e1f091f7b889641094b0ea7385d59` and the single filesystem layer digest. |
| [Executable](image-comparison.txt) and [generated C](generated-c.txt) | Executable bytes matched the downloaded image. Generated MoonApp C matched the source archive. |
| [Corresponding system sources](system-files.txt) | All 12 files matched the signed Ubuntu Noble index. The [four source packages](system-unpack.txt) unpacked successfully. |
| [Deployment of the downloaded image](release-candidate.json) | The operator became ready in [Kind on Kubernetes 1.37.0](kubernetes.json), applied the MoonApp resources and reconciled the Service target port from 8080 to 8081. |

The native build used the source archive from the tagged release commit, the
bundled core and module sources, the pinned MoonBit SDK, and the recorded
[builder packages](builder-packages.tsv). Docker built without cache at the
original logical source and toolchain paths with the published
`SOURCE_DATE_EPOCH`. It used the same prebuilt runtime packages from the
pinned Ubuntu snapshot. The system-source check covered signatures,
checksums, version correspondence and unpacking. The build compiled the
MoonOperator executable from source.

The Docker image ID comparison uses the image configuration digest. Kind
reports a containerd manifest reference in its deployment receipt. The
acceptance covered the public image and source archives, reproducible build,
and one cluster deployment and reconciliation. No full regression or long
soak ran.
