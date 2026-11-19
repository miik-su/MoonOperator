## MoonOperator kind

Status before report upload: **success**. GitHub shows the final workflow status. Missing evidence is not a pass.

Source commit: `6235a5f5a81fa0b5e197532565a644aa2d2cbde3`.

| Acceptance evidence | Recorded value |
| --- | --- |
| create_update_drift_restart_gc | true |
| real_api_crud_patch_paginate_conflict_forbidden_watch | true |
| tls_verified | true |

Kubernetes server: v1.37.0. Download kind-acceptance for reports and runtime package versions.

### NetworkPolicy enforcement

| Check | Observed |
| --- | --- |
| cni | Calico 3.33.0 |
| allowed_before_and_after | true |
| missing_pod_label_denied | true |
| missing_namespace_label_denied | true |

A missing policy report is not an enforcement pass. RBAC expected/actual details are preserved in rbac-report.json.

### Explicit ownership adoption

| Mode | Default refused | Explicit result | Passed |
| --- | --- | --- | --- |
| deny | true | 403 without delete permission | true |
| allow | true | allowed with fixture-named delete permission | true |
