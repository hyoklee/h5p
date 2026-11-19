#!/bin/bash
#
# Build and test hyoklee/hdf5 develop with the ROS3 (S3) VFD on the OpenBSD
# 8.0 aarch64 QEMU VM, and submit to CDash as site obsd-8.0.aarch64, build
# hk/develop/ros3 (with zlib and szip from libaec).
#
# A run takes hours (no KVM here, so the VM is fully emulated). This script
# only starts the run in the guest and returns. Later calls skip while a run
# is still going, and skip when develop has not changed since the last run
# (FORCE=1 runs anyway).
#
# PR=<number> tests the head of that HDFGroup/hdf5 pull request instead, as
# build <number>/ros3, keeping its own record of the last commit tested.
#
# S3 tests: OpenBSD has no aws-c-s3 package, so on first use the guest builds
# aws-c-s3 and its dependencies from source (obsd-aws-deps.sh) against the
# OpenSSL 3.5 package (obsd-openssl.env), since aws-c-cal needs OpenSSL 3. The ros3 and
# s3comms tests read from an andrewgaul/s3proxy container on this host
# (127.0.0.1:9001, reached from the guest as 192.168.122.1:9001), set up the
# way HDF5's HDF5_ENABLE_ROS3_VFD_DOCKER_PROXY option does.
#
# The VM is the anyvm-org/openbsd-builder v2.1.1 aarch64 image run with the
# user-local QEMU in ~/.local/qemu/bin (virt machine, neoverse-n1, UEFI from
# the local AAVMF build padded to 64 MB pflash, 4 GB, 4 vCPUs), ssh on
# 127.0.0.1 only.

set -u

SRC=${SRC:-$HOME/hdf5}            # clone with origin = hyoklee/hdf5, upstream = HDFGroup/hdf5
PR=${PR:-}
SITE=obsd-8.0.aarch64
if [ -n "$PR" ]; then
  REF=upstream/pr/$PR
  FETCH=(upstream "+pull/$PR/head:refs/remotes/$REF")
  BUILDNAME=$PR/ros3
  TAG=-pr$PR
else
  REF=origin/develop
  FETCH=(origin develop)
  BUILDNAME=hk/develop/ros3
  TAG=
fi
HOST=openbsd-8.0-aarch64          # ~/.ssh/config.d entry (127.0.0.1:10023)
PORT=10023
MONITOR=4448
STATE=$HOME/.cache/obsd-aarch64-hk

VMDIR=$HOME/.cache/anyvm-obsd/aarch64/openbsd/v2.1.1
QEMU=$HOME/.local/qemu/bin/qemu-system-aarch64
BIN=$(dirname "$(readlink -f "$0")")

S3PROXY=s3proxy-hdf5-obsd         # docker container name
S3PORT=9001
S3BUCKET=hdf5ros3
S3ID=remote-identity              # fixed test credentials, as in HDF5's runProxy.cmake
S3KEY=remote-credential

log() { echo "$(date -u '+%F %T') $*"; }
gssh() { ssh -o ConnectTimeout=30 -o LogLevel=ERROR "$HOST" "$@"; }

mkdir -p "$STATE"
# fd 9 holds the lock; QEMU is started with 9>&- so the daemon does not keep it
exec 9> "$STATE/lock"
flock -n 9 || { log "another instance is running"; exit 0; }

