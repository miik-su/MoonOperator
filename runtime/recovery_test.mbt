///|
async test "informer relists after expired RV and fails closed on forbidden" {
  let kind : @core.ResourceType = {
    gvk: { group: "", version: "v1", kind: "Pod", },
    plural: "pods",
    scope: Namespaced,
  }
  let resource = @core.Resource::from_json({
    "apiVersion": "v1",
    "kind": "Pod",
    "metadata": { "name": "x", "resourceVersion": "opaque" },
  })
  let lists = Ref(0)
  let versions : Array[String] = []
  let source = @runtime.Source::new(
    () => {
      lists.val += 1
      {
        items: [resource],
        resource_version: "list-\{lists.val}",
        continue_token: "",
      }
    },
    (rv, on_event) => {
      versions.push(rv)
      if versions.length() == 1 {
        on_event(Bookmark("bookmark-rv"))
        raise @core.Api(410, "Expired")
      }
      raise @core.Api(403, "Forbidden")
    },
  )
  let store = @cache.Store::new()
  let queue = @queue.Queue::new()
  let forbidden = try source.run(kind, store, queue) catch {
    @core.Api(403, _) => true
    _ => false
  } noraise {
    _ => false
  }
  assert_true(forbidden)
  assert_eq(lists.val, 2)
  assert_eq(versions, ["list-1", "list-2"])
  assert_false(store.ready(kind.gvk))
}
