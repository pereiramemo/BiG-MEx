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

if [[ "${1}" == "meta" ]]; then
  shift
  
  # run help
  if [[ "${1}" == "--help" ]]; then
    singularity run docker://epereira/meta_bgc_dom_div:latest --help
    exit 0    
  fi

  # check input parameters
  if [[ "$#" -lt 4 ]]; then
    echo -e "Failed. Missing parameters.\nSee run_bgc_dom_div.bash meta --help"
    exit
  fi
  
  # handle annotation file
  if [[ -f "${1}" ]]; then
    INPUT_FILE1=$(basename $1)
    INPUT_DIR1=$(dirname $(realpath $1))
    shift
  fi
    
  # handle input sequences
  if [[ -f "${1}" ]]; then
    INPUT_FILE2=$(basename $1)
    INPUT_DIR2=$(dirname $(realpath $1))
    shift
    
    if [[ "${INPUT_DIR1}" != "${INPUT_DIR2}" ]]; then
      echo "Input files should be in the same directory"
      exit 1
    fi
  fi  

  # handle input sequences
  if [[ -f "${1}" ]]; then
    INPUT_FILE3=$(basename $1)
    INPUT_DIR3=$(dirname $(realpath $1))
    shift	
    
    if [[ "${INPUT_DIR1}" != "${INPUT_DIR3}" ]]; then
      echo "Input files should be in the same directory"
      exit 1
    fi  
  fi

  # handle input sequences
  if [[ -f "${1}" ]]; then
    INPUT_FILE4=$(basename $1)
    INPUT_DIR4=$(dirname $(realpath $1))
    shift
  
    if [[ "${INPUT_DIR1}" != "${INPUT_DIR4}" ]]; then
      echo "Input files should be in the same directory"
      exit 1
    fi
  fi

  # handle output dir
  if [[ ! -f "${1}" ]]; then
    OUTPUT_DIR=$(dirname $(realpath $1))
    OUTPUT=$(basename $1)
    shift
  fi
  
  # check parameters
  if [[ "${1}" != "--"* ]]; then
    echo -e "Positional parameters were not processed correctly.\nSee run_bgc_dom_div.bash meta --help"
    exit
  fi
  
# Links within the container
  CONTAINER_SRC_DIR=/input
  CONTAINER_DST_DIR=/output

# Links within the container
  CONTAINER_SRC_DIR=/input
  CONTAINER_DST_DIR=/output

  if [[ -z "${INPUT_FILE4}" ]]; then

    singularity run \
      --bind ${INPUT_DIR1}:${CONTAINER_SRC_DIR}:rw \
      --bind ${OUTPUT_DIR}:${CONTAINER_DST_DIR}:rw \
      docker://epereira/meta_bgc_dom_div:latest \
        --input "${CONTAINER_SRC_DIR}/${INPUT_FILE1}" \
        --reads1 "${CONTAINER_SRC_DIR}/${INPUT_FILE2}" \
        --reads2 "${CONTAINER_SRC_DIR}/${INPUT_FILE3}" \
	    --outdir "${OUTPUT}" \
        $@
        
  else

    singularity run \
      --bind ${INPUT_DIR1}:${CONTAINER_SRC_DIR}:rw \
      --bind ${OUTPUT_DIR}:${CONTAINER_DST_DIR}:rw \
      docker://epereira/meta_bgc_dom_div:latest \
        --input "${CONTAINER_SRC_DIR}/${INPUT_FILE1}" \
        --reads1 "${CONTAINER_SRC_DIR}/${INPUT_FILE2}" \
        --reads2 "${CONTAINER_SRC_DIR}/${INPUT_FILE3}" \
        --single_reads "${CONTAINER_SRC_DIR}/${INPUT_FILE4}" \
        --outdir "${OUTPUT}" \
        $@
  fi
  
  FLAG="1"
  
fi

if [[ "${1}" == "merge" ]]; then
  shift

  # run help
  if [[ "${1}" == "--help" ]]; then
    singularity run docker://epereira/merge_bgc_dom_div:latest --help
    exit 0    
  fi
  
  # check input parameters
  if [[ "$#" -lt 3 ]]; then
    echo -e "Failed. Missing parameters.\nSee run_bgc_dom_div.bash merge --help"
    exit
  fi
  
  # handle input file
  INPUT_FILES="${1}"
  INPUT_DIR=$(dirname $(realpath ${INPUT_FILES/\,*/} ))  
  shift
  
  OUTPUT_DIR=$(dirname $(realpath "${1}"))
  OUTPUT=$(basename "${1}")
  shift
  
   # check parameters
  if [[ "${1}" != "--"* ]]; then
    echo -e "Positional parameters were not processed correctly.\nSee run_bgc_dom_div.bash merge --help"
    exit
  fi
  
# Links within the container
  CONTAINER_SRC_DIR=/input
  CONTAINER_DST_DIR=/output

# Links within the container
  CONTAINER_SRC_DIR=/input
  CONTAINER_DST_DIR=/output

  IFS=","
  for i in $( echo "${INPUT_FILES}" ); do 
    N=$(( N + 1 ))
    INPUTS_ARRAY[${N}]="${CONTAINER_SRC_DIR}/$(basename "${i}")"
  done
  IFS=" "  
 
  INPUT=$(printf "%s," ${INPUTS_ARRAY[*]} | sed 's/\,$//')
  
  singularity run \
    --bind ${INPUT_DIR}:${CONTAINER_SRC_DIR}:rw \
    --bind ${OUTPUT_DIR}:${CONTAINER_DST_DIR}:rw \
    docker://epereira/merge_bgc_dom_div:latest \
      --input_dirs "${INPUT}" \
      --outdir "${OUTPUT}" \
      $@
  
  FLAG="1"
fi

# failed run
if [[ "${FLAG}" != "1" ]]; then
  echo -e "Failed. Missing parameters.\n\
See run_bgc_dom_div.bash meta --help\n\
See run_bgc_dom_div.bash merge --help"
  exit
fi
