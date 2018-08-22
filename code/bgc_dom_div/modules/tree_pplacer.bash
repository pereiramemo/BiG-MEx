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
  -o|--outdir)
  if [[ -n "${2}" ]]; then
   OUT_DIR="${2}"
   shift
  fi
  ;;
  --outdir=?*)
  OUT_DIR="${1#*=}" # Delete everything up to "=" and assign the remainder.
  ;;
  --outdir=) # Handle the empty case
  printf "ERROR: --outdir requires a non-empty option argument.\n"  >&2
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

REF_ALIGN="${REF_PKG_DIR}/${DOMAIN}.refpkg/${DOMAIN}_rep.align"
REF_PKG="${REF_PKG_DIR}/${DOMAIN}.refpkg"

OUT_DIR="${OUT_DIR}/${DOMAIN}_tree_data"

mkdir "${OUT_DIR}"

#################################
### clean fasta file
#################################

tr "[ -%,;\(\):=\.\\\*[]\"\']" "_" < "${INPUT}" > "${OUT_DIR}/query_clean.fasta"

#################################
### add sequences to profile
#################################
unset MAFFT_BINARIES

"${mafft}" \
--add "${OUT_DIR}/query_clean.fasta" \
--reorder \
"${REF_ALIGN}" > "${OUT_DIR}/ref_added_query.align.fasta"

#################################
### place sequences on tree
#################################

"${pplacer}" \
  -o "${OUT_DIR}/${DOMAIN}_query.jplace" \
  -p \
  --keep-at-most 10 \
  --discard-nonoverlapped \
  -c "${REF_PKG}" \
  "${OUT_DIR}/ref_added_query.align.fasta"

#################################
### visualize tree
#################################

"${guppy}" fat \
  --node-numbers \
  --point-mass \
  --pp \
  -o "${OUT_DIR}/${DOMAIN}_query.phyloxml" \
  "${OUT_DIR}/${DOMAIN}_query.jplace"

"${guppy}" tog \
  --node-numbers \
  --pp \
  --out-dir "${OUT_DIR}" \
  -o "${DOMAIN}_query.newick" \
  "${OUT_DIR}/${DOMAIN}_query.jplace"

#################################
### compute stats
#################################  

"${guppy}" to_csv \
  --point-mass \
  --pp \
  -o "${OUT_DIR}/${DOMAIN}_query_info.csv" \
  "${OUT_DIR}/${DOMAIN}_query.jplace"

#################################
### compute edpl
################################
  
  "${guppy}" edpl \
  --csv \
  --pp \
  -o "${OUT_DIR}/${DOMAIN}_query_edpl.csv" \
  "${OUT_DIR}/${DOMAIN}_query.jplace"
  
  
#################################
### left join tables: info and edpl
#################################

awk 'BEGIN {FS=","; OFS="," } { 
  if (NR==FNR) {

    array_edpl[$1]=$2;
    next;
  }

  if ( FNR == 1) {
  
    print $0,"edpl"
  
  } else {
  
    if (array_edpl[$2] != "" ) {
    
      print $0,array_edpl[$2];
      
    }
  }
}' "${OUT_DIR}/${DOMAIN}_query_edpl.csv" "${OUT_DIR}/${DOMAIN}_query_info.csv" \
> "${OUT_DIR}/${DOMAIN}_tmp.csv"

### clean
mv "${OUT_DIR}/${DOMAIN}_tmp.csv" "${OUT_DIR}/${DOMAIN}_query_info.csv"
rm "${OUT_DIR}/${DOMAIN}_query_edpl.csv" 
rm "${OUT_DIR}/query_clean.fasta"

  
