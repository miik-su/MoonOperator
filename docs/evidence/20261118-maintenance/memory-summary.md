## MoonOperator memory

Status before report upload: **success**. GitHub shows the final workflow status. Missing evidence is not a pass.

Source commit: `6235a5f5a81fa0b5e197532565a644aa2d2cbde3`.

| Profile | Limit bytes | Required success | Completed | OOMKilled | Exit code | Peak RSS KiB |
| --- | ---: | --- | --- | --- | ---: | ---: |
| operator | 134217728 | true | true | false | 0 | 38116 |
| operator | 268435456 | true | true | false | 0 | 38152 |
| operator | 536870912 | true | true | false | 0 | 38128 |
| 10k | 134217728 | false | true | false | 0 | 129896 |
| 10k | 268435456 | false | true | false | 0 | 129724 |
| 10k | 536870912 | true | true | false | 0 | 129824 |

operator profile must complete at every limit; generic 10k profile must complete at 512 MiB; lower-limit failures remain failures in individual records. Raw stderr, phases and container state are retained. Short observations do not establish 1h/24h stability.
