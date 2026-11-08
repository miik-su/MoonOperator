# Delivery status — 2026-11-08

Core and example control loops are implemented with focused local and public CI
verification. The original multi-stage implementation plan is reflected in
roadmap.md; compatibility.md states the supported subset for each capability.

Recorded public evidence:

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

Remaining release gates are explicit: long-duration (hours/days) soak and RSS
measurement, broader Kubernetes/version/auth matrices, package namespace/account
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
See review-followup-20261108.md for the current review changes and API migration.
