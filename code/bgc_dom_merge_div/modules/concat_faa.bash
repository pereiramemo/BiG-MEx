#!/bin/bash -l

# set -x
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
# 4. Concat fasta
###############################################################################

IFS=","
for D in $( echo "${INPUT_DIRS}" ); do 
    
  SUBSEQS="${D}"/"${DOMAIN}_dom_seqs.faa"
  SAMPLE_NAME=$(basename $(dirname "${SUBSEQS}") | sed 's/\./_/g')
  
  if [[ ! -f "${SUBSEQS}" ]]; then
    echo 2> "${DOMAIN}_dom_seqs.faa not found in ${D}"
    exit 1
  fi  
  
  awk -v FC="${SAMPLE_NAME}" '{
    if ( $0 ~ /^>/ ) {
      sub(/^>/,">"FC"_bf_",$0)
    } 
    print $0;
  }' "${SUBSEQS}"	
 
done > "${TMP_NAME}_all.faa"

