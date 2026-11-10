///|
async fn main {
  let args = @env.args()
  guard args.length() == 3 && ["allow", "deny"].contains(args[2]) else {
    fail("usage: diagnostic_probe URL allow|deny")
  }
  let result = @async.with_timeout_opt(1500, () => @http.get(args[1]))
  match (args[2], result) {
    ("allow", Some((response, body))) => {
      assert_eq(response.code, 200)
      assert_true(body.text().contains("moonoperator_queue_depth"))
    }
    ("deny", None) => ()
    _ => fail("diagnostic access did not match expected policy")
  }
  println("diagnostic policy " + args[2] + " verified")
}
