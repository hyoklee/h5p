#!/bin/bash
#
# Build and test hyoklee/hdf5 develop on the FreeBSD 15.1 powerpc64
# (big-endian) QEMU VM and submit to CDash as site fbsd-15.1.powerpc64, build
# hk/develop (with zlib and szip from libaec).
#
# Meant for cron. A run takes many hours (build plus tests on one emulated
# CPU), so this script only starts it in the guest and returns. Later calls
# skip while a run is still going, and skip when develop has not changed
# since the last run (FORCE=1 runs anyway).
#
#   0 13 * * * $HOME/h5p/bin/fbsd-ppc64-hk.sh >> $HOME/.cache/fbsd-ppc64-hk/cron.log 2>&1
#
# PR=<number> tests the head of that HDFGroup/hdf5 pull request instead, as
# build <number>, keeping its own record of the last commit tested:
#
#   PR=6698 $HOME/h5p/bin/fbsd-ppc64-hk.sh
#
# The VM is the anyvm-org/freebsd-builder 15.1 powerpc64 image, started with
# anyvm.py (2 GB; anyvm forces 1 vCPU for powerpc64 under TCG) on the
# user-local QEMU 8.2 in ~/.local/qemu/bin.

set -u

SRC=${SRC:-$HOME/hdf5}            # clone with origin = hyoklee/hdf5, upstream = HDFGroup/hdf5
PR=${PR:-}
SITE=fbsd-15.1.powerpc64
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
HOST=freebsd-15.1-powerpc64       # ~/.ssh/config.d entry (127.0.0.1:10025)
PORT=10025
STATE=$HOME/.cache/fbsd-ppc64-hk

ANYVM=$HOME/.cache/anyvm-obsd/anyvm.py
DATADIR=$HOME/.cache/anyvm-obsd   # images land in $DATADIR/powerpc64/freebsd/<builder tag>/

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
  if pgrep -f "qemu-system-ppc64 .*-name $HOST" > /dev/null; then
    log "ERROR: VM process is up but ssh fails; not running"
    exit 1
  fi
  log "starting VM with anyvm"
  PATH=$HOME/.local/qemu/bin:$HOME/miniconda3/bin:$PATH \
    python3 "$ANYVM" --os freebsd --release 15.1 --arch powerpc64 \
      --mem 2048 --ssh-port $PORT --data-dir "$DATADIR" -d >> "$STATE/anyvm.log" 2>&1 ||
    { log "ERROR: anyvm failed to start the VM (see $STATE/anyvm.log)"; exit 1; }
  KEY=$(ls -t "$DATADIR"/powerpc64/freebsd/*/"$HOST-host.id_rsa" 2>/dev/null | head -1)
  [ -n "$KEY" ] || { log "ERROR: no ssh key for $HOST under $DATADIR"; exit 1; }
  rm -f "$HOME/.ssh/config.d/$PORT.conf"
  printf '%s\n' "Host $HOST" "  StrictHostKeyChecking no" "  UserKnownHostsFile /dev/null" \
    "  ConnectTimeout 60" "  ConnectionAttempts 3" "  ServerAliveInterval 30" \
    "  ServerAliveCountMax 6" "  User root" "  HostName 127.0.0.1" "  Port $PORT" \
    "  IdentityFile $KEY" > "$HOME/.ssh/config.d/$HOST.conf"
  chmod 600 "$HOME/.ssh/config.d/$HOST.conf"
  gssh true 2>/dev/null || { log "ERROR: VM did not come up"; exit 1; }
fi

# [t] keeps pgrep from matching the remote shell running this very command
if gssh 'pgrep -f "fbsd-ppc64-hk-gues[t].sh"' > /dev/null; then
  log "previous run still in progress; skipping"
  exit 0
fi

git -C "$SRC" fetch -q "${FETCH[@]}" || { log "ERROR: git fetch failed"; exit 1; }
COMMIT=$(git -C "$SRC" rev-parse --short=11 "$REF")
if [ "${FORCE:-0}" != 1 ] && [ "$COMMIT" = "$(cat "$STATE/last-commit$TAG" 2>/dev/null)" ]; then
  log "$REF $COMMIT already tested; skipping"
  exit 0
fi

gssh "mkdir -p /home" || { log "ERROR: cannot reach the VM"; exit 1; }
TGZ=$STATE/hdf5-hk.tgz
git -C "$SRC" archive --prefix=hdf5-hk/ "$REF" | gzip -1 > "$TGZ" &&
  scp -q -o LogLevel=ERROR "$TGZ" "$HOST:/home/hdf5-hk.tgz" ||
  { log "ERROR: copying source to the VM failed"; exit 1; }
rm -f "$TGZ"

# The guest script: fresh tree, 3 h per-test timeout, and no 1 h testhdf5
# alarm (the emulated CPU makes the heaviest tests take about an hour).
gssh "cat > /home/fbsd-ppc64-hk-guest.sh" <<EOF
#!/bin/sh
cd /home || exit 1
rm -rf hdf5-hk && tar xzf hdf5-hk.tgz && rm hdf5-hk.tgz || exit 1
# libaec provides szip; pkg is a no-op for packages already installed
env ASSUME_ALWAYS_YES=yes pkg install -y cmake libaec || exit 1
cd hdf5-hk
sed -i '' 's/HDF5_ALARM_SECONDS=3600/HDF5_ALARM_SECONDS=0/g' test/CMakeTests.cmake
mkdir build && cd build
echo "=== $COMMIT start \$(date)"
cmake -DCMAKE_BUILD_TYPE=Release \\
  -DCTEST_DROP_SITE_INIT:STRING="my.cdash.org" \\
  -DCTEST_DROP_LOCATION_INIT:STRING="/submit.php?project=HDF5" \\
  -DHDF5_ENABLE_ZLIB_SUPPORT:BOOL=ON \\
  -DHDF5_ENABLE_SZIP_SUPPORT:BOOL=ON \\
  -DSITE:STRING="$SITE" -DBUILDNAME:STRING="$BUILDNAME" ..
ctest -D Experimental -C Release -j1 --timeout 10800
echo "=== $COMMIT ctest rc=\$? end \$(date)"
EOF

GLOG=/home/fbsd-ppc64-hk$TAG-$(date -u +%Y%m%d).log
gssh "chmod +x /home/fbsd-ppc64-hk-guest.sh; ls -t /home/fbsd-ppc64-hk-*.log 2>/dev/null | tail -n +8 | xargs rm -f;
  nohup /home/fbsd-ppc64-hk-guest.sh > $GLOG 2>&1 < /dev/null &" ||
  { log "ERROR: starting the guest run failed"; exit 1; }
echo "$COMMIT" > "$STATE/last-commit$TAG"
log "started $REF $COMMIT in the VM, log $GLOG"
