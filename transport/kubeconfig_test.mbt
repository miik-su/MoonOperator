///|
test "YAML kubeconfig supports context and rejects ambiguous duplicate secrets" {
  let input =
    #|apiVersion: v1
    #|kind: Config
    #|current-context: demo
    #|contexts:
    #|  - name: demo
    #|    context:
    #|      cluster: c
    #|      user: u
    #|clusters:
    #|  - name: c
    #|    cluster:
    #|      server: https://api.example
    #|users:
    #|  - name: u
    #|    user:
    #|      token: test-token
  ignore(@transport.Config::parse_kubeconfig(input))
  for
    invalid in [
      input.replace_all(old="token: test-token", new="token: 123"),
      input + "\n  - name: u\n    user: {}\n",
      input.replace_all(
        old="token: test-token",
        new="token: test-token\n      tokenFile: /tmp/token",
      ),
      input.replace_all(
        old="server: https://api.example",
        new="server: https://api.example\n      insecure-skip-tls-verify: nope",
      ),
      input.replace_all(old="token: test-token", new="client-key: /tmp/key"),
    ] {
    assert_true(
      try @transport.Config::parse_kubeconfig(invalid) catch {
        @core.Invalid(_) => true
        _ => false
      } noraise {
        _ => false
      },
    )
  }
  let duplicate = input + "\ncurrent-context: other\n"
  assert_true(
    try @transport.Config::parse_kubeconfig(duplicate) catch {
      @core.Invalid(_) => true
      _ => false
    } noraise {
      _ => false
    },
  )
  assert_true(
    try @transport.Config::parse_kubeconfig("x: &a [1,2]\ny: *a") catch {
      @core.Invalid(_) => true
      _ => false
    } noraise {
      _ => false
    },
  )
}
