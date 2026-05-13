#!/bin/bash
#
# FUNCTION: Starts up a DB2 Genius Hub container
#

usage() {
  echo -e "Usage example: \n$0 \n\
          [-b | --base-image] base-image-name - like ubuntu:22.04 \n\
          [-v | --vrmf] v.r.m.f               - DB2 Genius Hub Installation image version, must be placed to ${DIR?}/distrib/db2gh/ibm-db2GeniusHub-v.r.m.f-linux.tgz \n\
          [-e | --entrypoint]                 - change entrypoint to /bin/bash \n\
          " >&2; exit 1;
}

DIR="$(cd "$(dirname "$0")" && pwd -P)"
CONT=db2gh
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
        -e|--entrypoint)
            ENTRYPOINT="--entrypoint=/bin/bash"; shift;;
        --) shift; break;;
        -h|--help) usage; exit 1;;
        *)
            echo "Internal error!" >&2; exit 1;;
    esac
done

# [ "X${VRMF}" = "X" ] && { usage; exit 1; }
: ${IMAGE_BASE="ubuntu:22.04"}
: ${VRMF="1.1.0.0"}

IMAGE_SUFFIX="unknown"
for img in ubuntu redhat suse amazon alma rocky; do
  if printf "${IMAGE_BASE?}" | grep "${img?}" &>/dev/null; then
    IMAGE_SUFFIX="${img?}"
    break
  fi
done
IMAGE=db2/db2gh-${IMAGE_SUFFIX?}:${VRMF?}

docker stop ${CONT?}
docker rm -f ${CONT?}

# --entrypoint=/bin/bash \
#    --privileged \
#    -v ${DIR?}/distrib/db2/${VRMF?}:/tmp/distrib/db2 \
#  --hostname ${HOST?} \
#    -v ${DIR?}/database:/database \
#    -p 50010:50000 \
# In a docker network
set -x
docker run -itd \
    --hostname ${CONT?} \
    -p 11100:11100 \
    -p 11101:11101 \
    --env-file .env_list_gh \
    --name ${CONT?} \
    ${ENTRYPOINT} \
    ${IMAGE}
