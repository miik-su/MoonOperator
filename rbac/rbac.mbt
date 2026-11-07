///|
pub(all) struct Rule {
  group : String
  resources : Array[String]
  verbs : Array[String]
}

///|
/// JSON manifests are valid Kubernetes input (and a subset of YAML).
pub fn manifests(
  name : String,
  ns : String,
  rules : Array[Rule],
  cluster~ : Bool = false,
) -> Array[Json] raise @core.OperatorError {
  if name.is_empty() || ns.is_empty() {
    raise @core.Invalid("RBAC name and namespace required")
  }
  let encoded : Array[Json] = []
  for rule in rules {
    if rule.group == "*" ||
      rule.resources.is_empty() ||
      rule.verbs.is_empty() ||
      rule.resources.any(r => r.contains("*")) {
      raise @core.Invalid("explicit API groups and resources required")
    }
    for verb in rule.verbs {
      if !["get", "list", "watch", "create", "update", "patch", "delete"].contains(
          verb,
        ) {
        raise @core.Invalid("unsupported or privileged RBAC verb")
      }
    }
    encoded.push({
      "apiGroups": [rule.group],
      "resources": rule.resources,
      "verbs": rule.verbs,
    })
  }
  let role = if cluster { "ClusterRole" } else { "Role" }
  let meta : Json = if cluster {
    { "name": name }
  } else {
    { "name": name, "namespace": ns }
  }
  [
    {
      "apiVersion": "v1",
      "kind": "ServiceAccount",
      "metadata": { "name": name, "namespace": ns },
    },
    {
      "apiVersion": "rbac.authorization.k8s.io/v1",
      "kind": role,
      "metadata": meta,
      "rules": encoded,
    },
    {
      "apiVersion": "rbac.authorization.k8s.io/v1",
      "kind": role + "Binding",
      "metadata": meta,
      "subjects": [{ "kind": "ServiceAccount", "name": name, "namespace": ns }],
      "roleRef": {
        "apiGroup": "rbac.authorization.k8s.io",
        "kind": role,
        "name": name,
      },
    },
  ]
}