# Boot the VM if it is not up. Under TCG the boot loader's 5 s timeout never
# fires, so press Enter at the boot> prompt through the QEMU monitor.
if ! gssh true 2>/dev/null; then
  if pgrep -f "qemu-system-aarch64 .*-name $HOST" > /dev/null; then
    log "ERROR: VM process is up but ssh fails; not running"
    exit 1
  fi
  log "booting VM"
  "$QEMU" \
    -chardev socket,id=serial0,host=127.0.0.1,port=7005,server=on,wait=off,logfile=$VMDIR/$HOST.serial.log \
    -serial chardev:serial0 -monitor tcp:127.0.0.1:$MONITOR,server,nowait,nodelay \
    -name $HOST -m 4096 -smp 4 -rtc base=utc,clock=host \
    -netdev user,id=net0,net=192.168.122.0/24,host=192.168.122.1,dhcpstart=192.168.122.254,ipv6=off,hostfwd=tcp:127.0.0.1:$PORT-192.168.122.254:22 \
    -object rng-builtin,id=rng0 -device virtio-rng-pci,rng=rng0,max-bytes=1024,period=1000 \
    -machine virt,accel=tcg,gic-version=3,usb=on,acpi=off -cpu neoverse-n1 \
    -device qemu-xhci -device usb-kbd -device virtio-net-pci,netdev=net0,romfile= \
    -drive if=pflash,format=raw,readonly=on,file=$VMDIR/$HOST-QEMU_EFI.fd \
    -drive if=pflash,format=raw,file=$VMDIR/$HOST-QEMU_EFI_VARS.fd,unit=1 \
    -drive file=$VMDIR/$HOST.qcow2,format=qcow2,if=none,id=disk0,discard=unmap,detect-zeroes=unmap \
    -device virtio-blk-pci,drive=disk0,bootindex=0 \
    -device virtio-gpu-pci -display none -daemonize 9>&- || { log "ERROR: QEMU failed to start"; exit 1; }
  for i in $(seq 90); do
    [ "$i" -le 3 ] && { sleep 20; printf 'sendkey ret\n' | nc -q 1 127.0.0.1 $MONITOR > /dev/null 2>&1; }
    gssh true 2>/dev/null && break
    sleep 20
  done
  gssh true 2>/dev/null || { log "ERROR: VM did not come up"; exit 1; }
  # The guest clock is not kept in sync under emulation
  gssh "date -u $(date -u +%Y%m%d%H%M.%S)" > /dev/null
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

# S3 test server: start the s3proxy container (localhost only) if needed and
# load the bucket the ros3/s3comms tests expect, with the same keys and ACLs
# as HDF5's runProxy.cmake.
if [ "$(docker inspect -f '{{.State.Running}}' $S3PROXY 2>/dev/null)" != true ]; then
  log "starting $S3PROXY"
  docker rm -f $S3PROXY > /dev/null 2>&1
  docker run -d --publish 127.0.0.1:$S3PORT:80 --name $S3PROXY \
    --env S3PROXY_AUTHORIZATION=aws-v4 --env S3PROXY_ENDPOINT=http://0.0.0.0:80 \
    --env S3PROXY_IDENTITY=$S3ID --env S3PROXY_CREDENTIAL=$S3KEY \
    --env S3PROXY_CORS_ALLOW_ALL=true andrewgaul/s3proxy > /dev/null ||
    { log "ERROR: cannot start $S3PROXY"; exit 1; }
  for i in $(seq 30); do curl -s -o /dev/null http://127.0.0.1:$S3PORT/ && break; sleep 2; done
fi
CREDS=$STATE/s3-credentials
printf '[default]\naws_access_key_id = %s\naws_secret_access_key = %s\nregion = us-east-2\n\n[ros3_vfd_test]\naws_access_key_id = %s\naws_secret_access_key = %s\nregion = us-east-2\n' \
  $S3ID $S3KEY $S3ID $S3KEY > "$CREDS"
