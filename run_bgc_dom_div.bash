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

if [[ "${1}" == "sample" ]]; then
  shift

# handle input file
  INPUT_FILE1=$(basename $1)
  INPUT_DIR=$(dirname $(realpath $1))
  shift

  INPUT_FILE2=$(basename $1)
  shift	

  if [[ -f $1 ]]; then
    INPUT_FILE3=$(basename $1)
    shift	
  fi

  if [[ -f $1 ]]; then
    INPUT_FILE4=$(basename $1)
    shift	
  fi  


  OUTPUT_DIR=$(dirname $(realpath $1))
  OUTPUT=$(basename $1)
  shift

  
if [[ -d "${OUTPUT_DIR}/${OUTPUT}" ]] && [[ ${OUTPUT} != "." ]]; then
  echo "output dir ${OUTPUT_DIR}/${OUTPUT} already exists"
  exit
fi 
  
# Links within the container
  CONTAINER_SRC_DIR=/input
  CONTAINER_DST_DIR=/output

# Links within the container
  CONTAINER_SRC_DIR=/input
  CONTAINER_DST_DIR=/output

  if [[ -z "${INPUT_FILE4}" ]]; then

    docker run \
      --volume ${INPUT_DIR}:${CONTAINER_SRC_DIR}:rw \
      --volume ${OUTPUT_DIR}:${CONTAINER_DST_DIR}:rw \
      --detach=false \
      --rm \
      epereira/ufbgctoolbox:bgc_dom_div \
        --input "${CONTAINER_SRC_DIR}/${INPUT_FILE1}" \
        --reads "${CONTAINER_SRC_DIR}/${INPUT_FILE2}" \
        --reads2 "${CONTAINER_SRC_DIR}/${INPUT_FILE3}" \
	--outdir "${OUTPUT}" \
        $@

  else

    docker run \
      --volume ${INPUT_DIR}:${CONTAINER_SRC_DIR}:rw \
      --volume ${OUTPUT_DIR}:${CONTAINER_DST_DIR}:rw \
      --detach=false \
      --rm \
      epereira/ufbgctoolbox:bgc_dom_div \
        --input "${CONTAINER_SRC_DIR}/${INPUT_FILE1}" \
        --reads "${CONTAINER_SRC_DIR}/${INPUT_FILE2}" \
        --reads2 "${CONTAINER_SRC_DIR}/${INPUT_FILE3}" \
        --single_reads "${CONTAINER_SRC_DIR}/${INPUT_FILE4}" \
        --outdir "${OUTPUT}" \
        $@
  fi
fi

if [[ "${1}" == "merge" ]]; then
  shift

# handle input file
  INPUT_FILES="${1}"
  INPUT_DIR=$(dirname $( realpath ${INPUT_FILES/\,*/} ))
  shift
  
  OUTPUT_DIR=$(dirname $(realpath $1))
  OUTPUT=$(basename $1)
  shift
  
  if [[ -d "${OUTPUT_DIR}/${OUTPUT}" ]] && [[ ${OUTPUT} != "." ]]; then
    echo "output dir ${OUTPUT_DIR}/${OUTPUT} already exists"
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
    INPUTS_ARRAY[${N}]="${CONTAINER_SRC_DIR}/$( basename "${i}" )"
  done
  IFS=" "  
 
  INPUT=$( printf "%s," ${INPUTS_ARRAY[*]} | sed 's/\,$//' )
  
  docker run \
    --volume ${INPUT_DIR}:${CONTAINER_SRC_DIR}:rw \
    --volume ${OUTPUT_DIR}:${CONTAINER_DST_DIR}:rw \
    --detach=false \
    --rm \
    epereira/ufbgctoolbox:bgc_dom_merge_div \
      --input_dirs "${INPUT}" \
      --outdir "${OUTPUT}" \
      $@

fi