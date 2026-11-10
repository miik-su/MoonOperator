///|
fn main raise {
  let ns = @env.get_env_var("MOONOPERATOR_NAMESPACE").unwrap_or("default")
  let schema : Json = {
    "type": "object",
    "required": ["spec"],
    "properties": {
      "spec": @moonapp.spec_schema(),
      "status": {
        "type": "object",
        "x-kubernetes-preserve-unknown-fields": true,
      },
    },
  }
  let crd = @crd.definition(@moonapp.app_type, "moonapp", schema)
  let items = @rbac.manifests("moonoperator", ns, [
    {
      group: "moonoperator.dev",
      resources: ["moonapps"],
      verbs: ["get", "list", "watch"],
    },
    {
      group: "moonoperator.dev",
      resources: ["moonapps/status"],
      verbs: ["get", "update"],
    },
    {
      group: "moonoperator.dev",
      resources: ["moonapps/finalizers"],
      // Required by OwnerReferencesPermissionEnforcement for blockOwnerDeletion,
      // even though MoonApp itself uses GC rather than a cleanup finalizer.
      verbs: ["update"],
    },
    {
      group: "apps",
      resources: ["deployments"],
      verbs: ["get", "create", "update"],
    },
    { group: "", resources: ["services"], verbs: ["get", "create", "update"], },
  ])
  items.push(crd)
  items.push(@rbac.diagnostics_policy(ns))
  let bundle : Json = { "apiVersion": "v1", "kind": "List", "items": items }
  println(bundle.stringify(indent=2))
}
