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

# handle input file
INPUT_FILE=$(basename $1)
INPUT_DIR=$(dirname $(realpath $1))
shift

# handle output file
if [[ -d "${1}" ]]; then
  echo "output dir ${1} already exists"
  exit
fi

OUTPUT_DIR=$(dirname $(realpath $1))
OUTPUT=$(basename $1)
shift

# Links within the container
CONTAINER_SRC_DIR=/input
CONTAINER_DST_DIR=/output

docker run \
  --volume ${INPUT_DIR}:${CONTAINER_SRC_DIR}:rw \
  --volume ${OUTPUT_DIR}:${CONTAINER_DST_DIR}:rw \
  --detach=false \
  --rm \
   epereira/ufbgctoolbox:bgc_class_models \
  --input "${CONTAINER_SRC_DIR}/${INPUT_FILE}" \
  --outdir "${OUTPUT}" \
  $@


