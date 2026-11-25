# Reusable release workflow verification

The [candidate workflow](https://github.com/miik-su/MoonOperator/actions/runs/45560113330)
read the project version from `moon.mod` at commit
`5fafa36c12eb31120bd6b5b5f7201e707d13bec6`. Two independent clean Ubuntu
24.04 amd64 runners built without Docker cache using separate source
directories. The comparison job passed its checks of both complete image
receipts, module source digests, package records and the candidate bundle hashes.

- [Runner A image](candidate/image-a.json) and [runner B image](candidate/image-b.json)
  have the same image ID, filesystem layer digest and executable SHA-256.
- [Module source A](candidate/modules-a.sha256) and [module source B](candidate/modules-b.sha256)
  have the same digest after independent resolution and frozen builds.
- The [candidate archive hashes](candidate/payload-SHA256SUMS) passed in the
  comparison job. The reloaded candidate [became ready and reconciled a
  MoonApp](candidate/release-candidate.json) in Kind on Kubernetes 1.37.0.

The [public acceptance workflow](https://github.com/miik-su/MoonOperator/actions/runs/45560118909)
took the existing `v0.1.1` tag as input. All [five downloads](published/downloads.txt)
matched the [public GitHub asset digests](published/public-asset-digests.txt)
and release checksums. The signed Ubuntu source records matched the system
archive, and the [four source packages unpacked successfully](published/system-unpack.txt).
The project rebuilt from the downloaded source archive. The
[downloaded image](published/public-image.json) and
[rebuilt image](published/rebuilt-image.json) shared image ID
`sha256:756fbf1ba23d245dc013941f2ebe85c83b5e1f091f7b889641094b0ea7385d59`
and the same layer digest and executable bytes. The
[public image deployed and reconciled](published/release-candidate.json) in
Kind on Kubernetes 1.37.0.

The [isolated module-version fixture](sbom-version-fixture.json) generated a
root SBOM entry and package URL for version `42.17.3` from that fixture's
manifest. The tracked dependency inventory also matched fresh generation for
the actual module. The checks were limited to release construction, integrity,
reproduction and focused cluster deployment.
