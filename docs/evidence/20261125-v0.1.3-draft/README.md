# MoonOperator v0.1.3 draft verification

The [draft workflow](https://github.com/miik-su/MoonOperator/actions/runs/45629396174)
built commit `dddf77f6a4ba33ce44f797b341a235e1063257dc` on two independent
GitHub-hosted Ubuntu 24.04 amd64 runners with separate source directories
and empty Docker build caches. The [first](image-a.json) and
[second](image-b.json) receipts carry the same image ID
`sha256:bab688eb63d886e87f625ae7d563c0d8cf21483b3fdb6c5979001d96731976eb`,
layer digest and executable SHA-256. Module source digests and package
records also matched. The [reloaded candidate](kind-deployment.json) became
ready on Kubernetes 1.37.0 in Kind and reconciled the MoonApp Service target
port from 8080 to 8081.

After comparison passed, the packaging job checked the corresponding Ubuntu
and GCC source versions using the signed source archive from v0.1.2. The
workflow assembled and verified the Linux amd64 image, project/runtime
source archive, system source archive and [release manifest](release-manifest.json)
against [SHA256SUMS](SHA256SUMS), then created the GitHub draft.

The [draft verification receipt](draft-verification.json) records the tested
commit, all five uploaded assets and their server-side SHA-256 digests. The
manifest and checksum file were independently downloaded from the draft.
Their hashes matched GitHub metadata, and all archive entries matched both
the checksum file and manifest. GitHub returned `draft: true` and
`published_at: null`. The original asset IDs and digests for v0.1.0, v0.1.1
and v0.1.2 matched their pre-run metadata. The current public download is
[v0.1.2](https://github.com/miik-su/MoonOperator/releases/tag/v0.1.2).
