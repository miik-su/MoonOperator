///|
async test "initial LIST larger than queue drains through bounded admission" {
  let kind : @core.ResourceType = {
    gvk: { group: "", version: "v1", kind: "Pod", },
    plural: "pods",
    scope: Namespaced,
  }
  let a = @core.Resource::from_json({
    "apiVersion": "v1",
    "kind": "Pod",
    "metadata": { "name": "a" },
  })
  let b = a.with_metadata("name", Json::string("b"))
  let processed : Array[String] = []
  let source = @runtime.Source::new(
    () => { items: [a, b], resource_version: "snapshot", continue_token: "", },
    (_, _) => {
      while processed.length() < 2 {
        @async.sleep(1)
      }
      raise @core.Api(403, "Stop")
    },
  )
  let store = @cache.Store::new()
  let queue = @queue.Queue::new(capacity=1)
  @async.with_timeout(2000, () => {
    @async.with_task_group(group => {
      group.spawn_bg(() => {
        while processed.length() < 2 {
          if store.ready(kind.gvk) && queue.get(0L) is Some(key) {
            processed.push(key.name)
            queue.done(key)
          }
          @async.sleep(1)
        }
      })
      ignore(
        source.run(kind, store, queue) catch {
          @core.Api(403, _) => ()
          error => raise error
        },
      )
    })
  })
  assert_eq(processed, ["a", "b"])
  assert_eq(queue.pending(), 0)
}
