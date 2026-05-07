#!/bin/bash
#
# Function: Builds DB2 root image.
# There must be distrib/db2/${1}/server_dec directory with a DB2 installation image 
#

usage() {
  printf "Usage:\n$0 [os-image]\n" >&2
  exit 1
}

# IMAGE_BASE=${1:-"redhat/ubi9"}
IMAGE_BASE=${1:-"ubuntu:22.04"}

IMAGE_SUFFIX="unknown"
for img in ubuntu redhat suse amazon; do
  if printf "${IMAGE_BASE?}" | grep "${img?}" &>/dev/null; then
    IMAGE_SUFFIX="${img?}"
    break
  fi
done
IMAGE=db2/db2-nr-${IMAGE_SUFFIX?}
CONT=db2inst1-nr
DIR="$(cd "$(dirname "$0")" && pwd -P)"

docker stop ${CONT?}
docker rm -f ${CONT?}
docker rmi ${IMAGE} --force
docker build \
	-f Dockerfile-nr \
	-t ${IMAGE?} \
	--build-arg IMAGE_BASE=${IMAGE_BASE?} \
	--progress=plain .
