#!/bin/bash

set -o errexit
SIF_PATH="/home/epereira/workspace/repositories/BiG-MEx/singularity/bgc_profiler/"

function realpath() {
  CURRENT_DIR=$(pwd)
  DIR=$(dirname $1)
  FILE=$(basename $1)
  cd "${DIR}"
  echo "$(pwd)/${FILE}"
  cd "${CURRENT_DIR}"
}

# check input parameters
if [[ "$#" -lt 2 ]]; then
  echo -e "Failed. Missing parameters.\nSee run_bgc_dom2class_prof . . --help"
  exit
fi

# handle input file1
INPUT_FILE1=$(basename $1)
INPUT_DIR1=$(dirname $(realpath $1))
shift

# handle input file2
if [[ -f $1 && $1 != *.RData ]]; then
  INPUT_FILE2=$(basename $1)
  INPUT_DIR2=$(dirname $(realpath $1))
  shift 

  if [[ "${INPUT_DIR1}" != "${INPUT_DIR2}" ]]; then
    echo "R1 and R2 input files should be in the same directory"
    exit 1
  fi
  
fi  

# handle input models
if [[ -f $1 && $1 == *.RData ]]; then
  MODELS=$(basename $1)
  INPUT_DIR_MODELS=$(dirname $(realpath $1))
  shift
  
  if [[ "${INPUT_DIR1}" != "${INPUT_DIR_MODELS}" ]]; then
    echo "R1 and R2 files, and input models should be in the same directory"
    exit 1
  fi
  
fi

OUTPUT_DIR=$(dirname $(realpath $1))
OUTPUT=$(basename $1)
shift

# Links within the container
CONTAINER_SRC_DIR=/input
CONTAINER_DST_DIR=/output

# case 1: R1 and R2 with input models
if [[ -n "${INPUT_FILE2}" && -n "${MODELS}" ]]; then
  singularity run \
    --bind ${INPUT_DIR1}:${CONTAINER_SRC_DIR}:rw \
    --bind ${OUTPUT_DIR}:${CONTAINER_DST_DIR}:rw \
    docker-daemon:epereira/bgc_profiler:latest \
    --reads1 "${CONTAINER_SRC_DIR}/${INPUT_FILE1}" \
    --reads2 "${CONTAINER_SRC_DIR}/${INPUT_FILE2}" \
    --bgc_models "${CONTAINER_SRC_DIR}/${MODELS}" \
    --outdir "${OUTPUT}" \
    $@
fi
 
# case 2: SR with input models 
if [[ -z "${INPUT_FILE2}" && -n "${MODELS}" ]]; then 
  singularity run \
    --bind ${INPUT_DIR1}:${CONTAINER_SRC_DIR}:rw \
    --bind ${OUTPUT_DIR}:${CONTAINER_DST_DIR}:rw \
    docker-daemon:epereira/bgc_profiler:latest \
    --single_reads "${CONTAINER_SRC_DIR}/${INPUT_FILE1}" \
    --bgc_models "${CONTAINER_SRC_DIR}/${MODELS}" \
    --outdir "${OUTPUT}" \
    $@
fi
   
# case 3: R1 and R2 without input models   
if [[ -n "${INPUT_FILE2}" && -z "${MODELS}" ]]; then 
  singularity run \
    --bind ${INPUT_DIR1}:${CONTAINER_SRC_DIR}:rw \
    --bind ${OUTPUT_DIR}:${CONTAINER_DST_DIR}:rw \
    docker-daemon:epereira/bgc_profiler:latest \
    --reads1 "${CONTAINER_SRC_DIR}/${INPUT_FILE1}" \
    --reads2 "${CONTAINER_SRC_DIR}/${INPUT_FILE2}" \
    --outdir "${OUTPUT}" \
    $@
fi

# case 4: SR without input models   
if [[ -z "${INPUT_FILE2}" && -z "${MODELS}" ]]; then 
  singularity run \
    --bind ${INPUT_DIR1}:${CONTAINER_SRC_DIR}:rw \
    --bind ${OUTPUT_DIR}:${CONTAINER_DST_DIR}:rw \
    docker-daemon:epereira/bgc_profiler:latest \
    --single_reads "${CONTAINER_SRC_DIR}/${INPUT_FILE1}" \
    --outdir "${OUTPUT}" \
    $@
fi
  
