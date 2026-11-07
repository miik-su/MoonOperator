///|
test "RBAC generates namespace permissions and rejects wildcard escalation" {
  let documents = @rbac.manifests("operator", "demo", [
    { group: "", resources: ["pods"], verbs: ["get", "list", "watch"], },
  ])
  assert_eq(documents.length(), 3)
  assert_eq(@core.field(documents[1], "kind"), Json::string("Role"))
  assert_true(
    try
      @rbac.manifests("operator", "demo", [
        { group: "*", resources: ["*"], verbs: ["*"], },
      ])
    catch {
      _ => true
    } noraise {
      _ => false
    },
  )
}
