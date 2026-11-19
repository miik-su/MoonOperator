# Maintenance observations · 2026-11-18

Local clean source: `420620c7a0a4fd0c259e5492ddea6b0267edef64`.
Platform: Windows native; MoonBit 0.10.17+d971670cd / moon 0.1.20261023.
Command: `moon run scripts/maintenance-checks.mbtx -- FRESH_OUTPUT_DIRECTORY`.

- windows-targeted.json is the unmodified captured report: 14 selected tests
  passed, independent public consumer passed, actual source archive passed.
- windows-package.json is the unmodified package-audit-report.json produced by
  that run: 278 archive paths, required notices present, no forbidden generated/
  credential-like paths. This is not a content secret scan or publication.
- Both reports record worktree_modified=false. The local source includes the
  deployment guide added after the core maintenance commit; tests do not imply
  hours/day stability, installed-registry compatibility or an OS vulnerability audit.

The consumer uses a local source workspace and in-memory Fake. Its observed
result is two reconciles, one child update, unrelated annotation preserved and
pending=0. The targeted tests use the source implementations and fixed synthetic
state/fault models described in ../../test-models.md. They contain no AI weights.
Project-authored fixtures and reports follow the root Apache-2.0 license;
original third-party notices inside later copyright artifacts keep their licenses.

Linux CI runs for core maintenance source
`83bae3d87db6659bf144f32a6013f5712d48bb21` are separate from this local source.
The subsequent 420620c changes only the deployment document and skipped CI.
Final workflow conclusions and copyright gaps must be read from completed runs;
an implemented workflow or a partial artifact is not a passing result.

## Initial Linux failure and distribution evidence

Source 83bae3d's [native run](https://github.com/miik-su/MoonOperator/actions/runs/44330744245)
passed the model tests and public consumer but failed the archive phase.
linux-initial-failure.json preserves that outcome. Artifact native-observations
14438812468 ZIP SHA-256:
`af3b02dc3325e29ac24c03f6263ff38d65e38a8cb000ab93b704a3125a7364fb`.
The initial wrapper retained only ShellError.CommandFailed. Follow-up code uses
a ZIP-capable listing tool (bsdtar or unzip) and prints inner error output before
propagating failures. No initial failure is relabeled as a pass.

The same source's image job actually collected 94 installed OS packages and
all 94 available copyright texts, with missing_copyright=[]. The immutable image
ID and package versions are retained in container-inventory-83bae3d.json and
container-packages-83bae3d.tsv. Full copyright/common-license/project-notice
payloads: runtime-distribution-inventory artifact 14438318848 in
[Kind workflow 44330744537](https://github.com/miik-su/MoonOperator/actions/runs/44330744537),
ZIP SHA-256 `d6791d1b647308f6dde2d7d38f7ae8c696d341407c2c0122770268a87b0c132a`.
Availability of these texts is not a legal clearance, complete linkage SBOM,
source-offer review or vulnerability scan. The source-module SBOM remains separate.

## Corrected Linux native result

Source `6235a5f5a81fa0b5e197532565a644aa2d2cbde3` passed
[native run 44331915192](https://github.com/miik-su/MoonOperator/actions/runs/44331915192).
Artifact native-observations 14438319725, ZIP SHA-256:
`16f2e30f889e7d8d993ed135732aa2627e96dd9b0cbb27482c462449df609a18`.
linux-targeted.json, linux-package.json and linux-tls-negative.json are unchanged
payloads with shortened filenames. The maintenance phases passed, including the
ZIP check using unzip; the normal native job also completed its existing focused
security/recovery/benchmark/ten-second observation and source-advisory checks.
This is still not a full native regression or long-duration stability run.

Same-source image/memory evidence in Kind run 44331915265:

| Artifact | ID | ZIP SHA-256 | Permanent extraction |
| --- | --- | --- | --- |
| runtime-distribution-inventory | 14440570344 | `c3a815a29df7ec77f624044af0a22722ea4dbabb1753853f96c379f6a471eca7` | container-inventory.json, container-packages.tsv |
| memory-observations | 14440475974 | `0c07bddcf23eafdfff3b7487f30eb4a0257c48ac64e9de9890f4d3ad3b744055` | memory.json, memory-summary.md |

The production image ID is recorded in container-inventory.json. The same-source inventory
again contains 94 packages with no missing copyright text. The downloadable
artifact also retains the actual copyright/common-license/project-notice files.
All six fresh-container memory cases completed with exit=0 and OOMKilled=false.
Generic 10k at 128 MiB remains near its limit, not a recommended headroom profile.
The memory executable measures cache replacement, not the complete live operator.

The [Kind workflow](https://github.com/miik-su/MoonOperator/actions/runs/44331915265)
completed successfully, including MoonApp lifecycle, real API access, scoped
ownership admission, Calico allow/deny/recovery and the independent memory job.
The kind-acceptance artifact 14439019722 has ZIP SHA-256
`82fcc3dc35246bef079aafb772da3fe59420dc5054b42027b3f96286ddb402a5`.
The original JSON payloads and rendered summary are retained with shortened
filenames. The [WASM workflow](https://github.com/miik-su/MoonOperator/actions/runs/44331915170)
also passed on the same source.
