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
  DOMAIN="${1#*=}"
  ;;
  --domain=)
  printf "ERROR: --domain requires a non-empty argument\n"  >&2
  exit 1
  ;;
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
  --input)
  if [[ -n "${2}" ]]; then
   INPUT="${2}"
   shift
  fi
  ;;
  --input=?*)
  INPUT="${1#*=}"
  ;;
  --input=)
  printf "ERROR: --input requires a non-empty argument\n"  >&2
  exit 1
  ;;
############
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
# 3. Load and create environment
###############################################################################

source "${ENV}"

if [[ "$?" -ne "0" ]]; then 
  echo "${DOMAIN}: Sourcing ${ENV} failed"  
  exit 1
fi
  
REF_ALIGN="${REF_PKG_DIR}/${DOMAIN}.refpkg/${DOMAIN}_core.align"
REF_PKG="${REF_PKG_DIR}/${DOMAIN}.refpkg"
OUT_DIR="${THIS_JOB_TMP_DIR}/${DOMAIN}_tree_data"

mkdir "${OUT_DIR}"

if [[ "$?" -ne "0" ]]; then  
  echo "${DOMAIN}: Creating ${OUT_DIR} failed"
  exit 1
fi  

###############################################################################
# 4. Clean fasta file
###############################################################################

tr "[ -%,;\(\):=\.\\\*[]\"\']" "_" < "${INPUT}" > "${OUT_DIR}/query_clean.fasta"

if [[ "$?" -ne "0" ]]; then
  echo "${DOMAIN}: Generating ${OUT_DIR}/query_clean.fasta failed"
  exit 1
fi  

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
  echo "${DOMAIN}: Generating ${OUT_DIR}/${DOMAIN}_tmp.csv failed"
  exit 1
fi

###############################################################################
# 11. Clean
###############################################################################

mv "${OUT_DIR}/${DOMAIN}_tmp.csv" "${OUT_DIR}/${DOMAIN}_query_info.csv"

if [[ "$?" -ne "0" ]]; then
  echo "${DOMAIN}: Naming ${OUT_DIR}/${DOMAIN}_query_info.csv failed"
  exit 1
fi

rm "${OUT_DIR}/${DOMAIN}_query_edpl.csv" \
   "${OUT_DIR}/query_clean.fasta"
   
if [[ "$?" -ne "0" ]]; then
  echo "${DOMAIN}: Removing ${OUT_DIR}/${DOMAIN}_query_edpl.csv ${OUT_DIR}/query_clean.fasta failed"
  exit 1
fi   
