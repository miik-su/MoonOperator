///|
/// Kubernetes failures remain machine-readable. Server messages are deliberately
/// excluded from diagnostics because they may contain submitted credentials.
pub(all) suberror OperatorError {
  Invalid(String)
  Api(Int32, String)
  Capacity(String)
  CacheCapacity(String)
  QueueCapacity(String)
  ListCapacity(String)
  Transport(String)
} derive(Debug)

///|
pub fn retryable(code : Int32) -> Bool {
  code == 409 || code == 429 || code >= 500
}

///|
pub(all) enum Scope {
  Namespaced
  Cluster
} derive(Debug, Eq)

///|
pub(all) struct GVK {
  group : String
  version : String
  kind : String
} derive(Debug, Eq, Hash)

///|
pub fn GVK::api_version(self : GVK) -> String {
  if self.group.is_empty() {
    self.version
  } else {
    self.group + "/" + self.version
  }
}

///|
pub(all) struct ResourceType {
  gvk : GVK
  plural : String
  scope : Scope
} derive(Debug, Eq)

///|
pub(all) struct Key {
  gvk : GVK
  ns : String
  name : String
} derive(Debug, Eq, Hash)

///|
/// A private owned JSON tree. Accessors return copies, never aliases into cache.
pub struct Resource {
  value : Json
}

///|
/// All resource fields may contain secrets, including custom kinds and metadata.
pub impl Debug for Resource with fn to_repr(_) {
  @debug.Repr("Resource(<redacted>)")
}

///|
pub fn copy_json(value : Json) -> Json {
  match value {
    Object(fields) => {
      let result : Map[String, Json] = Map([])
      for key, item in fields {
        result[key] = copy_json(item)
      }
      Json::object(result)
    }
    Array(items) => Json::array(items.map(copy_json))
    _ => value
  }
}

///|
pub fn field(value : Json, key : String) -> Json {
  match value {
    Object(fields) => fields.get(key).unwrap_or(Json::null())
    _ => Json::null()
  }
}

///|
pub fn text(value : Json) -> String {
  match value {
    String(s) => s
    _ => ""
  }
}

///|
/// Validate the minimal object identity and retain all other fields unchanged.
pub fn Resource::from_json(value : Json) -> Resource raise OperatorError {
  ignore(json_size(value))
  guard value is Object(_) else { raise Invalid("resource must be an object") }
  let meta = field(value, "metadata")
  if text(field(value, "apiVersion")).is_empty() ||
    text(field(value, "kind")).is_empty() ||
    text(field(meta, "name")).is_empty() {
    raise Invalid("apiVersion, kind and metadata.name are required")
  }
  for key in ["namespace", "uid", "resourceVersion"] {
    let item = field(meta, key)
    if item != Json::null() && !(item is String(_)) {
      raise Invalid("metadata identity fields must be strings")
    }
  }
  { value: copy_json(value), }
}

///|
pub fn Resource::parse(input : String) -> Resource raise {
  if input.length() > 4194304 {
    raise Capacity("resource input limit")
  }
  Resource::from_json(
    @json.parse(input, max_nesting_depth=128, reject_duplicate_keys=true),
  )
}

///|
pub fn Resource::json(self : Resource) -> Json {
  copy_json(self.value)
}

///|
pub fn Resource::metadata(self : Resource) -> Json {
  copy_json(field(self.value, "metadata"))
}

///|
pub fn Resource::key(self : Resource) -> Key {
  let version = text(field(self.value, "apiVersion"))
  let (group, version) = match version.split_once("/") {
    Some((group, version)) => (group.to_owned(), version.to_owned())
    None => ("", version)
  }
  let meta = field(self.value, "metadata")
  {
    gvk: { group, version, kind: text(field(self.value, "kind")), },
    ns: text(field(meta, "namespace")),
    name: text(field(meta, "name")),
  }
}

///|
/// Resource versions are opaque strings; they are never ordered or parsed.
pub fn Resource::resource_version(self : Resource) -> String {
  text(field(field(self.value, "metadata"), "resourceVersion"))
}

///|
pub fn Resource::with_field(
  self : Resource,
  name : String,
  value : Json,
) -> Resource raise OperatorError {
  ignore(json_size(value))
  let json = self.json()
  if json is Object(fields) {
    fields[name] = copy_json(value)
  }
  Resource::from_json(json)
}

///|
pub fn Resource::with_metadata(
  self : Resource,
  name : String,
  value : Json,
) -> Resource raise OperatorError {
  ignore(json_size(value))
  let meta = self.metadata()
  if meta is Object(fields) {
    fields[name] = copy_json(value)
  }
  self.with_field("metadata", meta)
}

///|
pub struct Registry {
  types : Map[GVK, ResourceType]
}

///|
pub fn Registry::new() -> Registry {
  { types: Map([]), }
}

///|
pub fn Registry::register(
  self : Registry,
  resource_type : ResourceType,
) -> Unit raise OperatorError {
  if self.types.contains(resource_type.gvk) {
    raise Invalid("duplicate GVK registration")
  }
  self.types[resource_type.gvk] = resource_type
}

///|
pub fn Registry::lookup(self : Registry, gvk : GVK) -> ResourceType? {
  self.types.get(gvk)
}
