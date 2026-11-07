# MoonOperator

A MoonBit-native Kubernetes Operator development framework.

The implementation follows the linked MoonOperator design: dynamic resources,
an injectable Kubernetes client, LIST/WATCH recovery, a bounded cache and work
queue, and idempotent reconciliation. See [the roadmap](docs/roadmap.md).

This is an early implementation. Production readiness requires real-cluster
validation; supported and unverified capabilities are tracked explicitly.
