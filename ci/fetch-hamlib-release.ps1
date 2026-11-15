# Download a hamlib-woarm-builds release, verify it against the release's
# SHA256SUMS and unpack it into a Hamlib prefix for ci/build-ws.sh
# (bin/ with libhamlib-4.dll and the rigctl tools, include/, lib/).
#
#   pwsh ci/fetch-hamlib-release.ps1 [-Tag <tag>|latest] [-Dest hamlib-install]
#
# Without -Tag the release pinned in .github/workflows/windows-arm64.yml
# (HAMLIB_RELEASE) is used, which is what CI builds against. Needs the gh
# CLI (signed in, or GH_TOKEN set).
#
# Local builds can instead use any Hamlib install prefix, e.g. one built
# from your own Hamlib tree with hamlib-woarm-builds' ci/build.sh.
param(
  [string] $Tag = '',
  [string] $Dest = 'hamlib-install',
  [string] $Repo = 'aj7kt/hamlib-woarm-builds'
)
$ErrorActionPreference = 'Stop'

if (-not $Tag) {
  $wf = Join-Path $PSScriptRoot '..\.github\workflows\windows-arm64.yml'
  $m = Select-String -Path $wf -Pattern '^\s*HAMLIB_RELEASE:\s*(\S+)\s*$'
  if (-not $m) { throw "no HAMLIB_RELEASE in $wf" }
  $Tag = $m.Matches[0].Groups[1].Value
}
if ($Tag -eq 'latest') { $Tag = gh release view -R $Repo --json tagName --jq .tagName }
if (Test-Path $Dest) { throw "$Dest already exists" }

$dl = Join-Path ([IO.Path]::GetTempPath()) ("hamlib-dl-" + [guid]::NewGuid())
New-Item -ItemType Directory $dl | Out-Null
try {
  gh release download $Tag -R $Repo -p "$Tag.zip" -p SHA256SUMS -D $dl
  if ($LASTEXITCODE) { throw "gh release download failed for $Tag" }
  $line = Select-String -Path "$dl/SHA256SUMS" -Pattern ('^([0-9a-f]{64})\s+\*?' + [regex]::Escape("$Tag.zip") + '$')
  if (-not $line) { throw "SHA256SUMS has no entry for $Tag.zip" }
  $want = $line.Matches[0].Groups[1].Value
  $got = (Get-FileHash "$dl/$Tag.zip" -Algorithm SHA256).Hash.ToLower()
  if ($want -ne $got) { throw "checksum mismatch for $Tag.zip: expected $want, got $got" }
  Expand-Archive "$dl/$Tag.zip" -DestinationPath $dl
  Move-Item "$dl/$Tag" $Dest
} finally {
  Remove-Item -Recurse -Force $dl -ErrorAction SilentlyContinue
}
Write-Host "Hamlib release $Tag (sha256 $got) -> $Dest"
Get-Content (Join-Path $Dest 'BUILDINFO.txt')
