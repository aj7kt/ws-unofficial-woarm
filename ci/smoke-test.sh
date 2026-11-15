#!/usr/bin/env bash
# Decoder smoke test: simulate signals, decode them, check the text.
#   bash smoke-test.sh <dir-with-ws-executables> [work-dir]
# Exit status is non-zero if any tool fails or a message is not decoded.
set -uo pipefail

BIN=${1:?usage: smoke-test.sh BIN_DIR [WORK_DIR]}
WORK=${2:-$(mktemp -d)}
fail=0

pass () { printf 'PASS  %s\n' "$1"; }
bad ()  { printf 'FAIL  %s\n' "$1"; fail=1; }

# run_decode NAME EXPECTED-TEXT DECODER-CMD...
# runs in the current directory; decoded text is looked for in stdout
run_decode () {
  local name=$1 want=$2; shift 2
  local out rc
  out=$("$@" 2>&1); rc=$?
  if [ $rc -ne 0 ]; then
    bad "$name: decoder exit status $rc"
  elif grep -qF -- "$want" <<<"$out"; then
    pass "$name"
  else
    bad "$name: '$want' not decoded"; printf '%s\n' "$out" | tail -5 | sed 's/^/      /'
  fi
}

# sim NAME CMD... : generate a signal, fail loudly if the simulator fails
sim () {
  local name=$1; shift
  local rc
  "$@" >/dev/null 2>&1; rc=$?
  if [ $rc -ne 0 ]; then bad "$name: simulator exit status $rc"; return 1; fi
}

mkdir -p "$WORK"

# FT8, strong and weak, single- and multi-threaded
for snr in 10 -15; do
  for th in 1 4; do
    d="$WORK/ft8_${snr}_${th}"; mkdir -p "$d"; cd "$d" || exit 2
    sim "ft8sim $snr" "$BIN/ft8sim.exe" "CQ AJ7KT DN13" 1500 0.0 0.0 0.0 1 "$snr" &&
      run_decode "FT8 snr=$snr threads=$th" "CQ AJ7KT DN13" \
        "$BIN/jt9.exe" -8 -m "$th" 000000_000001.wav
  done
done

# FT4
d="$WORK/ft4"; mkdir -p "$d"; cd "$d" || exit 2
sim ft4sim "$BIN/ft4sim.exe" "AJ7KT K1ABC FN42" 1000 0.0 0.0 0.0 1 -10 &&
  run_decode "FT4 snr=-10" "AJ7KT K1ABC FN42" "$BIN/jt9.exe" -5 000000_000001.wav

# WSPR (wsprsim writes a .c2 file that wsprd reads). wsprsim's main()
# returns 1 even on success (upstream), so check for the file instead.
d="$WORK/wspr"; mkdir -p "$d"; cd "$d" || exit 2
"$BIN/wsprsim.exe" -o 261114_1200.c2 -s -20 "AJ7KT DN13 37" >/dev/null 2>&1
if [ -s 261114_1200.c2 ]; then
  run_decode "WSPR snr=-20" "AJ7KT DN13 37" "$BIN/wsprd.exe" 261114_1200.c2
else
  bad "wsprsim: no .c2 file written"
fi

[ $fail -eq 0 ] && echo "all decoder smoke tests passed" || echo "SOME DECODER SMOKE TESTS FAILED"
exit $fail
