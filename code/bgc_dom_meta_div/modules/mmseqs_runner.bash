#!/bin/bash

set -o pipefail

###############################################################################
# 1. Load general configuration
###############################################################################

source /bioinfo/software/conf

###############################################################################
# 2. Set parameters
###############################################################################

while :; do
  case "${1}" in 
#############
  --env) # Takes an option argument, ensuring it has been specified.
  if [[ -n "${2}" ]]; then
    ENV="${2}"
    shift
  else
    printf 'ERROR: "--env" requires a non-empty option argument.\n' >&2
    exit 1
  fi
  ;;
  --env=?*)
  ENV=${1#*=} # Delete everything up to "=" and assign the remainder.
  ;;
  --env=)   # Handle the case of an empty --file=
  printf 'ERROR: "--env" requires a non-empty option argument.\n' >&2
  exit 1
  ;;  
#############
  --prefix) # Takes an option argument, ensuring it has been specified.
  if [[ -n "${2}" ]]; then
    NAME="${2}"
    shift
  else
    printf 'ERROR: "--prefix" requires a non-empty option argument.\n' >&2
    exit 1
  fi
  ;;
  --prefix=?*)
  NAME=${1#*=} # Delete everything up to "=" and assign the remainder.
  ;;
  --prefix=)   # Handle the case of an empty --file=
  printf 'ERROR: "--prefix" requires a non-empty option argument.\n' >&2
  exit 1
  ;;
#############
  --tmp_prefix) # Takes an option argument, ensuring it has been specified.
  if [[ -n "${2}" ]]; then
    TMP_NAME="${2}"
    shift
  else
    printf 'ERROR: "--tmp_prefix" requires a non-empty option argument.\n' >&2
    exit 1
  fi
  ;;
  --tmp_prefix=?*)
  TMP_NAME=${1#*=} # Delete everything up to "=" and assign the remainder.
  ;;
  --tmp_prefix=)   # Handle the case of an empty --file=
  printf 'ERROR: "--tmp_prefix" requires a non-empty option argument.\n' >&2
  exit 1
  ;; 
#############
  --tmp_folder) # Takes an option argument, ensuring it has been specified.
  if [[ -n "${2}" ]]; then
    TMP_FOLDER="${2}"
    shift
  else
    printf 'ERROR: "--tmp_folder" requires a non-empty option argument.\n' >&2
    exit 1
  fi
  ;;
  --tmp_prefix=?*)
  TMP_FOLDER=${1#*=} # Delete everything up to "=" and assign the
                     # remainder.
  ;;
  --tmp_folder=)     # Handle the case of an empty --file=
  printf 'ERROR: "--tmp_folder" requires a non-empty option argument.\n' >&2
  exit 1
  ;;
#############
  --)            # End of all options.
  shift
  break
  ;;
  -?*)
  printf 'WARN: Unknown option (ignored): %s\n' "$1" >&2
  ;;
  *) # Default case: If no more options then break out of the loop.
  break
  esac
  shift
done

###############################################################################
# 3. Load env
###############################################################################

source "${ENV}"

###############################################################################
# 4. Cluster seqs
###############################################################################

if [[ -d "${TMP_FOLDER}" ]]; then
  rm -r "${TMP_FOLDER}"
fi  
    
"${mmseqs}" createdb "${NAME}_dom_seqs.faa" "${TMP_NAME}_db"
mkdir "${TMP_FOLDER}" 

"${mmseqs}" cluster "${TMP_NAME}_db" "${TMP_NAME}_clu" \
"${TMP_FOLDER}" \
--min-seq-id "${ID}" \
--remove-tmp-files \
-c 0.8 \
-s 7.5 \
--threads "${NSLOTS}"

"${mmseqs}" createtsv "${TMP_NAME}_db" "${TMP_NAME}_db" \
"${TMP_NAME}_clu" "${TMP_NAME}_clu".tsv

