///|
pub fn Resource::deleting(self : Resource) -> Bool {
  !text(field(self.metadata(), "deletionTimestamp")).is_empty()
}

///|
pub fn Resource::finalizers(self : Resource) -> Array[String] {
  match field(self.metadata(), "finalizers") {
    Array(items) => items.map(text)
    _ => []
  }
}

///|
/// Idempotently add/remove only the caller's finalizer; preserve other owners.
pub fn Resource::set_finalizer(
  self : Resource,
  name : String,
  present : Bool,
) -> Resource raise OperatorError {
  if !name.contains("/") {
    raise Invalid("finalizer must be qualified")
  }
  let values = self.finalizers().filter(value => value != name)
  if present {
    values.push(name)
  }
  self.with_metadata("finalizers", Json::array(values.map(Json::string)))
}

///|
/// Kubernetes requires a single controlling owner and forbids cross-namespace ownership.
pub fn Resource::controlled_by(
  self : Resource,
  owner : Resource,
  dependent_type~ : ResourceType,
  owner_type~ : ResourceType,
) -> Resource raise OperatorError {
  let uid = text(field(owner.metadata(), "uid"))
  if uid.is_empty() ||
    self.key().gvk != dependent_type.gvk ||
    owner.key().gvk != owner_type.gvk {
    raise Invalid("owner UID and matching resource types required")
  }
  for (resource, kind) in [(self, dependent_type), (owner, owner_type)] {
    if (kind.scope == Cluster && !resource.key().ns.is_empty()) ||
      (kind.scope == Namespaced && resource.key().ns.is_empty()) {
      raise Invalid("resource namespace does not match declared scope")
    }
  }
  if owner_type.scope == Namespaced &&
    (dependent_type.scope == Cluster || self.key().ns != owner.key().ns) {
    raise Invalid("namespaced owners require a dependent in the same namespace")
  }
  if text(field(self.metadata(), "uid")) == uid {
    raise Invalid("resource cannot own itself")
  }
  let refs = match field(self.metadata(), "ownerReferences") {
    Array(items) => items
    _ => []
  }
  for entry in refs {
    if field(entry, "controller") == Json::boolean(true) &&
      text(field(entry, "uid")) != uid {
      raise Invalid("resource already has a different controller")
    }
  }
  let refs = refs.filter(entry => text(field(entry, "uid")) != uid)
  refs.push({
    "apiVersion": owner.key().gvk.api_version(),
    "kind": owner.key().gvk.kind,
    "name": owner.key().name,
    "uid": uid,
    "controller": true,
    "blockOwnerDeletion": true,
  })
  self.with_metadata("ownerReferences", Json::array(refs))
}

///|
/// Preserve lastTransitionTime when status is unchanged, even if reason changes.
pub fn conditions_upsert(
  conditions : Json,
  condition : Json,
) -> Json raise OperatorError {
  let kind = text(field(condition, "type"))
  let status = text(field(condition, "status"))
  if kind.is_empty() ||
    !(status == "True" || status == "False" || status == "Unknown") {
    raise Invalid("invalid status condition")
  }
  let items = match copy_json(conditions) {
    Array(items) => items
    _ => []
  }
  let replacement = copy_json(condition)
  for old in items {
    if text(field(old, "type")) == kind &&
      field(old, "status") == field(condition, "status") {
      if replacement is Object(fields) {
        fields["lastTransitionTime"] = field(old, "lastTransitionTime")
      }
    }
  }
  let result = items.filter(item => text(field(item, "type")) != kind)
  result.push(replacement)
  Json::array(result)
}
