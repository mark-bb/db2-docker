#!/bin/bash
#
# FUNCTION: Starts up root DB2 container
#

usage() {
  echo -e "Usage example: \n$0 \n\
          [-b | --base-image] base-image-name - like ubuntu:22.04 \n\
          [-v | --vrmf] v.r.m.f               - DB2 Installation image version, must be placed to ${DIR?}/distrib/db2/v.r.m.f/server_dec \n\
          [-e | --entrypoint]                 - change entrypoint to /bin/bash \n\
          " >&2; exit 1;
}

DIR="$(cd "$(dirname "$0")" && pwd -P)"
CONT=db2inst1
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

[ "X${VRMF}" = "X" ] && { usage; exit 1; }
: ${IMAGE_BASE="ubuntu:22.04"}

IMAGE_SUFFIX="unknown"
for img in ubuntu redhat suse amazon alma; do
  if printf "${IMAGE_BASE?}" | grep "${img?}" &>/dev/null; then
    IMAGE_SUFFIX="${img?}"
    break
  fi
done
IMAGE=db2/db2-${IMAGE_SUFFIX?}:${VRMF?}
[ ! -d "${DIR?}/distrib/db2/${VRMF?}" ] && { echo "No dir with db2 distributive: \"${DIR?}/distrib/db2/${VRMF?}\"" >&2; exit 1; }

docker stop ${CONT?}
docker rm -f ${CONT?}

# --entrypoint=/bin/bash \
#    --privileged \
#    -v ${DIR?}/distrib/db2/${VRMF?}:/tmp/distrib/db2 \
#  --hostname ${HOST?} \
# In a docker network
set -x
docker run -itd \
    --privileged \
    -v ${DIR?}/database:/database \
    -p 50010:50000 \
    --env-file .env_list \
    --name ${CONT?} \
    ${ENTRYPOINT} \
    ${IMAGE}
