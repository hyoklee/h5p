#!/bin/bash
#
# Build and test hyoklee/hdf5 develop on the OpenBSD 8.0 aarch64 QEMU VM and
# submit to CDash as site obsd-8.0.aarch64, build hk/develop (with zlib and
# szip from libaec).
#
# Meant for cron. A run takes many hours (build plus tests on two emulated
# CPUs), so this script only starts it in the guest and returns. Later calls
# skip while a run is still going, and skip when develop has not changed
# since the last run (FORCE=1 runs anyway).
#
#   0 1 * * * $HOME/h5p/bin/obsd-aarch64-hk.sh >> $HOME/.cache/obsd-aarch64-hk/cron.log 2>&1
#
# PR=<number> tests the head of that HDFGroup/hdf5 pull request instead, as
# build <number>, keeping its own record of the last commit tested:
#
#   PR=6698 $HOME/h5p/bin/obsd-aarch64-hk.sh
#
# The VM is the anyvm-org/openbsd-builder 8.0 aarch64 image, started with
# anyvm.py (2 GB, 2 vCPUs) on the user-local QEMU in ~/.local/qemu/bin.

set -u

SRC=${SRC:-$HOME/hdf5}            # clone with origin = hyoklee/hdf5, upstream = HDFGroup/hdf5
PR=${PR:-}
SITE=obsd-8.0.aarch64
if [ -n "$PR" ]; then
  REF=upstream/pr/$PR
  FETCH=(upstream "+pull/$PR/head:refs/remotes/$REF")
  BUILDNAME=$PR
  TAG=-pr$PR
else
  REF=origin/develop
  FETCH=(origin develop)
  BUILDNAME=hk/develop
  TAG=
fi
HOST=openbsd-8.0-aarch64          # ~/.ssh/config.d entry (127.0.0.1:10023)
PORT=10023
STATE=$HOME/.cache/obsd-aarch64-hk

ANYVM=$HOME/.cache/anyvm-obsd/anyvm.py
VMDIR=$HOME/.cache/anyvm-obsd/aarch64/openbsd/v2.1.1

log() { echo "$(date -u '+%F %T') $*"; }
gssh() { ssh -o ConnectTimeout=30 -o LogLevel=ERROR "$HOST" "$@"; }

mkdir -p "$STATE"
exec 9> "$STATE/lock"
flock -n 9 || { log "another instance is running"; exit 0; }

# Start the VM with anyvm if it is not up. anyvm downloads the image on
# first use, boots it and waits for ssh. It also writes ssh config with a
# global "Host *" block that hands this VM's key to every host, so replace
# its config with a block for this VM only.
if ! gssh true 2>/dev/null; then
  if pgrep -f "qemu-system-aarch64 .*-name openbsd-8.0-aarch64" > /dev/null; then
    log "ERROR: VM process is up but ssh fails; not running"
    exit 1
  fi
  log "starting VM with anyvm"
  PATH=$HOME/.local/qemu/bin:$HOME/miniconda3/bin:$PATH \
    python3 "$ANYVM" --os openbsd --release 8.0 --arch aarch64 \
      --mem 2048 --cpu 2 --ssh-port $PORT -d >> "$STATE/anyvm.log" 2>&1 ||
    { log "ERROR: anyvm failed to start the VM (see $STATE/anyvm.log)"; exit 1; }
  rm -f "$HOME/.ssh/config.d/$PORT.conf"
  printf '%s\n' "Host $HOST" "  StrictHostKeyChecking no" "  UserKnownHostsFile /dev/null" \
    "  ConnectTimeout 60" "  ConnectionAttempts 3" "  ServerAliveInterval 30" \
    "  ServerAliveCountMax 6" "  User root" "  HostName 127.0.0.1" "  Port $PORT" \
    "  IdentityFile $VMDIR/$HOST-host.id_rsa" > "$HOME/.ssh/config.d/$HOST.conf"
  chmod 600 "$HOME/.ssh/config.d/$HOST.conf"
  gssh true 2>/dev/null || { log "ERROR: VM did not come up"; exit 1; }
fi

# [t] keeps pgrep from matching the remote shell running this very command
if gssh 'pgrep -f "obsd-aarch64-hk-gues[t].sh"' > /dev/null; then
  log "previous run still in progress; skipping"
  exit 0
fi

git -C "$SRC" fetch -q "${FETCH[@]}" || { log "ERROR: git fetch failed"; exit 1; }
COMMIT=$(git -C "$SRC" rev-parse --short=11 "$REF")
if [ "${FORCE:-0}" != 1 ] && [ "$COMMIT" = "$(cat "$STATE/last-commit$TAG" 2>/dev/null)" ]; then
  log "$REF $COMMIT already tested; skipping"
  exit 0
fi

TGZ=$STATE/hdf5-hk.tgz
git -C "$SRC" archive --prefix=hdf5-hk/ "$REF" | gzip -1 > "$TGZ" &&
  scp -q -o LogLevel=ERROR "$TGZ" "$HOST:/home/hdf5-hk.tgz" ||
  { log "ERROR: copying source to the VM failed"; exit 1; }
rm -f "$TGZ"

# The guest script: fresh tree, 3 h per-test timeout, and no 1 h testhdf5
# alarm (emulated CPUs make the heaviest tests take about an hour).
gssh "cat > /home/obsd-aarch64-hk-guest.sh" <<EOF
#!/bin/sh
cd /home || exit 1
rm -rf hdf5-hk && tar xzf hdf5-hk.tgz && rm hdf5-hk.tgz || exit 1
# libaec provides szip; -I installs non-interactively, no-op if present
pkg_add -I cmake libaec || exit 1
cd hdf5-hk
sed -i 's/HDF5_ALARM_SECONDS=3600/HDF5_ALARM_SECONDS=0/g' test/CMakeTests.cmake
mkdir build && cd build
echo "=== $COMMIT start \$(date)"
cmake -DCMAKE_BUILD_TYPE=Release \\
  -DCTEST_DROP_SITE_INIT:STRING="my.cdash.org" \\
  -DCTEST_DROP_LOCATION_INIT:STRING="/submit.php?project=HDF5" \\
  -DHDF5_ENABLE_ZLIB_SUPPORT:BOOL=ON \\
  -DHDF5_ENABLE_SZIP_SUPPORT:BOOL=ON \\
  -DSITE:STRING="$SITE" -DBUILDNAME:STRING="$BUILDNAME" ..
MAKEFLAGS=-j2 ctest -D Experimental -C Release -j2 --timeout 10800
echo "=== $COMMIT ctest rc=\$? end \$(date)"
EOF

GLOG=/home/obsd-aarch64-hk$TAG-$(date -u +%Y%m%d).log
gssh "chmod +x /home/obsd-aarch64-hk-guest.sh; ls -t /home/obsd-aarch64-hk-*.log 2>/dev/null | tail -n +8 | xargs rm -f;
  nohup /home/obsd-aarch64-hk-guest.sh > $GLOG 2>&1 < /dev/null &" ||
  { log "ERROR: starting the guest run failed"; exit 1; }
echo "$COMMIT" > "$STATE/last-commit$TAG"
log "started $REF $COMMIT in the VM, log $GLOG"
