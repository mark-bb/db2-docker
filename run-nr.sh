#!/bin/bash
#
# FUNCTION: Starts up non-root DB2 container
#

usage() {
  echo -e "Usage example: \n$0 \n\
	  [-b | --base-image] base-image-name - like ubuntu:22.04 \n\
	  [-v | --vrmf] v.r.m.f               - DB2 Installation image version, must be placed to ${DIR?}/distrib/db2/v.r.m.f/server_dec \n\
	  [-e | --entrypoint]                 - change entrypoint to /bin/bash \n\
	  [-m | --memory] X_in_GB             - memory limit in GB \n\
	  " >&2; exit 1;
}

DIR="$(cd "$(dirname "$0")" && pwd -P)"
CONT=db2inst1-nr
# read the options
TEMP=$(getopt -o heb:v:m: --long help,entrypoint,base-image:,vrmf:,memory: -n "$0" -- "$@")
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
        -m|--memory)
            MEM="$2"; shift 2;;
        --) shift; break;;
        -h|--help) usage; exit 1;;
        *) 
            echo "Internal error!" >&2; exit 1;;
    esac
done

if [ "X${VRMF}" = "X" -a ! -d "${DIR?}/distrib/db2/${VRMF}" ]; then
  echo "No dir with DB2 installation image: \"${DIR?}/distrib/db2/${VRMF}\"" >&2
  exit 1
fi

[ "X${VRMF}" != "X" ] && DISTR_MOUNT="-v ${DIR?}/distrib/db2/${VRMF}:/tmp/distrib/db2"

# : ${IMAGE_BASE="redhat/ubi9"}
: ${IMAGE_BASE="ubuntu:22.04"}
: ${MEM="4"}

IMAGE_SUFFIX="unknown"
for img in ubuntu redhat suse amazon; do
  if printf "${IMAGE_BASE?}" | grep "${img?}" &>/dev/null; then
    IMAGE_SUFFIX="${img?}"
    break
  fi
done
IMAGE=db2/db2-nr-${IMAGE_SUFFIX?}

docker stop ${CONT?}
docker rm -f ${CONT?}

# --entrypoint=/bin/bash \
#    --privileged \
#    -v ${DIR?}/distrib/db2/${VRMF?}:/tmp/distrib/db2 \
#  --hostname ${HOST?} \
# In a docker network
set -x
semmsl=250
semmni=$((256*MEM))
semmns=$((semmsl*semmni))
[ ${semmns?} -lt 256000 ] && semmns=256000

docker run -itd \
    -m ${MEM?}GB \
    --memory-swap=$((MEM+4))GB \
    --memory-swappiness=5 \
    --sysctl kernel.shmmni=$((256*MEM)) \
    --sysctl kernel.shmmax=$((MEM*2**30)) \
    --sysctl kernel.shmall=$((2*MEM*2**30/$(getconf PAGESIZE))) \
    --sysctl kernel.sem="${semmsl?} ${semmns?} 32 ${semmni?}" \
    --sysctl kernel.msgmni=$((1024*MEM)) \
    --sysctl kernel.msgmax=65536 \
    --sysctl kernel.msgmnb=65536 \
    -v ${DIR?}/database-nr:/database \
    ${DISTR_MOUNT} \
    -p 50011:50000 \
    --env-file .env_list \
    --name ${CONT?} \
    ${ENTRYPOINT} \
    ${IMAGE}
