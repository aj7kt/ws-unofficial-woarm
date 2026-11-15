# Install, check and uninstall a WS Windows on Arm installer, silently.
# Needs an elevated shell (the installer is per machine), e.g. a CI runner.
#
#   pwsh ci/test-installer.ps1 -Installer path\to\WS-...-win-arm64-<layout>.exe [-Dir C:\ws-installer-test]
#
# Checks: the installer exits 0; ws.exe, jt9.exe and libhamlib-4.dll are
# installed and every installed binary is ARM64; the uninstall registry
# entry exists; jt9 and rigctl-ws run from the install using only its
# DLLs; the silent uninstaller removes the programs and the registry entry.
param(
  [Parameter(Mandatory)] [string] $Installer,
  [string] $Dir = 'C:\ws-installer-test'     # no spaces: /D= must not be quoted
)
$ErrorActionPreference = 'Stop'
$fail = 0
function Pass($m) { Write-Host "PASS  $m" }
function Fail($m) { Write-Host "FAIL  $m"; $script:fail = 1 }

$Installer = (Resolve-Path $Installer).Path
if (Test-Path $Dir) { throw "$Dir already exists" }

# /D must be the last argument and unquoted
$p = Start-Process $Installer -ArgumentList '/S', "/D=$Dir" -Wait -PassThru
if ($p.ExitCode -eq 0) { Pass "installer exit code 0" } else { Fail "installer exit code $($p.ExitCode)" }

foreach ($f in 'bin\ws.exe', 'bin\jt9.exe', 'bin\libhamlib-4.dll', 'Uninstall.exe') {
  if (Test-Path (Join-Path $Dir $f)) { Pass "installed $f" } else { Fail "missing $f" }
}

$bad = 0
foreach ($f in Get-ChildItem $Dir -Recurse -File | Where-Object { $_.Extension -in '.exe', '.dll' -and $_.Name -ne 'Uninstall.exe' }) {
  $b = [IO.File]::ReadAllBytes($f.FullName)
  $machine = [BitConverter]::ToUInt16($b, [BitConverter]::ToInt32($b, 0x3C) + 4)
  if ($machine -ne 0xAA64) { $bad++; Write-Host ("  not ARM64: {0} (0x{1:X4})" -f $f.FullName.Substring($Dir.Length), $machine) }
}
if ($bad -eq 0) { Pass "all installed binaries are ARM64" } else { Fail "$bad installed binaries are not ARM64" }

$key = Get-ChildItem 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall' |
       Where-Object { (Get-ItemProperty $_.PSPath).InstallLocation -eq $Dir -or $_.PSChildName -like 'WS *(ARM64)' } |
       Select-Object -First 1
if ($key) { Pass "uninstall entry: $($key.PSChildName)" } else { Fail "no uninstall registry entry" }

# run from the install with only its own DLLs (and Windows)
$saved = $env:PATH
$env:PATH = (Join-Path $Dir 'bin') + ';' + (Join-Path $env:SystemRoot 'System32') + ";$env:SystemRoot"
$out = & (Join-Path $Dir 'bin\jt9.exe') -h 2>&1
if ($LASTEXITCODE -eq 0 -and ($out -join ' ') -match 'Usage') { Pass "jt9 runs" } else { Fail "jt9 (exit $LASTEXITCODE)" }
$out = @(& (Join-Path $Dir 'bin\rigctl-ws.exe') -m 1 F 14074000 f 2>&1 | ForEach-Object { "$_".Trim() })
if ($LASTEXITCODE -eq 0 -and $out[0] -eq '14074000') { Pass "rigctl-ws drives the dummy rig" } else { Fail "rigctl-ws: $($out -join ' | ')" }
$env:PATH = $saved

# _?= makes the uninstaller run in place and wait (it cannot delete itself then)
$p = Start-Process (Join-Path $Dir 'Uninstall.exe') -ArgumentList '/S', "_?=$Dir" -Wait -PassThru
if ($p.ExitCode -eq 0) { Pass "uninstaller exit code 0" } else { Fail "uninstaller exit code $($p.ExitCode)" }
# what is left: the uninstaller itself and, by design, the Hamlib DLL backup
$left = @(Get-ChildItem $Dir -Recurse -File -ErrorAction SilentlyContinue |
          Where-Object { $_.Name -ne 'Uninstall.exe' -and $_.Name -notlike 'libhamlib-*_old.dll' })
if ($left.Count -eq 0) { Pass "uninstall removed the programs" } else { Fail "left after uninstall: $($left.Count) files, e.g. $($left[0].FullName)" }
if ($key -and -not (Test-Path $key.PSPath)) { Pass "uninstall entry removed" } elseif ($key) { Fail "uninstall entry still present" }
Remove-Item -Recurse -Force $Dir -ErrorAction SilentlyContinue

exit $fail
