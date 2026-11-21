# Delivery status — 2026-11-21

Core and example control loops are implemented with focused local and public CI
verification. The original multi-stage implementation plan is reflected in
roadmap.md; compatibility.md states the supported subset for each capability.

Earlier bounded evidence is archived in
[the November 13 follow-up](review-followup-20261113.md) and
[permanent Linux snapshots](evidence/20261113-linux/README.md).
Earlier code source 31d7390 passed
[native](https://github.com/miik-su/MoonOperator/actions/runs/43416752124),
[WASM](https://github.com/miik-su/MoonOperator/actions/runs/43416752053) and
[Kind](https://github.com/miik-su/MoonOperator/actions/runs/43416752043), including
independent six-case memory observations, Calico enforcement and scoped
ownership-adoption admission. [Same-source raw reports](evidence/20261113-linux/31d7390/README.md)
are permanent. Earlier optional-adoption probes failed because the test assumed
an admission plugin that Kubernetes 1.37 does not enable by default; the final
acceptance explicitly enables it and proves both denied and permitted paths.

Namespace-migration source 3572f1b passed
[native](https://github.com/miik-su/MoonOperator/actions/runs/43599908948),
[Kind](https://github.com/miik-su/MoonOperator/actions/runs/43599908952) and
[WASM](https://github.com/miik-su/MoonOperator/actions/runs/43599908961).
The subsequent 70c2b07 was README-only and skipped CI. Neither older source is
presented as execution evidence for new November 18 maintenance code.
Maintenance source `6235a5f` passed
[native](https://github.com/miik-su/MoonOperator/actions/runs/44331915192),
[Kind](https://github.com/miik-su/MoonOperator/actions/runs/44331915265) and
[WASM](https://github.com/miik-su/MoonOperator/actions/runs/44331915170).
See [maintenance evidence](evidence/20261118-maintenance/README.md) for original
reports, the initial archive failure, and the exact scope of each result.

Protocol hardening source `39f6383` passed [Kind acceptance](https://github.com/miik-su/MoonOperator/actions/runs/44730507863).
The [native job](https://github.com/miik-su/MoonOperator/actions/runs/44730507770)
passed the test stages and failed the OSV advisory gate for the older Wasmtime
50.0.1 pin. The optional runtime was updated to
[50.0.3](https://github.com/bytecodealliance/wasmtime/releases/tag/v50.0.3).
The local OSV query for that exact crates.io version returned no advisory IDs.

On source `457c794`, the [focused Linux native workflow](https://github.com/miik-su/MoonOperator/actions/runs/44881119471)
[experimental WASM probe](https://github.com/miik-su/MoonOperator/actions/runs/44881119458),
and [Kind acceptance](https://github.com/miik-su/MoonOperator/actions/runs/44881119467)
all passed. [Protocol and Wasmtime evidence](evidence/20261121-protocol/README.md)
records the test scope, original reports and archive digests.

Collection-scope and archive-notice revision `7c16596` passed
[native](https://github.com/miik-su/MoonOperator/actions/runs/44882516711),
[Kind](https://github.com/miik-su/MoonOperator/actions/runs/44882516781) and
[WASM](https://github.com/miik-su/MoonOperator/actions/runs/44882516742).
[Same-source Windows and CI evidence](evidence/20261121-scope-license/README.md)
records 16 targeted models on each native host, package notice bytes on both
archive readers, and the Kubernetes/Calico versions actually exercised.

Container and compatibility revision `471a658` passed both pinned Kind jobs,
focused native checks and the optional WASM probe. The production image includes
the Ubuntu glibc fix for USN-9065-1. [Image security and compatibility evidence](evidence/20261121-container/README.md)
records the OS scan, remaining package findings, corresponding source checks and
successful Kubernetes 1.36.4 and 1.37.0 acceptance with Calico 3.33.0.

Redistribution revision `13c0492` passed the native link audit, image and source
ZIP notice verification, and both pinned Kind jobs. The
[distribution review evidence](evidence/20261121-redistribution/README.md)
verifies three exact Ubuntu source signatures and retains the vendor recheck
for all 14 previous CVEs.

Historical public evidence:

- [Linux native checks](https://github.com/miik-su/MoonOperator/actions/runs/42444225315)
  passed for 3313b41.
- [Kind MoonApp acceptance](https://github.com/miik-su/MoonOperator/actions/runs/42444225161)
  passed for 3313b41: create/update, owned Deployment/Service, drift repair,
  restart recovery and garbage collection under the generated Role.
- [Linux WASM probe](https://github.com/miik-su/MoonOperator/actions/runs/42444225190)
  passed for 3313b41: actual compiled MoonBit guest and bounded Wasmtime 50.0.1.
- [Expanded real-API Client and MoonApp acceptance](https://github.com/miik-su/MoonOperator/actions/runs/42445725470)
  passed for 704ac68: in-cluster CA/token, actual Client CRUD, merge PATCH,
  paginated snapshots, stale-update 409, forbidden namespace 403, live watch and
  the MoonApp lifecycle. Its first run exposed omitted TypeMeta in built-in LIST
  items, fixed with a regression before this successful rerun.
- Windows fixed-data observations and a 10-second fault/duplicate load run are
  retained under evidence/. No full test suite was run.
- `moon package` succeeds offline and produces the 0.1.0 source archive under
  `_build/publish`. No package has been published to Mooncakes.

Remaining release gates are explicit: long-duration (hours/days) soak and leak
investigation, additional Kubernetes/CNI/auth matrices, package namespace/account
confirmation and Mooncakes publication. The current module namespace is
`miik-su/moonoperator`, migrated from `mik1e80/moonoperator` on November 14.
Internal imports, generated interfaces and the current source SBOM use the new
name. Historical raw observations keep their original source identity. Selecting
this namespace does not establish Mooncakes authentication or publication rights.
HA/Lease, admission/conversion webhooks and a general JSON guest ABI are outside
this single-replica release scope. Scalar Wasmtime hosting remains experimental.

The native Docker image can be built after
`moon build cmd/moonapp --target native --release`; install CRD/RBAC
using cmd/manifests and config/operator.yaml in the same namespace. CI creates
and deletes only the explicitly named disposable Kind cluster.

Default Docker builds select the production stage; it excludes client-probe.
The separate acceptance stage requires a release build of tests/cluster_client.
Ubuntu is digest-pinned and runtime APT packages use a dated archive snapshot.
CI retains the exact installed package list alongside Kind version evidence.
Short Linux RSS observations now cover six fresh read-only containers at
128/256/512 MiB. They are not a long-duration memory guarantee. Full regression
and longer soak have manual entry points and were not run under this task's
focused-testing constraint. See review-followup-20261113.md for current findings
and review-followup-20261108.md for earlier API migration.
