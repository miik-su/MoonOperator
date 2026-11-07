///|
pub let app_type : @core.ResourceType = {
  gvk: { group: "moonoperator.dev", version: "v1", kind: "MoonApp", },
  plural: "moonapps",
  scope: Namespaced,
}

///|
pub let deployment_type : @core.ResourceType = {
  gvk: { group: "apps", version: "v1", kind: "Deployment", },
  plural: "deployments",
  scope: Namespaced,
}

///|
pub let service_type : @core.ResourceType = {
  gvk: { group: "", version: "v1", kind: "Service", },
  plural: "services",
  scope: Namespaced,
}

///|
pub fn spec_schema() -> Json {
  {
    "type": "object",
    "required": ["image"],
    "properties": {
      "image": { "type": "string" },
      "replicas": {
        "type": "integer",
        "default": 1,
        "minimum": 0,
        "maximum": 1000,
      },
      "port": {
        "type": "integer",
        "default": 80,
        "minimum": 1,
        "maximum": 65535,
      },
    },
  }
}

///|
pub fn desired(
  app : @core.Resource,
) -> Array[(@core.ResourceType, @core.Resource)] raise {
  let spec = @crd.validate(spec_schema(), @core.field(app.json(), "spec"))
  let image = @core.text(@core.field(spec, "image"))
  if image.is_empty() {
    raise @core.Invalid("MoonApp image is empty")
  }
  let key = app.key()
  let labels : Json = {
    "app.kubernetes.io/instance": key.name,
    "app.kubernetes.io/managed-by": "moonoperator",
  }
  let meta : Json = { "name": key.name, "namespace": key.ns, "labels": labels }
  let deployment = @core.Resource::from_json({
    "apiVersion": "apps/v1",
    "kind": "Deployment",
    "metadata": meta,
    "spec": {
      "replicas": @core.field(spec, "replicas"),
      "selector": { "matchLabels": labels },
      "template": {
        "metadata": { "labels": labels },
        "spec": {
          "containers": [
            {
              "name": "app",
              "image": image,
              "ports": [{ "containerPort": @core.field(spec, "port") }],
            },
          ],
        },
      },
    },
  }).controlled_by(app)
  let service = @core.Resource::from_json({
    "apiVersion": "v1",
    "kind": "Service",
    "metadata": meta,
    "spec": {
      "selector": labels,
      "ports": [
        {
          "port": @core.field(spec, "port"),
          "targetPort": @core.field(spec, "port"),
        },
      ],
    },
  }).controlled_by(app)
  [(deployment_type, deployment), (service_type, service)]
}

///|
/// Only compare desired fields: API-server defaults must not cause write loops.
fn contains_desired(actual : Json, expected : Json) -> Bool {
  match (actual, expected) {
    (Object(actual), Object(expected)) => {
      for key, value in expected {
        if !contains_desired(actual.get(key).unwrap_or(Json::null()), value) {
          return false
        }
      }
      true
    }
    (Array(actual), Array(expected)) => {
      if actual.length() != expected.length() {
        return false
      }
      for i, value in expected {
        if !contains_desired(actual[i], value) {
          return false
        }
      }
      true
    }
    _ => actual == expected
  }
}

///|
/// Merge desired object fields without removing server-assigned fields.
fn overlay(actual : Json, expected : Json) -> Json {
  match (actual, expected) {
    (Object(actual), Object(expected)) => {
      for key, value in expected {
        actual[key] = overlay(actual.get(key).unwrap_or(Json::null()), value)
      }
      Json::object(actual)
    }
    _ => @core.copy_json(expected)
  }
}

///|
pub async fn reconcile(
  client : @client.Client,
  key : @core.Key,
) -> @controller.Outcome {
  let app = client.get(app_type, key.ns, key.name) catch {
    @core.Api(404, _) => return Complete
    error => raise error
  }
  if app.deleting() {
    return Complete
  } // OwnerReference garbage collection owns children.
  for (kind, expected) in desired(app) {
    let existing = try client.get(kind, key.ns, key.name) catch {
      @core.Api(404, _) => None
      error => raise error
    } noraise {
      resource => Some(resource)
    }
    match existing {
      None => ignore(client.create(kind, expected))
      Some(actual) => {
        // Refuse to adopt a same-name resource controlled by someone else.
        let owned = actual.controlled_by(app)
        let merged = overlay(owned.json(), expected.json())
        if !contains_desired(actual.json(), expected.json()) {
          ignore(client.update(kind, @core.Resource::from_json(merged)))
        }
      }
    }
  }
  let status : Json = {
    "observedGeneration": @core.field(app.metadata(), "generation"),
    "phase": "ResourcesApplied",
  }
  if @core.field(app.json(), "status") != status {
    ignore(
      client.update(app_type, app.with_field("status", status), status=true),
    )
  }
  // Periodic resync repairs child drift even when no MoonApp event occurs.
  RequeueAfter(30000)
}
