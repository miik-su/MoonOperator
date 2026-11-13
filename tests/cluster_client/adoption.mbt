///|
/// Actual API admission under two narrowly scoped ServiceAccounts. Extra delete
/// permission is granted only to the positive fixture, never the example SA.
async fn adoption(mode : String) -> Unit {
  guard ["deny", "allow"].contains(mode) else {
    fail("adoption mode must be deny or allow")
  }
  let name = if mode == "allow" {
    "adoption-allowed"
  } else {
    "adoption-denied"
  }
  let ns = "moonoperator-e2e"
  let client = @transport.Config::in_cluster(
    @env.get_env_var("KUBERNETES_SERVICE_HOST").unwrap(),
    port=@env.get_env_var("KUBERNETES_SERVICE_PORT").unwrap_or("443"),
  ).client()
  let app = client.get(@app.app_type, ns, name)
  assert_true(
    try @app.reconcile(client, app.key()) catch {
      @core.Invalid(_) => true
      _ => false
    } noraise {
      _ => false
    },
  )
  let mut error : Error? = None
  for attempt in 0..<5 {
    error = try {
      ignore(@app.reconcile(client, app.key(), adopt_unowned=true))
      None
    } catch {
      error => Some(error)
    }
    if error is Some(@core.Api(409, _)) && attempt < 4 {
      @async.sleep(100)
    } else {
      break
    }
  }
  if mode == "deny" {
    if error is Some(error) {
      println("adoption-denied observed: \{error}")
    } else {
      println("adoption-denied observed: successful adoption")
    }
    assert_true(
      error is Some(@core.Api(403, _)),
      msg="explicit adoption must require dependent delete permission",
    )
    let child = client.get(@app.deployment_type, ns, name)
    assert_eq(@core.field(child.metadata(), "ownerReferences"), Json::null())
  } else {
    if error is Some(error) {
      raise error
    }
    for kind in [@app.deployment_type, @app.service_type] {
      let child = client.get(kind, ns, name)
      guard @core.field(child.metadata(), "ownerReferences") is Array(refs) else {
        fail("adoption reference missing")
      }
      assert_true(
        refs.any(entry => {
          @core.field(entry, "controller") == Json::boolean(true) &&
          @core.field(entry, "uid") == @core.field(app.metadata(), "uid")
        }),
      )
      assert_eq(
        @core.field(
          @core.field(child.metadata(), "annotations"),
          "moonoperator.dev/fixture",
        ),
        "preserve",
      )
    }
  }
  let report : Json = {
    "mode": mode,
    "default_adoption_refused": true,
    "explicit_adoption": if mode == "allow" {
      "allowed with fixture-named delete permission"
    } else {
      "403 without delete permission"
    },
    "passed": true,
  }
  println(report.stringify())
}
