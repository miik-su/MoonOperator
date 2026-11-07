///|
test "schema defaults and required integer bounds" {
  let schema : Json = {
    "type": "object",
    "required": ["image"],
    "properties": {
      "image": { "type": "string" },
      "replicas": {
        "type": "integer",
        "default": 1,
        "minimum": 0,
        "maximum": 100,
      },
    },
  }
  let input : Json = { "image": "nginx" }
  let result = @crd.validate(schema, input)
  assert_eq(@core.field(result, "replicas"), Json::number(1.0))
  assert_eq(@core.field(input, "replicas"), Json::null())
  assert_true(
    try @crd.validate(schema, { "image": "nginx", "replicas": -1 }) catch {
      _ => true
    } noraise {
      _ => false
    },
  )
}
