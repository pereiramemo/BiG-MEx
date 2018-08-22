#!/bin/bash -l

# set -x
set -o pipefail

#############################################################################
# 1. load general configuration
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
# 3. Concat fasta
#############################################################################

IFS=","
for D in $( echo "${INPUT_DIRS}" ); do 
    
  SUBSEQS="${D}"/"${DOMAIN}_subseqs.faa"
  SAMPLE_NAME=$( basename $( dirname "${SUBSEQS}") | sed 's/\./_/g')
  
  if [[ ! -f "${SUBSEQS}" ]]; then
    echo 2> "${DOMAIN}_subseqs.faa not found in ${D}"
    exit 1
  fi  
  
  awk -v FC="${SAMPLE_NAME}" '{
    if ( $0 ~ /^>/ ) {
      sub(/^>/,">"FC"_bf_",$0)
    } 
    print $0;
  }' "${SUBSEQS}"	
 
done > "${OUTPUT}"

