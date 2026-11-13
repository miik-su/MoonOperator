# Delivery status — 2026-11-13

Core and example control loops are implemented with focused local and public CI
verification. The original multi-stage implementation plan is reflected in
roadmap.md; compatibility.md states the supported subset for each capability.

Latest bounded evidence is archived in
[the November 13 follow-up](review-followup-20261113.md) and
[permanent Linux snapshots](evidence/20261113-linux/README.md).
Final code source 31d7390 passed
[native](https://github.com/miik-su/MoonOperator/actions/runs/43416752124),
[WASM](https://github.com/miik-su/MoonOperator/actions/runs/43416752053) and
[Kind](https://github.com/miik-su/MoonOperator/actions/runs/43416752043), including
independent six-case memory observations, Calico enforcement and scoped
ownership-adoption admission. [Same-source raw reports](evidence/20261113-linux/31d7390/README.md)
are permanent. Earlier optional-adoption probes failed because the test assumed
an admission plugin that Kubernetes 1.37 does not enable by default; the final
acceptance explicitly enables it and proves both denied and permitted paths.

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
investigation, broader Kubernetes/version/auth matrices, package namespace/account
confirmation and Mooncakes publication. Current module namespace remains
`mik1e80/moonoperator`, independently of the GitHub repository owner `miik-su`.
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
