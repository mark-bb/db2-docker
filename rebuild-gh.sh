#!/bin/bash
#
# Function: Builds DB2 Genius Hub image
#

usage() {
  echo -e "Usage example: \n$0 \n\
          [-b | --base-image] base-image-name - like ubuntu:22.04 \n\
          [-v | --vrmf] v.r.m.f               - DB2 Genius Hub Installation image version, must be placed to ${DIR?}/distrib/db2gh/ibm-db2GeniusHub-v.r.m.f-linux.tgz \n\
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

# [ "X${VRMF}" = "X" ] && { usage; exit 1; }

# : ${IMAGE_BASE="redhat/ubi9"}
: ${IMAGE_BASE="ubuntu:22.04"}
: ${VRMF="1.1.0.0"}

distr="${DIR?}/distrib/db2gh/ibm-db2GeniusHub-${VRMF?}-linux.tgz"
if [ ! -f "${distr?}" ]; then
  echo "No dir with DB2 GH installation image: \"${distr?}\"" >&2
  exit 1
fi

IMAGE_SUFFIX="unknown"
for img in ubuntu redhat suse amazon alma rocky; do
  if printf "${IMAGE_BASE?}" | grep "${img?}" &>/dev/null; then
    IMAGE_SUFFIX="${img?}"
    break
  fi
done
IMAGE=db2/db2gh-${IMAGE_SUFFIX?}:${VRMF?}
CONT=db2gh

docker stop ${CONT?}
docker rm -f ${CONT?}
docker rmi ${IMAGE} --force
docker build \
        -f Dockerfile-gh \
        -t ${IMAGE?} \
        --build-arg VRMF=${VRMF?} \
        --build-arg IMAGE_BASE=${IMAGE_BASE?} \
        --progress=plain .
