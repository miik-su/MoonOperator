# CRD and RBAC contracts

CRD generation validates the resource registration, a named API group, bounded
metadata name, DNS1035 plural/singular/generated listKind and object root schema.
Every version identifier is checked. A malformed registration fails locally;
the API server still performs authoritative structural schema/admission checks.
The generator is not a complete Kubernetes OpenAPI compiler.

Local value validation supports object properties/required/defaults, explicit
additionalProperties=false, arrays/items/minItems/maxItems, string lengths,
enum, scalar types, numeric bounds and nullable. Unknown schema keywords are
not evaluated locally. Do not use local validation as the sole security check
for unsupported schema constraints. See crd/schema.mbt for the exact subset.

definition_with_versions requires exactly one served storage version, a served
preferred version, unique names, equal schemas and equal status-subresource
semantics. It generates no conversion webhook. Schema evolution requiring
conversion is outside this release.

RBAC declarations use explicit API groups/resources/verbs and reject wildcards.
cmd/manifests produces MoonApp namespaced Role/RoleBinding/ServiceAccount and a
cluster-scoped CRD. An administrator installs CRDs; the runtime ServiceAccount
does not gain administrative installation privileges. Namespace the generated
bundle and deployment consistently. See the README/deployment guide.

MoonApp creates children with blockOwnerDeletion=true, so the owner finalizers
subresource update permission remains intentional even without custom cleanup.
With OwnerReferencesPermissionEnforcement enabled, modifying existing child
owner references additionally requires delete on that dependent. The example
Role deliberately excludes it; opt-in adoption needs separately reviewed grants.
The real acceptance probe grants delete only for named test fixtures.

Naming reference: [Kubernetes CRD validation](https://github.com/kubernetes/kubernetes/blob/v1.37.0/staging/src/k8s.io/apiextensions-apiserver/pkg/apis/apiextensions/validation/validation.go).
Scope/reference semantics: [Kubernetes ownership admission](https://github.com/kubernetes/kubernetes/blob/v1.37.0/plugin/pkg/admission/gc/gc_admission.go).
