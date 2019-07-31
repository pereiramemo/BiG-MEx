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
  --domain)
  if [[ -n "${2}" ]]; then
   DOMAIN="${2}"
   shift
  fi
  ;;
  --domain=?*)
  DOMAIN="${1#*=}" # Delete everything up to "=" and assign the remainder.
  ;;
  --domain=) # Handle the empty case
  printf "ERROR: --domain requires a non-empty option argument.\n"  >&2
  exit 1
  ;;
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
  --prefix)
  if [[ -n "${2}" ]]; then
   NAME="${2}"
   shift
  fi
  ;;
  --prefix=?*)
  NAME="${1#*=}" # Delete everything up to "=" and assign the remainder.
  ;;
  --prefix=) # Handle the empty case
  printf "ERROR: --prefix requires a non-empty option argument.\n"  >&2
  exit 1
  ;;
############
  --)      # End of all options.
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
# 3. Load environment
###############################################################################

source "${ENV}"

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

