#!/bin/bash

set -o pipefail

###############################################################################
# 1. Load general configuration
###############################################################################

source /bioinfo/software/conf

###############################################################################
# 2. Parse parameters
###############################################################################

while :; do
  case "${1}" in
#############
  --domain)
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
  --input)
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

###############################################################################
# 3. Load environment
###############################################################################

source "${ENV}"

REF_ALIGN="${REF_PKG_DIR}/${DOMAIN}.refpkg/${DOMAIN}_core.align"
REF_PKG="${REF_PKG_DIR}/${DOMAIN}.refpkg"
OUT_DIR="${THIS_JOB_TMP_DIR}/${DOMAIN}_tree_data"

mkdir "${OUT_DIR}"

###############################################################################
# 4. Clean fasta file
###############################################################################

tr "[ -%,;\(\):=\.\\\*[]\"\']" "_" < "${INPUT}" > "${OUT_DIR}/query_clean.fasta"

###############################################################################
# 5. Add sequences to profile
###############################################################################

unset MAFFT_BINARIES

"${mafft}" \
--add "${OUT_DIR}/query_clean.fasta" \
--reorder \
"${REF_ALIGN}" > "${OUT_DIR}/ref_added_query.align.fasta"

if [[ "$?" -ne "0" ]]; then
  echo "${DOMAIN}: mafft alignment failed"
  exit 1
fi

###############################################################################
# 6. Place sequences onto tree
###############################################################################

"${pplacer}" \
-o "${OUT_DIR}/${DOMAIN}_query.jplace" \
-p \
--keep-at-most 10 \
--discard-nonoverlapped \
-c "${REF_PKG}" \
   "${OUT_DIR}/ref_added_query.align.fasta"
   
if [[ "$?" -ne "0" ]]; then
  echo "${DOMAIN}: pplacer failed"
  exit 1
fi

###############################################################################
# 7. Visualize tree
###############################################################################

"${guppy}" fat \
--node-numbers \
--point-mass \
--pp \
-o "${OUT_DIR}/${DOMAIN}_query.phyloxml" \
"${OUT_DIR}/${DOMAIN}_query.jplace"
   
if [[ "$?" -ne "0" ]]; then
  echo "${DOMAIN}: guppy fat failed"
  exit 1
fi

"${guppy}" tog \
--node-numbers \
--pp \
--out-dir "${OUT_DIR}" \
-o "${DOMAIN}_query.newick" \
"${OUT_DIR}/${DOMAIN}_query.jplace"

if [[ "$?" -ne "0" ]]; then
  echo "${DOMAIN}: guppy tog failed"
  exit 1
fi

###############################################################################
# 8. Compute stats
###############################################################################  

"${guppy}" to_csv \
--point-mass \
--pp \
-o "${OUT_DIR}/${DOMAIN}_query_info.csv" \
"${OUT_DIR}/${DOMAIN}_query.jplace"

if [[ "$?" -ne "0" ]]; then
  echo "${DOMAIN}: guppy to_csv failed"
  exit 1
fi

###############################################################################
# 9. Compute edpl
###############################################################################
  
"${guppy}" edpl \
--csv \
--pp \
-o "${OUT_DIR}/${DOMAIN}_query_edpl.csv" \
"${OUT_DIR}/${DOMAIN}_query.jplace"
  
if [[ "$?" -ne "0" ]]; then
  echo "${DOMAIN}: guppy edpl failed"
  exit 1
fi  
  
###############################################################################
# 10. Left join tables: info and edpl
###############################################################################

awk 'BEGIN {FS=","; OFS="," } { 
  if (NR==FNR) {
    array_edpl[$1]=$2;
    next;
  }

  if (FNR == 1) {
  
    print $0,"edpl"
  
  } else {
  
    if (array_edpl[$2] != "" ) {
    
      print $0,array_edpl[$2];
      
    }
  }
}' "${OUT_DIR}/${DOMAIN}_query_edpl.csv" "${OUT_DIR}/${DOMAIN}_query_info.csv" \
> "${OUT_DIR}/${DOMAIN}_tmp.csv"

if [[ "$?" -ne "0" ]]; then
  echo "${DOMAIN}: awk command crossing tables failed"
  exit 1
fi

###############################################################################
# 11. Clean
###############################################################################

mv "${OUT_DIR}/${DOMAIN}_tmp.csv" "${OUT_DIR}/${DOMAIN}_query_info.csv"
rm "${OUT_DIR}/${DOMAIN}_query_edpl.csv" 
rm "${OUT_DIR}/query_clean.fasta"
