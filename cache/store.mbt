///|
/// Mutations are synchronous on one cooperative event loop.
pub struct Store {
  mut objects : Map[@core.Key, @core.Resource]
  synced : Map[@core.GVK, Bool]
  capacity : Int32
}

///|
pub fn Store::new(capacity~ : Int32 = 10000) -> Store {
  { objects: Map([]), synced: Map([]), capacity, }
}

///|
pub fn Store::ready(self : Store, gvk : @core.GVK) -> Bool {
  self.synced.get(gvk).unwrap_or(false)
}

///|
pub fn Store::invalidate(self : Store, gvk : @core.GVK) -> Unit {
  self.synced[gvk] = false
}

///|
/// Stage the entire snapshot before publishing; failure leaves old data intact.
pub fn Store::replace(
  self : Store,
  gvk : @core.GVK,
  items : Array[@core.Resource],
) -> Unit raise @core.OperatorError {
  let staged : Map[@core.Key, @core.Resource] = Map([])
  for key, resource in self.objects {
    if key.gvk != gvk {
      staged[key] = resource
    }
  }
  for resource in items {
    if resource.key().gvk != gvk {
      raise @core.Invalid("snapshot kind mismatch")
    }
    staged[resource.key()] = resource
    if staged.length() > self.capacity {
      raise @core.Capacity("cache capacity")
    }
  }
  self.objects = staged
  self.synced[gvk] = true
}

///|
pub fn Store::get(self : Store, key : @core.Key) -> @core.Resource? {
  self.objects.get(key)
}

///|
pub fn Store::list(
  self : Store,
  gvk : @core.GVK,
  ns~ : String = "",
  labels~ : Map[String, String] = Map([]),
) -> Array[@core.Resource] {
  self.objects
  .values()
  .filter(resource => {
    let key = resource.key()
    let mut matches = true
    for name, value in labels {
      if @core.text(
          @core.field(@core.field(resource.metadata(), "labels"), name),
        ) !=
        value {
        matches = false
      }
    }
    key.gvk == gvk && (ns.is_empty() || key.ns == ns) && matches
  })
  .collect()
}

///|
pub fn Store::apply(
  self : Store,
  event : @watch.Event,
) -> Unit raise @core.OperatorError {
  match event {
    Added(r) | Modified(r) => {
      if !self.objects.contains(r.key()) &&
        self.objects.length() >= self.capacity {
        raise @core.Capacity("cache capacity")
      }
      self.objects[r.key()] = r
    }
    Deleted(r) =>
      // Ignore delayed tombstones for a previous incarnation of the name.
      if self.objects.get(r.key()) is Some(old) &&
        @core.field(old.metadata(), "uid") == @core.field(r.metadata(), "uid") {
        self.objects.remove(r.key())
      }
    _ => ()
  }
}
