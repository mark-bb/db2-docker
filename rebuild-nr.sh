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

if printf "${IMAGE_BASE?}" | grep "ubuntu" &>/dev/null; then
  IMAGE_SUFFIX="ubuntu"
elif printf "${IMAGE_BASE?}" | grep "redhat" &>/dev/null; then
  IMAGE_SUFFIX="redhat"
elif printf "${IMAGE_BASE?}" | grep "suse" &>/dev/null; then
  IMAGE_SUFFIX="suse"
else
  IMAGE_SUFFIX="unknown"
fi
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
