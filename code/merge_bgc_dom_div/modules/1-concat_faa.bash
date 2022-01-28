#!/bin/bash -l

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
# 4. Concat fasta
###############################################################################

IFS=","
for D in $( echo "${INPUT_DIRS}" ); do 
    
  SUBSEQS="${D}"/"${DOMAIN}_dom_seqs.faa"
  SAMPLE_NAME=$(basename $(dirname "${SUBSEQS}") | sed 's/\./_/g')
  
  if [[ ! -f "${SUBSEQS}" ]]; then
    echo "${DOMAIN}_dom_seqs.faa not found in ${D}"
    exit 1
  fi  
  
  awk -v FC="${SAMPLE_NAME}" '{
    if ( $0 ~ /^>/ ) {
      sub(/^>/,">"FC"_bf_",$0)
    } 
    print $0;
  }' "${SUBSEQS}"	
 
done > "${TMP_NAME}_all.faa"

if [[ "$?" -ne "0" ]]; then
  echo "Generating ${TMP_NAME}_all.faa failed"
  exit 1
fi  

