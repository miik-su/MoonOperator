# 0.1.0 (unreleased)

Update inherited Ubuntu packages from a fixed snapshot and enforce the Noble
glibc security minimum. Record installed package source identities, startup
linkage and a dated OS scan. Verify Kind 1.36.4 and 1.37.0 with Calico 3.33.0.
Keep CI images on workers and publish evidence files.

Enforce informer collection scope on LIST and Watch input, and reject blank
custom-source bookmarks before dispatch. Verify the source ZIP's seven notice
payloads and compare bundled async/YAML with their resolved license copies.

Update the optional Wasmtime runtime and its verified Linux archive to 50.0.3
after the advisory gate detected new findings for 50.0.1.

Reject malformed LIST metadata and duplicate snapshot keys before returning or
publishing a snapshot. Check the identity of successful single-resource API
responses. Treat a changed UID as a new resource in Watch predicates, including
when the generation is unchanged.

Maintenance 2026-11-18: reject incomplete/unversioned custom Source snapshots
before cache publication; add duplicate/UID/410/namespace and in-flight conflict
models; preserve existing duration series while adding fixed latency histograms
and safe exception categories; validate CRD names/root schema/all version IDs;
add a separate public-API consumer; audit actual source ZIP paths/notices and
collect installed image copyrights. Clarify test-model provenance, deployment,
licensing and capability boundaries. Full regression/long soak/publication remain
unexecuted manual release gates; see docs/maintenance.md.

2026-11-14: migrate the unpublished module and all internal imports from
`mik1e80/moonoperator` to `miik-su/moonoperator`; regenerate public interfaces
and the current source SBOM. Historical test snapshots retain original identity.
Mooncakes account authentication and publication are separate pending steps.

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
