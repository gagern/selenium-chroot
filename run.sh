#!/bin/bash

export DISPLAY=:99.0
export GEOMETRY="${SCREEN_WIDTH:-1360}x${SCREEN_HEIGHT:-1020}x${SCREEN_DEPTH:-24}"
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
#        --chrome)
#            browser=chrome
#            ;;
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
rm -f the.pid
mkfifo the.pid
popd >/dev/null
"${chrootcmd[@]}" "${dir}" /usr/bin/env \
    xvfb-run --server-args="$DISPLAY -screen 0 $GEOMETRY -ac +extension RANDR" \
    logpid.sh /the.pid \
    java -jar /opt/selenium/selenium-server-standalone.jar \
    > "${logfile}" 2>&1 &
pid=$(< ${dir}/the.pid)
if [[ ${#cmd[@]} -eq 0 ]]; then
    echo "${pid}"
else
    trap "kill -s SIGTERM ${pid}" SIGTERM SIGINT
    "${cmd[@]}"
    res=$?
    kill -s SIGTERM "${pid}"
    exit ${res}
fi
