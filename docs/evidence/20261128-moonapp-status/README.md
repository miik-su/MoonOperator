# MoonApp status regression and Kind acceptance

| Source revision | GitHub native | Kind Kubernetes 1.36.4 | Kind Kubernetes 1.37.0 | Experimental WASM |
| --- | --- | --- | --- | --- |
| `1b73fa8d07236ebd31cdcecb6725ea96cc6ba60c` | [Passed](https://github.com/miik-su/MoonOperator/actions/runs/46107621114) | [Passed](https://github.com/miik-su/MoonOperator/actions/runs/46107621098/job/140863793798) | [Passed](https://github.com/miik-su/MoonOperator/actions/runs/46107621098/job/140863793592) | [Passed](https://github.com/miik-su/MoonOperator/actions/runs/46107621152) |
| `9a077ab0b6eba12e1f953748af92cc112a85631b` | [Passed](https://github.com/miik-su/MoonOperator/actions/runs/46107820688) | [Passed](https://github.com/miik-su/MoonOperator/actions/runs/46107820471/job/140864428181) | [Passed](https://github.com/miik-su/MoonOperator/actions/runs/46107820471/job/140864428380) | [Passed](https://github.com/miik-su/MoonOperator/actions/runs/46107820423) |

The follow-up updates an existing condition in its original position, collapses
duplicates of that type and preserves a recorded transition time while the
status is unchanged. Its regression failed before the fix because updating a
condition moved it to the end of the list.

Windows native `moon check`, `moon fmt --check` and interface verification passed.
The focused Windows command returned **9 passed, 0 failed**:

```sh
moon test core/lifecycle_test.mbt examples/moonapp/status_test.mbt examples/moonapp/operator_test.mbt examples/moonapp/ownership_test.mbt controller/worker_test.mbt --target native
```

Both follow-up Kind job logs confirm that an external status field and a
condition written through the real status subresource survived reconciliation
after a spec change. The check waited for the operator to publish the new
observed generation and verified that the external condition retained its list
position. The existing create, update, drift, restart and garbage-collection
checks also passed on both versions.
