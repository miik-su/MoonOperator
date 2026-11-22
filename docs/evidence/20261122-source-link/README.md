# Ubuntu corresponding sources and linker selection · 2026-11-22

## Installed Ubuntu package sources

The [binary-to-source table](../20261121-container/binary-source-packages.tsv)
describes the 94 installed system packages of the scanned amd64 image.
All 94 entries mapped to 67 exact source package versions in `main` in the
fixed Ubuntu snapshot `20261120T000000Z`. The authenticated indexes supplied
23 versions from noble, 18 from noble-updates and 26 from noble-security.

The three InRelease signatures were checked against Canonical's published
archive signing fingerprint. Each compressed source index matched the hash
and size in its signed InRelease content. All 212 files listed for the 67
packages were downloaded locally and matched the signed index's SHA-256 and
size. The 67 .dsc files matched the exact package names and versions, and each
descriptor's SHA-256 list matched its source files in the authenticated index.
The [manifest](ubuntu-source-manifest.json) records the image, repository
identifiers, source paths, sizes and hashes.

The independent uploader signatures for glibc, OpenSSL and ca-certificates
were [verified in the previous review](../20261121-redistribution/ubuntu-source-signatures.json).
For this wider set, authenticity is from the archive signature path.
The downloaded archives remain in the local audit workspace. The manifest
covers the installed dpkg versions of the recorded image. Corresponding
sources for superseded lower-layer packages and SDK-embedded components
remain separate release work. This record does not establish a public
source offer. [Ubuntu archive verification](https://documentation.ubuntu.com/security/software-integrity/archive-verification/)

## Native archive member selection

The [linker audit](https://github.com/miik-su/MoonOperator/actions/runs/44985782839)
used source `79c331c`. It built the normal production executable and generated
a GNU link map in a second build. The two executables matched each other and
the installed file in the audited image by SHA-256. The digest also matches
the executable from the preceding image scan.
[Link provenance](link-provenance.json) and [map selection](archive-selection.txt)
record 19 distinct selected archive members.

- `libbacktrace.a` was passed to the linker. Zero members of that archive
  were selected. `libruntime.a(runtime-backtrace.o)` is a separate selected
  MoonBit runtime member.
- `libruntime.a(simdutf.o)` and `libruntime.a(moonbit_simdutf.o)` were selected.
  The SDK's precise simdutf source revision is still unverified.
- The linker selected `libgcc.a(_popcountsi2.o)` and
  `libc_nonshared.a(atexit.oS)`. These are compiler or libc build-time inputs.
  Review the GCC Runtime Library Exception and glibc source terms for the
  exact builder packages when preparing a release.
  [GCC library terms](https://gcc.gnu.org/onlinedocs/gcc-13.4.0/libstdc++/manual/manual/license.html)
  [GNU link-map definition](https://sourceware.org/binutils/docs/ld/Options.html)

The full map, link commands and ELF evidence are in native-link-evidence,
artifact ID 14739657070. Its verified ZIP SHA-256 is
`43cec33ee3b03312575a1b0359c66e943d9237a1bba5933ecf18731cbb5f5832`.

## CVE and history-scan follow-up

The [Canonical recheck](ubuntu-cve-recheck.json) found four Noble source-package
records still marked needed and ten deferred. It found no released Noble fix
for the 14 rechecked advisories.

The previous history scan flagged two published Ubuntu OpenPGP fingerprints
as generic API keys. Only those two exact matches are excluded through
`.gitleaksignore`. The same full-history scan passed locally and in the
[focused native workflow](https://github.com/miik-su/MoonOperator/actions/runs/44985782829).
