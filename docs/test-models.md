# Test models, provenance and interpretation

"Model" here means Kubernetes resource/event/state-machine and fault models.
MoonOperator does not ship AI weights, perform AI inference or depend on a model
provider to decide whether reconciliation is correct.

| Model | Inputs / source | Expected invariant | Actual evidence and limits |
| --- | --- | --- | --- |
| Snapshot admission | runtime/model_test.mbt: missing RV, nonempty continuation token or duplicate key | Preserve old data, mark unready, admit no queue keys and do not start Watch | Focused regression of the custom Source contract |
| API response identity | client/rest_test.mbt and client/pagination_test.mbt: foreign-namespace objects, malformed LIST metadata and duplicate keys across pages | Reject invalid responses and incomplete snapshots | Injected responses cover protocol handling. The Kind workflow exercises the real API |
| Recovery / UID / namespace | Same file: 100 updates with duplicate events, UID recreation, stale delete, 410, authoritative relist; separate east/west Stores | New UID survives old tombstone, complete relist converges, removed key is delivered, other Store stays intact | Synthetic I/O uses the production Source loop; no OS-thread-safety or shared-Store multi-watch claim |
| In-flight event storm | controller/storm_test.mbt: 100 desired changes and a 409 during processing | Final state equals revision 100, one successful write, no lost dirty work, pending=0 | One bounded key with injected conflict; independent concurrency tests cover cooperative worker exclusion |
| Schema / registration | crd/generator_test.mbt and versions_test.mbt | Reject malformed registration/root schema/version and mismatched served schemas | API server still decides complete structural-schema/admission validity |
| Public consumer | Separate examples/consumer module, synthetic ConfigMap annotation | Two reconciles, one update, preserve unrelated annotation, pending=0 | Source-workspace public API smoke; not registry installation or a real cluster |
| Capacity / performance | benchmarks/runtime, benchmarks/queue_scale and tests/memory_profile | Fixed bounded operations and successful required profiles | Short measurements; operation latency, encoded bytes and process/container memory are distinct |
| Authentication / TLS | transport/token_rotation_test.mbt, tests/tls_negative | Reread rotated token after simulated 401; reject wrong CA/hostname | Expired-token response is simulated; no real JWT aging claim; TLS acceptance runs Linux/OpenSSL |
| WASM ABI / faults | examples/wasm_validator and tests/wasm_host/fixtures | Correct scalar result or typed ABI/trap/fuel/memory/deadline failure | Optional Wasmtime CLI, no general JSON guest ABI or full process sandbox |

Inputs are project-authored synthetic JSON and WAT, and follow the root
Apache-2.0 license. Dummy identifiers, tokens, domains and image strings in local
models are not harvested cluster records. External executable/container/license
rights remain separate; see ../LICENSING.md and ../THIRD_PARTY_NOTICES.md.
TLS acceptance certificates/keys are generated ephemerally under ignored _build;
no private keys are committed or intentionally packaged.

Historical raw snapshots under evidence/ retain their original source SHA,
environment and filenames. A previous green run does not imply a newer commit
was retested. Public CI summaries and artifacts include source provenance.
Full regression and 1h/24h synthetic/real-cluster soak remain distinct unexecuted
release gates. No leak-freedom, universal Kubernetes compatibility or production
security guarantee follows from this model set. See test-results.md for data.
