///|
test "ownership validates declared scope and preserves noncontrolling references" {
  let ns : @core.ResourceType = {
    gvk: { group: "", version: "v1", kind: "Pod", },
    plural: "pods",
    scope: Namespaced,
  }
  let cluster : @core.ResourceType = {
    gvk: { group: "", version: "v1", kind: "Node", },
    plural: "nodes",
    scope: Cluster,
  }
  let pod = @core.Resource::from_json({
    "apiVersion": "v1",
    "kind": "Pod",
    "metadata": {
      "name": "p",
      "namespace": "a",
      "uid": "p",
      "ownerReferences": [{ "uid": "unrelated", "controller": false }],
    },
  })
  let node = @core.Resource::from_json({
    "apiVersion": "v1",
    "kind": "Node",
    "metadata": { "name": "n", "uid": "n" },
  })
  let other = pod.with_metadata("name", "other").with_metadata("uid", "other")
  let owned = pod.controlled_by(node, dependent_type=ns, owner_type=cluster)
  guard @core.field(owned.metadata(), "ownerReferences") is Array(refs) else {
    fail("missing references")
  }
  assert_eq(refs.length(), 2)
  ignore(pod.controlled_by(other, dependent_type=ns, owner_type=ns))
  ignore(
    node.controlled_by(
      node.with_metadata("uid", "another"),
      dependent_type=cluster,
      owner_type=cluster,
    ),
  )
  assert_true(
    try node.controlled_by(pod, dependent_type=cluster, owner_type=ns) catch {
      _ => true
    } noraise {
      _ => false
    },
  )
  assert_true(
    try
      pod.controlled_by(
        other.with_metadata("namespace", "b"),
        dependent_type=ns,
        owner_type=ns,
      )
    catch {
      _ => true
    } noraise {
      _ => false
    },
  )
  assert_true(
    try
      pod.controlled_by(node, dependent_type=cluster, owner_type=cluster)
    catch {
      _ => true
    } noraise {
      _ => false
    },
  )
  assert_true(
    try
      pod.controlled_by(
        node.with_metadata("namespace", "a"),
        dependent_type=ns,
        owner_type=cluster,
      )
    catch {
      _ => true
    } noraise {
      _ => false
    },
  )
}
