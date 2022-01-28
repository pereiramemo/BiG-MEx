#!/bin/bash

set -o pipefail

###############################################################################
# 1. Load general configuration
###############################################################################

source "/software/conf"

if [[ "$?" -ne "0" ]]; then
  echo "${DOMAIN}: Sourcing /software/conf failed"
  exit 1
fi  

###############################################################################
# 2. Set parameters
###############################################################################

while :; do
  case "${1}" in 
#############
  --env)
  if [[ -n "${2}" ]]; then
    ENV="${2}"
    shift
  fi
  ;;
  --env=?*)
  ENV=${1#*=}
  ;;
  --env=)
  printf 'ERROR: --env requires a non-empty argument\n' >&2
  exit 1
  ;;  
#############
  --prefix)
  if [[ -n "${2}" ]]; then
    NAME="${2}"
    shift
  fi
  ;;
  --prefix=?*)
  NAME=${1#*=}
  ;;
  --prefix=)
  printf 'ERROR: --prefix requires a non-empty argument\n' >&2
  exit 1
  ;;
#############
  --tmp_prefix)
  if [[ -n "${2}" ]]; then
    TMP_NAME="${2}"
    shift
  fi
  ;;
  --tmp_prefix=?*)
  TMP_NAME=${1#*=}
  ;;
  --tmp_prefix=)
  printf 'ERROR: --tmp_prefix requires a non-empty argument\n' >&2
  exit 1
  ;; 
#############
  --tmp_folder)
  if [[ -n "${2}" ]]; then
    TMP_FOLDER="${2}"
    shift
  fi
  ;;
  --tmp_folder=?*)
  TMP_FOLDER=${1#*=} 
  ;;
  --tmp_folder=) 
  printf 'ERROR: --tmp_folder requires a non-empty argument\n' >&2
  exit 1
  ;;
#############
  --)         
  shift
  break
  ;;
  -?*)
  printf 'WARN: Unknown argument (ignored): %s\n' "$1" >&2
  ;;
  *) 
  break
  esac
  shift
done

###############################################################################
# 3. Load env
###############################################################################

source "${ENV}"

if [[ $? -ne "0" ]]; then
  echo "${DOMAIN}: Sourcing ${ENV} failed"
  exit 1
fi 

###############################################################################
# 4. Cluster seqs
###############################################################################

if [[ -d "${TMP_FOLDER}" ]]; then
  rm -r "${TMP_FOLDER}"
  
  if [[ $? -ne "0" ]]; then
    echo "${DOMAIN}: Removing ${TMP_FOLDER} failed"
    exit 1
  fi  
  
fi 
  
"${mmseqs}" createdb "${NAME}_dom_seqs.faa" "${TMP_NAME}_db"

if [[ "$?" -ne "0" ]]; then
  echo "${DOMAIN}: mmseqs createdb failed"
  exit 1
fi  

mkdir "${TMP_FOLDER}" 

if [[ "$?" -ne "0" ]]; then
  echo "${DOMAIN}: Creating ${TMP_FOLDER} failed"
  exit 1
fi

"${mmseqs}" cluster "${TMP_NAME}_db" "${TMP_NAME}_clu" \
"${TMP_FOLDER}" \
--min-seq-id "${ID}" \
-c 0.8 \
-s 7.5 \
--threads "${NSLOTS}"

if [[ "$?" -ne "0" ]]; then
  echo "${DOMAIN}: mmseqs cluster failed"
  exit 1
fi  

"${mmseqs}" createtsv "${TMP_NAME}_db" "${TMP_NAME}_db" \
"${TMP_NAME}_clu" "${TMP_NAME}_clu".tsv

if [[ "$?" -ne "0" ]]; then
  echo "${DOMAIN}: mmseqs createtsv failed"
  exit 1
fi
