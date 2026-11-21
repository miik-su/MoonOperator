///|
async test "incomplete source snapshots preserve old data without queue admission" {
  let kind : @core.ResourceType = {
    gvk: { group: "", version: "v1", kind: "Pod", },
    plural: "pods",
    scope: Namespaced,
  }
  let old = @core.Resource::from_json({
    "apiVersion": "v1",
    "kind": "Pod",
    "metadata": {
      "name": "retained",
      "namespace": "west",
      "uid": "old",
      "resourceVersion": "old-rv",
    },
  })
  for
    (rv, token, items) in [
      ("", "", []),
      ("snapshot", "next-page", []),
      ("snapshot", "", [old, old.with_metadata("uid", "duplicate")]),
    ] {
    let store = @cache.Store::new()
    store.replace(kind.gvk, [old])
    let queue = @queue.Queue::new()
    let lists = Ref(0)
    let watches = Ref(0)
    let source = @runtime.Source::new(
      () => {
        lists.val += 1
        { items, resource_version: rv, continue_token: token, }
      },
      (_, _) => {
        watches.val += 1
        raise @core.Api(403, "stop")
      },
    )
    assert_true(
      try source.run(kind, store, queue) catch {
        @core.Invalid(_) => true
        _ => false
      } noraise {
        _ => false
      },
    )
    assert_eq(lists.val, 1)
    assert_eq(watches.val, 0)
    assert_eq(store.get(old.key()).unwrap().json(), old.json())
    assert_false(store.ready(kind.gvk))
    assert_eq(queue.pending(), 0)
  }
}

///|
async test "event storm UID recreation and 410 relist converge without namespace interference" {
  let kind : @core.ResourceType = {
    gvk: { group: "", version: "v1", kind: "Pod", },
    plural: "pods",
    scope: Namespaced,
  }
  let old = @core.Resource::from_json({
    "apiVersion": "v1",
    "kind": "Pod",
    "metadata": {
      "name": "same",
      "namespace": "west",
      "uid": "old",
      "resourceVersion": "initial",
    },
  })
  let recreated = old
    .with_metadata("uid", "new")
    .with_metadata("resourceVersion", "recreated")
  let gone = old.with_metadata("name", "gone")
  let east = @cache.Store::new()
  let other = old.with_metadata("namespace", "east")
  east.replace(kind.gvk, [other])
  let west = @cache.Store::new()
  let queue = @queue.Queue::new(capacity=4)
  let lists = Ref(0)
  let source = @runtime.Source::new(
    () => {
      lists.val += 1
      {
        items: if lists.val == 1 {
          [old, gone]
        } else {
          [recreated]
        },
        resource_version: "list-\{lists.val}",
        continue_token: "",
      }
    },
    (rv, emit) => {
      if lists.val == 1 {
        assert_eq(rv, "list-1")
        for i in 0..<100 {
          let changed = old.with_metadata("resourceVersion", "opaque-\{i}")
          emit(Modified(changed))
          emit(Modified(changed))
        }
        emit(Added(recreated))
        emit(Deleted(old))
        assert_eq(west.get(old.key()).unwrap().json(), recreated.json())
        emit(Failure(410))
      }
      assert_eq(rv, "list-2")
      assert_eq(west.list(kind.gvk).length(), 1)
      assert_eq(west.get(old.key()).unwrap().json(), recreated.json())
      assert_true(east.ready(kind.gvk))
      assert_eq(east.get(other.key()).unwrap().json(), other.json())
      raise @core.Api(403, "stop after convergence")
    },
  )
  assert_true(
    try @async.with_timeout(3000, () => source.run(kind, west, queue)) catch {
      @core.Api(403, _) => true
      _ => false
    } noraise {
      _ => false
    },
  )
  assert_eq(lists.val, 2)
  assert_eq(queue.pending(), 2)
  let delivered : Array[@core.Key] = []
  while queue.get(@async.now()) is Some(key) {
    delivered.push(key)
    queue.done(key)
  }
  assert_true(delivered.contains(gone.key()))
  assert_true(delivered.contains(old.key()))
  assert_eq(queue.pending(), 0)
  assert_false(west.ready(kind.gvk))
  assert_true(east.ready(kind.gvk))
}

