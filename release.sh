#!/bin/bash

set -e
if [[ $1 != indocker ]]; then
    touch selenium-chroot-${1}.tar.xz
    docker run --rm -v ${PWD}:/src -it buildpack-deps:trusty \
        /bin/bash /src/release.sh indocker "$@"
    exit $?
fi
mkdir /build
cd /build
cp -r /src/build.sh /src/run.sh /src/fakechroot .
make -C fakechroot clean
ln -s /src/selenium-*.tar .
./build.sh selenium-chroot-${2}.tar.xz
cat selenium-chroot-${2}.tar.xz > /src/selenium-chroot-${2}.tar.xz
