#!/bin/bash

set -o errexit
# set -o nounset

function realpath() {
    echo $(readlink -f $1 2>/dev/null )
}

# handle input file
INPUT_FILE1=$(basename $1)
INPUT_DIR=$(dirname $(realpath $1))
shift

if [[ -f $1 ]]; then
  INPUT_FILE2=$(basename $1)
  shift	
fi

if [[ -f $1 ]]; then
  INPUT_FILE3=$(basename $1)
  shift	
fi  

# handle output file
OUTPUT_DIR=$( dirname $(realpath $1))
OUTPUT=$(basename $1)
shift

# Links within the container
CONTAINER_SRC_DIR=/input
CONTAINER_DST_DIR=/output

if [[ -z "${INPUT_FILE2}" ]]; then 

  docker run \
    --volume ${INPUT_DIR}:${CONTAINER_SRC_DIR}:rw \
    --volume ${OUTPUT_DIR}:${CONTAINER_DST_DIR}:rw \
    --detach=false \
    --rm \
    epereira/ufbgctoolbox:bgc_dom_annot \
    --single_reads "${CONTAINER_SRC_DIR}/${INPUT_FILE1}" \
    --outdir "${OUTPUT}" \
    $@

elif [[ -z "${INPUT_FILE3}" ]]; then 

 docker run \
    --volume ${INPUT_DIR}:${CONTAINER_SRC_DIR}:rw \
    --volume ${OUTPUT_DIR}:${CONTAINER_DST_DIR}:rw \
    --detach=false \
    --rm \
    epereira/ufbgctoolbox:bgc_dom_annot \
    --reads "${CONTAINER_SRC_DIR}/${INPUT_FILE1}" \
    --reads2 "${CONTAINER_SRC_DIR}/${INPUT_FILE2}" \
    --outdir "${OUTPUT}" \
    $@

else 

 docker run \
    --volume ${INPUT_DIR}:${CONTAINER_SRC_DIR}:rw \
    --volume ${OUTPUT_DIR}:${CONTAINER_DST_DIR}:rw \
    --detach=false \
    --rm \
    epereira/ufbgctoolbox:bgc_dom_annot \
    --reads "${CONTAINER_SRC_DIR}/${INPUT_FILE1}" \
    --reads2 "${CONTAINER_SRC_DIR}/${INPUT_FILE2}" \
    --single_reads "${CONTAINER_SRC_DIR}/${INPUT_FILE3}" \
    --outdir "${OUTPUT}" \
    $@ 
fi