///|
async test "informer rejects out-of-scope snapshots before publication" {
  let pod : @core.ResourceType = {
    gvk: { group: "", version: "v1", kind: "Pod", },
    plural: "pods",
    scope: Namespaced,
  }
  let node : @core.ResourceType = {
    gvk: { group: "", version: "v1", kind: "Node", },
    plural: "nodes",
    scope: Cluster,
  }
  let west = @core.Resource::from_json({
    "apiVersion": "v1",
    "kind": "Pod",
    "metadata": { "name": "sample", "namespace": "west" },
  })
  let cluster = @core.Resource::from_json({
    "apiVersion": "v1",
    "kind": "Node",
    "metadata": { "name": "sample" },
  })
  for
    (kind, ns, retained, rejected) in [
      (pod, "west", west, west.with_metadata("namespace", "east")),
      (pod, "", west, west.with_metadata("namespace", "")),
      (node, "", cluster, cluster.with_metadata("namespace", "west")),
    ] {
    let store = @cache.Store::new()
    store.replace(kind.gvk, [retained])
    let queue = @queue.Queue::new()
    let watched = Ref(false)
    let source = @runtime.Source::new(
      () => {
        items: [rejected],
        resource_version: "snapshot",
        continue_token: "",
      },
      (_, _) => watched.val = true,
    )
    assert_true(
      try source.run(kind, store, queue, ns~) catch {
        @core.Invalid(_) => true
        _ => false
      } noraise {
        _ => false
      },
    )
    assert_false(watched.val)
    assert_false(store.ready(kind.gvk))
    assert_eq(queue.pending(), 0)
    assert_eq(store.list(kind.gvk).length(), 1)
    assert_eq(store.get(retained.key()).unwrap().json(), retained.json())
  }
}

///|
async test "invalid watch events relist without reaching the predicate cache or queue" {
  let kind : @core.ResourceType = {
    gvk: { group: "", version: "v1", kind: "Pod", },
    plural: "pods",
    scope: Namespaced,
  }
  let west = @core.Resource::from_json({
    "apiVersion": "v1",
    "kind": "Pod",
    "metadata": {
      "name": "sample",
      "namespace": "west",
      "resourceVersion": "object-rv",
    },
  })
  let east = west.with_metadata("namespace", "east")
  let store = @cache.Store::new()
  store.replace(kind.gvk, [east])
  let queue = @queue.Queue::new()
  let lists = Ref(0)
  let predicates = Ref(0)
  let source = @runtime.Source::new(
    () => {
      assert_false(store.ready(kind.gvk))
      lists.val += 1
      {
        items: [west],
        resource_version: "list-\{lists.val}",
        continue_token: "",
      }
    },
    (rv, emit) => {
      assert_eq(rv, "list-\{lists.val}")
      assert_true(store.get(east.key()) is None)
      assert_eq(queue.pending(), 1)
      match lists.val {
        1 => emit(Added(east))
        2 => emit(Bookmark(""))
        _ => {
          emit(Bookmark("valid-checkpoint"))
          raise @core.Api(403, "stop")
        }
      }
    },
  )
  assert_true(
    try
      @async.with_timeout(3000, () => {
        source.run(kind, store, queue, ns="west", predicate=(_, _) => {
          predicates.val += 1
          true
        })
      })
    catch {
      @core.Api(403, _) => true
      _ => false
    } noraise {
      _ => false
    },
  )
  assert_eq(lists.val, 3)
  assert_eq(predicates.val, 1)
  assert_true(store.get(east.key()) is None)
  assert_eq(store.get(west.key()).unwrap().json(), west.json())
  assert_eq(queue.pending(), 1)
}
