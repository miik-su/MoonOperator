# Security model

HTTPS verification is required, except an explicitly enabled loopback developer
proxy. Private credential fields have no Debug/Show implementation; projected
token files are reread per request. API errors use HTTP codes and fixed reasons,
not arbitrary server messages. Request bodies and tokens are never logged.

Body/event byte limits, JSON nesting limits, deadlines and cache/queue bounds
prevent unbounded ordinary accumulation. Explicit RBAC declarations reject
wildcards. Ownership rejects a second controlling UID. Diagnostics contain only
queue/cache gauges and should remain on the trusted operator network.
This is a single-replica framework, not a multitenant isolation boundary.

Transport accepts only origin-relative request targets, rejects control characters
and credential-bearing redirects, and validates request JSON before serialization.
Default request/response budgets are 4 MiB; projected token files are limited to
16 KiB. Kubeconfig rejects duplicate entry names, wrong field types, mixed bearer
sources and unsupported proxy/TLS-name/credential overrides rather than silently
ignoring their security meaning.

Resources reject more than 4 MiB of encoded JSON, 100,000 value nodes or 128
levels of nesting before copying. CRD validation uses a 64-level budget. Cache
defaults are 10,000 objects, 64 MiB total encoded bytes and 1 MiB per object.
Snapshot byte/count admission is atomic. These are encoded-size budgets, not
heap/RSS guarantees; the process/container still needs an operating-system limit.
Controller and finalizer callbacks default to a 30-second cooperative deadline.
Permanent API/validation errors do not enter automatic queue retry loops.

CI downloads fixed SDK, core, Kind, Gitleaks and Wasmtime releases and checks
committed SHA-256 values before execution. Actions use full commit SHAs.
Dependabot covers Actions and Docker; Mooncakes updates require manual review.
The generated CycloneDX inventory covers resolved source modules only.
See [the audit record](security-audit-20261108.md) for verification and exclusions.

Resource Debug output redacts all fields, including metadata and custom kinds.
MoonApp refuses implicit adoption and preserves noncontrolling owner references.
Ownership checks require declared resource scopes. Watch resource events require
nonempty string RVs before application. Cache/LIST capacity failures stop the
informer; queue pressure yields; repeated malformed watch data is limited to
three attempts. File limits are enforced while reading a single opened handle.

Local diagnostics bind to 127.0.0.1 by default. The cluster manifest explicitly
binds to the pod interface and is accompanied by an ingress NetworkPolicy.
The policy requires a CNI that enforces NetworkPolicy and a correctly labeled
monitoring namespace AND pod. Diagnostics have no built-in authentication; use
a trusted proxy if access must cross the trusted monitoring boundary.
