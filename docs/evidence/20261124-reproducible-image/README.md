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
