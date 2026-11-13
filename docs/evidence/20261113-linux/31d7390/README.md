# Final source verification · 2026-11-13

Source: `31d7390e2e60c6e41853c916636b45e4d8f720ab`.
All three workflows completed successfully for this same source:
[native](https://github.com/miik-su/MoonOperator/actions/runs/43416752124),
[WASM](https://github.com/miik-su/MoonOperator/actions/runs/43416752053),
[Kind](https://github.com/miik-su/MoonOperator/actions/runs/43416752043).

| Artifact | ID | Download ZIP SHA-256 |
| --- | --- | --- |
| kind-acceptance | 14032347548 | `949b71ceb7846be49be654bb63e86247613005a26bdce1f9ad963f7c33ffef02` |
| memory-observations | 14031842316 | `bef502bb1d6b9062aee977a224513bd4bbaf8042c64baffee3735dfc5282139f` |

JSON payloads and summary.md are unchanged extractions, with shortened filenames.
memory.json contains all six successful fresh-container cases; none was OOMKilled.
Peak RSS KiB: operator 128/256/512 MiB = 38092/38052/38076;
10k 128/256/512 MiB = 129740/129728/129792. This is a cache replacement probe,
not a full controller process or long-duration stability measurement.

adoption.json proves default refusal in both fixtures, explicit 403 without
dependent delete rights, and successful explicit adoption with grants restricted
to the fixture's Deployment/Service names. CI explicitly enables
OwnerReferencesPermissionEnforcement, which is not default-on in Kubernetes
1.37. The production example Role was not broadened. kind.json and summary.md
also record lifecycle, generation-aware status and Calico allow/deny/recovery.

Earlier unsuccessful adoption runs tested an incorrect assumption about default
admission enforcement; they are not erased by this result. See the review
follow-up for that correction. Full regression, one-hour and 24-hour runs remain
unexecuted. Documentation archived after this source does not change that scope.
