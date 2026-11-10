///|
pub(all) struct Version {
  name : String
  schema : Json
  served : Bool
  storage : Bool
  status_subresource : Bool
}

///|
/// Multiple schemas, exactly one served storage version. No webhook conversion
/// is generated; schemas must be compatible without conversion.
pub fn definition_with_versions(
  kind : @core.ResourceType,
  singular : String,
  versions : Array[Version],
) -> Json raise @core.OperatorError {
  if versions.is_empty() {
    raise @core.Invalid("CRD versions required")
  }
  let names : Map[String, Bool] = Map([])
  let mut storage_count = 0
  let mut preferred_served = false
  let encoded : Array[Json] = []
  let schema = versions[0].schema
  ignore(@core.json_size(schema, max_depth=64))
  for version in versions {
    ignore(@core.json_size(version.schema, max_depth=64))
    if version.schema != schema ||
      version.status_subresource != versions[0].status_subresource {
      raise @core.Invalid(
        "without conversion all version schemas and subresource semantics must match",
      )
    }
    if version.name.is_empty() ||
      names.contains(version.name) ||
      (version.storage && !version.served) ||
      @core.text(@core.field(version.schema, "type")) != "object" {
      raise @core.Invalid("invalid CRD version")
    }
    names[version.name] = true
    if version.storage {
      storage_count += 1
    }
    if version.name == kind.gvk.version && version.served {
      preferred_served = true
    }
    let item : Map[String, Json] = {
      "name": Json::string(version.name),
      "served": Json::boolean(version.served),
      "storage": Json::boolean(version.storage),
      "schema": { "openAPIV3Schema": @core.copy_json(version.schema) },
    }
    if version.status_subresource {
      item["subresources"] = { "status": {} }
    }
    encoded.push(Json::object(item))
  }
  if storage_count != 1 || !preferred_served {
    raise @core.Invalid(
      "one storage version and served preferred version required",
    )
  }
  let result = definition(kind, singular, versions[0].schema)
  if result is Object(fields) && fields.get("spec") is Some(Object(spec)) {
    spec["versions"] = Json::array(encoded)
  }
  result
}
