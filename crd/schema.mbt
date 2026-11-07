///|
/// A deliberately bounded OpenAPI subset: objects, arrays, scalars, required,
/// enum, numeric range and defaults. Unknown keywords are left to API validation.
pub fn validate(schema : Json, input : Json) -> Json raise @core.OperatorError {
  validate_at(schema, @core.copy_json(input), 0)
}

///|
fn validate_at(
  schema : Json,
  input : Json,
  depth : Int32,
) -> Json raise @core.OperatorError {
  if depth > 64 {
    raise @core.Invalid("schema nesting limit")
  }
  let kind = @core.text(@core.field(schema, "type"))
  let valid = match (kind, input) {
    ("object", Object(_))
    | ("array", Array(_))
    | ("string", String(_))
    | ("boolean", True)
    | ("boolean", False)
    | ("number", Number(_, ..)) => true
    ("integer", Number(n, ..)) => n == n.floor()
    _ => false
  }
  if !valid {
    raise @core.Invalid("schema type mismatch: " + kind)
  }
  if @core.field(schema, "enum") is Array(values) && !values.contains(input) {
    raise @core.Invalid("schema enum mismatch")
  }
  match input {
    Object(fields) => {
      if @core.field(schema, "properties") is Object(properties) {
        for key, property in properties {
          match fields.get(key) {
            Some(value) => fields[key] = validate_at(property, value, depth + 1)
            None =>
              if @core.field(property, "default") != Json::null() {
                fields[key] = validate_at(
                  property,
                  @core.copy_json(@core.field(property, "default")),
                  depth + 1,
                )
              }
          }
        }
      }
      if @core.field(schema, "required") is Array(required) {
        for key in required {
          if !fields.contains(@core.text(key)) {
            raise @core.Invalid("missing required field: " + @core.text(key))
          }
        }
      }
      input
    }
    Array(items) =>
      Json::array(
        items.map(item => {
          validate_at(@core.field(schema, "items"), item, depth + 1)
        }),
      )
    Number(n, ..) => {
      if @core.field(schema, "minimum") is Number(minimum, ..) && n < minimum {
        raise @core.Invalid("below minimum")
      }
      if @core.field(schema, "maximum") is Number(maximum, ..) && n > maximum {
        raise @core.Invalid("above maximum")
      }
      input
    }
    _ => input
  }
}

///|
/// Generate a single storage version with status subresource.
pub fn definition(
  kind : @core.ResourceType,
  singular : String,
  schema : Json,
) -> Json raise @core.OperatorError {
  if kind.gvk.group.is_empty() || kind.plural.is_empty() {
    raise @core.Invalid("CRD group/plural required")
  }
  {
    "apiVersion": "apiextensions.k8s.io/v1",
    "kind": "CustomResourceDefinition",
    "metadata": { "name": kind.plural + "." + kind.gvk.group },
    "spec": {
      "group": kind.gvk.group,
      "scope": if kind.scope == Namespaced {
        "Namespaced"
      } else {
        "Cluster"
      },
      "names": {
        "plural": kind.plural,
        "singular": singular,
        "kind": kind.gvk.kind,
      },
      "versions": [
        {
          "name": kind.gvk.version,
          "served": true,
          "storage": true,
          "subresources": { "status": {} },
          "schema": { "openAPIV3Schema": schema },
        },
      ],
    },
  }
}
