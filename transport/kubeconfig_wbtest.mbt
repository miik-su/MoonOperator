///|
async test "kubeconfig credential paths resolve against configuration directory" {
  let config = Config::load_kubeconfig(
    "transport/fixtures/relative-config.yaml",
  )
  assert_true(config.ca_file.has_suffix("/transport/fixtures/certs/ca.crt"))
  assert_true(
    config.token_file.has_suffix("/transport/fixtures/credentials/token"),
  )
}
