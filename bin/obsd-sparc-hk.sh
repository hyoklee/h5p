#!/bin/bash
#
# Build and test hyoklee/hdf5 develop on the OpenBSD 8.0 sparc64 QEMU VM and
# submit to CDash as site obsd-8.0.sparc64, build hk/develop (with zlib).
#
# Meant for cron. A run takes about 15 hours (build plus tests on one emulated
# CPU), so this script only starts it in the guest and returns. Later calls
# skip while a run is still going, and skip when develop has not changed
# since the last run (FORCE=1 runs anyway).
#
#   0 1 * * * $HOME/h5p/bin/obsd-sparc-hk.sh >> $HOME/.cache/obsd-sparc-hk/cron.log 2>&1
#
# The VM must run the locally patched qemu-system-sparc64 (BQL around the
# SOFTINT helpers); the stock anyvm binary loses a tick and the guest clock
# stops after a day or two. If the VM is down it is restored from the
# "booted" snapshot.

set -u

SRC=${SRC:-$HOME/hdf5}            # clone with origin = hyoklee/hdf5
REF=${REF:-origin/develop}
SITE=obsd-8.0.sparc64
BUILDNAME=hk/develop
HOST=openbsd-8.0-sparc64          # ~/.ssh/config.d entry (127.0.0.1:10022)
STATE=$HOME/.cache/obsd-sparc-hk

VMDIR=$HOME/.cache/anyvm-obsd/sparc64/openbsd/v2.1.1
QEMU=$HOME/.cache/anyvm-obsd/sparc64/tools/qemu-10.2.3-sparc64-noble/qemu10-sparc64/bin/qemu-system-sparc64
QEMU_SHA256=c796105bbad5a51ecb64e593413504633a97375074e63d72f6c45c9d74e9442a

log() { echo "$(date -u '+%F %T') $*"; }
gssh() { ssh -o ConnectTimeout=30 -o LogLevel=ERROR "$HOST" "$@"; }

mkdir -p "$STATE"
exec 9> "$STATE/lock"
flock -n 9 || { log "another instance is running"; exit 0; }

if [ "$(sha256sum "$QEMU" | cut -d' ' -f1)" != "$QEMU_SHA256" ]; then
  log "ERROR: $QEMU is not the patched build (anyvm re-download?); not running"
  exit 1
fi

# Start the VM from the "booted" snapshot if it is not up.
if ! gssh true 2>/dev/null; then
  if pgrep -f "^$QEMU .*-name openbsd-8.0-sparc64" > /dev/null; then
    log "ERROR: VM process is up but ssh fails; not running"
    exit 1
  fi
  log "starting VM from snapshot 'booted'"
  "$QEMU" \
    -chardev socket,id=serial0,host=127.0.0.1,port=7000,server=on,wait=off,logfile=$VMDIR/openbsd-8.0-sparc64.serial.log \
    -serial chardev:serial0 -name openbsd-8.0-sparc64 -smp 1 -m 1024 \
    -netdev user,id=net0,net=192.168.122.0/24,dhcpstart=192.168.122.10,ipv6=off,hostfwd=tcp:127.0.0.1:10022-:22 \
    -drive file=$VMDIR/openbsd-8.0-sparc64.qcow2,format=qcow2,if=ide,index=0 \
    -rtc base=utc,clock=host -machine sun4u -vga none \
    -device e1000,netdev=net0,bus=pciB -boot order=c \
    -bios $VMDIR/openbios-sparc64.elf -display none \
    -monitor tcp:127.0.0.1:4444,server,nowait,nodelay \
    -loadvm booted -daemonize || { log "ERROR: QEMU failed to start"; exit 1; }
  for i in $(seq 30); do gssh true 2>/dev/null && break; sleep 10; done
  gssh true 2>/dev/null || { log "ERROR: VM did not come up"; exit 1; }
  # The snapshot restores the guest clock from when it was saved
  gssh "date -u $(date -u +%Y%m%d%H%M.%S)" > /dev/null
fi

# [t] keeps pgrep from matching the remote shell running this very command
if gssh 'pgrep -f "obsd-sparc-hk-gues[t].sh"' > /dev/null; then
  log "previous run still in progress; skipping"
  exit 0
fi

git -C "$SRC" fetch -q origin develop || { log "ERROR: git fetch failed"; exit 1; }
COMMIT=$(git -C "$SRC" rev-parse --short=11 "$REF")
if [ "${FORCE:-0}" != 1 ] && [ "$COMMIT" = "$(cat "$STATE/last-commit" 2>/dev/null)" ]; then
  log "$REF $COMMIT already tested; skipping"
  exit 0
fi

TGZ=$STATE/hdf5-hk.tgz
git -C "$SRC" archive --prefix=hdf5-hk/ "$REF" | gzip -1 > "$TGZ" &&
  scp -q -o LogLevel=ERROR "$TGZ" "$HOST:/home/hdf5-hk.tgz" ||
  { log "ERROR: copying source to the VM failed"; exit 1; }
rm -f "$TGZ"

# The guest script: fresh tree, 3 h per-test timeout, and no 1 h testhdf5
# alarm (the heaviest tests need up to ~1 h on the emulated CPU).
gssh "cat > /home/obsd-sparc-hk-guest.sh" <<EOF
#!/bin/sh
cd /home || exit 1
rm -rf hdf5-hk && tar xzf hdf5-hk.tgz && rm hdf5-hk.tgz || exit 1
cd hdf5-hk
sed -i 's/HDF5_ALARM_SECONDS=3600/HDF5_ALARM_SECONDS=0/g' test/CMakeTests.cmake
mkdir build && cd build
echo "=== $COMMIT start \$(date)"
cmake -DCMAKE_BUILD_TYPE=Release \\
  -DCTEST_DROP_SITE_INIT:STRING="my.cdash.org" \\
  -DCTEST_DROP_LOCATION_INIT:STRING="/submit.php?project=HDF5" \\
  -DHDF5_ENABLE_ZLIB_SUPPORT:BOOL=ON \\
  -DSITE:STRING="$SITE" -DBUILDNAME:STRING="$BUILDNAME" ..
ctest -D Experimental -C Release -j1 --timeout 10800
echo "=== $COMMIT ctest rc=\$? end \$(date)"
EOF

GLOG=/home/obsd-sparc-hk-$(date -u +%Y%m%d).log
gssh "chmod +x /home/obsd-sparc-hk-guest.sh; ls -t /home/obsd-sparc-hk-2*.log 2>/dev/null | tail -n +8 | xargs rm -f;
  nohup /home/obsd-sparc-hk-guest.sh > $GLOG 2>&1 < /dev/null &" ||
  { log "ERROR: starting the guest run failed"; exit 1; }
echo "$COMMIT" > "$STATE/last-commit"
log "started $REF $COMMIT in the VM, log $GLOG"
