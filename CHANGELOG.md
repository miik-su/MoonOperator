# 0.1.0 (unreleased)

Review 2026-11-13: stdout-only read-only container memory probe, independent
image/cluster/memory jobs, retained failure states and six memory-limit cases;
explicit API-group/subresource RBAC checks; actual Calico traffic enforcement;
token reread after simulated expiry and negative CA/hostname TLS acceptance.
Add optional ownership-adoption permission probes, bounded 24-hour soak counters
and periodic RSS evidence, and a manual-only full-regression/long-soak workflow.
Full regression and hours/day runs have not been executed in this review.
See docs/review-followup-20261113.md and permanent Linux evidence.

Follow-up code review: redact Resource Debug, explicit FinalizeResult outcomes,
scope-aware owner references, deny implicit MoonApp adoption, preserve unrelated
owners, require watch RVs, separate cache/queue/LIST capacity failures, bound
malformed-event recovery and LIST bytes, validate constructors/API types/RBAC,
read credentials under a handle byte budget, release-only production image with
separate probes, pinned Ubuntu/APT inputs, local diagnostics and NetworkPolicy,
and non-root workload defaults. API migration: docs/api-design.md.

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
