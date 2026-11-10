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
      "image": { "type": "string", "minLength": 1 },
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
          "securityContext": {
            "runAsNonRoot": true,
            "seccompProfile": { "type": "RuntimeDefault" },
          },
          "containers": [
            {
              "name": "app",
              "image": image,
              "securityContext": {
                "allowPrivilegeEscalation": false,
                "capabilities": { "drop": ["ALL"] },
              },
              "resources": {
                "requests": { "cpu": "50m", "memory": "32Mi" },
                "limits": { "cpu": "500m", "memory": "128Mi" },
              },
              "ports": [{ "containerPort": @core.field(spec, "port") }],
            },
          ],
        },
      },
    },
  }).controlled_by(app, dependent_type=deployment_type, owner_type=app_type)
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
  }).controlled_by(app, dependent_type=service_type, owner_type=app_type)
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
  adopt_unowned~ : Bool = false,
) -> @controller.Outcome {
  let app = client.get(app_type, key.ns, key.name) catch {
    @core.Api(404, _) => return Complete
    error => raise error
  }
  if app.deleting() {
    return Complete
  } // OwnerReference garbage collection owns children.
  let mut spec_accepted = false
  let failure : Error? = try {
    ignore(@crd.validate(spec_schema(), @core.field(app.json(), "spec")))
    spec_accepted = true
    apply_resources(client, app, adopt_unowned~)
    None
  } catch {
    error => Some(error)
  }
  if failure is Some(error) {
    let (accepted, reason, message) = match error {
      @core.Invalid(_) =>
        (
          spec_accepted,
          if spec_accepted {
            "OwnershipConflict"
          } else {
            "InvalidSpec"
          },
          "Check the spec and child resource ownership",
        )
      @core.Api(403, _) =>
        (
          true, "Forbidden", "ServiceAccount permissions do not allow the requested operation",
        )
      @core.Api(409, _) =>
        (
          true, "Conflict", "A resource changed concurrently; reconciliation will retry",
        )
      @core.Api(_, _) =>
        (true, "ApiFailure", "A Kubernetes API operation failed")
      _ =>
        (
          true, "ReconcileFailure", "Reconciliation failed; consult the safe operator event log",
        )
    }
    // Do not replace an original failure if status writing also fails.
    publish_status(client, app, accepted~, applied=false, reason~, message~) catch {
      _ => ()
    }
    raise error
  }
  publish_status(
    client,
    app,
    accepted=true,
    applied=true,
    reason="ResourcesApplied",
    message="Desired Deployment and Service API resources have been applied",
  )
  RequeueAfter(30000)
}

///|
async fn apply_resources(
  client : @client.Client,
  app : @core.Resource,
  adopt_unowned~ : Bool,
) -> Unit {
  let key = app.key()
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
        let references = @core.field(actual.metadata(), "ownerReferences")
        let ours = match references {
          Array(refs) =>
            refs.any(entry => {
              @core.field(entry, "controller") == Json::boolean(true) &&
              @core.field(entry, "uid") == @core.field(app.metadata(), "uid")
            })
          _ => false
        }
        if !ours && !adopt_unowned {
          raise @core.Invalid("refusing to adopt an existing resource")
        }
        // Explicit adoption still rejects a foreign controlling owner.
        let owned = actual.controlled_by(
          app,
          dependent_type=kind,
          owner_type=app_type,
        )
        // Owner references have merge-by-identity semantics, not array replacement.
        let expected = expected.with_metadata(
          "ownerReferences",
          @core.field(owned.metadata(), "ownerReferences"),
        )
        let merged = overlay(owned.json(), expected.json())
        if !contains_desired(actual.json(), expected.json()) {
          ignore(client.update(kind, @core.Resource::from_json(merged)))
        }
      }
    }
  }
}
