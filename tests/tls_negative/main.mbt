///|
async fn main {
  guard @async.platform is Linux else {
    fail(
      "TLS acceptance probe requires Linux/OpenSSL; unavailable is not a pass",
    )
  }
  @async.with_timeout(20000, () => {
    @fs.mkdir("_build/tls-fixtures", recursive=true, allow_exist=true)
    for name in ["localhost", "unrelated"] {
      let output = @shell.Cmd(
        "openssl",
        [
          "req",
          "-x509",
          "-newkey",
          "rsa:2048",
          "-nodes",
          "-keyout",
          "_build/tls-fixtures/" + name + ".key",
          "-out",
          "_build/tls-fixtures/" + name + ".crt",
          "-days",
          "1",
          "-subj",
          "/CN=" + name,
          "-addext",
          "subjectAltName=DNS:" + name,
        ],
        stdout=Discard,
        stderr=Discard,
      ).output(timeout_ms=10000)
      output.check()
    }
    let server = @socket.TcpServer(@socket.Addr::parse("127.0.0.1:0"))
    defer server.close()
    @async.with_task_group(group => {
      group.spawn_bg(() => {
        for _ in 0..<3 {
          let (tcp, _) = server.accept()
          defer tcp.close()
          answer_tls(tcp) catch {
            _ => ()
          } // Verification failures abort the peer handshake.
        }
      })
      let request : @client.Request = {
        verb: "GET",
        path: "/",
        body: Json::null(),
        content_type: "application/json",
      }
      let positive = @transport.Config::new(
        "https://localhost:\{server.addr.port()}",
        ca_file="_build/tls-fixtures/localhost.crt",
        timeout_ms=3000,
      )
      assert_eq(positive.send(request).code, 200)
      let wrong_ca = @transport.Config::new(
        "https://localhost:\{server.addr.port()}",
        ca_file="_build/tls-fixtures/unrelated.crt",
        timeout_ms=3000,
      )
      assert_true(
        try wrong_ca.send(request) catch {
          @tls.TlsError(_) => true
          _ => false
        } noraise {
          _ => false
        },
      )
      let wrong_host = @transport.Config::new(
        "https://127.0.0.1:\{server.addr.port()}",
        ca_file="_build/tls-fixtures/localhost.crt",
        timeout_ms=3000,
      )
      assert_true(
        try wrong_host.send(request) catch {
          @tls.TlsError(_) => true
          _ => false
        } noraise {
          _ => false
        },
      )
      group.return_immediately(())
    })
    let report : Json = {
      "platform": "Linux",
      "positive_trusted_ca_hostname": true,
      "unrelated_ca_rejected": true,
      "wrong_hostname_rejected": true,
      "fixtures": "ephemeral self-signed certificates generated under ignored _build directory; no private keys distributed",
    }
    @fs.write_file("tls-negative-report.json", report.stringify(indent=2))
    println(report.stringify())
  })
}

///|
#cfg(not(platform="windows"))
async fn answer_tls(tcp : @socket.Tcp) -> Unit {
  let tls = @tls.Tls::server(
    tcp,
    private_key_file="_build/tls-fixtures/localhost.key",
    private_key_type=PEM,
    certificate_file="_build/tls-fixtures/localhost.crt",
    certificate_type=PEM,
  )
  defer tls.close()
  ignore(tls.read_until("\r\n\r\n"))
  tls.write(
    "HTTP/1.1 200 OK\r\nContent-Length: 2\r\nConnection: close\r\n\r\n{}",
  )
}

///|
#cfg(platform="windows")
fn answer_tls(_tcp : @socket.Tcp) -> Unit raise {
  fail("Linux TLS acceptance probe is unavailable on Windows")
}
