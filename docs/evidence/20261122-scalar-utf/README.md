# Audited scalar UTF production build · 2026-11-22

## Build path and provenance

The audited Linux amd64 production build uses MoonBit's scalar UTF runtime.
The pinned Moon planner selects its optional SIMD path only when both SDK
objects are available. CI extracts the checksum-verified SDK and core into a
separate directory and omits those two entries. It compiles the scalar UTF C
source from the SDK. User installations and other build profiles continue to
use their selected toolchain.
[Runtime input hashes](runtime-input.json)
[Moon object-selection source](https://github.com/moonbitlang/moon/blob/3778465a252d2838357dddf25dc0ebf3ff3ba40f/crates/moonutil/src/compiler_flags.rs#L880)

The [GNU link map evidence](archive-selection.txt) shows `runtime-utf.o` in
the selected archive list. Neither `simdutf.o` nor `moonbit_simdutf.o` appears
in the complete link map, and the demangled symbol table contains no
`simdutf::` library symbols. MoonBit's scalar source has its own helper names.
The [link provenance](link-provenance.json) records those checks and matches
the map-enabled executable to the one installed by the audit image.

The [production comparison](production-verification.json) matches that
executable's SHA-256 against the independent Kind image's executable.
The earlier `dccf759` run used different randomly named SDK directories and
the executable digests differed across jobs. Source `ce94fb5` uses the same
isolated SDK path on both fresh workers and their executable digests match.
The image IDs are recorded separately.

The 94 installed package versions still match the
[authenticated Ubuntu source manifest](../20261122-source-link/ubuntu-source-manifest.json).
Ten bundled notices passed the byte check. The retained simdutf notice
applies to historical or stock-SDK builds which include that library.
The precise source revision of the old SDK object remains unverified
and is preserved in the historical [SDK observation](../20261122-production-layers/simdutf-provenance.json).

## Tested evidence

The [native link and release watch job](https://github.com/miik-su/MoonOperator/actions/runs/45038476444)
passed 2/2 release-mode Watch tests, including UTF-8 bytes split at every
boundary for both BMP and supplementary characters.

| Artifact | ID | Verified ZIP SHA-256 |
| --- | ---: | --- |
| native-link-evidence | 14760672435 | `2628711d2e942fa71496ea781a0c33e7839a831eed3490f8f17fe1c60ca6c8a3` |
| runtime-distribution-inventory | 14760294004 | `64e9e788684f8d7b347bfb247109e3ee90ad4e88ef82cb17e74ad8e42e922d95` |

[Kind on Kubernetes 1.36.4](kind-v1.36.4.md) and
[Kind on Kubernetes 1.37.0](kind-v1.37.0.md) passed with Calico 3.33.0,
including real API calls, TLS, compatibility and policy checks.
The [same-source Kind workflow](https://github.com/miik-su/MoonOperator/actions/runs/45038476352),
[focused native workflow](https://github.com/miik-su/MoonOperator/actions/runs/45038476372)
and [optional WASM workflow](https://github.com/miik-su/MoonOperator/actions/runs/45038476295)
all completed successfully. The [OS rescan](rescan.json) matches the previous
23 package-level findings. It listed no newly available Ubuntu package fix.

| Artifact | ID | Verified ZIP SHA-256 |
| --- | ---: | --- |
| kind-acceptance-v1.36.4 | 14760708106 | `e3d2b84f5c0f599659c1402cdf029eb624df10ac25b5f7d0030715f117deadf0` |
| kind-acceptance-v1.37.0 | 14760163976 | `c953ef5d7c74f5e5859cd4572b598316a139ceb10190124a33843f75a60ab7e0` |
| os-vulnerability-observations | 14760982023 | `702f83138f6f602f46dd83b91d1bbbf3263a6d8e54cc37e263633318c1ab54ad` |
