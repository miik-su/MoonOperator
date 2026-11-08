///|
/// True means normal reconciliation may proceed. False means a finalizer update
/// or deletion cleanup occurred and the caller should requeue. Cleanup must be
/// idempotent: failures/conflicts leave the finalizer in place for the next run.
pub async fn finalize(
  client : @client.Client,
  kind : @core.ResourceType,
  resource : @core.Resource,
  name : String,
  cleanup : async (@core.Resource) -> Bool,
) -> Bool {
  let present = resource.finalizers().contains(name)
  if resource.deleting() {
    if present && cleanup(resource) {
      ignore(client.update(kind, resource.set_finalizer(name, false)))
    }
    return false
  }
  if !present {
    ignore(client.update(kind, resource.set_finalizer(name, true)))
    return false
  }
  true
}
