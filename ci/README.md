# Windows on Arm build scripts

Native ARM64 Windows builds of WS with the MSYS2 **CLANGARM64** toolchain
(clang + LLVM flang + lld, Qt 6). The GitHub workflow
`.github/workflows/windows-arm64.yml` uses these same scripts.

| Script | Purpose |
|---|---|
| `build-ws.sh` | configure, build and install WS against a given Hamlib prefix |
| `fetch-hamlib-release.ps1` | download + verify a Hamlib release into a prefix |
| `smoke-test.sh` | simulate FT8/FT4/WSPR signals and check they decode |
| `make-installer.sh` | build the NSIS installer for a build tree's layout |
| `test-installer.ps1` | silent install, run, silent uninstall of an installer (needs admin) |

## Installers

`make-installer.sh` runs CPack's NSIS generator with WS's own template.
It needs `makensis`: MSYS2's `mingw-w64-x86_64-nsis` (there is no ARM64
NSIS; the x64 one runs emulated, and NSIS installers are 32-bit x86
programs in any case). The Windows on Arm installer has its own identity,
so it installs side by side with an official x64 WS of the same version:
`C:\WS\<version>-arm64`, "WS <version> (ARM64)" in Apps and Start menu, and
its own registry keys. It refuses to run on non-ARM64 Windows.

## Hamlib

WS needs a Hamlib *install prefix* (`bin/libhamlib-4.dll` and the rigctl
tools, `include/hamlib/`, `lib/libhamlib.dll.a`). Hamlib is built
separately, in [hamlib-woarm-builds](https://github.com/aj7kt/hamlib-woarm-builds).

- **CI** always uses a release of hamlib-woarm-builds, pinned by
  `HAMLIB_RELEASE` in the workflow (a manual run can override it, or use
  `latest`). Change that tag to move WS to a newer Hamlib.
- **Local builds** can use the same release, or any Hamlib you built
  yourself, e.g. from your own Hamlib tree with hamlib-woarm-builds'
  `ci/build.sh`.

## Local build

In an MSYS2 CLANGARM64 shell, with the packages listed in
`MSYS2_PACKAGES` in the workflow installed:

```sh
# Hamlib, either the release CI uses ...
pwsh ci/fetch-hamlib-release.ps1 -Dest ../hamlib-install
# ... or your own build, e.g. ../my-hamlib-prefix

WS_LAYOUT=al bash ci/build-ws.sh . ../ws-build ../ws-install ../hamlib-install
bash ci/smoke-test.sh "$PWD/../ws-build" "$PWD/../smoke"
```

`WS_LAYOUT` is `standard` (default), `al` (alternate layout) or
`widescreen`. The install tree (`../ws-install`) is self-contained:
run `bin/ws.exe` from it.

## Releases

Builds never publish anything by themselves. Each branch has one
standing **draft** release, tagged `next-<branch>` (e.g. `next-main`),
which every successful push build of that branch updates in place: the
three zips, a `SHA256SUMS`, the target commit and the notes are replaced.
Drafts are visible only to people with write access to the repository.
Pull request builds and tag pushes do not touch it.

To release: download the draft's zips (Releases page, or
`gh release download next-main -R <owner>/<repo>`) and test them. Then
edit the draft, change its tag to the real one (e.g. `v3.2.1-woa1`), write
the release notes and click **Publish release**, all in that one edit.
The next build of the branch starts a new standing draft. Anything typed
into the draft before then is replaced by the next build.
