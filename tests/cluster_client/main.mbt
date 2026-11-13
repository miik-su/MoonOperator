///|
suberror WatchComplete

///|
/// Opt-in real-cluster probe using its own narrowly scoped ServiceAccount.
async fn run_probe() -> Unit {
  let ns = @env.get_env_var("MOONOPERATOR_NAMESPACE").unwrap_or(
    "moonoperator-e2e",
  )
  let config = @transport.Config::in_cluster(
    @env.get_env_var("KUBERNETES_SERVICE_HOST").unwrap(),
    port=@env.get_env_var("KUBERNETES_SERVICE_PORT").unwrap_or("443"),
  )
  let client = config.client()
  let kind : @core.ResourceType = {
    gvk: { group: "", version: "v1", kind: "ConfigMap", },
    plural: "configmaps",
    scope: Namespaced,
  }
  for suffix in ["a", "b", "c"] {
    ignore(
      client.create(
        kind,
        @core.Resource::from_json({
          "apiVersion": "v1",
          "kind": "ConfigMap",
          "metadata": {
            "namespace": ns,
            "name": "client-probe-" + suffix,
            "labels": { "test": "moonoperator-probe" },
          },
          "data": { "initial": "value" },
        }),
      ),
    )
  }
  let first = client.get(kind, ns, "client-probe-a")
  println("client-probe: create/get passed")
  let updated = client.update(
    kind,
    first.with_field("data", { "updated": "value" }),
  )
  assert_true(
    try client.update(kind, first) catch {
      @core.Api(409, _) => true
      _ => false
    } noraise {
      _ => false
    },
  )
  println("client-probe: update/conflict passed")
  let patched = client.patch(kind, ns, "client-probe-a", {
    "metadata": { "resourceVersion": updated.resource_version() },
    "data": { "updated": null, "patched": "value" },
  })
  assert_eq(@core.field(patched.json(), "data"), { "patched": "value" })
  println("client-probe: merge patch passed")
  let page = client.list_page(
    kind,
    ns,
    labels="test=moonoperator-probe",
    limit=1,
  )
  assert_true(page.items.length() <= 1)
  assert_false(page.continue_token.is_empty())
  let snapshot = client.list(
    kind,
    ns,
    labels="test=moonoperator-probe",
    page_size=1,
  )
  assert_eq(snapshot.items.length(), 3)
  println("client-probe: pagination passed")
  let namespace_type : @core.ResourceType = {
    gvk: { group: "", version: "v1", kind: "Namespace", },
    plural: "namespaces",
    scope: Cluster,
  }
  assert_true(
    try client.get(namespace_type, "", "default") catch {
      @core.Api(403, _) => true
      _ => false
    } noraise {
      _ => false
    },
  )
  let observed = Ref(false)
  @async.with_task_group(group => {
    group.spawn_bg(() => {
      @async.sleep(100)
      ignore(
        client.patch(kind, ns, "client-probe-a", {
          "data": { "watched": "true" },
        }),
      )
    })
    @async.with_timeout(10000, () => {
      @watch.stream(
        config,
        @watch.watch_path(
          kind,
          ns,
          snapshot.resource_version,
          labels="test=moonoperator-probe",
        ),
        event => {
          if event.resource() is Some(resource) &&
            @core.field(@core.field(resource.json(), "data"), "watched") ==
            Json::string("true") {
            observed.val = true
            raise WatchComplete
          }
        },
      )
    }) catch {
      WatchComplete => ()
      error => raise error
    }
  })
  assert_true(observed.val)
  println("client-probe: forbidden/watch passed")
  for suffix in ["a", "b", "c"] {
    let resource = client.get(kind, ns, "client-probe-" + suffix)
    client.delete(
      kind,
      ns,
      resource.key().name,
      uid=@core.text(@core.field(resource.metadata(), "uid")),
    )
  }
  let report : Json = {
    "real_api_crud_patch_paginate_conflict_forbidden_watch": true,
    "service_account": "moonoperator-probe",
    "tls_verified": true,
  }
  println(report.stringify())
}

///|
async fn main {
  if @env.get_env_var("MOONOPERATOR_ADOPTION_PROBE") is Some(mode) {
    adoption(mode)
    return
  }
  run_probe() catch {
    @core.Invalid(message) => {
      println("client-probe validation: " + message)
      raise @core.Invalid(message)
    }
    @core.Api(code, _) => {
      println("client-probe HTTP \{code}")
      raise @core.Api(code, "ClusterProbeFailed")
    }
    error => raise error
  }
}
