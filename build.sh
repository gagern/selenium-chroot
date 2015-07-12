#!/bin/bash

browsers="firefox chrome"
perBrowser=(
    opt/selenium/config.json
    var/cache/fontconfig
    var/lib/dpkg/alternatives
    etc/ld.so.cache
)
differing=()

set -e
olfIFS=${IFS}    
shopt -s dotglob
rm -rf selenium-all
mkdir selenium-all
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
    newDiff=( $(diff -rq "selenium-${browser}" "selenium-all" 2>/dev/null \
                       | grep -v ^Only | cut -d\  -f2 | cut -d/ -f2-) )
    IFS=${oldIFS}
    rm -rf -- \
       "${newDiff[@]/#/selenium-${browser}\/}" \
       "${newDiff[@]/#/selenium-all\/}"
    differing+=( "${newDiff[@]}" )
    cp -a --link "selenium-${browser}"/* selenium-all/
done

echo "Relativizing symlinks"
find selenium-all -type l | while read -r i; do
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
cp run.sh selenium-all/
chmod a+x selenium-all/run.sh
cd selenium-all
mkdir selenium-chroot
for i in "${perBrowser[@]}"; do
    printf '%s\n' "${i}" >> selenium-chroot/perBrowser.txt
done
for i in "${differing[@]}"; do
    printf '%s\n' "${i}" >> selenium-chroot/differing.tmp
done
sort selenium-chroot/differing.tmp > selenium-chroot/differing.txt
rm selenium-chroot/differing.tmp
cd ..

echo "Compressing result"
# TODO: use -J resp. xz compression for official releases
tar czf selenium-all.tar.gz selenium-all

echo "Done"
