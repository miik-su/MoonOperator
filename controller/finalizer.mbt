///|
pub(all) enum FinalizeResult {
  Continue
  FinalizerAdded
  CleanupPending
  CleanupComplete
  NoLongerResponsible
} derive(Debug, Eq)

///|
pub extend FinalizeResult with Eq::{equal, not_equal}

///|
pub extend FinalizeResult with Debug::{to_repr}

///|
/// Requeue only FinalizerAdded/CleanupPending. The two deletion completion
/// outcomes must stop normal reconciliation without scheduling another attempt.
/// Failures/conflicts retain the finalizer and propagate to the worker policy.
pub async fn finalize(
  client : @client.Client,
  kind : @core.ResourceType,
  resource : @core.Resource,
  name : String,
  cleanup : async (@core.Resource) -> Bool,
  cleanup_timeout_ms~ : Int32 = 30000,
) -> FinalizeResult {
  if cleanup_timeout_ms <= 0 {
    raise @core.Invalid("cleanup deadline must be positive")
  }
  let present = resource.finalizers().contains(name)
  if resource.deleting() {
    if !present {
      return NoLongerResponsible
    }
    if !@async.with_timeout(cleanup_timeout_ms, () => cleanup(resource)) {
      return CleanupPending
    }
    ignore(client.update(kind, resource.set_finalizer(name, false)))
    return CleanupComplete
  }
  if !present {
    ignore(client.update(kind, resource.set_finalizer(name, true)))
    return FinalizerAdded
  }
  Continue
}
