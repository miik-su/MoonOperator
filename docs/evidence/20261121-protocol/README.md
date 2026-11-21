# Protocol and Wasmtime checks · 2026-11-21

## Windows native

The selected tests passed 15/15 with the Kubernetes response and Watch changes
through source 39f63832b0674f21a7c0058c94764d184cdabf3e. The command was:

```text
moon test client/rest_test.mbt client/pagination_test.mbt client/typed_list_test.mbt client/budget_test.mbt cache/budget_test.mbt runtime/model_test.mbt watch/predicates_test.mbt examples/moonapp/operator_test.mbt examples/moonapp/status_test.mbt testing/patch_test.mbt --target native
```

Native type checking, formatting and generated-interface checks also passed.
The targeted optional-host test passed 1/1 after updating the Wasmtime pin.

The tests use [synthetic Kubernetes models](../../test-models.md) with the
[repository's licensing terms](../../../LICENSING.md). They cover object identity,
LIST metadata and duplicate keys, atomic cache replacement, and UID changes.
They model API state and contain no trained model weights or real cluster records.

## Linux CI

Source 39f6383 passed [Kind acceptance](https://github.com/miik-su/MoonOperator/actions/runs/44730507863).
The [native run](https://github.com/miik-su/MoonOperator/actions/runs/44730507770)
passed its test stages and failed the advisory gate for Wasmtime 50.0.1. OSV
returned eight advisories, RUSTSEC-2026-0566 through RUSTSEC-2026-0573.

Source [457c794630a66b3c9bf9b29ff904937a80441df0](https://github.com/miik-su/MoonOperator/commit/457c794630a66b3c9bf9b29ff904937a80441df0)
passed [focused Linux native checks](https://github.com/miik-su/MoonOperator/actions/runs/44881119471)
and the [experimental WASM probe](https://github.com/miik-su/MoonOperator/actions/runs/44881119458)
with Wasmtime 50.0.3. The WASM report records 10/10 cases using the MoonBit
guest and purpose-built fixtures. The advisory report records the exact
crates.io Wasmtime version and an empty list of returned OSV advisory IDs.

The Linux native report records 14/14 maintenance model tests, the independent
public API consumer, and the source ZIP path and notice check. The TLS report
records successful validation with the test CA and rejection with a wrong CA
or hostname. The focused CI workflow also ran the client and Watch test files.

| Artifact | ID | ZIP SHA-256 | Archived report |
| --- | ---: | --- | --- |
| native-observations | 14697708259 | da5d54cbfdfcc5a1abf3bad84da214f854c2835c1eb41e7e8feee5751b1c5682 | [linux-targeted.json](linux-targeted.json), [tls.json](tls.json) |
| source-dependency-inventory | 14698386529 | 566c57bd6ca8b9a54e1d4877b21cdffda716bc67081808c9712803b05422308c | [advisory.json](advisory.json) |
| wasm-host-evidence | 14697917880 | b79b327dd6bd81bb8d62ab674843256f16f311e35ed3d0770c0ec1cf03072850 | [wasm.json](wasm.json) |

The archives were checked against GitHub's ZIP digests before extraction.
The JSON payloads retain their original contents with shortened filenames.
The advisory query covers only the selected Wasmtime package version. The
native workflow includes a ten-second observation. Full native regression and
hour/day stability testing were outside this round's scope.

## Kind cluster acceptance

The same-source Kind workflow passed against Kubernetes 1.37.0 and Calico 3.33.0.
It exercised MoonApp lifecycle, real API CRUD/PATCH and pagination, 409 and 403
responses, live Watch, six RBAC checks, ownership adoption with explicitly
enabled admission, and NetworkPolicy allow/deny/recovery.

The kind-acceptance artifact 14697879545 has ZIP SHA-256
`44b15521426d690e6b630f98ff44ac5c2c8a9bfe49ad8d04fd2159e154904d7b`.
Archived JSON: [MoonApp](kind-e2e-report.json), [client](cluster-client-report.json),
[versions](kind-version.json), [RBAC](rbac-report.json),
[adoption](adoption-report.json), and [NetworkPolicy](network-policy-report.json).

## Images and bounded memory observations

The [Kind workflow](https://github.com/miik-su/MoonOperator/actions/runs/44881119467)
built the production and acceptance images from the same source. The production
image contains the checked project and third-party notice files. The installed
package inventory records 94 dpkg packages and an available copyright text for
each. The full CI artifact contains those texts and the common licenses. The
inventory records collection coverage; license compatibility, source-offer
obligations and OS advisories require separate review.

Six fresh, read-only containers completed their cache replacement probes with
exit code 0 and OOMKilled=false. The synthetic 10,000-object profile at 128 MiB
peaked at 129,776 KiB RSS. This measures the cache probe process under the stated
limit. The result is close to the limit and gives no production headroom estimate.

| Artifact | ID | ZIP SHA-256 | Archived report |
| --- | ---: | --- | --- |
| runtime-distribution-inventory | 14697518168 | d08bb4959a872204830d0fde7157deb5308846e210af7c90a806d7c5d4aa1032 | [container-inventory.json](container-inventory.json), [container-packages.tsv](container-packages.tsv) |
| memory-observations | 14698466999 | e73588433a7b8eb4b86d2e8ed6f9c5d313f1f96a6227d2befd029f6430126b64 | [memory.json](memory.json) |
