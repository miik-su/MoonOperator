# Kind compatibility across Kubernetes 1.35–1.37

The [retest](https://github.com/miik-su/MoonOperator/actions/runs/46121168737)
ran against source `316132e8253ad7de666cc7ed819dc7c6302806b7` on Ubuntu 24.04
amd64 with Kind v0.33.0 and Calico 3.33.0. All three jobs checked the actual API
server version and verified the ownership admission flag before running probes.

| Kubernetes | Job | Artifact ID | Verified ZIP SHA-256 | Reports |
| --- | --- | --- | --- | --- |
| v1.35.8 | [Passed](https://github.com/miik-su/MoonOperator/actions/runs/46121168737/job/140905780191) | 15253502867 | `e68eeb971483729a0789e51f8cfb4abac279b18e9842e528890baeae94c8870e` | [MoonApp](v1.35.8/kind-e2e-report.json), [adoption](v1.35.8/adoption-report.json), [network](v1.35.8/network-policy-report.json) |
| v1.36.4 | [Passed](https://github.com/miik-su/MoonOperator/actions/runs/46121168737/job/140905780382) | 15253408002 | `a797ef73c9c3dcc66b09ca435f1966406c067f20b35ee118aac3f4c3368ac634` | [MoonApp](v1.36.4/kind-e2e-report.json), [adoption](v1.36.4/adoption-report.json), [network](v1.36.4/network-policy-report.json) |
| v1.37.0 | [Passed](https://github.com/miik-su/MoonOperator/actions/runs/46121168737/job/140905780400) | 15253868380 | `73e72e660257d4e3fdf423deb5d77217c01a36016ecdaadd3fcf0cc576347c70` | [MoonApp](v1.37.0/kind-e2e-report.json), [adoption](v1.37.0/adoption-report.json), [network](v1.37.0/network-policy-report.json) |

The [first 1.35.8 run](https://github.com/miik-su/MoonOperator/actions/runs/46120531200/job/140903827361)
failed when Kubernetes accepted the negative adoption fixture. Kind v0.33.0
uses kubeadm v1beta3 for Kubernetes 1.35 and v1beta4 for 1.36 and later. The
Kind configuration previously applied the admission patch only to v1beta4.
The [Kind release notes](https://github.com/kubernetes-sigs/kind/releases/tag/v0.33.0)
describe the version split. The fix configures both schemas and checks the
running API server flag.

Across all three versions, actual API CRUD, patch, pagination, conflict,
forbidden and Watch checks passed with verified in-cluster TLS. The default
adoption guard refused unmanaged children. With ownership admission enabled,
explicit adoption got HTTP 403 without dependent delete permission and
succeeded with permission limited to the fixture's resource names. Calico
denied the clients missing either required label and allowed the labeled
client before and after the negative checks. MoonApp lifecycle and external
status preservation also passed.

[Focused Linux native checks](https://github.com/miik-su/MoonOperator/actions/runs/46121168748)
and the [experimental WASM checks](https://github.com/miik-su/MoonOperator/actions/runs/46121168706)
passed on the same revision. This matrix covers the pinned Kind and Calico
configuration and the tested ServiceAccount auth path.
