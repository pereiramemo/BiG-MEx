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
INPUT_R1=$(basename $1)
shift
INPUT_R2=$(basename $1)
shift

if [[ -f $1 ]]; then
  INPUT_SR=$(basename $1)
  shift	
fi  

# handle output file
OUTPUT_DIR=$(pwd)

# Links within the container
CONTAINER_SRC_DIR=/input
CONTAINER_DST_DIR=/output

# Links within the container
CONTAINER_SRC_DIR=/input
CONTAINER_DST_DIR=/output

# echo $INPUT_FILE
# echo $INPUT_R1
# echo $INPUT_R2
# echo $INPUT_SR
# echo $INPUT_DIR
# echo $OUTPUT_DIR

if [[ -z "${SR}" ]]; then

  docker run \
    --volume ${INPUT_DIR}:${CONTAINER_SRC_DIR}:rw \
    --volume ${OUTPUT_DIR}:${CONTAINER_DST_DIR}:rw \
    --detach=false \
    --rm \
    epereira/bgc_dom_shannon:v1 \
    --input "${CONTAINER_SRC_DIR}/${INPUT_FILE}" \
    --reads "${CONTAINER_SRC_DIR}/${INPUT_R1}" \
    --reads2 "${CONTAINER_SRC_DIR}/${INPUT_R2}" \
    $@

else

   docker run \
    --volume ${INPUT_DIR}:${CONTAINER_SRC_DIR}:rw \
    --volume ${OUTPUT_DIR}:${CONTAINER_DST_DIR}:rw \
    --detach=false \
    --rm \
    epereira/bgc_dom_shannon:v1 \
    --input "${CONTAINER_SRC_DIR}/${INPUT_FILE}" \
    --reads "${CONTAINER_SRC_DIR}/${INPUT_R1}" \
    --reads2 "${CONTAINER_SRC_DIR}/${INPUT_R2}" \
    --single_reads "${CONTAINER_SRC_DIR}/${INPUT_SR}" \
    $@
fi
