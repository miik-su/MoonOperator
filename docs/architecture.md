# Architecture

Application → Manager / Reconciler → Queue → Cache / Watch → Client → API server.
Core resource types have no dependencies on the higher layers. Transport is
injectable so the same client contract can drive both real and fake servers.
Public types belong to their public package. All control logic is MoonBit.

Design references (consulted 2026-11-07):

- https://github.com/kubernetes-sigs/controller-runtime — keys and reconciliation
- https://github.com/kubernetes/client-go — dirty/processing queue semantics
- https://kubernetes.io/docs/reference/using-api/api-concepts/ — opaque resource
  versions, consistent LIST snapshots and recovery after HTTP 410
- https://github.com/moonbitlang/async — reusable I/O instead of custom TLS

These inform behavior; no Go source is copied. The initial runtime uses a single
cooperative event loop. Synchronous queue/cache mutations contain no suspension
points. Independent keys may reconcile concurrently; one key cannot run twice.
