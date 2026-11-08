///|
/// Ignore repeated resource versions, while keeping initial/add/delete events.
pub fn changed(old : @core.Resource?, event : Event) -> Bool {
  match (old, event) {
    (Some(old), Modified(resource)) =>
      old.resource_version().is_empty() ||
      old.resource_version() != resource.resource_version()
    (_, Added(_) | Deleted(_)) => true
    (None, Modified(_)) => true
    _ => false
  }
}

///|
/// Ignore status-only changes when generation is available. Deletion/finalizer
/// transitions still trigger cleanup. For resources without generation, fall back
/// to RV changes rather than suppressing meaningful updates.
pub fn generation_changed(old : @core.Resource?, event : Event) -> Bool {
  match (old, event) {
    (Some(old), Modified(resource)) => {
      let before = old.metadata()
      let after = resource.metadata()
      if @core.field(before, "deletionTimestamp") !=
        @core.field(after, "deletionTimestamp") ||
        @core.field(before, "finalizers") != @core.field(after, "finalizers") {
        return true
      }
      if @core.field(before, "generation") == Json::null() ||
        @core.field(after, "generation") == Json::null() {
        return changed(Some(old), event)
      }
      @core.field(before, "generation") != @core.field(after, "generation")
    }
    _ => changed(old, event)
  }
}
