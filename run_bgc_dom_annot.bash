#!/bin/bash

set -o errexit

function realpath() {
  CURRENT_DIR=$(pwd)
  DIR=$(dirname $1)
  FILE=$(basename $1)
  cd "${DIR}"
  echo "$(pwd)/${FILE}"
  cd "${CURRENT_DIR}"
}

if [[ "$#" -lt 2 ]]; then
  echo -e "Failed. Missing parameters.\nSee run_bgc_dom_annot.bash . . --help"
  exit
fi  

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
    -u $(id -u):$(id -g) \
    epereira/bgc_dom_annot:latest \
    --single_reads "${CONTAINER_SRC_DIR}/${INPUT_FILE1}" \
    --outdir "${OUTPUT}" \
    $@

elif [[ -z "${INPUT_FILE3}" ]]; then 

 docker run \
    --volume ${INPUT_DIR}:${CONTAINER_SRC_DIR}:rw \
    --volume ${OUTPUT_DIR}:${CONTAINER_DST_DIR}:rw \
    --detach=false \
    --rm \
    --user $(id -u):$(id -g) \
    epereira/bgc_dom_annot:latest \
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
    --user $(id -u):$(id -g) \
     epereira/bgc_dom_annot:latest  \
    --reads "${CONTAINER_SRC_DIR}/${INPUT_FILE1}" \
    --reads2 "${CONTAINER_SRC_DIR}/${INPUT_FILE2}" \
    --single_reads "${CONTAINER_SRC_DIR}/${INPUT_FILE3}" \
    --outdir "${OUTPUT}" \
    $@ 
fi

