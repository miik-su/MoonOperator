///|
priv struct Registration {
  controller : Controller
  ready : () -> Bool
  workers : Int32
}

///|
pub struct Manager {
  controllers : Map[String, Registration]
  mut running : Bool
}

///|
pub fn Manager::new() -> Manager {
  { controllers: Map([]), running: false, }
}

///|
pub fn Manager::register(
  self : Manager,
  name : String,
  controller : Controller,
  ready : () -> Bool,
  workers~ : Int32 = 1,
) -> Unit raise @core.OperatorError {
  if self.running ||
    name.is_empty() ||
    self.controllers.contains(name) ||
    workers < 1 ||
    workers > 128 {
    raise @core.Invalid("invalid controller registration")
  }
  self.controllers[name] = { controller, ready, workers, }
}

///|
pub fn Manager::ready(self : Manager) -> Bool {
  if !self.running || self.controllers.is_empty() {
    return false
  }
  for _, entry in self.controllers {
    if !(entry.ready)() {
      return false
    }
  }
  true
}

///|
pub fn Manager::stop(self : Manager) -> Unit {
  for _, entry in self.controllers {
    entry.controller.stop()
  }
  self.running = false
}

///|
pub async fn Manager::run(self : Manager) -> Unit {
  if self.running || self.controllers.is_empty() {
    raise @core.Invalid("manager already running or empty")
  }
  self.running = true
  defer self.stop()
  @async.with_task_group(group => {
    for _, entry in self.controllers {
      group.spawn_bg(() => {
        entry.controller.run(entry.ready, workers=entry.workers)
      })
    }
  })
}
