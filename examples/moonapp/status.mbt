///|
/// Ready remains Unknown: applying API objects is not evidence that Pods serve
/// traffic. Fixed public messages never contain server payloads or spec values.
async fn publish_status(
  client : @client.Client,
  app : @core.Resource,
  accepted~ : Bool,
  applied~ : Bool,
  reason~ : String,
  message~ : String,
) -> Unit {
  let old = @core.field(app.json(), "status")
  let generation = @core.field(app.metadata(), "generation")
  let time = @core.rfc3339(@env.now().reinterpret_as_int64() / 1000L)
  let mut conditions = @core.field(old, "conditions")
  for
    (kind, state, why, text) in [
      (
        "Accepted",
        if accepted {
          "True"
        } else {
          "False"
        },
        if accepted {
          "SpecAccepted"
        } else {
          reason
        },
        if accepted {
          "Resource spec was accepted for reconciliation"
        } else {
          message
        },
      ),
      (
        "ResourcesApplied",
        if applied {
          "True"
        } else {
          "False"
        },
        reason,
        message,
      ),
      (
        "Ready", "Unknown", "ReadinessNotObserved", "Pod readiness is outside this controller's observation scope",
      ),
      ("Degraded", if applied { "False" } else { "True" }, reason, message),
    ] {
    conditions = @core.conditions_upsert(conditions, {
      "type": kind,
      "status": state,
      "reason": why,
      "message": text,
      "observedGeneration": generation,
      "lastTransitionTime": time,
    })
  }
  let status : Json = {
    "observedGeneration": generation,
    "phase": if applied {
      "ResourcesApplied"
    } else {
      "Degraded"
    },
    "conditions": conditions,
  }
  if old != status {
    ignore(
      client.update(app_type, app.with_field("status", status), status=true),
    )
  }
}
