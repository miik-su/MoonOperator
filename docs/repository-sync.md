# Repository and publishing identity

| Role | Current identity / status |
| --- | --- |
| GitHub source | https://github.com/miik-su/MoonOperator |
| Verified GitHub default branch | main |
| MoonBit module | miik-su/moonoperator |
| Previous unpublished development module | mik1e80/moonoperator |
| Mooncakes publication | Not published; authenticate the intended account and verify namespace rights before publication |
| Optional additional mirror | Not configured; not a prerequisite for maintaining this GitHub project |

The module rename on 2026-11-14 changes internal imports, generated interfaces
and the current source dependency inventory. Archived test observations retain
their original module names and source revisions. Repository ownership and a
module-name string alone do not prove applicant identity or publishing rights.

## Optional Gitlink setup and subsequent updates

GitHub is the source repository. A Gitlink mirror is optional and is not listed
as a pending requirement for this project's annual hackathon maintenance. Do not
substitute requirements from another contest. Configure a mirror only when the
owner explicitly requests it; no account/repository address is assumed.

Use Gitlink's [official repository import guide](https://help.gitlink.org.cn/快速开始/导入GitHub等第三方Git项目)
to import the public GitHub repository, retaining its history. Import the existing
repository rather than initializing an unrelated README or license commit.
Confirm public visibility and set the default branch to main. The target URL must
be supplied by its owner; no Gitlink account or repository address is assumed.

Once the actual clone URL is available, configure it as the additional `gitlink`
remote, keeping `origin` pointed at GitHub. Push main normally, without force or
mirror deletion. After each update, compare the full main commit IDs on both
hosts, and check that README, LICENSE and source files appear on each site's
default branch. Merely importing once does not ensure future synchronization.

If the target contains unrelated history, review it before resolving the
divergence; do not overwrite it. Share any optional mirror URL only after these
checks succeed. The project does not create or submit registration forms.
