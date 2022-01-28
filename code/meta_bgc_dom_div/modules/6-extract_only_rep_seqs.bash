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

if [[ "$?" -ne "0" ]]; then
  echo "${DOMAIN}: Sourcing ${ENV} failed"
  exit 1
fi

###############################################################################
# 4. Collapse table
###############################################################################

awk 'BEGIN {OFS="\t"}; {

  cluster = $1;
  id = $2;
  
  array_cluster2abund[cluster] = array_cluster2abund[cluster] + $3;
  
  if (id ~ /_repseq$/) {
    array_cluster2id[cluster] = id;
  }
  
} END {
  for (c in array_cluster2abund) {
    print  c,array_cluster2id[c],array_cluster2abund[c]
  }
}' "${NAME}_cluster2abund.tsv" > "${TMP_NAME}_onlyrep_cluster2abund.tsv"

if [[ "$?" -ne "0" ]]; then
  echo "${DOMAIN}: Generating ${TMP_NAME}_onlyrep_cluster2abund.tsv failed"
  exit 1
fi

###############################################################################
# 5. Extract headers
###############################################################################

cut -f2 "${TMP_NAME}_onlyrep_cluster2abund.tsv" | \
sed "s/_repseq$//" > "${TMP_NAME}.onlyrep_headers"

if [[ "$?" -ne "0" ]]; then
  echo "${DOMAIN}: Generating ${TMP_NAME}.onlyrep_headers failed"
  exit 1
fi

###############################################################################
# 6. Extract seqs
###############################################################################

"${filterbyname}" \
in="${NAME}_dom_seqs.faa" \
out="${TMP_NAME}_onlyrep_dom_seqs.faa" \
names="${TMP_NAME}.onlyrep_headers" \
include=t \
overwrite=t

if [[ "$?" -ne "0" ]]; then
  echo "${DOMAIN}: filterbyname failed"
  exit 1
fi
