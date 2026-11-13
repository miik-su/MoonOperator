# Review follow-up · 2026-11-13

Review baseline: `556882744e7989920a7bf30a70ab7935d54df00b`.
The repository is `miik-su/MoonOperator`; the Mooncakes module namespace remains
`mik1e80/moonoperator` pending account confirmation. No package was published.

## Implemented changes and evidence

| Review finding | Change | Evidence / limit |
| --- | --- | --- |
| Memory job failed before cluster acceptance | Probe emits stdout without writing the read-only root; every case retains stderr, timeout, exit/OOM state and observation | [Before/after raw reports](evidence/20261113-linux/README.md); original exit 1 was not OOM |
| Coupled jobs hid independent results | Images are shared by separate memory and cluster jobs | Both succeeded for 695c58c; later revisions retain independent status |
| RBAC failure omitted the actual operation | Fully qualified groups and explicit finalizers subresource; expected/actual records | [Six real authorization decisions](evidence/20261113-linux/rbac.json) |
| NetworkPolicy was only generated | Checksum-verified Calico plus real traffic allow/deny/recovery | [Policy result](evidence/20261113-linux/network-policy.json), Kubernetes 1.37.0 only |
| Authentication negative paths lacked acceptance | Local real-socket token rotation after HTTP 401; Linux trust/hostname rejection | [Native CI](https://github.com/miik-su/MoonOperator/actions/runs/43366355163); 401 is simulated expiry, not real JWT aging |
| Optional adoption needs additional permission | Separate default-refusal and explicit deny/allow fixtures; extra delete rights restricted to named test resources | Latest probe is still under investigation; no passing adoption claim yet |
| Full regression / long soak evidence absent | Manual-only workflow, recorded counts/toolchain/source; Int64 long-run counters and bounded minute RSS sampling | Entry points added; full regression and one-hour/24-hour runs remain unexecuted |

The normal example Role retains `update moonapps/finalizers`, needed when setting
`blockOwnerDeletion=true`. It does not gain dependent delete permissions merely
to enable optional adoption. Kubernetes admission distinguishes changing a
dependent's owner references from setting blocking ownership on an owner:
[upstream admission implementation](https://github.com/kubernetes/kubernetes/blob/v1.37.0/plugin/pkg/admission/gc/gc_admission.go).

## Public functionality and data boundaries

MoonOperator provides MoonBit dynamic resource/client, watch/cache/workqueue,
controller lifecycle and CRD/RBAC generation with a MoonApp example. It runs as
a single native replica on one cooperative event loop. It does not implement
HA/Lease election, admission/conversion webhooks, OS-thread-safe shared stores,
or Pod readiness observation. ResourcesApplied is not Pod Ready; the example's
Ready condition remains Unknown without workload readiness evidence.

The experimental WASM host executes a bounded scalar guest ABI with Wasmtime;
it is not a general Kubernetes JSON guest runtime. Multiple served CRD versions
must share the supported schema; no conversion is performed.

Test "models" are synthetic Kubernetes JSON, fake reconciliation faults and
project-authored WAT fixtures, not trained AI weights or downloaded datasets.
Project-authored examples and fixtures follow the repository Apache-2.0 license;
third-party runtime/tool/dependency licenses are recorded separately in NOTICE,
THIRD_PARTY_NOTICES.md and the source dependency inventory. Source-only SBOM and
an installed OS package list do not constitute a full image/binary license audit.
No personal registration details belong in these public reports.

## Remaining release evidence

Keep full native regression, one-hour/24-hour stability and leak investigation,
multiple Kubernetes versions/auth providers, real token expiration, WASM host
process RSS, complete distribution SBOM/license review and package namespace
confirmation open. Short successful observations establish only their stated
input and environment. Manual workflow availability is not execution evidence.
