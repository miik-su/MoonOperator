///|
pub(all) struct Request {
  verb : String
  path : String
  body : Json
  content_type : String
}

///|
pub(all) struct Response {
  code : Int32
  body : Json
  retry_after_seconds : Int32?
}

///|
/// Transport injection is the boundary between protocol and I/O.
pub struct Client {
  send : async (Request) -> Response
  mut not_before : Int64
}

///|
pub fn Client::new(send : async (Request) -> Response) -> Client {
  { send, not_before: 0L, }
}

///|
/// Percent-encode UTF-8 bytes, including selectors and opaque continue tokens.
pub fn encode(value : String) -> String {
  let out = StringBuilder()
  let hex = "0123456789ABCDEF"
  for byte in @utf8.encode(value) {
    let n = byte.to_int()
    if (n >= 65 && n <= 90) ||
      (n >= 97 && n <= 122) ||
      (n >= 48 && n <= 57) ||
      n == 45 ||
      n == 46 ||
      n == 95 ||
      n == 126 {
      out.write_char(n.unsafe_to_char())
    } else {
      out.write_string("%")
      out.write_char(hex.get_char(n / 16).unwrap())
      out.write_char(hex.get_char(n % 16).unwrap())
    }
  }
  out.to_string()
}

///|
fn segment(value : String) -> String raise @core.OperatorError {
  if value.is_empty() ||
    value == "." ||
    value == ".." ||
    value.contains_any(chars="/\\?#%") ||
    value.contains_char('\n') ||
    value.contains_char('\r') {
    raise @core.Invalid("invalid resource path segment")
  }
  encode(value)
}

///|
/// Empty namespace addresses all namespaces for LIST/WATCH only.
pub fn collection_path(
  kind : @core.ResourceType,
  ns : String,
) -> String raise @core.OperatorError {
  kind.validate()
  let prefix = if kind.gvk.group.is_empty() {
    "/api/"
  } else {
    "/apis/" + segment(kind.gvk.group) + "/"
  }
  let base = prefix + segment(kind.gvk.version)
  if kind.scope == Cluster && !ns.is_empty() {
    raise @core.Invalid("cluster resource has no namespace")
  }
  base +
  (if ns.is_empty() { "" } else { "/namespaces/" + segment(ns) }) +
  "/" +
  segment(kind.plural)
}

///|
pub fn object_path(
  kind : @core.ResourceType,
  ns : String,
  name : String,
) -> String raise @core.OperatorError {
  if kind.scope == Namespaced && ns.is_empty() {
    raise @core.Invalid("object namespace required")
  }
  collection_path(kind, ns) + "/" + segment(name)
}

///|
pub fn list_path(
  kind : @core.ResourceType,
  ns : String,
  limit~ : Int32 = 500,
  continue_token~ : String = "",
  labels~ : String = "",
  fields~ : String = "",
) -> String raise @core.OperatorError {
  if limit <= 0 {
    raise @core.Invalid("LIST limit must be positive")
  }
  collection_path(kind, ns) +
  "?limit=\{limit}&continue=" +
  encode(continue_token) +
  "&labelSelector=" +
  encode(labels) +
  "&fieldSelector=" +
  encode(fields)
}

///|
pub async fn Client::execute(self : Client, request : Request) -> Response {
  while self.not_before > @async.now() {
    let delay = self.not_before - @async.now()
    if delay > 0L {
      @async.sleep(delay.to_int())
    }
  }
  let response = (self.send)(request)
  if (response.code == 429 || response.code == 503) &&
    response.retry_after_seconds is Some(seconds) &&
    seconds > 0 {
    let seconds = if seconds > 3600 { 3600 } else { seconds }
    self.not_before = @async.now() + seconds.to_int64() * 1000L
  }
  if response.code < 200 || response.code >= 300 {
    let reason = match response.code {
      400 => "BadRequest"
      401 => "Unauthorized"
      403 => "Forbidden"
      404 => "NotFound"
      409 => "Conflict"
      410 => "Expired"
      429 => "TooManyRequests"
      _ => "ServerError"
    }
    raise @core.Api(response.code, reason)
  }
  response
}

///|
pub async fn Client::get(
  self : Client,
  kind : @core.ResourceType,
  ns : String,
  name : String,
) -> @core.Resource {
  let response = self.execute({
    verb: "GET",
    path: object_path(kind, ns, name),
    body: Json::null(),
    content_type: "application/json",
  })
  @core.Resource::from_json(response.body)
}

///|
pub(all) struct ResourceList {
  items : Array[@core.Resource]
  resource_version : String
  continue_token : String
}

