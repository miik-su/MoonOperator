///|
/// Credentials are private and have no derived Debug/Show implementation.
pub struct Config {
  metrics : @observability.Metrics
  server : String
  token : String
  token_file : String
  ca_file : String
  timeout_ms : Int32
  max_response_bytes : Int32
  max_request_bytes : Int32
  min_interval_ms : Int32
  mut next_request_ms : Int64
}

///|
/// HTTPS is required except an explicitly enabled loopback development proxy.
pub fn Config::new(
  server : String,
  token~ : String = "",
  token_file~ : String = "",
  ca_file~ : String = "",
  timeout_ms~ : Int32 = 30000,
  max_response_bytes~ : Int32 = 4194304,
  max_request_bytes~ : Int32 = 4194304,
  min_interval_ms~ : Int32 = 20,
  allow_loopback_http~ : Bool = false,
  metrics~ : @observability.Metrics = @observability.Metrics::new(),
) -> Config raise @core.OperatorError {
  let server = server.trim_end(chars="/").to_owned()
  let authority = if server.has_prefix("https://") {
    server[8:].to_owned()
  } else if allow_loopback_http &&
    (
      server.has_prefix("http://127.0.0.1:") ||
      server.has_prefix("http://localhost:")
    ) {
    server[7:].to_owned()
  } else {
    raise @core.Invalid(
      "HTTPS required; HTTP allowed only for explicit loopback proxy",
    )
  }
  if authority.is_empty() ||
    authority.contains_any(chars="/@?#\\ \r\n\t") ||
    timeout_ms <= 0 ||
    max_response_bytes <= 0 ||
    max_request_bytes <= 0 ||
    min_interval_ms < 0 ||
    !safe_header(token) ||
    token.length() > 16384 {
    raise @core.Invalid("invalid transport configuration")
  }
  {
    metrics,
    server,
    token,
    token_file,
    ca_file,
    timeout_ms,
    max_response_bytes,
    max_request_bytes,
    min_interval_ms,
    next_request_ms: 0L,
  }
}

///|
fn safe_header(value : String) -> Bool {
  value.all(c => c.to_int() >= 32 && c.to_int() != 127)
}

///|
/// JSON kubeconfig subset: current context, bearer token/tokenFile, CA file.
/// Convert YAML using `kubectl config view --raw -o json`; exec auth is rejected.
pub fn Config::from_kubeconfig(
  input : Json,
  metrics~ : @observability.Metrics = @observability.Metrics::new(),
) -> Config raise @core.OperatorError {
  ignore(@core.json_size(input, max_bytes=1048576, max_depth=64))
  let context_name = config_string(input, "current-context", required=true)
  let context = named_entry(
    @core.field(input, "contexts"),
    context_name,
    "context",
  )
  let cluster = named_entry(
    @core.field(input, "clusters"),
    config_string(context, "cluster", required=true),
    "cluster",
  )
  let user = named_entry(
    @core.field(input, "users"),
    config_string(context, "user", required=true),
    "user",
  )
  let insecure = @core.field(cluster, "insecure-skip-tls-verify")
  if insecure != Json::null() && insecure != Json::boolean(false) {
    raise @core.Invalid("TLS verification must remain enabled")
  }
  for name in ["client-key", "client-key-data", "username", "password"] {
    if @core.field(user, name) != Json::null() {
      raise @core.Invalid("unsupported kubeconfig credential method")
    }
  }
  for name in ["proxy-url", "tls-server-name"] {
    if @core.field(cluster, name) != Json::null() {
      raise @core.Invalid("unsupported kubeconfig endpoint override")
    }
  }
  let token = config_string(user, "token")
  let token_file = config_string(user, "tokenFile")
  if !token.is_empty() && !token_file.is_empty() {
    raise @core.Invalid("ambiguous kubeconfig bearer credentials")
  }
  if @core.field(user, "exec") != Json::null() ||
    @core.field(user, "auth-provider") != Json::null() ||
    @core.field(user, "client-certificate") != Json::null() ||
    @core.field(user, "client-certificate-data") != Json::null() ||
    @core.field(cluster, "certificate-authority-data") != Json::null() {
    raise @core.Invalid(
      "unsupported kubeconfig credentials or embedded CA; use bearer token and CA file",
    )
  }
  Config::new(
    config_string(cluster, "server", required=true),
    token~,
    token_file~,
    ca_file=config_string(cluster, "certificate-authority"),
    metrics~,
  )
}

///|
fn named_entry(
  items : Json,
  name : String,
  field : String,
) -> Json raise @core.OperatorError {
  let names : Map[String, Bool] = Map([])
  let mut found : Json? = None
  if items is Array(items) {
    for item in items {
      let entry_name = config_string(item, "name", required=true)
      if names.contains(entry_name) {
        raise @core.Invalid("duplicate kubeconfig entry name")
      }
      names[entry_name] = true
      let value = @core.field(item, field)
      guard value is Object(_) else {
        raise @core.Invalid("kubeconfig entry must be an object")
      }
      if entry_name == name {
        found = Some(value)
      }
    }
  }
  if found is Some(value) {
    return value
  }
  raise @core.Invalid("kubeconfig context/cluster/user not found")
}

///|
fn config_string(
  input : Json,
  name : String,
  required~ : Bool = false,
) -> String raise @core.OperatorError {
  match @core.field(input, name) {
    String(value) => {
      if required && value.is_empty() {
        raise @core.Invalid("empty kubeconfig reference")
      }
      value
    }
    Null =>
      if required {
        raise @core.Invalid("missing kubeconfig reference")
      } else {
        ""
      }
    _ => raise @core.Invalid("kubeconfig string field has invalid type")
  }
}

///|
/// Caller supplies KUBERNETES_SERVICE_HOST/PORT; projected token is reread per request.
pub fn Config::in_cluster(
  host : String,
  port~ : String = "443",
  service_account_dir~ : String = "/var/run/secrets/kubernetes.io/serviceaccount",
  metrics~ : @observability.Metrics = @observability.Metrics::new(),
) -> Config raise @core.OperatorError {
  let host = if host.contains(":") { "[" + host + "]" } else { host }
  Config::new(
    "https://" + host + ":" + port,
    token_file=service_account_dir + "/token",
    ca_file=service_account_dir + "/ca.crt",
    metrics~,
  )
}
