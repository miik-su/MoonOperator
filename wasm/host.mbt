///|
/// Experimental ABI v1: abi_version() -> i32 and validate(replicas:i32) -> i32.
/// Wasmtime 50.0.1 runs each call in a fresh process. No WASI imports or ambient
/// guest filesystem/network/environment are enabled. Precompiled code is denied.
pub struct Host {
  executable : String
  module_path : String
  fuel : Int32
  memory_bytes : Int32
  timeout_ms : Int32
}

///|
pub(all) suberror PluginError {
  ModuleLoad
  GuestTrap
  FuelExhausted
  MemoryLimit
  Deadline
  InvalidAbi
  InvalidResult
}

///|
pub fn Host::new(
  executable : String,
  module_path : String,
  fuel~ : Int32 = 1000000,
  memory_bytes~ : Int32 = 16777216,
  timeout_ms~ : Int32 = 5000,
) -> Host raise @core.OperatorError {
  if executable.is_empty() ||
    !(module_path.has_suffix(".wasm") || module_path.has_suffix(".wat")) ||
    fuel <= 0 ||
    fuel > 100000000 ||
    memory_bytes < 65536 ||
    memory_bytes > 67108864 ||
    timeout_ms < 10 ||
    timeout_ms > 30000 {
    raise @core.Invalid("invalid WASM host limits or module path")
  }
  { executable, module_path, fuel, memory_bytes, timeout_ms, }
}

///|
/// Only explicitly named exports and numeric arguments are ever passed to CLI.
async fn Host::invoke(
  self : Host,
  export_name : String,
  values : Array[String],
) -> Int32 {
  let size = @fs.file_size(self.module_path) catch { _ => raise ModuleLoad }
  if size > 1048576L {
    raise @core.Capacity("WASM module byte limit")
  }
  let args = [
    "run",
    "-C",
    "cache=n",
    "-S",
    "cli=n",
    "-S",
    "http=n",
    "-S",
    "nn=n",
    "-W",
    "fuel=\{self.fuel}",
    "-W",
    "max-memory-size=\{self.memory_bytes}",
    "-W",
    "max-table-elements=10000",
    "-W",
    "max-instances=1",
    "-W",
    "max-memories=1",
    "-W",
    "max-wasm-stack=1048576",
    "-W",
    "timeout=\{self.timeout_ms}ms",
    "--invoke",
    export_name,
    "--",
    self.module_path,
  ]
  args.append(values)
  let result = @shell.Cmd(self.executable, args, inherit_env=false, env={
    "MOONOPERATOR_WASM_HOST": "1",
  }).output(timeout_ms=self.timeout_ms, max_output_bytes=4096) catch {
    @async.TimeoutError => raise Deadline
    _ => raise ModuleLoad
  }
  if result.exit_code() != 0 {
    let diagnostic = result.stderr()
    if diagnostic.contains("fuel consumed") {
      raise FuelExhausted
    }
    if diagnostic.contains("memory limits") {
      raise MemoryLimit
    }
    if diagnostic.contains("wasm trap") {
      raise GuestTrap
    }
    raise ModuleLoad
  }
  let value = @json.parse(result.stdout().trim()) catch {
    _ => raise InvalidResult
  }
  match value {
    Number(n, ..) =>
      if n == n.floor() && n >= 0.0 && n <= 1.0 {
        n.to_int()
      } else {
        raise InvalidResult
      }
    _ => raise InvalidResult
  }
}

///|
/// JSON input/output stays host-side; guest sees only a validated scalar.
pub async fn Host::validate(self : Host, input : Json) -> Json {
  let replicas = match @core.field(input, "replicas") {
    Number(n, ..) =>
      if n == n.floor() && n >= -2147483648.0 && n <= 2147483647.0 {
        n.to_int()
      } else {
        raise @core.Invalid("replicas must be i32")
      }
    _ => raise @core.Invalid("replicas required")
  }
  let version = @shell.Cmd(self.executable, ["--version"], inherit_env=false, env={
    "MOONOPERATOR_WASM_HOST": "1",
  }).output(timeout_ms=self.timeout_ms, max_output_bytes=4096)
  if version.exit_code() != 0 ||
    !version.stdout().has_prefix("wasmtime 50.0.1 ") {
    raise @core.Invalid("WASM host requires Wasmtime 50.0.1")
  }
  if self.invoke("abi_version", []) != 1 {
    raise InvalidAbi
  }
  let code = self.invoke("validate", [replicas.to_string()])
  { "abiVersion": 1, "valid": code == 0 }
}
