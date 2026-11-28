# One-hour Linux native synthetic soak

[GitHub Actions run 46120453967](https://github.com/miik-su/MoonOperator/actions/runs/46120453967)
passed for source `98121f4675d87a8e5a5266fe50f3a8dfab0380fc` on an Ubuntu
24.04 GitHub runner with MoonBit 0.10.17+d971670cd. The full-native job was
skipped. Subsequent compatibility changes before the documentation update
touched only Kind configuration and workflow files.

| Measurement | Observed |
| --- | --- |
| Workload | 1,000 synthetic resources, duplicate enqueue on every iteration, periodic injected transport failures |
| Elapsed time | 3,600,002 ms |
| Iterations | 530,081,177 |
| Reconciliations | 512,981,794 successes and 17,100,000 injected failures |
| Retry handling | 17,100,000 recorded retries |
| Final state after drain | 0 pending keys, 1,000 cache objects, 110,890 encoded cache bytes |
| Linux RSS | 61 samples; 3,540 KiB at startup, 5,004 KiB at minute one, 5,484 KiB at minute 30, and 5,976 KiB at the end |
| Process high-water mark | 5,976 KiB |

The process exited with code 0. After the first minute, sampled RSS increased
by 972 KiB over the remainder of the hour. The measurements cover Linux
process RSS for this run. The workload uses synthetic I/O and advances the
queue clock per iteration, so its operation counts characterize this model.
A live-cluster soak, GC live-heap profiling and a 24-hour run remain open.

The downloaded artifact (ID `15254789526`) matched GitHub's ZIP SHA-256
`9bebbeb6160f277121a631c74771bb1657645693809326067d865e3fd8386dcb`. Retained files include the
[input](soak-input.json), [full report](soak-report.json),
[progress snapshots](soak-progress-report.json) and
[runner and toolchain metadata](release-validation-report.json).
