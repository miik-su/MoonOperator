# Release packaging and draft verification

The [packaging rehearsal](https://github.com/miik-su/MoonOperator/actions/runs/45626013423)
used the reviewed system source archive from v0.1.2. Independent Ubuntu
24.04 amd64 builds of commit `9c11986d3b5e23af00cb402c5849733f5d3be2fc`
both produced image ID
`sha256:857255ff3392871b8da75d2ad509c3a324ecf78ee2489770cec9b750bd0f7a63`.
The comparison job passed, and Kind verified readiness and MoonApp Service
reconciliation before packaging.

The packaging job verified the signed Ubuntu index and all 12 source payloads
against both build inventories. It produced and checked the image archive,
project/runtime source archive, system source archive and release manifest
in `SHA256SUMS`. The [five-file workflow artifact](https://github.com/miik-su/MoonOperator/actions/runs/45626013423/artifacts/15028289100)
has SHA-256 `3b37cb193a6ec6c974b2f330e4cda6dda29fb418845c335ffa4e5f9cad61d67a`.
See the [packaging log excerpt](packaging-checks.txt).

The real workflow ran with `create_draft=false`. The
[draft fixture](draft-fixture.json) executed the production draft step against
simulated GitHub responses and verified creation, upload and digest checking
for five files, an idempotent retry, and refusal on a published release,
digest mismatch, existing tag, or tag pointing at a different commit.

A [manual public acceptance run for the existing v0.1.2 release](https://github.com/miik-su/MoonOperator/actions/runs/45626147854)
passed all five public download hash checks, unpacked all four signed source
packages, rebuilt the same image ID and passed deployment on Kubernetes 1.37.0
in Kind. See the [public acceptance log excerpt](public-checks.txt).
The release publication trigger is configured alongside manual dispatch.
