# References

Consulted 2026-11-07: client-go for dirty/processing queues;
controller-runtime for key-based reconcile/manager; Kubernetes API Concepts for
LIST/WATCH/RV semantics; moonbitlang/async for actual HTTP/TLS and cancellation.
Links are in architecture.md. No Go implementation is copied or vendored.
Updated 2026-11-08 using `moon search kubernetes --limit 8 --json` and the linked
project sources. This is a bounded survey, not an exhaustive ecosystem census.

| Project | Confirmed source scope | Relationship |
|---|---|---|
| [KubeMoon 0.1.1](https://github.com/cxh04/KubeMoon) | Dynamic client, reflector/store/queue/controller, HTTP transport, ConfigMirror and Kind acceptance described by upstream | Significant core overlap; MoonOperator makes no first/unique-framework claim |
| [moonbitlang/async](https://github.com/moonbitlang/async) | MoonBit async HTTP/TLS/process primitives | Actual reused dependency, pinned 0.22.5 |
| [community YAML](https://github.com/moonbit-community/yaml.mbt) | JSON-compatible YAML parser/events | Actual reused dependency, pinned 0.0.8 |
| [Wasmtime](https://github.com/bytecodealliance/wasmtime) | Wasm execution with configurable limits | Optional separately installed runtime, pinned 50.0.1 |

KubeMoon capabilities above are upstream-described; its tests were not executed
in this work. MoonOperator's independently implemented work concentrates on the
MoonApp example, CRD/RBAC generation, configuration boundaries, recovery probes
and the experimental scalar validation host. API discovery interoperability with
KubeMoon is a possible future integration, not a current dependency or claim.
