# v0.1.0 image reproducibility

The [legacy comparison](https://github.com/miik-su/MoonOperator/actions/runs/45405408225)
rebuilt the Dockerfile from the public source archive using the executable
copied from the public image. The executable matched the release SHA-256.
Extracted filesystem contents and symbolic link targets matched. The 64 layer
listing entries matched after removing modification timestamps from the
comparison. The [layer listing diff](legacy-timestamp-diff.txt) shows the
original timestamps.

The [image configuration diff](legacy-config-diff.txt) shows two independent
digest inputs that changed. BuildKit wrote the current build time into the
image configuration and history. The changing layer modification times also
changed the uncompressed layer digest in `rootfs.diff_ids`. The image ID
hashes the configuration JSON, which includes both kinds of changes.

The same run showed that `moon build --strip` alone still produced different
executable hashes when compiling in two different absolute source directories.
The reproducible profile compiles both physical source trees at the original
logical release path and checks the original release executable digest. A
private Linux mount namespace scopes the path mapping to the build. The image
build uses one fixed `SOURCE_DATE_EPOCH` for the configuration, history and
filesystem modification times.

## Two-directory result

The [successful workflow](https://github.com/miik-su/MoonOperator/actions/runs/45406477029)
extracted the public sources into [directory A](rebuild/a-source-directory.txt)
and [directory B](rebuild/b-source-directory.txt), compiled each copy and ran
both Docker builds without build cache.

| Check | Result |
| --- | --- |
| [Executable A](rebuild/a-executable.txt) and [B](rebuild/b-executable.txt) | Both matched the published executable SHA-256. |
| [Image A](rebuild/a-image.json) and [B](rebuild/b-image.json) | Both had ID `sha256:c6e159aa0f33e8b9f23f1fb688b9b34d3f6dd417f2b52e7f62d69732f1a7a86c` and the same single filesystem layer digest. |
| [Rebuilt image in Kind](rebuild/release-rebuilt.json) | The operator became ready and reconciled a MoonApp Service target port from 8080 to 8081. |

This check covers Docker image identity under the tested Ubuntu 24.04 amd64
build profile. The old public archive retains its original digest. The
workflow ran the focused deployment and reconciliation checks.
