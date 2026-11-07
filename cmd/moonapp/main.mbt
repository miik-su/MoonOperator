///|
async fn main {
  @signal.set_global_cancellation_signals([SIGINT, SIGTERM])
  let ns = @env.get_env_var("MOONOPERATOR_NAMESPACE").unwrap_or("default")
  let config = match @env.get_env_var("MOONOPERATOR_KUBECONFIG_JSON") {
    Some(path) =>
      @transport.Config::from_kubeconfig(
        @json.parse(@fs.read_file(path).text()),
      )
    None =>
      match @env.get_env_var("KUBERNETES_SERVICE_HOST") {
        Some(host) =>
          @transport.Config::in_cluster(
            host,
            port=@env.get_env_var("KUBERNETES_SERVICE_PORT").unwrap_or("443"),
          )
        None =>
          @transport.Config::new(
            "http://127.0.0.1:8001",
            allow_loopback_http=true,
          )
      }
  }
  let client = config.client()
  let store = @cache.Store::new()
  let queue = @queue.Queue::new()
  let controller = @controller.Controller::new(queue, key => {
    @app.reconcile(client, key)
  })
  defer controller.stop()
  println("MoonApp operator starting (single replica)")
  @async.with_task_group(group => {
    group.spawn_bg(() => {
      @observability.serve(
        "0.0.0.0:8080",
        () => store.ready(@app.app_type.gvk),
        () => queue.length(),
      )
    })
    group.spawn_bg(() => {
      @runtime.inform(config, @app.app_type, ns, store, queue)
    })
    controller.run(() => store.ready(@app.app_type.gvk), workers=2)
  })
}
