#!/bin/bash
#
# Build and test hyoklee/hdf5 develop on the OpenBSD 8.0 riscv64 QEMU VM and
# submit to CDash as site obsd-8.0.riscv64, build hk/develop (with zlib and
# szip from libaec).
#
# Meant for cron. A run takes many hours (build plus tests on two emulated
# CPUs), so this script only starts it in the guest and returns. Later calls
# skip while a run is still going, and skip when develop has not changed
# since the last run (FORCE=1 runs anyway).
#
#   0 13 * * * $HOME/h5p/bin/obsd-riscv64-hk.sh >> $HOME/.cache/obsd-riscv64-hk/cron.log 2>&1
#
# PR=<number> tests the head of that HDFGroup/hdf5 pull request instead, as
# build <number>, keeping its own record of the last commit tested:
#
#   PR=6698 $HOME/h5p/bin/obsd-riscv64-hk.sh
#
# The VM is the anyvm-org/openbsd-builder 8.0 riscv64 image run with a
# user-local QEMU 8.2 (Ubuntu debs extracted under ~/.local/qemu/root, no
# root needed); if it is down it is booted from cold.

set -u

SRC=${SRC:-$HOME/hdf5}            # clone with origin = hyoklee/hdf5, upstream = HDFGroup/hdf5
PR=${PR:-}
SITE=obsd-8.0.riscv64
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
HOST=openbsd-8.0-riscv64          # ~/.ssh/config.d entry (127.0.0.1:10024)
STATE=$HOME/.cache/obsd-riscv64-hk

VMDIR=$HOME/.cache/anyvm-obsd/riscv64/openbsd/v2.1.1
QROOT=$HOME/.local/qemu/root
QEMU=$HOME/.local/qemu/bin/qemu-system-riscv64

log() { echo "$(date -u '+%F %T') $*"; }
gssh() { ssh -o ConnectTimeout=30 -o LogLevel=ERROR "$HOST" "$@"; }

mkdir -p "$STATE"
# fd 9 holds the lock; QEMU is started with 9>&- so the daemon does not keep it
exec 9> "$STATE/lock"
flock -n 9 || { log "another instance is running"; exit 0; }

# Boot the VM if it is not up (U-Boot S-mode payload, as openbsd-builder
# runs it; romfile= because the NIC's iPXE ROM is not installed and the
# guest does not need it).
if ! gssh true 2>/dev/null; then
  if pgrep -f "qemu-system-riscv64 .*-name openbsd-8.0-riscv64" > /dev/null; then
    log "ERROR: VM process is up but ssh fails; not running"
    exit 1
  fi
  log "booting VM"
  "$QEMU" \
    -chardev socket,id=serial0,host=127.0.0.1,port=7002,server=on,wait=off,logfile=$VMDIR/openbsd-8.0-riscv64.serial.log \
    -serial chardev:serial0 -monitor tcp:127.0.0.1:4445,server,nowait,nodelay \
    -name openbsd-8.0-riscv64 -m 2048 -smp 2 -rtc base=utc,clock=host \
    -netdev user,id=net0,net=192.168.122.0/24,host=192.168.122.1,dhcpstart=192.168.122.254,ipv6=off,hostfwd=tcp:127.0.0.1:10024-192.168.122.254:22 \
    -object rng-builtin,id=rng0 -device virtio-rng-pci,rng=rng0,max-bytes=1024,period=1000 \
    -machine virt,accel=tcg,usb=on,acpi=off -cpu rv64 -device qemu-xhci \
    -device virtio-net-pci,netdev=net0,romfile= -device virtio-balloon-pci \
    -kernel $QROOT/usr/lib/u-boot/qemu-riscv64_smode/uboot.elf \
    -drive file=$VMDIR/openbsd-8.0-riscv64.qcow2,format=qcow2,if=virtio,discard=unmap,detect-zeroes=unmap \
    -display none -daemonize 9>&- || { log "ERROR: QEMU failed to start"; exit 1; }
  for i in $(seq 60); do gssh true 2>/dev/null && break; sleep 20; done
  gssh true 2>/dev/null || { log "ERROR: VM did not come up"; exit 1; }
fi

# [t] keeps pgrep from matching the remote shell running this very command
if gssh 'pgrep -f "obsd-riscv64-hk-gues[t].sh"' > /dev/null; then
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
gssh "cat > /home/obsd-riscv64-hk-guest.sh" <<EOF
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
CMAKE_BUILD_PARALLEL_LEVEL=2 ctest -D Experimental -C Release -j2 --timeout 10800
echo "=== $COMMIT ctest rc=\$? end \$(date)"
EOF

GLOG=/home/obsd-riscv64-hk$TAG-$(date -u +%Y%m%d).log
gssh "chmod +x /home/obsd-riscv64-hk-guest.sh; ls -t /home/obsd-riscv64-hk-*.log 2>/dev/null | tail -n +8 | xargs rm -f;
  nohup /home/obsd-riscv64-hk-guest.sh > $GLOG 2>&1 < /dev/null &" ||
  { log "ERROR: starting the guest run failed"; exit 1; }
echo "$COMMIT" > "$STATE/last-commit$TAG"
log "started $REF $COMMIT in the VM, log $GLOG"
