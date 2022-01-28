#!/bin/bash -l

# set -x
set -o pipefail

###############################################################################
# 1. Load general configuration
###############################################################################

source "/software/conf"

if [[ "$?" -ne "0" ]]; then
  echo "Sourcing /software/conf failed"
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
  ENV="${1#*=}"
  ;;
  --env=)
  printf "ERROR: --env requires a non-empty argument\n"  >&2
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

if [[ "$?" -ne "0" ]]; then
  echo "Sourcing ${ENV} failed"
  exit 1
fi

###############################################################################
# 4. Collapse table
###############################################################################

awk 'BEGIN {OFS="\t"}; {

  cluster = $1;
  id = $2;
  array_cluster2abund[cluster] = array_cluster2abund[cluster] + $3;
  
  if ( array_cluster2id[cluster] == ""  ) {
    array_cluster2id[cluster] = id;
    sample_array[cluster] = $4
  }
  
} END {
  for (c in array_cluster2abund) {
    printf "%s\t%s\t%s\t%s\n",  \
    c,array_cluster2id[c],array_cluster2abund[c],sample_array[c]
  }
}' "${TMP_NAME}_concat_cluster2abund.tsv" > \
   "${TMP_NAME}_onlyrep_cluster2abund.tsv"

if [[ "$?" -ne "0" ]]; then
  echo "Generating ${TMP_NAME}_onlyrep_cluster2abund.tsv failed"
  exit 1
fi  

###############################################################################
# 5. Extract repseqs
###############################################################################

cut -f2 "${TMP_NAME}_onlyrep_cluster2abund.tsv" | \
sed "s/_repseq$//" > "${TMP_NAME}.onlyrep_headers"

if [[ "$?" -ne "0" ]]; then
  echo "Generating ${TMP_NAME}.onlyrep_headers failed"
  exit 1
fi  

"${filterbyname}" \
in="${TMP_NAME}_all.faa" \
out="${TMP_NAME}_onlyrep_subseqs.faa" \
names="${TMP_NAME}.onlyrep_headers" \
include=t \
overwrite=t

if [[ "$?" -ne "0" ]]; then
  echo "filterbyname failed"
  exit 1
fi  
