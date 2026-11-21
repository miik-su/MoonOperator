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
