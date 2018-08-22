#!/bin/bash -l

# set -x
set -o pipefail

#############################################################################
# 1. Load general configuration
#############################################################################

source /bioinfo/software/conf

#############################################################################
# 2. set parameters
#############################################################################

while :; do
  case "${1}" in
#############
  -d|--domain)
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
  -i|--input_dirs)
  if [[ -n "${2}" ]]; then
   INPUT_DIRS="${2}"
   shift
  fi
  ;;
  --input_dirs=?*)
  INPUT_DIRS="${1#*=}" # Delete everything up to "=" and assign the remainder.
  ;;
  --intput_dirs=) # Handle the empty case
  printf "ERROR: --input_dirs requires a non-empty option argument.\n"  >&2
  exit 1
  ;;
#############
  -o|--output)
  if [[ -n "${2}" ]]; then
   OUTPUT="${2}"
   shift
  fi
  ;;
  --output=?*)
  OUTPUT="${1#*=}" # Delete everything up to "=" and assign the remainder.
  ;;
  --output=) # Handle the empty case
  printf "ERROR: --output requires a non-empty option argument.\n"  >&2
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


#############################################################################
# 2. concat cluster
#############################################################################

IFS=","
for D in $( echo "${INPUT_DIRS}" ); do 
  
  CLUSTER2ABUND="${D}"/"${DOMAIN}_cluster2abund.tsv"
  SAMPLE_NAME=$( basename $( dirname "${CLUSTER2ABUND}") | sed 's/\./_/g')
  
  if [[ ! -f "${CLUSTER2ABUND}" ]]; then
    echo 2> "no ${DOMAIN}_cluster2abund.tsv found in ${D}"
    exit 1
  fi  
  
  awk -v FC="${SAMPLE_NAME}" 'BEGIN {OFS="\t" }{
    sub(/^/,FC"_bf_",$2)
    print $2,$3;
  }' "${CLUSTER2ABUND}"
  
done  > "${OUTPUT}"
