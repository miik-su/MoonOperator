///|
async test "finalizer is retained on failed cleanup and removed after success" {
  let fake = @testing.Fake::new()
  let client = fake.client()
  let kind : @core.ResourceType = {
    gvk: { group: "demo.dev", version: "v1", kind: "App", },
    plural: "apps",
    scope: Namespaced,
  }
  let created = client.create(
    kind,
    @core.Resource::from_json({
      "apiVersion": "demo.dev/v1",
      "kind": "App",
      "metadata": {
        "name": "x",
        "namespace": "demo",
        "finalizers": ["other.dev/cleanup"],
      },
    }),
  )
  assert_eq(
    @controller.finalize(client, kind, created, "demo.dev/cleanup", _ => true),
    FinalizerAdded,
  )
  let live = client.get(kind, "demo", "x")
  assert_eq(
    @controller.finalize(client, kind, live, "demo.dev/cleanup", _ => true),
    Continue,
  )
  let deleting = client.update(
    kind,
    live.with_metadata("deletionTimestamp", Json::string("now")),
  )
  assert_eq(
    @controller.finalize(client, kind, deleting, "demo.dev/cleanup", _ => false),
    CleanupPending,
  )
  assert_true(
    try
      @controller.finalize(client, kind, deleting, "demo.dev/cleanup", _ => {
        raise @core.Transport("cleanup unavailable")
      })
    catch {
      _ => true
    } noraise {
      _ => false
    },
  )
  assert_true(
    client.get(kind, "demo", "x").finalizers().contains("demo.dev/cleanup"),
  )
  assert_true(
    try
      @controller.finalize(
        client,
        kind,
        deleting,
        "demo.dev/cleanup",
        _ => {
          @async.sleep(10000)
          true
        },
        cleanup_timeout_ms=10,
      )
    catch {
      _ => true
    } noraise {
      _ => false
    },
  )
  assert_true(
    client.get(kind, "demo", "x").finalizers().contains("demo.dev/cleanup"),
  )
  assert_eq(
    @controller.finalize(client, kind, deleting, "demo.dev/cleanup", _ => true),
    CleanupComplete,
  )
  assert_false(
    client.get(kind, "demo", "x").finalizers().contains("demo.dev/cleanup"),
  )
  assert_true(
    client.get(kind, "demo", "x").finalizers().contains("other.dev/cleanup"),
  )
  let cleaned = client.get(kind, "demo", "x")
  assert_eq(
    @controller.finalize(client, kind, cleaned, "demo.dev/cleanup", _ => {
      fail("must not clean twice")
    }),
    NoLongerResponsible,
  )
  assert_eq(
    @controller.finalize(
      client,
      kind,
      created.with_metadata("deletionTimestamp", "now"),
      "demo.dev/cleanup",
      _ => fail("not responsible"),
    ),
    NoLongerResponsible,
  )
}
