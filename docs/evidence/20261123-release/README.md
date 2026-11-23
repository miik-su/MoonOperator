# Linux amd64 redistribution review

The downloadable image uses the Dockerfile's `distribution` target. It
assembles the application, selected glibc and OpenSSL libraries, the generated
CA bundle and their notices into a scratch filesystem. The package database
in that filesystem contains only source-traceability records for those files.
The internal Ubuntu build filesystem and cluster probe image have separate
distribution scope.

| Component | Exact source | Evidence and notices |
| --- | --- | --- |
| glibc loader, libc, NSS and startup objects | `glibc 2.39-0ubuntu8.12` | Installed package copyright, common licenses and exact Ubuntu source, including packaging. |
| Runtime-loaded OpenSSL libraries | `openssl 3.0.13-0ubuntu3.16` | Installed package copyright and exact source. OpenSSL is loaded by MoonBit async at runtime. |
| Mozilla trust data | `ca-certificates 20260816ubuntu0.24.04.2` | Installed copyright and exact source, including the trust data and bundle-generation scripts. |
| GCC helper and startup objects | `gcc-13 13.3.0-6ubuntu2~24.04.1` | Exact compiler source and packaging, with `COPYING3` and `COPYING.RUNTIME`. |
| MoonBit runtime, core, async and YAML | SDK `0.10.17+d971670cd`, async `0.22.5`, YAML `0.0.8` | Pinned SDK runtime source and headers, exact core and resolved module sources, with project and upstream notices. |

[System source manifest](system-source-manifest.json) lists the 12 files with
sizes and SHA-256 digests. The Ubuntu archive signature on the Noble security
index verifies under `F6ECB3762474EDA9D21B7022871920D1991BC93C`. All four
source-package versions match that authenticated index. The archive was
extracted and all 12 payloads and both signed-index files were rehashed.
See the [archive digest](system-source-archive.json) and the
[previous Ubuntu verification](../20261122-source-link/README.md).

The [native release-mode audit](https://github.com/miik-su/MoonOperator/actions/runs/45039422655)
passed Unicode watch framing and TLS trust/identity verification. Its
[builder package records](builder-source-packages.tsv) and
[byte-matched GNU link evidence](native-link-provenance.json) identify GCC's
selected `_popcountsi2.o` and the runtime compiled from the pinned MoonBit
sources. The system allocator avoids the SDK allocator object. The optional
SIMD UTF objects and libbacktrace archive supplied no code to the audited
executable. The [GCC exception](https://www.gnu.org/licenses/gcc-exception-3.1.en.html)
and [MoonBit compiler output terms](https://github.com/moonbitlang/moonbit-compiler/blob/main/LICENSE.TXT)
are distinct from the project and runtime component licenses.
