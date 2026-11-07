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
    min_interval_ms < 0 ||
    token.contains_any(chars="\r\n") {
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
    min_interval_ms,
    next_request_ms: 0L,
  }
}

///|
/// JSON kubeconfig subset: current context, bearer token/tokenFile, CA file.
/// Convert YAML using `kubectl config view --raw -o json`; exec auth is rejected.
pub fn Config::from_kubeconfig(
  input : Json,
  metrics~ : @observability.Metrics = @observability.Metrics::new(),
) -> Config raise @core.OperatorError {
  let context_name = @core.text(@core.field(input, "current-context"))
  let context = named_entry(
    @core.field(input, "contexts"),
    context_name,
    "context",
  )
  let cluster = named_entry(
    @core.field(input, "clusters"),
    @core.text(@core.field(context, "cluster")),
    "cluster",
  )
  let user = named_entry(
    @core.field(input, "users"),
    @core.text(@core.field(context, "user")),
    "user",
  )
  if @core.field(cluster, "insecure-skip-tls-verify") == Json::boolean(true) ||
    @core.field(user, "exec") != Json::null() ||
    @core.field(user, "auth-provider") != Json::null() ||
    @core.field(user, "client-certificate") != Json::null() ||
    @core.field(user, "client-certificate-data") != Json::null() ||
    @core.field(cluster, "certificate-authority-data") != Json::null() {
    raise @core.Invalid(
      "unsupported kubeconfig credentials or embedded CA; use bearer token and CA file",
    )
  }
  Config::new(
    @core.text(@core.field(cluster, "server")),
    token=@core.text(@core.field(user, "token")),
    token_file=@core.text(@core.field(user, "tokenFile")),
    ca_file=@core.text(@core.field(cluster, "certificate-authority")),
    metrics~,
  )
}

///|
fn named_entry(
  items : Json,
  name : String,
  field : String,
) -> Json raise @core.OperatorError {
  if items is Array(items) {
    for item in items {
      if @core.text(@core.field(item, "name")) == name {
        return @core.field(item, field)
      }
    }
  }
  raise @core.Invalid("kubeconfig context/cluster/user not found")
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
