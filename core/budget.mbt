///|
priv struct JsonBudget {
  mut remaining : Int32
  mut nodes : Int32
  max_depth : Int32
}

///|
/// Measure compact JSON UTF-8 size before copying/serializing. Depth and node
/// limits also reject cyclic in-memory JSON values without unbounded recursion.
pub fn json_size(
  value : Json,
  max_bytes~ : Int32 = 4194304,
  max_depth~ : Int32 = 128,
  max_nodes~ : Int32 = 100000,
) -> Int32 raise OperatorError {
  if max_bytes < 0 || max_depth < 0 || max_depth > 128 || max_nodes <= 0 {
    raise Invalid("invalid JSON budget")
  }
  let budget : JsonBudget = {
    remaining: max_bytes,
    nodes: max_nodes,
    max_depth,
  }
  budget.visit(value, 0)
  max_bytes - budget.remaining
}

///|
fn JsonBudget::consume(
  self : JsonBudget,
  bytes : Int32,
) -> Unit raise OperatorError {
  if bytes > self.remaining {
    raise Capacity("JSON byte limit")
  }
  self.remaining -= bytes
}

///|
fn JsonBudget::string(
  self : JsonBudget,
  value : String,
) -> Unit raise OperatorError {
  self.consume(2)
  for c in value {
    let cp = c.to_int()
    let size = if c == '"' ||
      c == '\\' ||
      c == '\n' ||
      c == '\r' ||
      c == '\t' ||
      cp == 8 ||
      cp == 12 {
      2
    } else if cp < 32 {
      6
    } else if cp < 128 {
      1
    } else if cp < 2048 {
      2
    } else if cp < 65536 {
      3
    } else {
      4
    }
    self.consume(size)
  }
}

///|
fn JsonBudget::visit(
  self : JsonBudget,
  value : Json,
  depth : Int32,
) -> Unit raise OperatorError {
  if depth > self.max_depth || self.nodes <= 0 {
    raise Capacity("JSON depth or node limit")
  }
  self.nodes -= 1
  match value {
    Object(fields) => {
      self.consume(2)
      let mut first = true
      for key, item in fields {
        if !first {
          self.consume(1)
        }
        first = false
        self.string(key)
        self.consume(1)
        self.visit(item, depth + 1)
      }
    }
    Array(items) => {
      self.consume(2)
      for i, item in items {
        if i > 0 {
          self.consume(1)
        }
        self.visit(item, depth + 1)
      }
    }
    String(s) => self.string(s)
    _ => self.consume(value.stringify().length())
  }
}

///|
/// Encoded resource size, with the same bounded traversal used by transport.
pub fn Resource::byte_size(
  self : Resource,
  max_bytes~ : Int32 = 4194304,
) -> Int32 raise OperatorError {
  json_size(self.value, max_bytes~)
}