///|
pub async fn Client::list_page(
  self : Client,
  kind : @core.ResourceType,
  ns : String,
  continue_token~ : String = "",
  labels~ : String = "",
  fields~ : String = "",
  limit~ : Int32 = 500,
) -> ResourceList {
  let response = self.execute({
    verb: "GET",
    path: list_path(kind, ns, continue_token~, labels~, fields~, limit~),
    body: Json::null(),
    content_type: "application/json",
  })
  guard @core.field(response.body, "items") is Array(items) else {
    raise @core.Invalid("LIST items required")
  }
  let meta = @core.field(response.body, "metadata")
  {
    items: items.map(item => decode_list_item(kind, item)),
    resource_version: @core.text(@core.field(meta, "resourceVersion")),
    continue_token: @core.text(@core.field(meta, "continue")),
  }
}

///|
/// Built-in typed LIST items may omit TypeMeta. The collection endpoint supplies
/// their GVK; explicit conflicting type metadata must still be rejected.
fn decode_list_item(
  kind : @core.ResourceType,
  value : Json,
) -> @core.Resource raise @core.OperatorError {
  ignore(@core.json_size(value))
  let value = @core.copy_json(value)
  guard value is Object(fields) else {
    raise @core.Invalid("LIST item must be object")
  }
  if !fields.contains("apiVersion") {
    fields["apiVersion"] = Json::string(kind.gvk.api_version())
  }
  if !fields.contains("kind") {
    fields["kind"] = Json::string(kind.gvk.kind)
  }
  let resource = @core.Resource::from_json(value)
  if resource.key().gvk != kind.gvk {
    raise @core.Invalid("LIST item GVK mismatch")
  }
  resource
}

///|
/// Accumulate one consistent snapshot, with finite page and object limits.
pub async fn Client::list(
  self : Client,
  kind : @core.ResourceType,
  ns : String,
  labels~ : String = "",
  fields~ : String = "",
  max_items~ : Int32 = 10000,
  page_size~ : Int32 = 500,
) -> ResourceList {
  let items : Array[@core.Resource] = []
  let seen : Map[String, Bool] = Map([])
  for token = "", version = "", pages = 0 {
    if pages >= 1000 {
      raise @core.ListCapacity("LIST page limit")
    }
    let page = self.list_page(
      kind,
      ns,
      continue_token=token,
      labels~,
      fields~,
      limit=page_size,
    )
    if page.resource_version.is_empty() ||
      (!version.is_empty() && version != page.resource_version) {
      raise @core.Invalid("LIST snapshot resourceVersion changed or missing")
    }
    if items.length() + page.items.length() > max_items {
      raise @core.ListCapacity("LIST object limit")
    }
    items.append(page.items)
    if page.continue_token.is_empty() {
      break {
        items,
        resource_version: page.resource_version,
        continue_token: "",
      }
    }
    if seen.contains(page.continue_token) {
      raise @core.Invalid("repeated LIST continue token")
    }
    seen[page.continue_token] = true
    continue page.continue_token, page.resource_version, pages + 1
  }
}

///|
pub async fn Client::create(
  self : Client,
  kind : @core.ResourceType,
  resource : @core.Resource,
) -> @core.Resource {
  let key = resource.key()
  if key.gvk != kind.gvk || (kind.scope == Namespaced && key.ns.is_empty()) {
    raise @core.Invalid("resource identity does not match endpoint")
  }
  let response = self.execute({
    verb: "POST",
    path: collection_path(kind, key.ns),
    body: resource.json(),
    content_type: "application/json",
  })
  @core.Resource::from_json(response.body)
}

///|
/// Updates require an optimistic concurrency token. /status is explicit.
pub async fn Client::update(
  self : Client,
  kind : @core.ResourceType,
  resource : @core.Resource,
  status~ : Bool = false,
) -> @core.Resource {
  let key = resource.key()
  if key.gvk != kind.gvk || resource.resource_version().is_empty() {
    raise @core.Invalid("UPDATE requires matching GVK and resourceVersion")
  }
  let path = object_path(kind, key.ns, key.name) +
    (if status { "/status" } else { "" })
  let response = self.execute({
    verb: "PUT",
    path,
    body: resource.json(),
    content_type: "application/json",
  })
  @core.Resource::from_json(response.body)
}

///|
pub async fn Client::patch(
  self : Client,
  kind : @core.ResourceType,
  ns : String,
  name : String,
  patch : Json,
  status~ : Bool = false,
) -> @core.Resource {
  let response = self.execute({
    verb: "PATCH",
    path: object_path(kind, ns, name) + (if status { "/status" } else { "" }),
    body: patch,
    content_type: "application/merge-patch+json",
  })
  @core.Resource::from_json(response.body)
}

///|
pub async fn Client::delete(
  self : Client,
  kind : @core.ResourceType,
  ns : String,
  name : String,
  uid~ : String = "",
) -> Unit {
  let body : Json = if uid.is_empty() {
    { "propagationPolicy": "Background" }
  } else {
    { "propagationPolicy": "Background", "preconditions": { "uid": uid } }
  }
  ignore(
    self.execute({
      verb: "DELETE",
      path: object_path(kind, ns, name),
      body,
      content_type: "application/json",
    }),
  )
}
