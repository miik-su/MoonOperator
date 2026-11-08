# Contributing

Keep runtime behavior and automation in MoonBit where supported. Agent-authored
automation belongs in `.mbtx` files. Put changes in the package that owns the
behavior; see [module boundaries](docs/module-boundaries.md). Use small commits
with the problem, resulting behavior and relevant test evidence in the PR.

Before changing an API, explain its semantics, error handling, limits and any
breaking changes. Resource versions are opaque strings. Cleanup and reconciliation
must be idempotent. Never retry a write blindly, expose raw API error bodies in
logs or add cluster-admin permissions to make an example pass.

Run `moon check --target native`, `moon fmt` and `moon info --target native`.
Commit generated `.mbti` files. Run only affected test files, for example:

```sh
moon test transport/origin_test.mbt transport/kubeconfig_test.mbt --target native
moon test cache/budget_test.mbt controller/deadline_test.mbt --target native
moon run scripts/sbom.mbtx -- source-sbom.json
```

CI additionally exercises selected queue/recovery, in-cluster Kind and WASM-host
paths; a full test-suite run is not required for every change. Use dummy fixtures,
bounded workloads and deterministic regression cases. Describe untested platforms
and integration limits rather than claiming complete verification.

Dependency changes must update pins, licenses, checksums where applicable and
the generated source SBOM. Review upstream advisories directly when registries
have no scanner coverage. Preserve LICENSE, NOTICE and third-party notices in
redistributions. Contributions intentionally submitted for inclusion are governed
by Apache-2.0 section 5; this repository adds no separate CLA requirement.
See [conduct](CODE_OF_CONDUCT.md) and [private security reporting](SECURITY.md).
