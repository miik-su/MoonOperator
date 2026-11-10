///|
/// Ingress only. API/DNS egress and kubelet node probes retain their platform
/// semantics; enforcement requires a NetworkPolicy-capable CNI.
pub fn diagnostics_policy(ns : String) -> Json raise @core.OperatorError {
  if ns.is_empty() {
    raise @core.Invalid("policy namespace required")
  }
  {
    "apiVersion": "networking.k8s.io/v1",
    "kind": "NetworkPolicy",
    "metadata": { "name": "moonoperator-diagnostics", "namespace": ns },
    "spec": {
      "podSelector": { "matchLabels": { "app": "moonoperator" } },
      "policyTypes": ["Ingress"],
      "ingress": [
        {
          "from": [
            {
              "namespaceSelector": {
                "matchLabels": { "moonoperator.dev/diagnostics-access": "true" },
              },
              "podSelector": {
                "matchLabels": { "moonoperator.dev/diagnostics-client": "true" },
              },
            },
          ],
          "ports": [{ "protocol": "TCP", "port": 8080 }],
        },
      ],
    },
  }
}
