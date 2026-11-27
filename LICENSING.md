# Licensing and distribution boundaries

Project-authored MoonBit source, scripts, documentation, examples, synthetic
resource/event fixtures and WAT fault fixtures use the root Apache-2.0 LICENSE
unless a file explicitly states otherwise. No trained AI model weights or
third-party model datasets are shipped. Generated `.mbti` files describe the
project's APIs; generation does not grant rights to unrelated upstream content.
Existing third-party notices and license texts keep their own attribution.

LICENSE is the governing license. README, security guidance and example limits
describe capabilities and deployment responsibilities; they do not add a
noncommercial restriction, contest-only restriction, mandatory CLA, transfer of
copyright, guaranteed security certification or service-level commitment.
Contributions intentionally submitted for inclusion are handled under Apache-2.0
section 5 unless explicitly stated otherwise. Contributor rights must be held
or authorized. AI assistance does not establish provenance or ownership by itself.
Apache-2.0's warranty, liability and trademark provisions remain in LICENSE.
See [the official text](https://www.apache.org/licenses/LICENSE-2.0).

| Artifact | Coverage and required review |
| --- | --- |
| Source archive | Root LICENSE/NOTICE, dependency notices and synthetic-fixture provenance; inspect the packaged file list before release |
| Native MoonOperator binary | Preserve project and linked MoonBit/core/async notices; platform TLS and system library obligations depend on the actual build |
| Production container | Project notices are copied into /usr/share/doc/moonoperator; installed OS copyrights/common license texts remain separate from the source license |
| Acceptance container | Includes additional probes and fixtures; not the production image |
| Wasmtime executable | Optional external installation, Apache-2.0 WITH LLVM-exception; its own bundled licenses and dependencies govern redistribution |
| Referenced workload images | External image licenses apply independently; no assertion that Apache-2.0 relicenses their contents |

The source CycloneDX inventory covers only resolved Mooncakes modules.
`scripts/distribution-inventory.mbtx` collects immutable production image ID,
installed binary and source package versions, available copyright texts,
common licenses, and the production executable's digest and startup linkage
into CI evidence. It compares the image's required project and bundled notice
files with the checkout. An independent scan records installed Ubuntu package
findings for that built image. Remaining source and notice obligations, static
and runtime-loaded dependencies, and scanner coverage are described in the
[container security and redistribution guide](docs/container-distribution.md).
The source ZIP audit requires Windows bsdtar or unzip on Linux/macOS; the Linux
CI setup explicitly installs unzip. The audit checks actual ZIP paths, requires
each notice exactly once, compares its bytes with the checkout, and verifies
the bundled async and YAML licenses against the resolved Mooncakes copies.
The MoonBit core notice was also compared with the installed pinned core license
in the [local release evidence](docs/evidence/20261121-scope-license/README.md).

For the public Linux amd64 v0.1.2 image, use the
[release manifest](docs/evidence/20261125-v0.1.2/release-manifest.json) to match
the binary and both corresponding source archives to the release.
The [public verification record](docs/evidence/20261125-v0.1.2/README.md#public-release-acceptance)
records archive checksums, Ubuntu source verification and the image rebuild.
The image's dated package scan covers the package records in that artifact.
The [linkage and distribution evidence](docs/evidence/20261123-release/README.md)
records components considered separately from the installed package scan.

Architecture references client-go and controller-runtime are Apache-2.0; their
Go implementation is not copied or vendored here. Sources and reference scope:
[client-go license](https://github.com/kubernetes/client-go/blob/v0.37.0/LICENSE),
[controller-runtime license](https://github.com/kubernetes-sigs/controller-runtime/blob/v0.25.0/LICENSE),
[project reference survey](docs/ecosystem-comparison.md).
Dependency/runtime-specific licenses are listed in THIRD_PARTY_NOTICES.md.
