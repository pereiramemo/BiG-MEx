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
  --domain)
  if [[ -n "${2}" ]]; then
   DOMAIN="${2}"
   shift
  fi
  ;;
  --domain=?*)
  DOMAIN="${1#*=}"
  ;;
  --domain=)
  printf "ERROR: --domain requires a non-empty argument\n"  >&2
  exit 1
  ;;
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
  NAME="${1#*=}"
  ;;
  --prefix=) 
  printf "ERROR: --prefix requires a non-empty argument\n"  >&2
  exit 1
  ;;
############
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
# 3. Load environment
###############################################################################

source "${ENV}"

if [[ $? -ne "0" ]]; then
  echo "${DOMAIN}: Sourcing ${ENV} failed"
  exit 1
fi 

REF_SEQ_DB="${REF_SEQ_DIR}/${DOMAIN}.faa"

###############################################################################
# 4. Run blastp
###############################################################################

"${blastp}" \
-query "${NAME}_dom_seqs.faa"  \
-outfmt 6 \
-evalue 1e-03 \
-num_alignments 10 \
-db "${REF_SEQ_DB}" \
-num_threads "${NSLOTS}" \
-out "${NAME}_dom_seqs.blout"

if [[ $? -ne "0" ]]; then
  echo "${DOMAIN}: blastp failed"
  exit 1
fi  
