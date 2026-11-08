///|
/// In-memory API transport with resourceVersion conflicts and one-shot faults.
/// Not an API-server substitute: admission, GC and selector parsing are absent.
pub struct Fake {
  objects : Map[String, @core.Resource]
  mut revision : Int32
  mut fault : Int32?
  mut writes : Int32
}

///|
pub fn Fake::new() -> Fake {
  { objects: Map([]), revision: 0, fault: None, writes: 0, }
}

///|
pub fn Fake::fail_next(self : Fake, code : Int32) -> Unit {
  self.fault = Some(code)
}

///|
pub fn Fake::write_count(self : Fake) -> Int32 {
  self.writes
}

///|
pub fn Fake::client(self : Fake) -> @client.Client {
  @client.Client::new(request => self.send(request))
}

///|
fn response(code : Int32, body : Json) -> @client.Response {
  { code, body, retry_after_seconds: None, }
}

///|
pub fn Fake::send(
  self : Fake,
  request : @client.Request,
) -> @client.Response raise {
  if self.fault is Some(code) {
    self.fault = None
    return response(code, Json::null())
  }
  let path = match request.path.split_once("?") {
    Some((path, _)) => path.to_owned()
    None => request.path
  }
  let status = path.has_suffix("/status")
  let path = if status { path[:path.length() - 7].to_owned() } else { path }
  let old = self.objects.get(path)
  match request.verb {
    "GET" =>
      match old {
        Some(resource) => response(200, resource.json())
        None => {
          if !request.path.contains("?") {
            return response(404, Json::null())
          }
          let prefix = path + "/"
          let items : Array[Json] = []
          for key, resource in self.objects {
            if key.has_prefix(prefix) &&
              !key[prefix.length():].to_owned().contains("/") {
              items.push(resource.json())
            }
          }
          response(200, {
            "metadata": { "resourceVersion": self.revision.to_string() },
            "items": items,
          })
        }
      }
    "POST" => {
      let resource = @core.Resource::from_json(request.body)
      let target = path + "/" + @client.encode(resource.key().name)
      if self.objects.contains(target) {
        return response(409, Json::null())
      }
      self.revision += 1
      let resource = resource
        .with_metadata(
          "resourceVersion",
          Json::string(self.revision.to_string()),
        )
        .with_metadata("uid", Json::string("fake-\{self.revision}"))
      self.objects[target] = resource
      self.writes += 1
      response(201, resource.json())
    }
    "PUT" => {
      guard old is Some(old) else { return response(404, Json::null()) }
      let resource = @core.Resource::from_json(request.body)
      if resource.key() != old.key() {
        return response(400, Json::null())
      }
      if resource.resource_version() != old.resource_version() {
        return response(409, Json::null())
      }
      self.revision += 1
      let resource = if status {
        old.with_field("status", @core.field(resource.json(), "status"))
      } else {
        resource
      }
      let resource = resource.with_metadata(
        "resourceVersion",
        Json::string(self.revision.to_string()),
      )
      self.objects[path] = resource
      self.writes += 1
      response(200, resource.json())
    }
    "PATCH" => {
      guard old is Some(old) else { return response(404, Json::null()) }
      if request.content_type != "application/merge-patch+json" {
        return response(415, Json::null())
      }
      let patch_rv = @core.text(
        @core.field(@core.field(request.body, "metadata"), "resourceVersion"),
      )
      if !patch_rv.is_empty() && patch_rv != old.resource_version() {
        return response(409, Json::null())
      }
      let patched = if status {
        old.with_field(
          "status",
          merge_patch(
            @core.field(old.json(), "status"),
            @core.field(request.body, "status"),
          ),
        )
      } else {
        @core.Resource::from_json(merge_patch(old.json(), request.body))
      }
      if patched.key() != old.key() {
        return response(400, Json::null())
      }
      self.revision += 1
      let patched = patched.with_metadata(
        "resourceVersion",
        Json::string(self.revision.to_string()),
      )
      self.objects[path] = patched
      self.writes += 1
      response(200, patched.json())
    }
    "DELETE" => {
      guard old is Some(old) else { return response(404, Json::null()) }
      let uid = @core.text(
        @core.field(@core.field(request.body, "preconditions"), "uid"),
      )
      if !uid.is_empty() &&
        uid != @core.text(@core.field(old.metadata(), "uid")) {
        return response(409, Json::null())
      }
      self.objects.remove(path)
      self.revision += 1
      self.writes += 1
      response(200, { "kind": "Status", "status": "Success" })
    }
    _ => response(405, Json::null())
  }
}

///|
/// RFC 7386 object merge: null removes a field; arrays replace wholesale.
fn merge_patch(target : Json, patch : Json) -> Json {
  match patch {
    Object(fields) => {
      let result = match @core.copy_json(target) {
        Object(fields) => fields
        _ => Map([])
      }
      for key, value in fields {
        if value == Json::null() {
          result.remove(key)
        } else {
          result[key] = merge_patch(
            result.get(key).unwrap_or(Json::null()),
            value,
          )
        }
      }
      Json::object(result)
    }
    _ => @core.copy_json(patch)
  }
}
