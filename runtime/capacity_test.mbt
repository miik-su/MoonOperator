///|
async test "cache capacity failure stops LIST amplification and invalidates readiness" {
  let kind : @core.ResourceType = {
    gvk: { group: "", version: "v1", kind: "Pod", },
    plural: "pods",
    scope: Namespaced,
  }
  let r = @core.Resource::from_json({
    "apiVersion": "v1",
    "kind": "Pod",
    "metadata": { "name": "x", "namespace": "demo" },
  })
  let attempts = Ref(0)
  let source = @runtime.Source::new(
    () => {
      attempts.val += 1
      {
        items: [r, r.with_metadata("name", "y")],
        resource_version: "snapshot",
        continue_token: "",
      }
    },
    (_, _) => fail("watch must not start"),
  )
  let store = @cache.Store::new(capacity=1)
  assert_true(
    try source.run(kind, store, @queue.Queue::new()) catch {
      @core.CacheCapacity(_) => true
      _ => false
    } noraise {
      _ => false
    },
  )
  assert_eq(attempts.val, 1)
  assert_false(store.ready(kind.gvk))
  assert_eq(store.length(), 0)
}

///|
async test "persistent malformed watch events stop after three controlled recoveries" {
  let kind : @core.ResourceType = {
    gvk: { group: "", version: "v1", kind: "Pod", },
    plural: "pods",
    scope: Namespaced,
  }
  let r = @core.Resource::from_json({
    "apiVersion": "v1",
    "kind": "Pod",
    "metadata": { "name": "x", "namespace": "demo" },
  })
  let attempts = Ref(0)
  let source = @runtime.Source::new(
    () => {
      attempts.val += 1
      { items: [], resource_version: "snapshot", continue_token: "", }
    },
    (_, emit) => emit(Added(r)),
  )
  let store = @cache.Store::new()
  assert_true(
    try
      @async.with_timeout(3000, () => {
        source.run(kind, store, @queue.Queue::new())
      })
    catch {
      @core.Invalid(_) => true
      _ => false
    } noraise {
      _ => false
    },
  )
  assert_eq(attempts.val, 3)
  assert_eq(store.length(), 0)
  assert_false(store.ready(kind.gvk))
}
