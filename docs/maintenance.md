# Maintenance contract and open gates · 2026-11-21

The project remains a MoonBit Kubernetes Operator framework. Maintenance favors
correctness, recovery, public API usability, bounded diagnostics and accurate
distribution evidence. It does not expand the release into HA, conversion
webhooks or arbitrary untrusted plugin hosting. No registration form or personal
application information is maintained in this repository.

| Work item | Current disposition | Completion evidence / next action |
| --- | --- | --- |
| Complete custom-source snapshot admission | Implemented | runtime/model_test.mbt preserves data and rejects missing RV/unfinished pagination before publication |
| Client response and LIST integrity | Implemented | Typed identity, malformed LIST metadata and duplicate-key handling verified in the November 21 focused checks |
| Watch resource recreation | Implemented | Both change predicates admit a new UID with the same resource version or generation |
| Duplicate/recreation/410 fault model | Implemented | runtime/model_test.mbt verifies final UID/state, disappeared-key delivery and independent namespace Stores |
| In-flight conflict and event storm | Implemented | controller/storm_test.mbt checks final revision and actual write count |
| Bounded error/latency diagnostics | Implemented | Fixed exception classes and cumulative buckets; observability/metrics_test.mbt; timing contract in observability.md |
| CRD/RBAC usability | Improved | Naming/root-schema/all-version guards and CRD regressions; real API remains authoritative |
| Separate public API consumer | Implemented | examples/consumer uses a local workspace, runs two idempotent attempts and preserves metadata |
| Test models and licenses | Documented | test-models.md and ../LICENSING.md identify synthetic inputs and artifact-specific rights |
| Source archive integrity | Verified | Actual ZIP paths and ten notice payloads checked. Bundled async/YAML license texts match resolved modules |
| Container distribution evidence | Verified for the recorded amd64 image | Installed package/source versions, 94 copyright records, ten matching notice files, executable SHA-256 and native linkage. [Evidence](evidence/20261121-redistribution/README.md) |
| Experimental Wasmtime advisory check | Updated | Wasmtime 50.0.3 passed the exact-version OSV query and ten-case host probe. See [archived evidence](evidence/20261121-protocol/README.md) |
| Distribution and vulnerability coverage | Partial | All installed Ubuntu package sources mapped and downloaded. A byte-matched map confirms the selected archive members. Production exports one filesystem layer and the verified Ubuntu sources are bundled locally. Exact SDK revisions and public delivery for a formal binary release remain open |
| Full native regression | Available, not executed in this maintenance pass | Manual release-validation workflow; targeted testing was explicitly requested |
| 1h/24h synthetic and real-cluster soak | Open | Manual entry points exist; no long-duration success or leak-freedom claim |
| Multi-version Kubernetes/CNI/auth | Partially verified | Kind 1.36.4 and 1.37.0 with Calico 3.33.0 passed. Other versions, CNIs and identity providers remain open |
| Mooncakes / formal release | Open | Namespace authentication, published-version clean consumer and release gates must precede publication |

For each meaningful change, record the problem, resulting behavior, affected
public API/docs, narrow verification and remaining limitations. Keep separate
substantive commits. Issue/PR labels may distinguish bug/security/reliability/
test/documentation/compatibility/release; labels and commit counts are not quality
evidence by themselves. Review dependency changes against original sources and
update source/image inventory and notices together.

Before release, run the manually selected full regression and longer probes,
verify the real deployment from clean instructions, inspect the actual archive,
and test the published package in a clean module without workspace overrides.
Do not infer a pass from a configured workflow or an older source SHA. Preserve
failed observations and dated successful raw snapshots under evidence/.
