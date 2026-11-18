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
installed dpkg names/versions and available copyright texts/common licenses into
a CI artifact. Missing texts are reported explicitly; collecting files is not
an automated legal or vulnerability clearance. A redistributor must review
remaining source-offer, notice and license obligations for its actual artifact.
No complete distribution SBOM or OS vulnerability audit has yet been claimed.

Architecture references client-go and controller-runtime are Apache-2.0; their
Go implementation is not copied or vendored here. Sources and reference scope:
[client-go license](https://github.com/kubernetes/client-go/blob/v0.37.0/LICENSE),
[controller-runtime license](https://github.com/kubernetes-sigs/controller-runtime/blob/v0.25.0/LICENSE),
[project reference survey](docs/ecosystem-comparison.md).
Dependency/runtime-specific licenses are listed in THIRD_PARTY_NOTICES.md.
