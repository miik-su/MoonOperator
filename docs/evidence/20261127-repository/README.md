# Repository verification · 2026-11-27

Windows native checks used MoonBit `0.10.17+d971670cd` and moon
`0.1.20261023`. The checked repository baseline was
`b3f3e53747a7538c1386c67990b334262832da42`. The source ZIP was generated
from clean documentation revision `0e95fba17ce5d1a357b94505fc8d4f2a3a65f726`.
Those revisions have identical MoonBit source and public interfaces.

| Check | Observed result |
| --- | --- |
| `moon check --target native`, `moon fmt --check` and `moon info --target native` | Passed. The generated `.mbti` files had no changes. |
| `moon test controller/worker_test.mbt examples/moonapp/status_test.mbt rbac/rbac_test.mbt --target native` | 3 passed, 0 failed. |
| `moon run cmd/manifests --target native` | Generated valid JSON in `default` and `moonoperator-docs`. Each bundle contained a ServiceAccount, Role, RoleBinding, CustomResourceDefinition and NetworkPolicy. Namespaced items used the requested namespace and the CRD had no namespace. |
| `moon check --target native` and `moon run cmd/main --target native` in `examples/consumer` | Passed using the local source workspace and synthetic transport. Two reconcile attempts, one child update, unrelated annotation preserved, zero pending work. |
| `moon run scripts/package-audit.mbtx` | Verified 514 ZIP paths, byte-matched all 10 required notice payloads, and matched both bundled dependency license files to the resolved dependencies. No generated or credential-like paths were found by the archive path checks. |

Source ZIP: `miik-su-moonoperator-0.1.3.zip`

SHA-256: `d91ffd404eb51d91aa2173029de6d121aaa14028b2d1f2d297426e80ed584d2d`

The manifest check ran locally without applying the bundle to a cluster. For
real API and Kind results, see [public v0.1.2 acceptance](../20261125-v0.1.2/README.md#public-release-acceptance).
The archive check covers paths and notice bytes. Git history credential
scanning and Linux retry verification are recorded in the
[focused native CI](https://github.com/miik-su/MoonOperator/actions/runs/45755636817).
