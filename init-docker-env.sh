#!/bin/sh
PID=$$
TOPDIR="$(pwd)"

usage() {
    if [ -n "${target}" ]; then
    cat <<EOF
init_docker_env.sh [options] -t <target>
Options:
-d          : download directory (default: $dir)
-h          : show this help

$(echo "Available targets: $(ls config)")
EOF
    else
    cat <<EOF
init_docker_env.sh [options] -t <target>
Options:
-d          : download directory
-h          : show this help

$(echo "Available targets: $(ls config)")
EOF
    fi
}

if [ $# -eq 0 ]; then
    setup_error='true'
else
    count=0
    while getopts "d:h" setup_flag
    do
        case $setup_flag in
            d)  download_direct="$OPTARG";
                ;;
            h)  setup_show_help='true';
                ;;
            \?) setup_error='true';
                ;;
        esac
    done
    shift $((OPTIND-1));
fi

if test $setup_show_help; then
    usage
    exit 0
fi

if test $setup_error; then
    echo "Invalid arguments !!!!"
    usage
    exit 1
fi

if [ ! -d $download_direct ]; then
    printf "Download directory doesn't exit. Do you want to create $download_direct (Y/n)"
    read input
    case $input in
    y|Y|\n)
        mkdir -p $download_direct
        ;;
    n|N)
    ;;
    *)
    ;;
    esac
fi

cat > .env <<EOF
SRC_DIR=$TOPDIR
HOME_DIR=/home/$(id -un)
DOWNLOAD_DIR=${download_direct}
LANG=en_US.UTF-8
TEMPLATECONF=../meta-beaglebone/conf
USER="$(id -un)"
UID=$(id -u)
GROUP="$(id -gn)"
GID=$(id -g)
EOF