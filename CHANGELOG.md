# 0.1.0 (unreleased)

Security review 2026-11-08: bounded JSON traversal before copying, strict
kubeconfig and request targets, redirect refusal, atomic cache byte budgets and
gauges, reconcile/cleanup deadlines, permanent-error outcomes, strict watch
checkpoints/status codes, source SBOM and Wasmtime advisory checks, pinned and
checksum-verified CI tools, redacted history scanning, private vulnerability
reporting and contribution/module contracts. See docs/security-audit-20261108.md
for targeted evidence, API behavior changes and remaining release gates.

Initial native MoonBit resource/client/watch/cache/queue/controller framework,
lifecycle helpers, CRD/RBAC generators, fake API faults, idempotent MoonApp,
manifest CLI and cache-aware health/metrics.

Continuation: real Kind MoonApp lifecycle acceptance, pinned Wasmtime/MoonBit
guest execution and failure isolation, typed LIST decoding, Retry-After,
concurrent-key/shutdown regressions, finalizer reconciliation, predicates,
typed spec views, multiversion CRDs, restricted YAML configuration, structured
safe logs, duration/counter metrics and recorded native benchmark/load probes.
