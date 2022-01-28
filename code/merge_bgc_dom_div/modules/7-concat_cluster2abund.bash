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
  printf 'WARN: Unknown option (ignored): %s\n' "$1" >&2
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
# 4. Concat cluster2abund
###############################################################################

IFS="," 
for D in $( echo "${INPUT_DIRS}" ); do

  CLUSTER2ABUND="${D}"/"${DOMAIN}_cluster2abund.tsv"
  SAMPLE_NAME=$(basename $(dirname "${CLUSTER2ABUND}") | sed 's/\./_/g')
    
  if [[ ! -f "${CLUSTER2ABUND}" ]]; then
    echo "No ${DOMAIN}_cluster2abund.tsv found in ${D}"
    exit 1
  fi  
    
  awk -v FC="${SAMPLE_NAME}" 'BEGIN {OFS="\t" }{
    sub(/^/,FC"_bf_",$2)
    sub(/^/,FC"_bf_",$1)
    print $1,$2,$3,FC;
  }' "${CLUSTER2ABUND}"

done > "${TMP_NAME}_concat_cluster2abund.tsv"

if [[ "$?" -ne "0" ]]; then
  echo "Generating ${TMP_NAME}_concat_cluster2abund.tsv failed"
  exit 1
fi
