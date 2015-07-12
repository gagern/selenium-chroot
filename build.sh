#!/bin/bash

browsers="firefox chrome"
perBrowser=(
    opt/selenium/config.json
    var/cache/fontconfig
    var/lib/dpkg/alternatives
    etc/ld.so.cache
)
differing=()
if [[ -n "$1" ]]; then
    tarball=$1
    outdir=${1%.tar*}
    case ${1##*.tar} in
        "")
            compression=""
            ;;
        .gz)
            compression="z"
            ;;
        .bz2)
            compression="j"
            ;;
        .xz)
            compression="J"
            ;;
        *)
            echo "Unknown compression." 2>&1
            exit 2
            ;;
    esac
else
    outdir=selenium-chroot
    tarball=${outdir}.tar.gz
    compression=z
fi

set -e
olfIFS=${IFS}
topdir=${PWD}
shopt -s dotglob
rm -rf "${outdir}"
mkdir "${outdir}"

echo "Building fakechroot"
if [[ ! -d fakechroot ]]; then
    git submodule update --init fakechroot
fi
cd fakechroot
if [[ ! -e configure ]]; then
    ./autogen.sh
fi
if [[ ! -e Makefile ]]; then
    ./configure --prefix=/ --enable-shared --disable-static
fi
make
make DESTDIR="${topdir}/${outdir}" install
cd ..
mv "${outdir}"/sbin/* "${outdir}"/bin/

for browser in ${browsers}; do

    if [[ ! -e "selenium-${browser}.tar" ]]; then
        image=selenium/standalone-${browser}:2.46.0
        echo "Exporting ${image}"
        container=$(docker create "${image}")
        test -n "${container}"
        docker export -o "selenium-${browser}.tar" "${container}"
        docker rm "${container}" > /dev/null
    fi

    echo "Unpacking selenium-${browser}"
    rm -rf "selenium-${browser}"
    mkdir "selenium-${browser}"
    cd "selenium-${browser}"
    tar xf "../selenium-${browser}.tar" --exclude 'dev/*'

    echo "Merging selenium-${browser}"
    for i in "${perBrowser[@]}"; do
        if [[ -e "${i}" ]]; then
            mv -- "${i}" "${i}__${browser}"
        fi
    done
    rm -rf -- "${differing[@]}"
    cd ..
    IFS=$'\n'
    newDiff=( $(diff -rq "selenium-${browser}" "${outdir}" 2>/dev/null \
                       | grep -v ^Only | cut -d\  -f2 | cut -d/ -f2-) )
    IFS=${oldIFS}
    rm -rf -- \
       "${newDiff[@]/#/selenium-${browser}\/}" \
       "${newDiff[@]/#/${outdir}\/}"
    differing+=( "${newDiff[@]}" )
    cp -a --link "selenium-${browser}"/* "${outdir}"/
done

echo "Relativizing symlinks"
find "${outdir}" -type l | while read -r i; do
    dst=$(readlink "${i}")
    if [[ ${dst:0:1} != / ]]; then
        continue
    fi
    IFS=/
    rel=( ${i%/*/*} )
    rel="${rel[*]/*/..}"
    IFS=${oldIFS}
    ln -snf "${rel}${dst}" "${i}" 
done

echo "Finishing directory content"
cp run.sh "${outdir}"/
chmod a+x "${outdir}"/run.sh
cd "${outdir}"
mkdir etc/selenium-chroot
for i in "${perBrowser[@]}"; do
    printf '%s\n' "${i}" >> etc/selenium-chroot/perBrowser.txt
done
for i in "${differing[@]}"; do
    printf '%s\n' "${i}" >> etc/selenium-chroot/differing.tmp
done
sort etc/selenium-chroot/differing.tmp > etc/selenium-chroot/differing.txt
rm etc/selenium-chroot/differing.tmp
cd ..

echo "Compressing result"
tar c${compression}f "${tarball}" "${outdir}"

echo "Done"
