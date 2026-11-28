# Soak RSS investigation and one-hour live Kind verification

The previous [Linux synthetic soak](../20261128-linux-soak/README.md) retained
every parsed sample and rewrote the whole progress document every minute. The
follow-up writes one JSON line per sample and assembles the final sample array
after the last RSS measurement. The synthetic workload and MoonOperator library
code were unchanged across the three runs below.

## Linux native RSS

All values are KiB from Linux `/proc/self/status` on Ubuntu 24.04 GitHub runners.
The runs used the same pinned MoonBit SDK, with fresh runners for each job. The
system profile changes `MOONBIT_ALLOCATOR` while keeping the same UTF setup.

| Profile | Source and run | Iterations | First minute | End | Change after first minute |
| --- | --- | ---: | ---: | ---: | ---: |
| Default allocator, original report writer | [`98121f4`](https://github.com/miik-su/MoonOperator/actions/runs/46120453967) | 530,081,177 | 5,004 | 5,976 | +972 |
| Default allocator, streamed samples | [`cd4d2ce`](https://github.com/miik-su/MoonOperator/actions/runs/46152445508) | 536,561,747 | 5,024 | 5,152 | +128 |
| System allocator, streamed samples | [`5f3d7cb`](https://github.com/miik-su/MoonOperator/actions/runs/46153076984) | 458,596,483 | 4,972 | 4,988 | +16 |

The post-warmup increase fell by 844 KiB with streamed sampling at the default
allocator, at a slightly higher iteration count. This identifies the progress
writer as the main contributor observed in the original comparison. The
remaining increase was smaller with the system allocator. The default profile
also produced [mimalloc statistics](default/allocator-stats.txt) recording
allocator reservations and purges. Those statistics are separate from the
minute-by-minute Linux process RSS. Runner-to-runner variation and the
relative contribution of retained sample objects versus allocator pages
remain unmeasured. No live-heap profile was performed.

Both follow-up runs completed more than one hour with 61 samples. Both exercised
injected transport failures and delayed retries, ended with zero pending keys
and held 1,000 cache objects. The full-native jobs were skipped.

## Real Kind

[Kind run 46152463638](https://github.com/miik-su/MoonOperator/actions/runs/46152463638/job/141001849810)
tested Kubernetes 1.37.0 with Calico 3.33.0 at `cd4d2ce9c9bd441dc8d67fe5e7e3bfe20e5e5756`.
The live probe ran 3,600,381 ms over 61 checkpoints. At each checkpoint it
alternated the MoonApp replica count, verified the Deployment spec converged
and the observed generation advanced, and checked that the external status
field and condition survived. The same operator Pod remained ready at every
checkpoint with zero container restarts. The longest combined patch and
verification step was 372 ms. Kind also passed its existing lifecycle,
TLS/API, RBAC and network-policy checks. This probe sampled Pod health and
reconciliation, and did not measure operator RSS.

## Retained artifacts

Every downloaded ZIP matched the GitHub artifact SHA-256.

| Profile | Artifact ID | SHA-256 | Reports |
| --- | --- | --- | --- |
| Linux default | 15267719201 | `ee3fffdcb13313331905e7aa53760158b7b214d0d38ffd117cbf31ba9c6c010d` | [Soak](default/soak-report.json), [journal](default/soak-progress.jsonl) |
| Linux system | 15268162473 | `25661b0620ded7d4709247575fe0fa6d8c316af2c1eaa33173f8cbc6dcd1610f` | [Soak](system/soak-report.json), [journal](system/soak-progress.jsonl) |
| Kind live | 15269095181 | `8c76797f3d847442165c2bb1929cb70a6c98ab22078fcbcc4fe84a197d97bb8a` | [Soak](kind/kind-soak-report.json), [lifecycle](kind/kind-e2e-report.json) |
