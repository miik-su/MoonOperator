///|
async fn main {
  @signal.set_global_cancellation_signals([SIGINT, SIGTERM])
  let ns = @env.get_env_var("MOONOPERATOR_NAMESPACE").unwrap_or("default")
  let metrics = @observability.Metrics::new()
  let logger = @observability.Logger::stdout()
  let config_path = match @env.get_env_var("MOONOPERATOR_KUBECONFIG") {
    Some(path) => Some(path)
    None => @env.get_env_var("MOONOPERATOR_KUBECONFIG_JSON")
  }
  let config = match config_path {
    Some(path) => @transport.Config::load_kubeconfig(path, metrics~)
    None =>
      match @env.get_env_var("KUBERNETES_SERVICE_HOST") {
        Some(host) =>
          @transport.Config::in_cluster(
            host,
            port=@env.get_env_var("KUBERNETES_SERVICE_PORT").unwrap_or("443"),
            metrics~,
          )
        None =>
          @transport.Config::new(
            "http://127.0.0.1:8001",
            allow_loopback_http=true,
            metrics~,
          )
      }
  }
  let client = config.client()
  let store = @cache.Store::new(
    capacity=1024,
    max_bytes=8388608,
    max_object_bytes=262144,
  )
  let queue = @queue.Queue::new(capacity=1024)
  let progress = @observability.Progress::new()
  let max_disconnected_ms = match
    @env.get_env_var("MOONOPERATOR_MAX_DISCONNECTED_MS") {
    None => 180000
    Some(value) =>
      match @json.parse(value) {
        Number(n, ..) if n == n.floor() && n >= 0.0 && n <= 3600000.0 =>
          n.to_int()
        _ =>
          fail("disconnect readiness threshold must be 0..3600000 milliseconds")
      }
  }
  let controller = @controller.Controller::new(
    queue,
    key => @app.reconcile(client, key),
    metrics~,
    logger~,
  )
  defer controller.stop()
  println("MoonApp operator starting (single replica)")
  @async.with_task_group(group => {
    group.spawn_bg(() => {
      @observability.serve(
        @env.get_env_var("MOONOPERATOR_DIAGNOSTICS_ADDRESS").unwrap_or(
          "127.0.0.1:8080",
        ),
        () => {
          store.ready(@app.app_type.gvk) &&
          progress.fresh(@async.now(), max_disconnected_ms)
        },
        () => queue.length(),
        metrics~,
        cache_objects=() => store.length(),
        cache_bytes=() => store.bytes(),
        progress=() => progress.prometheus(@async.now()),
      )
    })
    group.spawn_bg(() => {
      @runtime.inform(
        config,
        @app.app_type,
        ns,
        store,
        queue,
        metrics~,
        predicate=@watch.generation_changed,
        logger~,
        progress~,
      )
    })
    controller.run(() => store.ready(@app.app_type.gvk), workers=2)
  })
}
