///|
test "JSON budget measures UTF8 escaping and rejects depth before copying" {
  let value : Json = { "unicode": "中文😀", "escaped": "\n\u0001\\\"" }
  assert_eq(@core.json_size(value), @utf8.encode(value.stringify()).length())
  assert_true(
    try @core.json_size(value, max_bytes=8) catch {
      @core.Capacity(_) => true
      _ => false
    } noraise {
      _ => false
    },
  )
  let fields : Map[String, Json] = Map([])
  let cycle = Json::object(fields)
  fields["self"] = cycle
  assert_true(
    try @core.Resource::from_json(cycle) catch {
      @core.Capacity(_) => true
      _ => false
    } noraise {
      _ => false
    },
  )
  fields.remove("self")
}

///|
test "metadata RV remains opaque but cannot be coerced from a number" {
  assert_true(
    try
      @core.Resource::from_json({
        "apiVersion": "v1",
        "kind": "Pod",
        "metadata": { "name": "x", "resourceVersion": 123 },
      })
    catch {
      @core.Invalid(_) => true
      _ => false
    } noraise {
      _ => false
    },
  )
}
