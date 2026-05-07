#!/bin/bash
#
# Function: Builds DB2 root image.
# There must be distrib/db2/${1}/server_dec directory with a DB2 installation image 
#

usage() {
  echo -e "Usage example: \n$0 \n\
          [-b | --base-image] base-image-name - like ubuntu:22.04 \n\
          " >&2; exit 1;
}

DIR="$(cd "$(dirname "$0")" && pwd -P)"
# read the options
TEMP=$(getopt -o hb: --long help,base-image: -n "$0" -- "$@")
[ $? -ne 0 ] && { echo "Terminating..." >&2; exit 1; }

# Just for test
#echo "$TEMP"
eval set -- "$TEMP"

# extract options and their arguments into variables.
while true ; do
    case "$1" in
        -b|--base-image)
            IMAGE_BASE="$2"; shift 2;;
        --) shift; break;;
        -h|--help) usage; exit 1;;
        *)
            echo "Internal error!" >&2; exit 1;;
    esac
done

# : ${IMAGE_BASE="redhat/ubi9"}
: ${IMAGE_BASE="ubuntu:22.04"}

IMAGE_SUFFIX="unknown"
for img in ubuntu redhat suse amazon alma; do
  if printf "${IMAGE_BASE?}" | grep "${img?}" &>/dev/null; then
    IMAGE_SUFFIX="${img?}"
    break
  fi
done
IMAGE=db2/db2-nr-${IMAGE_SUFFIX?}
CONT=db2inst1-nr

docker stop ${CONT?}
docker rm -f ${CONT?}
docker rmi ${IMAGE} --force
docker build \
	-f Dockerfile-nr \
	-t ${IMAGE?} \
	--build-arg IMAGE_BASE=${IMAGE_BASE?} \
	--progress=plain .
