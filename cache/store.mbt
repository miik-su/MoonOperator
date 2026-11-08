///|
/// Mutations are synchronous on one cooperative event loop.
pub struct Store {
  mut objects : Map[@core.Key, @core.Resource]
  synced : Map[@core.GVK, Bool]
  capacity : Int32
  max_bytes : Int32
  max_object_bytes : Int32
  mut sizes : Map[@core.Key, Int32]
  mut used_bytes : Int32
}

///|
pub fn Store::new(
  capacity~ : Int32 = 10000,
  max_bytes~ : Int32 = 67108864,
  max_object_bytes~ : Int32 = 1048576,
) -> Store {
  {
    objects: Map([]),
    synced: Map([]),
    capacity,
    max_bytes,
    max_object_bytes,
    sizes: Map([]),
    used_bytes: 0,
  }
}

///|
/// Compact JSON bytes retained, excluding runtime/container overhead.
pub fn Store::bytes(self : Store) -> Int32 {
  self.used_bytes
}

///|
pub fn Store::length(self : Store) -> Int32 {
  self.objects.length()
}

///|
fn Store::validate_budget(self : Store) -> Unit raise @core.OperatorError {
  if self.capacity < 0 || self.max_bytes < 0 || self.max_object_bytes < 0 {
    raise @core.Invalid("cache budgets must be nonnegative")
  }
}

///|
fn Store::resource_size(
  self : Store,
  resource : @core.Resource,
) -> Int32 raise @core.OperatorError {
  resource.byte_size(max_bytes=self.max_object_bytes) catch {
    @core.Capacity(reason) => raise @core.CacheCapacity(reason)
    error => raise error
  }
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
  self.validate_budget()
  let staged : Map[@core.Key, @core.Resource] = Map([])
  let sizes : Map[@core.Key, Int32] = Map([])
  let mut total = 0
  for key, resource in self.objects {
    if key.gvk != gvk {
      staged[key] = resource
      let size = self.sizes.get(key).unwrap_or(0)
      sizes[key] = size
      total += size
    }
  }
  for resource in items {
    if resource.key().gvk != gvk {
      raise @core.Invalid("snapshot kind mismatch")
    }
    let size = self.resource_size(resource)
    let previous = sizes.get(resource.key()).unwrap_or(0)
    if size > self.max_bytes - (total - previous) {
      raise @core.CacheCapacity("cache byte capacity")
    }
    total = total - previous + size
    sizes[resource.key()] = size
    staged[resource.key()] = resource
    if staged.length() > self.capacity {
      raise @core.CacheCapacity("cache capacity")
    }
  }
  self.objects = staged
  self.sizes = sizes
  self.used_bytes = total
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
      if @core.field(@core.field(resource.metadata(), "labels"), name) !=
        Json::string(value) {
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
  self.validate_budget()
  match event {
    Added(r) | Modified(r) => {
      let size = self.resource_size(r)
      let previous = self.sizes.get(r.key()).unwrap_or(0)
      if size > self.max_bytes - (self.used_bytes - previous) {
        raise @core.CacheCapacity("cache byte capacity")
      }
      if !self.objects.contains(r.key()) &&
        self.objects.length() >= self.capacity {
        raise @core.CacheCapacity("cache capacity")
      }
      self.objects[r.key()] = r
      self.sizes[r.key()] = size
      self.used_bytes = self.used_bytes - previous + size
    }
    Deleted(r) =>
      // Ignore delayed tombstones for a previous incarnation of the name.
      if self.objects.get(r.key()) is Some(old) &&
        @core.field(old.metadata(), "uid") == @core.field(r.metadata(), "uid") {
        self.objects.remove(r.key())
        self.used_bytes -= self.sizes.get(r.key()).unwrap_or(0)
        self.sizes.remove(r.key())
      }
    _ => ()
  }
}
