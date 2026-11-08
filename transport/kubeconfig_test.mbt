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
