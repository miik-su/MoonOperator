///|
test "transport rejects insecure endpoints and header injection" {
  let rejected = try
    @transport.Config::new("http://example.com", token="secret")
  catch {
    _ => true
  } noraise {
    _ => false
  }
  assert_true(rejected)
  let injected = try
    @transport.Config::new(
      "https://example.com",
      token="secret\r\nInjected: yes",
    )
  catch {
    _ => true
  } noraise {
    _ => false
  }
  assert_true(injected)
  ignore(
    @transport.Config::new("http://127.0.0.1:8001", allow_loopback_http=true),
  )
  let kubeconfig : Json = {
    "current-context": "demo",
    "contexts": [{ "name": "demo", "context": { "cluster": "c", "user": "u" } }],
    "clusters": [
      {
        "name": "c",
        "cluster": {
          "server": "https://api.example",
          "insecure-skip-tls-verify": true,
        },
      },
    ],
    "users": [{ "name": "u", "user": { "token": "secret" } }],
  }
  assert_true(
    try @transport.Config::from_kubeconfig(kubeconfig) catch {
      _ => true
    } noraise {
      _ => false
    },
  )
}
