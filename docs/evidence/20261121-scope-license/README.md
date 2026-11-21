# Informer collection scope and source archive notices · 2026-11-21

Tested source [7c16596](https://github.com/miik-su/MoonOperator/commit/7c16596075cf76eead1f7b2d5c2b523ab6770436).
The Windows run used a clean worktree and the pinned MoonBit SDK.

```sh
moon run scripts/maintenance-checks.mbtx -- FRESH_OUTPUT_DIRECTORY
```

- [Windows model and consumer results](windows-models.json) record 16/16 focused
  tests. The new cases use synthetic Pod and Node resources, a cross-namespace
  Watch event and a malformed custom bookmark. They check cache preservation,
  readiness, predicate calls, relisting and queue admission. The independent
  consumer used an in-memory transport and completed two reconciles with one
  update, an unrelated annotation preserved, and an empty queue.
  Local home and checkout paths in compiler output were shortened.
- [Windows package audit](windows-package.json) records 312 ZIP paths, seven
  unique nonempty notice files matching the checkout byte for byte, and two
  included license texts matching the resolved Mooncakes dependencies. The
  bundled MoonBit core license also matched the installed pinned SDK core
  license in a separate local SHA-256 comparison:
  `86460c45017ffacb9aa9e18850fa9fdb036339dc8851125465f4a3f3442fc894`.
  This checks notice contents for the source archive and records no publication.

The model inputs and project-authored reports follow the
[repository license terms](../../../LICENSING.md).
See the [model catalog](../../test-models.md) for the data scope.
No full regression or long-duration load run was performed.