s3api() { AWS_SHARED_CREDENTIALS_FILE=$CREDS AWS_PROFILE=default PATH=$HOME/miniconda3/bin:$PATH \
  aws s3api --endpoint-url=http://127.0.0.1:$S3PORT "$@" > /dev/null; }
T=$(mktemp -d)
for f in t8.shakespeare.txt Poe_Raven.txt charsets.h5; do
  git -C "$SRC" show "$REF:test/testfiles/$f" > "$T/$f" || { log "ERROR: no test file $f"; exit 1; }
done
s3api head-bucket --bucket $S3BUCKET 2>/dev/null || s3api create-bucket --bucket $S3BUCKET &&
  s3api put-object --bucket $S3BUCKET --key t8.shakespeare.txt --body "$T/t8.shakespeare.txt" &&
  s3api put-object --bucket $S3BUCKET --key Poe_Raven.txt --body "$T/Poe_Raven.txt" --acl public-read &&
  s3api put-object --bucket $S3BUCKET --key charsets.h5 --body "$T/charsets.h5" --acl public-read &&
  s3api put-object --bucket $S3BUCKET --key "src=h5test/fmt=hive+style@cloud/charsets.h5" --body "$T/charsets.h5" ||
  { log "ERROR: loading the S3 test bucket failed"; rm -rf "$T"; exit 1; }
rm -rf "$T"
scp -q -o LogLevel=ERROR "$CREDS" "$HOST:/home/s3-credentials" &&
  scp -q -o LogLevel=ERROR "$BIN/obsd-aws-deps.sh" "$BIN/obsd-openssl.env" "$HOST:/home/" ||
  { log "ERROR: copying S3 files to the VM failed"; exit 1; }

TGZ=$STATE/hdf5-hk.tgz
git -C "$SRC" archive --prefix=hdf5-hk/ "$REF" | gzip -1 > "$TGZ" &&
  scp -q -o LogLevel=ERROR "$TGZ" "$HOST:/home/hdf5-hk.tgz" ||
  { log "ERROR: copying source to the VM failed"; exit 1; }
rm -f "$TGZ"

# The guest script: AWS libraries on first use, fresh tree, 3 h per-test
# timeout, no 1 h testhdf5 alarm, and the S3 test environment.
gssh "cat > /home/obsd-aarch64-hk-guest.sh" <<EOF
#!/bin/sh
cd /home || exit 1
rm -rf hdf5-hk && tar xzf hdf5-hk.tgz && rm hdf5-hk.tgz || exit 1
# libaec provides szip; -I installs non-interactively, no-op if present
pkg_add -I cmake libaec || exit 1
if [ ! -d /usr/local/lib/cmake/aws-c-s3 ]; then
  sh /home/obsd-aws-deps.sh > /home/obsd-aws-deps.log 2>&1 || { tail -30 /home/obsd-aws-deps.log; exit 1; }
fi
. /home/obsd-openssl.env   # \$OSSL: OpenSSL 3.5, as the AWS libraries use
cd hdf5-hk
sed -i 's/HDF5_ALARM_SECONDS=3600/HDF5_ALARM_SECONDS=0/g' test/CMakeTests.cmake
mkdir build && cd build
echo "=== $COMMIT start \$(date)"
cmake -DCMAKE_BUILD_TYPE=Release \\
  -DCMAKE_PREFIX_PATH=/usr/local \$OSSL \\
  -DCTEST_DROP_SITE_INIT:STRING="my.cdash.org" \\
  -DCTEST_DROP_LOCATION_INIT:STRING="/submit.php?project=HDF5" \\
  -DHDF5_ENABLE_ZLIB_SUPPORT:BOOL=ON \\
  -DHDF5_ENABLE_SZIP_SUPPORT:BOOL=ON \\
  -DHDF5_ENABLE_ROS3_VFD:BOOL=ON \\
  -DSITE:STRING="$SITE" -DBUILDNAME:STRING="$BUILDNAME" ..
export HDF5_ROS3_TEST_BUCKET_URL=http://192.168.122.1:$S3PORT/$S3BUCKET
export AWS_ENDPOINT_URL=http://192.168.122.1:$S3PORT
export HDF5_ROS3_VFD_FORCE_PATH_STYLE=1
export AWS_SHARED_CREDENTIALS_FILE=/home/s3-credentials AWS_PROFILE=ros3_vfd_test
CMAKE_BUILD_PARALLEL_LEVEL=4 ctest -D Experimental -C Release -j4 --timeout 10800
echo "=== $COMMIT ctest rc=\$? end \$(date)"
EOF

GLOG=/home/obsd-aarch64-hk$TAG-$(date -u +%Y%m%d).log
gssh "chmod +x /home/obsd-aarch64-hk-guest.sh; ls -t /home/obsd-aarch64-hk-*.log 2>/dev/null | tail -n +8 | xargs rm -f;
  nohup /home/obsd-aarch64-hk-guest.sh > $GLOG 2>&1 < /dev/null &" ||
  { log "ERROR: starting the guest run failed"; exit 1; }
echo "$COMMIT" > "$STATE/last-commit$TAG"
log "started $REF $COMMIT in the VM, log $GLOG"
