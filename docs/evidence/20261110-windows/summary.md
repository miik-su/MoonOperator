## MoonOperator native

Status before report upload: **local observation**. GitHub shows the final workflow status. Missing evidence is not a pass.

Dataset: 1000 synthetic objects; platform: Windows; target: native-release.

| Observation | Iterations | Mean (µs/op) |
| --- | ---: | ---: |
| resource_copy_serialize | 1000 | 9.6895 |
| json_parse | 1000 | 12.3292 |
| cache_get_1000_objects | 10000 | 0.65596 |
| cache_label_query_1000_objects | 100 | 1873.411 |
| watch_event_decode | 1000 | 15.063699999999999 |
| queue_add_claim_done | 10000 | 1.50095 |
| moonapp_noop_fake_reconcile | 1000 | 567.3204 |

| Bounded load result | Value |
| --- | ---: |
| duration_ms | 10015 |
| iterations | 496409 |
| objects | 1000 |
| reconcile_failures | 16617 |
| queue_retries | 16617 |
| queue_pending_end | 0 |
| cache_objects_end | 1000 |
| cache_encoded_bytes_end | 107890 |

Single-run timings and a ten-second load observation; RSS is not measured. Download native-observations for inputs, raw results and source provenance.
