# Windows on Arm build scripts

Native ARM64 Windows builds of WS with the MSYS2 **CLANGARM64** toolchain
(clang + LLVM flang + lld, Qt 6). The GitHub workflow
`.github/workflows/windows-arm64.yml` uses these same scripts.

| Script | Purpose |
|---|---|
| `build-ws.sh` | configure, build and install WS against a given Hamlib prefix |
| `fetch-hamlib-release.ps1` | download + verify a Hamlib release into a prefix |
| `smoke-test.sh` | simulate FT8/FT4/WSPR signals and check they decode |

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
