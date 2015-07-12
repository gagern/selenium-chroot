#!/bin/bash

export SCREEN_WIDTH=1360 SCREEN_HEIGHT=1020 SCREEN_DEPTH=24 DISPLAY=:99.0
export HOME=/home/seluser
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu/mesa:/usr/lib/jvm/java-7-openjdk-amd64/jre/lib/amd64/jli

browser=firefox
logfile=/tmp/selenium.log
chrootcmd=()
cmd=()
while [[ $# -ne 0 ]]; do
    case $1 in
        --firefox)
            browser=firefox
            ;;
        --chrome)
            browser=chrome
            ;;
        --log=)
            logfile=${0:6}
            ;;
        --chrootcmd=)
            chrootcmd=( ${0:12} )
            ;;
        -*)
            "Invalid option: $1" >&2
            exit 2
            ;;
        *)
            cmd=( "$@" )
            break
            ;;
    esac
    shift
done

set -e
pushd $(dirname "$0") >/dev/null
dir=$(pwd)
if [[ ${#chrootcmd[@]} -eq 0 ]]; then  
    chrootcmd=(
        bash "${dir}/bin/fakechroot"
        --lib "${dir}/lib/fakechroot/libfakechroot.so"
        --config-dir "${dir}/etc/fakechroot"
        --bindir "${dir}/bin"
        chroot
    )
fi

# Provide a symlink to self, to make fakechroot more reliable
ddir=${dir#/}
pdir=${ddir%/*}
oldIFS=${IFS}
IFS=/
udir=( ${pdir} )
udir="${udir[*]/*/..}"
mkdir -p "${pdir}"
ln -snf "${udir}" "${ddir}"
IFS=${oldIFS}

while read -r i; do
    if [[ -e "${i}__${browser}" ]]; then
        ln -snf "${i##*/}__${browser}" "${i}"
    else
        rm -f "${i}"
    fi
done < etc/selenium-chroot/perBrowser.txt
popd >/dev/null
"${chrootcmd[@]}" "${dir}" /opt/bin/entry_point.sh > "${logfile}" 2>&1 &
pid=$!
if [[ ${#cmd[@]} -eq 0 ]]; then
    echo ${pid}
else
    "${cmd[@]}"
    res=$?
    kill -s SIGTERM ${pid} || pkill java
    exit ${res}
fi
