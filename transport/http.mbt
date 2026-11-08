///|
/// Establish a verified connection and send one request. Caller owns close().
pub async fn Config::open(
  self : Config,
  request : @client.Request,
) -> (@http.Response, @http.Client) {
  if !request.path.has_prefix("/") ||
    request.path.has_prefix("//") ||
    request.path.contains_any(chars="\\#") ||
    !safe_header(request.path) ||
    request.path.length() > 16384 ||
    !safe_header(request.content_type) ||
    request.content_type.length() > 256 {
    raise @core.Invalid(
      "request must use a safe origin-relative target and headers",
    )
  }
  if request.body != Json::null() {
    ignore(@core.json_size(request.body, max_bytes=self.max_request_bytes))
  }
  let now = @async.now()
  let delay = self.next_request_ms - now
  self.next_request_ms = (if delay > 0L { self.next_request_ms } else { now }) +
    self.min_interval_ms.to_int64()
  if delay > 0L {
    @async.sleep(delay.to_int())
  }
  @async.with_timeout(self.timeout_ms, () => {
    let token = if self.token_file.is_empty() {
      self.token
    } else {
      if @fs.file_size(self.token_file) > 16384L {
        raise @core.Capacity("bearer token file limit")
      }
      @fs.read_file(self.token_file).text().trim().to_owned()
    }
    if !safe_header(token) || token.length() > 16384 {
      raise @core.Invalid("invalid bearer token")
    }
    let headers : @http.Headers = {
      "Accept": "application/json",
      "Content-Type": request.content_type,
    }
    if !token.is_empty() {
      headers["Authorization"] = "Bearer " + token
    }
    let trust : @tls.TrustedRoot = if self.ca_file.is_empty() {
      SystemRoot
    } else {
      CustomPemFile(self.ca_file)
    }
    let conn = @http.Client(self.server, headers~, trust~)
    errdefer conn.close()
    let verb : @http.RequestMethod = match request.verb {
      "GET" => Get
      "POST" => Post
      "PUT" => Put
      "PATCH" => Patch
      "DELETE" => Delete
      _ => raise @core.Invalid("unsupported HTTP verb")
    }
    conn.request(verb, request.path)
    if request.body != Json::null() {
      conn.write(request.body.stringify())
    }
    let response = conn.end_request()
    if response.code >= 300 && response.code < 400 {
      raise @core.Api(response.code, "RedirectRefused")
    }
    (response, conn)
  })
}

///|
/// Enforce the response limit while reading, before allocating/decoding JSON.
pub async fn Config::send(
  self : Config,
  request : @client.Request,
) -> @client.Response {
  let started = @async.now()
  self.metrics.increment("api_request")
  defer self.metrics.observe("api", @async.now() - started)
  @async.with_timeout(self.timeout_ms, () => {
    let (response, conn) = self.open(request)
    if response.code >= 400 {
      self.metrics.increment("api_error")
    }
    defer conn.close()
    let bytes = Buffer()
    for ;; {
      match conn.read_some(max_len=8192) {
        None => break
        Some(chunk) => {
          if bytes.length() + chunk.length() > self.max_response_bytes {
            raise @core.Capacity("HTTP response byte limit")
          }
          bytes.write_bytes(chunk)
        }
      }
    }
    let body = if bytes.length() == 0 ||
      response.code < 200 ||
      response.code >= 300 {
      Json::null()
    } else {
      @json.parse(
        @utf8.decode(bytes.to_bytes()),
        max_nesting_depth=128,
        reject_duplicate_keys=true,
      )
    }
    let retry_after_seconds = match response.headers.get("Retry-After") {
      Some(value) =>
        try @json.parse(value) catch {
          _ => None
        } noraise {
          Number(n, ..) =>
            if n == n.floor() && n >= 0.0 && n <= 3600.0 {
              Some(n.to_int())
            } else {
              None
            }
          _ => None
        }
      None => None
    }
    { code: response.code, body, retry_after_seconds, }
  })
}

///|
pub fn Config::client(self : Config) -> @client.Client {
  @client.Client::new(request => self.send(request))
}
