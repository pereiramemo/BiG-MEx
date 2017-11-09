#!/bin/bash

set -o errexit


function realpath() {
  CURRENT_DIR=$( pwd )
  DIR=$( dirname $1 );
  FILE=$( basename $1 )
  cd "${DIR}";
  echo $( pwd )/"${FILE}"
  cd "${CURRENT_DIR}"
}

# check input parameters
if [[ "$#" -lt 2 ]]; then
  echo -e "Missing parameters.\nSee run_bgc_class_models . . --help"
  exit
fi

# handle input file
INPUT_FILE=$(basename $1)
INPUT_DIR=$(dirname $(realpath $1))
shift

# handle input bgc_models
if [[ -f $1 ]]; then
  MODELS=$(basename $1)
  shift
fi

OUTPUT_DIR=$( dirname $(realpath $1))
OUTPUT=$(basename $1)
shift

# Links within the container
CONTAINER_SRC_DIR=/input
CONTAINER_DST_DIR=/output

if [[ -n "${MODELS}" ]]; then
  docker run \
    --volume ${INPUT_DIR}:${CONTAINER_SRC_DIR}:rw \
    --volume ${OUTPUT_DIR}:${CONTAINER_DST_DIR}:rw \
    --detach=false \
    --rm \
    --user $(id -u):$(id -g) \
     epereira/bgc_class_pred:latest \
    --input "${CONTAINER_SRC_DIR}/${INPUT_FILE}" \
    --bgc_models "${CONTAINER_SRC_DIR}/${MODELS}" \
    --outdir "${OUTPUT}" \
    $@
else
docker run \
    --volume ${INPUT_DIR}:${CONTAINER_SRC_DIR}:rw \
    --volume ${OUTPUT_DIR}:${CONTAINER_DST_DIR}:rw \
    --detach=false \
    --rm \
    --user $(id -u):$(id -g) \
     epereira/bgc_class_pred:latest  \
    --input "${CONTAINER_SRC_DIR}/${INPUT_FILE}" \
    --outdir "${OUTPUT}" \
    $@
fi



