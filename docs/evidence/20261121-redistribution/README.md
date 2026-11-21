# Native redistribution verification

## Ubuntu signature chain

[Signature and payload evidence](ubuntu-source-signatures.json) covers the
exact glibc, OpenSSL and ca-certificates source revisions for the
[previously scanned image](../20261121-container/README.md). GnuPG checked
the Ubuntu archive signing key against Canonical's published fingerprint and
the uploader key against the registered Launchpad fingerprint. The archived
Ubuntu `InRelease` signature was valid. Its SHA-256 and size entry matched
`main/source/Sources.xz` from the fixed Noble security snapshot.

All three .dsc upload signatures were valid. The three descriptors matched
the authenticated source index, and all six payloads matched both their
descriptors and the index. A copy of InRelease with a changed Origin field
was rejected. Sources and keys were retrieved over HTTPS and checked locally.
The package archive and uploader signature roles remain distinct. These
checks cover three source packages and do not constitute a source offer.
[Ubuntu archive verification documentation](https://documentation.ubuntu.com/security/software-integrity/archive-verification/)

## Native linkage and notices

The [native linker job](https://github.com/miik-su/MoonOperator/actions/runs/44920466040)
captured the GNU linker command and read the ELF dynamic and symbol tables
on source `13c0492`. The executable digest matched the executable in its own
Docker build, the independently built image in the Kind job, and the earlier
scan's binary. The image IDs remain distinct. The SHA-256 value is in
[link provenance](link-provenance.json), along with
[link inputs](link-commands.txt), [dynamic dependencies](elf-dynamic.txt)
and [selected symbols](selected-symbols.txt).

| Component | Observation and license |
| --- | --- |
| MoonBit runtime, core, async and YAML | Generated MoonBit code, static runtime and async stub inputs. Existing Apache-2.0 and MIT notices are retained. The runtime upstream attributes some code to musl. [Runtime and attribution](https://github.com/moonbitlang/moonbit-native-runtime#attribution) |
| mimalloc | The executable defines `mi_version` and `mi_free`. The exact SDK's `libmoonbitrun.o` returns 217 from `mi_version`, matching upstream 2.1.7. [MIT license at 2.1.7](https://github.com/microsoft/mimalloc/blob/v2.1.7/LICENSE) |
| simdutf | Defined UTF validation symbols establish inclusion. The upstream offers MIT or Apache-2.0 and the MIT text is bundled. The precise SDK source revision remains open. [Upstream license choice](https://github.com/simdutf/simdutf#license) |
| libbacktrace | The SDK archive appears in the link command. Retained members were not established. The BSD-style license notice from the pinned SDK's header is bundled. |
| GCC and glibc startup | The command includes `crtbeginS.o`, `crtendS.o`, and glibc `Scrt1.o`, `crti.o`, `crtn.o`. Review GCC GPL-3.0-or-later runtime terms and GCC Runtime Library Exception where applicable, and the glibc startup objects under their source terms. The `-lgcc`/ `-lgcc_s` flags alone do not establish retained members. [GCC startup source](https://github.com/gcc-mirror/gcc/blob/releases/gcc-13.3.0/libgcc/crtstuff.c) |
| ELF dependencies | `libc.so.6` is the only reported DT_NEEDED entry. The loader is separate and OpenSSL is loaded at runtime. |

[SDK object digests and allocator version evidence](sdk-runtime.json) record
the inspected, checksum-verified SDK inputs. The license copies are in
[third_party](../../../third_party). This is a scoped binary component review.
Exact source correspondence for all SDK-supplied objects and release-source
coverage for all image packages remain open.

The [native ZIP audit](linux-package.json) and
[image notice verification](notice-verification.json) checked the same ten
files byte for byte, including the three new license copies. The image still
has the same 94 Ubuntu package versions as the preceding scan.

| CI artifact | ID | Verified ZIP SHA-256 |
| --- | ---: | --- |
| native-link-evidence | 14713207874 | `99aa886327eb28e31ae29759008281354bd0095a1efcad497fea0ed52f983394` |
| runtime-distribution-inventory | 14713637413 | `27f70160850456607fa398e5812761eb202334cb043f4410fa5d6ff8bf53ca54` |
| native-observations | 14712673815 | `2c7381b8f4b9d89660a35a0d331fbd8b2afa737a38a3a6a2cf48a0241c918c60` |

## Ubuntu CVE recheck

The [Canonical tracker recheck](ubuntu-cve-recheck.json) maps the 23 original
binary-package findings onto 14 Noble source-package CVE records. Four were
`needed`, ten were `deferred`, and none showed an available released Noble
fix at verification. Package-level findings remain visible. This targeted
recheck does not assess all new advisories or other package ecosystems.

The [new image rescan](rescan.json) returned the identical 23 rows on the
same package versions. Its os-vulnerability-observations artifact (ID
14713677470) has verified ZIP SHA-256
`c12c4c61447de5d7bd6e6a85edb5e527a7e5e5cd7946de499cd7338edfbbf24c`.

On source `13c0492`, the [focused native checks](https://github.com/miik-su/MoonOperator/actions/runs/44920465889),
[native linkage audit](https://github.com/miik-su/MoonOperator/actions/runs/44920466040),
[Kind 1.36.4 and 1.37.0 jobs](https://github.com/miik-su/MoonOperator/actions/runs/44920465849)
and [optional WASM check](https://github.com/miik-su/MoonOperator/actions/runs/44920465842)
all passed. This round used focused tests.
