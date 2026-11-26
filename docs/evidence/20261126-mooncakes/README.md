# Controller retry and Mooncakes preparation

Source commit `3db0d0176afe3a8716de6691a9feebba93306dd4` updates the worker
test to measure the reconciliation step before checking the retry deadline.
The worker still schedules backoff from completion. The test checks that the
item cannot run at 99 ms and can run by the measured step duration plus the
100 ms base delay.

| Check | Observed result |
| --- | --- |
| Native module check and interface generation | Passed. Generated interfaces were unchanged. |
| Worker retry test on Windows native | 15 consecutive passes. |
| Controller package on Windows native | 8 tests passed. |
| [Focused native CI](https://github.com/miik-su/MoonOperator/actions/runs/45755636817) | Passed. The step containing `controller/worker_test.mbt` passed all 8 selected tests. |
| Packaging and extracted-package check | Passed. The archive contained the root license, notices, module manifest and updated test. |
| [Independent consumer](source-archive-consumer.json) | Native check and run passed against the extracted archive via a temporary workspace. The second reconciliation produced no extra write and preserved an unrelated annotation. |

The inspected source ZIP was `miik-su-moonoperator-0.1.3.zip` with SHA-256
`52b85326a56deb39f6afe3b7d735ee6e37578c4a005d1490e10d43c8f8089d95`.

Mooncakes accepted the extracted-package build check, then refused publication
with HTTP 403 because the authenticated username was `mik1e80` and the module
namespace is `miik-su`. The exact-version public registry query returned
HTTP 404. Registry publication and a consumer run without a source override
are pending authentication as `miik-su`. The GitHub v0.1.3 release remains a
draft with five uploaded assets.
