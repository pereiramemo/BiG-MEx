#!/bin/bash

set -o errexit
# set -o nounset

function realpath() {
    echo $(readlink -f $1 2>/dev/null )
}

# handle input file
INPUT_FILE=$(basename $1)
INPUT_DIR=$(dirname $(realpath $1))
shift

if [[ -f $1 ]]; then
  INPUT_FILE2=$(basename $1)
  shift	
fi  

# handle output file
OUTPUT_DIR=$(realpath $1)
shift

# Links within the container
CONTAINER_SRC_DIR=/input
CONTAINER_DST_DIR=/output

if [ ! -d ${OUTPUT_DIR} ]; then
  mkdir ${OUTPUT_DIR}
fi

if [[ -z "${INPUT_FILE2}" ]]; then 

  docker run \
    --volume ${INPUT_DIR}:${CONTAINER_SRC_DIR}:rw \
    --volume ${OUTPUT_DIR}:${CONTAINER_DST_DIR}:rw \
    --detach=false \
    --rm \
    epereira/bgc_dom_annot:v1 \
    --reads "${CONTAINER_SRC_DIR}/${INPUT_FILE}" \
    $@

else

 docker run \
    --volume ${INPUT_DIR}:${CONTAINER_SRC_DIR}:rw \
    --volume ${OUTPUT_DIR}:${CONTAINER_DST_DIR}:rw \
    --detach=false \
    --rm \
    epereira/bgc_dom_annot:v1 \
    --reads "${CONTAINER_SRC_DIR}/${INPUT_FILE}" \
    --reads2 "${CONTAINER_SRC_DIR}/${INPUT_FILE2}" \
    $@
    
fi

