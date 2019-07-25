#!/bin/bash -l

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
  --env)
  if [[ -n "${2}" ]]; then
    ENV="${2}"
    shift
  fi
  ;;
  --env=?*)
  ENV="${1#*=}" # Delete everything up to "=" and assign the remainder.
  ;;
  --env=) # Handle the empty case
  printf "ERROR: --env requires a non-empty option argument.\n"  >&2
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
# 3. Load env
###############################################################################

source "${ENV}"

###############################################################################
# 4. Concat cluster
###############################################################################

IFS=","
for D in $( echo "${INPUT_DIRS}" ); do 
  
  CLUSTER2ABUND="${D}"/"${DOMAIN}_cluster2abund.tsv"
  SAMPLE_NAME=$(basename $(dirname "${CLUSTER2ABUND}") | sed 's/\./_/g')
  
  if [[ ! -f "${CLUSTER2ABUND}" ]]; then
    echo 2> "no ${DOMAIN}_cluster2abund.tsv found in ${D}"
    exit 1
  fi  
  
  awk -v FC="${SAMPLE_NAME}" 'BEGIN {OFS="\t" }{
    sub(/^/,FC"_bf_",$2)
    print $2,$3;
  }' "${CLUSTER2ABUND}"
  
done  > "${TMP_NAME}_all-coverage.table"
