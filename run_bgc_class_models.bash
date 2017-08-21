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

# handle output file
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


