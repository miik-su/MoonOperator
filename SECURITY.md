# Security policy

MoonOperator 0.1.x is experimental. Security fixes target the latest main
revision; there is no maintained stable or production support branch yet.
Use the current revision and pinned dependencies when reporting a problem.

## Report privately

Use [GitHub private vulnerability reporting](https://github.com/miik-su/MoonOperator/security/advisories/new).
Private reporting was enabled and verified on 2026-11-08. Include the affected
commit, target/platform, impact, prerequisites and a minimal reproducer using
dummy credentials. Do not publish tokens, kubeconfigs, private cluster names,
exploit payloads against live services or other people's data in an issue.
If the form is unavailable, request a private contact method in an issue
without disclosing vulnerability details. No response or remediation deadline
is guaranteed by this volunteer project. Coordinate disclosure with maintainers.

## Trust and deployment boundaries

Run one replica with a dedicated, narrowly scoped ServiceAccount. TLS CA and
hostname verification stay enabled. Loopback HTTP is an explicit development
option. Diagnostics belong on a trusted network. Kubernetes RBAC, admission,
network policy and container process limits remain deployment responsibilities.

The optional WASM validator is experimental: fuel, linear memory, output and
time limits do not constitute a full process-RSS or operating-system sandbox.
Only run reviewed modules from a trusted source; never pass credentials to them.
See [security model](docs/security-model.md), [WASM limits](docs/wasm-runtime.md)
and [audit and residual risks](docs/security-audit-20261108.md).

## Maintenance checks

CI runs focused regression tests, redacted Gitleaks Git-history scans, a reviewed
source dependency inventory and an OSV check for the pinned Wasmtime version.
Mooncakes ecosystem coverage is incomplete: an empty scanner result is not a
claim that all dependencies or distributed binaries are vulnerability-free.
SDK, native TLS and container OS updates require separate distributor review.
