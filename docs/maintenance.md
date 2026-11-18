# Maintenance contract and open gates · 2026-11-18

The project remains a MoonBit Kubernetes Operator framework. Maintenance favors
correctness, recovery, public API usability, bounded diagnostics and accurate
distribution evidence. It does not expand the release into HA, conversion
webhooks or arbitrary untrusted plugin hosting. No registration form or personal
application information is maintained in this repository.

| Work item | Current disposition | Completion evidence / next action |
| --- | --- | --- |
| Complete custom-source snapshot admission | Implemented | runtime/model_test.mbt preserves data and rejects missing RV/unfinished pagination before publication |
| Duplicate/recreation/410 fault model | Implemented | Same test verifies final UID/state, disappeared-key delivery and independent namespace Stores |
| In-flight conflict and event storm | Implemented | controller/storm_test.mbt checks final revision and actual write count |
| Bounded error/latency diagnostics | Implemented | Fixed exception classes and cumulative buckets; observability/metrics_test.mbt; timing contract in observability.md |
| CRD/RBAC usability | Improved | Naming/root-schema/all-version guards and CRD regressions; real API remains authoritative |
| Separate public API consumer | Implemented | examples/consumer uses a local workspace, runs two idempotent attempts and preserves metadata |
| Test models and licenses | Documented | test-models.md and ../LICENSING.md identify synthetic inputs and artifact-specific rights |
| Source archive integrity | Implemented | package-audit.mbtx checks actual ZIP paths and required license files; not a content secret scan |
| Container distribution evidence | Implemented collection, execution evidence tracked separately | distribution-inventory.mbtx records image ID, dpkg versions, available copyright/common-license files and missing texts |
| Complete distribution clearance | Open | Review missing copyrights, source offers, full linkage SBOM and OS/runtime vulnerability coverage |
| Full native regression | Available, not executed in this maintenance pass | Manual release-validation workflow; targeted testing was explicitly requested |
| 1h/24h synthetic and real-cluster soak | Open | Manual entry points exist; no long-duration success or leak-freedom claim |
| Multi-version Kubernetes/CNI/auth | Open | Dated 1.37.0/Calico 3.33.0 evidence exists; additional versions/providers require actual execution |
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
