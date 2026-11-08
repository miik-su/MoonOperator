///|
priv struct ScanFrame {
  mapping : Bool
  keys : Map[String, Bool]
  mut key : Bool
}

///|
priv struct ConfigScan {
  stack : Array[ScanFrame]
  mut nodes : Int32
  mut invalid : Bool
}

///|
/// Restrict kubeconfig YAML to a bounded JSON-compatible tree: no aliases,
/// anchors, custom tags, complex keys or duplicate mapping keys.
impl @yaml.MarkedEventReceiver for ConfigScan with fn on_event(
  self,
  event,
  _marker,
) {
  self.nodes += 1
  if self.nodes > 65536 {
    self.invalid = true
  }
  match event {
    Alias(..) => self.invalid = true
    Scalar(value~, id~, tag~, ..) => {
      if id != 0 || tag is Some(_) {
        self.invalid = true
      }
      self.consume(Some(value))
    }
    MappingStart(id~, tag~) | SequenceStart(id~, tag~) => {
      if id != 0 || tag is Some(_) {
        self.invalid = true
      }
      self.consume(None)
      self.stack.push({
        mapping: event is MappingStart(..),
        keys: Map([]),
        key: true,
      })
      if self.stack.length() > 64 {
        self.invalid = true
      }
    }
    MappingEnd | SequenceEnd => ignore(self.stack.pop())
    _ => ()
  }
}

///|
fn ConfigScan::consume(self : ConfigScan, scalar : String?) -> Unit {
  if self.stack.last() is Some(frame) && frame.mapping {
    if frame.key {
      match scalar {
        Some(key) => {
          if frame.keys.contains(key) {
            self.invalid = true
          }
          frame.keys[key] = true
        }
        None => self.invalid = true
      }
    }
    frame.key = !frame.key
  }
}

///|
/// Decode JSON or restricted YAML. Parser errors never echo credential text.
pub fn Config::parse_kubeconfig(
  input : String,
  metrics~ : @observability.Metrics = @observability.Metrics::new(),
) -> Config raise @core.OperatorError {
  if input.length() > 1048576 {
    raise @core.Capacity("kubeconfig input limit")
  }
  let value = if input.trim_start().has_prefix("{") {
    @json.parse(input, max_nesting_depth=64, reject_duplicate_keys=true) catch {
      _ => raise @core.Invalid("invalid JSON kubeconfig")
    }
  } else {
    let scan : ConfigScan = { stack: [], nodes: 0, invalid: false, }
    let parser = @yaml.Parser(input)
    parser.keep_tags(true)
    parser.load(scan, true) catch {
      _ => raise @core.Invalid("invalid YAML kubeconfig")
    }
    if scan.invalid {
      raise @core.Invalid("unsupported or unbounded YAML kubeconfig")
    }
    let documents = @yaml.Yaml::load_from_string(input) catch {
      _ => raise @core.Invalid("invalid YAML kubeconfig")
    }
    if documents.length() != 1 {
      raise @core.Invalid("one kubeconfig document required")
    }
    documents[0].to_json()
  }
  Config::from_kubeconfig(value, metrics~)
}

///|
/// Resolve CA/tokenFile relative to the kubeconfig file, as Kubernetes expects.
pub async fn Config::load_kubeconfig(
  path : String,
  metrics~ : @observability.Metrics = @observability.Metrics::new(),
) -> Config {
  if @fs.file_size(path) > 1048576L {
    raise @core.Capacity("kubeconfig file limit")
  }
  let config = Config::parse_kubeconfig(@fs.read_file(path).text(), metrics~)
  let absolute = @fs.realpath(path).replace_all(old="\\", new="/")
  let parent = match absolute.rev_split_once("/") {
    Some((dir, _)) => dir.to_owned()
    None => "."
  }
  fn resolve(value : String) -> String {
    if value.is_empty() ||
      value.has_prefix("/") ||
      (value.length() > 1 && value[1] == ':') {
      value
    } else {
      parent + "/" + value
    }
  }
  Config::new(
    config.server,
    token=config.token,
    token_file=resolve(config.token_file),
    ca_file=resolve(config.ca_file),
    metrics~,
  )
}
