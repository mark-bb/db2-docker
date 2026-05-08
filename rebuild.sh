#!/bin/bash
#
# Function: Builds DB2 root image.
# There must be distrib/db2/${1}/server_dec directory with a DB2 installation image 
#

usage() {
  echo -e "Usage example: \n$0 \n\
          [-b | --base-image] base-image-name - like ubuntu:22.04 \n\
          [-v | --vrmf] v.r.m.f               - DB2 Installation image version, must be placed to ${DIR?}/distrib/db2/v.r.m.f/server_dec \n\
          " >&2; exit 1;
}

DIR="$(cd "$(dirname "$0")" && pwd -P)"
# read the options
TEMP=$(getopt -o heb:v: --long help,entrypoint,base-image:,vrmf: -n "$0" -- "$@")
[ $? -ne 0 ] && { echo "Terminating..." >&2; exit 1; }

# Just for test
#echo "$TEMP"
eval set -- "$TEMP"

# extract options and their arguments into variables.
while true ; do
    case "$1" in
        -b|--base-image)
            IMAGE_BASE="$2"; shift 2;;
        -v|--vrmf)
            VRMF="$2"; shift 2;;
        --) shift; break;;
        -h|--help) usage; exit 1;;
        *)
            echo "Internal error!" >&2; exit 1;;
    esac
done

[ "X${VRMF}" = "X" ] && { usage; exit 1; }

if [ ! -d "${DIR?}/distrib/db2/${VRMF}" ]; then
  echo "No dir with DB2 installation image: \"${DIR?}/distrib/db2/${VRMF}\"" >&2
  exit 1
fi

# : ${IMAGE_BASE="redhat/ubi9"}
: ${IMAGE_BASE="ubuntu:22.04"}

IMAGE_SUFFIX="unknown"
for img in ubuntu redhat suse amazon alma rocky; do
  if printf "${IMAGE_BASE?}" | grep "${img?}" &>/dev/null; then
    IMAGE_SUFFIX="${img?}"
    break
  fi
done
IMAGE=db2/db2-${IMAGE_SUFFIX?}:${VRMF?}
CONT=db2inst1
[ ! -d "${DIR?}/distrib/db2/${VRMF?}" ] && { echo "No dir with a DB2 installation image: \"${DIR?}/distrib/db2/${VRMF?}\"" >&2; exit 1; }

docker stop ${CONT?}
docker rm -f ${CONT?}
docker rmi ${IMAGE} --force
docker build \
        -f Dockerfile \
        -t ${IMAGE?} \
        --build-arg VRMF=${VRMF?} \
        --build-arg IMAGE_BASE=${IMAGE_BASE?} \
        --progress=plain .
