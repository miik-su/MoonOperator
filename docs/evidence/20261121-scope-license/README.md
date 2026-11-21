# Informer collection scope and source archive notices · 2026-11-21

Tested source [7c16596](https://github.com/miik-su/MoonOperator/commit/7c16596075cf76eead1f7b2d5c2b523ab6770436).
The Windows run used a clean worktree and the pinned MoonBit SDK.

```sh
moon run scripts/maintenance-checks.mbtx -- FRESH_OUTPUT_DIRECTORY
```

- [Windows model and consumer results](windows-models.json) record 16/16 focused
  tests. The new cases use synthetic Pod and Node resources, a cross-namespace
  Watch event and a malformed custom bookmark. They check cache preservation,
  readiness, predicate calls, relisting and queue admission. The independent
  consumer used an in-memory transport and completed two reconciles with one
  update, an unrelated annotation preserved, and an empty queue.
  Local home and checkout paths in compiler output were shortened.
- [Windows package audit](windows-package.json) records 312 ZIP paths, seven
  unique nonempty notice files matching the checkout byte for byte, and two
  included license texts matching the resolved Mooncakes dependencies. The
  bundled MoonBit core license also matched the installed pinned SDK core
  license in a separate local SHA-256 comparison:
  `86460c45017ffacb9aa9e18850fa9fdb036339dc8851125465f4a3f3442fc894`.
  This checks notice contents for the source archive and records no publication.

The model inputs and project-authored reports follow the
[repository license terms](../../../LICENSING.md).
See the [model catalog](../../test-models.md) for the data scope.
No full regression or long-duration load run was performed.

## GitHub Actions on the same source

[Focused native](https://github.com/miik-su/MoonOperator/actions/runs/44882516711),
[Kind](https://github.com/miik-su/MoonOperator/actions/runs/44882516781) and
[experimental WASM](https://github.com/miik-su/MoonOperator/actions/runs/44882516742)
all passed on the same source. Linux native recorded 16/16 models, the independent
consumer, the TLS allow/reject checks, and the same 312 paths and seven notice
payloads using unzip. Kind verified the real API, RBAC, network policy and the
MoonApp lifecycle on Kubernetes 1.37.0 with Calico 3.33.0. The bounded scalar
WASM probe passed 10/10 on Wasmtime 50.0.3. OSV returned no advisories for that
exact crates.io package version in this run.

| Artifact | ID | ZIP SHA-256 | Archived selection |
| --- | ---: | --- | --- |
| native-observations | 14698865944 | 2ef691381b82068a244b7dffb4f7fb2b4159645ec56a14942c05110d5c2d5fe7 | [models](linux-models.json), [package](linux-package.json), [TLS](tls.json) |
| source-dependency-inventory | 14698870858 | 3682445a004b88dc70cf80ecd9c7ab87affc243812b2cb1db73ad4923735346d | [OSV query](advisory.json) |
| wasm-host-evidence | 14698374118 | a1ca91061f5afd35efb4581e8784644042011e6736af9a6fed125955312adc4a | [WASM cases](wasm.json) |
| kind-acceptance | 14699016795 | 6ccddf451399bba27fcc4617cd9575d610f59f8d3ab676da8871373c55e24085 | [Kind summary](kind.md), [client](kind-client.json) |

The four ZIP digests were checked before extraction. These tests provide dated
platform, source-archive and exact-version evidence. OS/binary dependency
vulnerability scans, additional Kubernetes/CNI combinations, macOS and installed
registry package compatibility remain open.
