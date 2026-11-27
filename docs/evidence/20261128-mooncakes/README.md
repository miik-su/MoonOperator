# Mooncakes 0.1.3 publication and consumer verification

On 2026-11-28 (Asia/Shanghai), `moon publish` succeeded for
[miik-su/moonoperator 0.1.3](https://mooncakes.io/docs/miik-su/moonoperator)
from source commit `c9c2f255f27d3e8dcb06a5090ccc11267a6abbff`. The module
uses Apache-2.0. The installed toolchain was MoonBit `0.10.17+d971670cd`
and moon `0.1.20261023` on Windows.

| Check | Observed result |
| --- | --- |
| Native check and formatting | `moon check --target native` and `moon fmt --check` passed. |
| Publish | Checkout check and extracted ZIP check passed. The registry returned HTTP 200. |
| Public registry lookup | `moon view miik-su/moonoperator@0.1.3 --json` returned version `0.1.3`, Apache-2.0, and `yanked: false`. |
| Archive integrity | Registry metadata SHA-256 matched the submitted ZIP. |
| Clean consumer install | `moon add miik-su/moonoperator@0.1.3` downloaded the module to a new consumer outside the checkout. No `moon.work` was present in the consumer directory or its ancestors. `moon tree` resolved exactly `0.1.3`. |
| Clean consumer execution | `moon check --target native` and `moon run cmd/main --target native` passed. The [consumer result](consumer.json) records two reconciles, one update, unrelated annotation preserved and no pending work. |

Submitted ZIP SHA-256:

```text
84f689866efa18916bc301a1ee871d53d5a05e1df90f4370475f257cc2ffa986
```

The consumer exercises public APIs with synthetic transport. Real cluster
acceptance is recorded separately for the
[public v0.1.2 image](../20261125-v0.1.2/README.md#public-release-acceptance).
The GitHub v0.1.3 image release is a draft.
