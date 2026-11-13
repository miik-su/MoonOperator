# Linux bounded evidence · 2026-11-13

These files are unchanged JSON/package-list payloads extracted from public CI
artifacts; report filenames are shortened for permanent version control.

Source: `695c58cc93a18bc2139751c7dad0e18f91b78e35`.
[Successful Kind workflow](https://github.com/miik-su/MoonOperator/actions/runs/43364884221).

| Original artifact | ID | ZIP SHA-256 | Permanent files |
| --- | --- | --- | --- |
| memory-observations | 14010171446 | `39f7df843ac0cea31afdf95c5203c68a2f4ca0ad8c94bd40da9df030364fe909` | memory.json |
| kind-acceptance | 14010122043 | `5be583a976997babbbe6769c5ae5ef71d28015dbc1e70ef97df7529ee8744bc1` | kind.json, client.json, rbac.json, network-policy.json, kubernetes.json, runtime-packages.txt |

Before-fix evidence: memory-before.json comes from source
`556882744e7989920a7bf30a70ab7935d54df00b`,
[failed workflow](https://github.com/miik-su/MoonOperator/actions/runs/42814360916),
artifact 13762918771, ZIP SHA-256
`9701b8a8b0342bec10678a41b6e64c8b04e2e3487ece23a34d8614a283f3bc89`.
Its observed exit code is 1 and OOMKilled is false; the old runner did not retain
stderr. A memory-limit explanation alone is therefore unsupported.

Each new memory case starts a fresh, non-root, read-only container with equal
memory and swap budgets. VmHWM is process peak RSS, not live heap after GC.
The 10k/128 MiB observation is close to the limit and provides no safe headroom.
These snapshots predate the optional-adoption acceptance probe added later;
they do not prove that probe, a full regression, a long soak, multiple Kubernetes
versions, or a complete distribution SBOM.
