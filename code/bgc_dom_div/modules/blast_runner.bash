#!/bin/bash

set -o pipefail

#############################################################################
# 1 - Load general configuration
#############################################################################

source /bioinfo/software/conf
#source /home/memo/Google_Drive/Doctorado/workspace/ufBGCtoolbox/bgc_dom_div/tmp_vars.bash

#############################################################################
# 2 - set parameters
#############################################################################

while :; do
  case "${1}" in
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
  -i|--input)
  if [[ -n "${2}" ]]; then
   INPUT="${2}"
   shift
  fi
  ;;
  --input=?*)
  INPUT="${1#*=}" # Delete everything up to "=" and assign the remainder.
  ;;
  --input=) # Handle the empty case
  printf "ERROR: --input requires a non-empty option argument.\n"  >&2
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
  -t|--nslots)
   if [[ -n "${2}" ]]; then
     NSLOTS="${2}"
     shift
   fi
  ;;
  --nslots=?*)
  NSLOTS="${1#*=}" # Delete everything up to "=" and assign the remainder.
  ;;
  --nslots=) # Handle the empty case
  printf 'Using default environment.\n' >&2
  ;;
############
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


REF_SEQ_DB="${REF_SEQ_DIR}/${DOMAIN}.faa"

#################################
### run blastp
#################################

"${blastp}" \
  -query  "${INPUT}" \
  -outfmt 6 \
  -evalue 1e-03 \
  -num_alignments 10 \
  -db "${REF_SEQ_DB}" \
  -num_threads "${NSLOTS}" \
  -out "${OUTPUT}"
