#!/bin/sh
# Build aws-c-s3 and its dependencies (versions pinned by aws-crt-cpp v0.34.5)
# into /usr/local on OpenBSD as static PIC libraries (CMake 4 rejects their
# shared-library install rules). aws-c-cal does not build with LibreSSL (it
# needs <openssl/evperr.h>), so everything uses the OpenSSL 3.5 package, which
# installs beside base LibreSSL; HDF5 must be configured with the same $OSSL.
set -e
pkg_add -I cmake openssl%3.5
. "$(dirname "$0")/obsd-openssl.env"
W=/home/awsbuild; rm -rf $W; mkdir -p $W; cd $W
build() {
  name=$1 repo=$2 sha=$3; shift 3
  echo "=== $name $(date -u +%T)"
  ftp -V -o $name.tgz https://github.com/$repo/archive/$sha.tar.gz
  d=$(tar tzf $name.tgz | head -1 | cut -d/ -f1); tar xzf $name.tgz
  cmake -S $d -B $name-build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local \
    -DCMAKE_PREFIX_PATH=/usr/local -DBUILD_SHARED_LIBS=OFF -DCMAKE_POSITION_INDEPENDENT_CODE=ON -DBUILD_TESTING=OFF $OSSL "$@" > $name.cfg.log 2>&1 || { tail -30 $name.cfg.log; exit 1; }
  cmake --build $name-build -j4 > $name.build.log 2>&1 || { grep -E "error|Error" $name.build.log | head -30; exit 1; }
  cmake --install $name-build > /dev/null
}
build aws-c-common      awslabs/aws-c-common      2b67a658e461520f1de20d64342b91ddcedc7ebb
build aws-checksums     awslabs/aws-checksums     9978ba2c33a7a259c1a6bd0f62abe26827d03b85
build aws-c-cal         awslabs/aws-c-cal         8703b3e5930c9fd508025b268ab837fc9df3c4fd -DUSE_OPENSSL=ON
build s2n               aws/s2n-tls               a7862238a9d6703e0a3e2d7ea4341de8d57429bd -DUNSAFE_TREAT_WARNINGS_AS_ERRORS=OFF
build aws-c-io          awslabs/aws-c-io          db7a1bddc9a29eca18734d0af189c3924775dcf1
build aws-c-compression awslabs/aws-c-compression f951ab2b819fc6993b6e5e6cfef64b1a1554bfc8
build aws-c-http        awslabs/aws-c-http        ce0d65623bff28f03204756d9d1b3366bd0b387d
build aws-c-sdkutils    awslabs/aws-c-sdkutils    f678bda9e21f7217e4bbf35e0d1ea59540687933
build aws-c-auth        awslabs/aws-c-auth        ab03bdd996437d9097953ebb9495de71b6adc537
build aws-c-s3          awslabs/aws-c-s3          3afa5d08be95e82199a153e3abbe59bbb42638d7
# the AWS libraries are static; only OpenSSL 3.5's libcrypto is shared
ldconfig -m /usr/local/lib/eopenssl35
echo "=== done $(date -u +%T)"
