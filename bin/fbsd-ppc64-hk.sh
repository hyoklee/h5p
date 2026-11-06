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
# The VM is the anyvm-org/freebsd-builder 15.1 powerpc64 image run with the
# user-local QEMU 8.2 in ~/.local/qemu/bin (2 GB, 1 vCPU), ssh on 127.0.0.1 only.

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

# image, keys and profile from anyvm-org/freebsd-builder v2.2.8 (fetched once with anyvm.py)
VMDIR=$HOME/.cache/anyvm-obsd/freebsd/v2.2.8
QEMU=$HOME/.local/qemu/bin/qemu-system-ppc64

log() { echo "$(date -u '+%F %T') $*"; }
gssh() { ssh -o ConnectTimeout=30 -o LogLevel=ERROR "$HOST" "$@"; }

mkdir -p "$STATE"
# fd 9 holds the lock; QEMU is started with 9>&- so the daemon does not keep it
exec 9> "$STATE/lock"
flock -n 9 || { log "another instance is running"; exit 0; }

# Boot the VM if it is not up. QEMU is run directly rather than through
# anyvm: anyvm forwards ssh on every LAN address and opens a VNC web UI, and
# the image's root key is public. Settings follow the image's anyvm profile
# (pseries, power9, virtio, SLOF firmware); one vCPU, as anyvm uses for TCG.
if ! gssh true 2>/dev/null; then
  if pgrep -f "qemu-system-ppc64 .*-name $HOST" > /dev/null; then
    log "ERROR: VM process is up but ssh fails; not running"
    exit 1
  fi
  [ -f "$VMDIR/$HOST.qcow2" ] || { log "ERROR: no image $VMDIR/$HOST.qcow2"; exit 1; }
  log "booting VM"
  "$QEMU" \
    -chardev socket,id=serial0,host=127.0.0.1,port=7003,server=on,wait=off,logfile=$VMDIR/$HOST.serial.log \
    -serial chardev:serial0 -monitor tcp:127.0.0.1:4446,server,nowait,nodelay \
    -name $HOST -m 2048 -smp 1 -rtc base=utc,clock=host \
    -machine pseries,accel=tcg,usb=off,cap-cfpc=broken,cap-sbbc=broken,cap-ibs=broken,cap-ccf-assist=off \
    -cpu power9 \
    -netdev user,id=net0,ipv6=off,hostfwd=tcp:127.0.0.1:$PORT-:22 \
    -device virtio-net-pci,netdev=net0,romfile= \
    -object rng-random,id=rng0,filename=/dev/urandom -device virtio-rng-pci,rng=rng0 \
    -drive file=$VMDIR/$HOST.qcow2,format=qcow2,if=virtio \
    -vga none -display none -daemonize 9>&- || { log "ERROR: QEMU failed to start"; exit 1; }
  if [ ! -f "$HOME/.ssh/config.d/$HOST.conf" ]; then
    printf '%s\n' "Host $HOST" "  StrictHostKeyChecking no" "  UserKnownHostsFile /dev/null" \
      "  ConnectTimeout 60" "  ConnectionAttempts 3" "  ServerAliveInterval 30" \
      "  ServerAliveCountMax 6" "  User root" "  HostName 127.0.0.1" "  Port $PORT" \
      "  IdentityFile $VMDIR/$HOST-host.id_rsa" > "$HOME/.ssh/config.d/$HOST.conf"
    chmod 600 "$HOME/.ssh/config.d/$HOST.conf"
  fi
  for i in $(seq 90); do gssh true 2>/dev/null && break; sleep 20; done
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
# pkg.FreeBSD.org has no ports packages for powerpc64, so the first run
# builds cmake and libaec (szip) from source into /usr/local; the VM disk
# keeps them for later runs.
if ! command -v cmake > /dev/null; then
  (set -e; cd /tmp
   get() { fetch -q -o "\$2" "\$1"; [ "\$(sha256 -q "\$2")" = "\$3" ]; tar xzf "\$2"; }
   get https://github.com/Kitware/CMake/releases/download/v3.31.6/cmake-3.31.6.tar.gz \\
     cmake.tgz 653427f0f5014750aafff22727fb2aa60c6c732ca91808cfb78ce22ddd9e55f0
   cd cmake-3.31.6
   ./bootstrap --prefix=/usr/local --no-qt-gui -- -DCMAKE_BUILD_TYPE=Release \\
     -DBUILD_TESTING=OFF -DCMAKE_USE_OPENSSL=ON
   make install
   cd /tmp
   get https://github.com/MathisRosenhauer/libaec/releases/download/v1.1.4/libaec-1.1.4.tar.gz \\
     libaec.tgz 1b9f3b913d9111469a83820ab62bb6a9f3ec7a5f9b6d681761776aecbc7fefbe
   cmake -S libaec-1.1.4 -B libaec-build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local
   cmake --build libaec-build && cmake --install libaec-build
   rm -rf /tmp/cmake* /tmp/libaec*) || exit 1
fi
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
