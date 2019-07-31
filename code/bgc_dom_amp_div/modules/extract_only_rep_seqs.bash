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
  --amp_orfs)
  if [[ -n "${2}" ]]; then
   AMP_ORFS="${2}"
   shift
  fi
  ;;
  --amp_orfs=?*)
  AMP_ORFS="${1#*=}" # Delete everything up to "=" and assign the remainder.
  ;;
  --amp_orfs=) # Handle the empty case
  printf "ERROR: --amp_orfs requires a non-empty option argument.\n"  >&2
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
  --)              # End of all options.
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

###############################################################################
# 4. Collapse table
###############################################################################

awk 'BEGIN {OFS="\t"}; {

  cluster = $1;
  id = $2;
  
  array_cluster2abund[cluster] = array_cluster2abund[cluster] + $3;
  
  if (id  ~ /_repseq$/) {
    array_cluster2id[cluster] = id;
  }
  
} END {
  for (c in array_cluster2abund) {
    print  c,array_cluster2id[c],array_cluster2abund[c]
  }
}' "${NAME}_cluster2abund.tsv" > "${TMP_NAME}_onlyrep_cluster2abund.tsv"

if [[ "$?" -ne "0" ]]; then
  echo "${DOMAIN}: awk command extract repseq failed"
  exit 1
fi

###############################################################################
# 5. Extract headers
###############################################################################

cut -f2 "${TMP_NAME}_onlyrep_cluster2abund.tsv" | \
sed "s/_repseq$//" > "${TMP_NAME}.onlyrep_headers"

if [[ "$?" -ne "0" ]]; then
  echo "${DOMAIN}: sed command remove repseq tag failed"
  exit 1
fi

###############################################################################
# 6. Extract seqs
###############################################################################

"${filterbyname}" \
in="${AMP_ORFS}" \
out="${TMP_NAME}_onlyrep.faa" \
names="${TMP_NAME}.onlyrep_headers" \
include=t \
overwrite=t

if [[ "$?" -ne "0" ]]; then
  echo "${DOMAIN}: filterbyname extract repseq failed"
  exit 1
fi

