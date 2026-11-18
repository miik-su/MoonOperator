# A separate framework consumer

This independent MoonBit module uses only exported MoonOperator APIs. Its local
moon.work resolves miik-su/moonoperator from the checkout rather than claiming
that the unpublished package can already be installed from Mooncakes.

From this directory, run:

```sh
moon check --target native
moon run cmd/main --target native
```

The example reconciles a synthetic ConfigMap annotation, preserves an unrelated
annotation, and proves a second reconcile performs no extra write. It uses the
public Fake transport; it needs no credentials, cluster, Docker or Wasmtime.
It does not prove real RBAC, admission, garbage collection or workload readiness.
The workspace selects source dependencies; this is not an installed-package test.
Code and synthetic example data are project-authored Apache-2.0 material.

For a real controller, supply a verified transport Config::client, declare the
resource scope and minimal permissions, feed LIST/WATCH into a bounded Store and
Queue, and use Controller::run with cache readiness. Treat 409 as a reason to
read current state and reconcile again, not to replay an old write blindly.
See ../../docs/developing-controllers.md for the integration contract.
