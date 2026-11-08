///|
pub(all) enum Event {
  Added(@core.Resource)
  Modified(@core.Resource)
  Deleted(@core.Resource)
  Bookmark(String)
  Failure(Int32)
}

///|
/// NDJSON framing operates on bytes, so split UTF-8 characters are safe.
pub struct Parser {
  mut pending : Buffer
  max_event_bytes : Int32
}

///|
pub fn Parser::new(max_event_bytes~ : Int32 = 1048576) -> Parser {
  { pending: Buffer(), max_event_bytes, }
}

///|
pub fn Parser::feed(self : Parser, chunk : Bytes) -> Array[Event] raise {
  let events : Array[Event] = []
  for byte in chunk {
    if byte == b'\n' {
      let line = @utf8.decode(self.pending.to_bytes()).trim().to_owned()
      self.pending = Buffer()
      if !line.is_empty() {
        events.push(
          decode_event(
            @json.parse(line, max_nesting_depth=128, reject_duplicate_keys=true),
          ),
        )
      }
    } else {
      if self.pending.length() >= self.max_event_bytes {
        raise @core.Capacity("watch event byte limit")
      }
      self.pending.write_byte(byte)
    }
  }
  events
}

///|
/// A partial final record is never applied; recovery resumes the last checkpoint.
pub fn Parser::finish(self : Parser) -> Unit raise @core.OperatorError {
  if self.pending.length() != 0 {
    raise @core.Invalid("truncated watch record")
  }
}

///|
fn decode_event(value : Json) -> Event raise @core.OperatorError {
  let object = @core.field(value, "object")
  match @core.text(@core.field(value, "type")) {
    "ADDED" => Added(@core.Resource::from_json(object))
    "MODIFIED" => Modified(@core.Resource::from_json(object))
    "DELETED" => Deleted(@core.Resource::from_json(object))
    "BOOKMARK" => {
      let rv = match
        @core.field(@core.field(object, "metadata"), "resourceVersion") {
        String(rv) => rv
        _ => raise @core.Invalid("bookmark resourceVersion must be a string")
      }
      if rv.is_empty() {
        raise @core.Invalid("bookmark resourceVersion required")
      }
      Bookmark(rv)
    }
    "ERROR" =>
      match @core.field(object, "code") {
        Number(code, ..) =>
          if code >= 100.0 && code <= 599.0 && code.to_int().to_double() == code {
            Failure(code.to_int())
          } else {
            raise @core.Invalid("invalid watch status code")
          }
        _ => raise @core.Invalid("watch error code required")
      }
    _ => raise @core.Invalid("unknown watch event type")
  }
}

///|
pub fn Event::resource(self : Event) -> @core.Resource? {
  match self {
    Added(r) | Modified(r) | Deleted(r) => Some(r)
    _ => None
  }
}

///|
pub fn Event::version(self : Event) -> String {
  match self {
    Bookmark(rv) => rv
    Added(r) | Modified(r) | Deleted(r) => r.resource_version()
    _ => ""
  }
}
