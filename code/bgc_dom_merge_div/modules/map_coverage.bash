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
  -cl|--cluster_tsv)
  if [[ -n "${2}" ]]; then
   CLUSTER_TSV="${2}"
   shift
  fi
  ;;
  --cluster_tsv=?*)
  CLUSTER_TSV="${1#*=}" # Delete everything up to "=" and assign the remainder.
  ;;
  --cluster_tsv=) # Handle the empty case
  printf "ERROR: --cluster_tsv requires a non-empty option argument.\n"  >&2
  exit 1
  ;;
#############
  -co|--coverage_tsv)
  if [[ -n "${2}" ]]; then
   COVERAGE_TSV="${2}"
   shift
  fi
  ;;
  --coverage_tsv=?*)
  COVERAGE_TSV="${1#*=}" # Delete everything up to "=" and assign the remainder.
  ;;
  --coverage_tsv=) # Handle the empty case
  printf "ERROR: --coverage_tsv requires a non-empty option argument.\n"  >&2
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
# 3. set parameters
#############################################################################

awk 'BEGIN {OFS="\t"} { 
  if (NR == FNR ) {
    id_aa=$1
    sub(/_repseq$/,"",id_aa)
    array_id2abund[id_aa] = $2;
    next;
  }
	  
  if (cluster_id != $1) {
    cluster_id = $1;
    cluster = "cluster_"n++;
    id_aa = $2
    repseq = 1
  } else {
    id_aa = $2
    repseq = 0 
  }
  
  array_id2cluster[id_aa] = cluster
  
  if ( array_id2abund[id_aa] == "" ) {
    array_id2abund[id_aa] = 0
  }
  
  id_aa2 = id_aa
  id_aa2 = gensub(/(^.*)_bf_/,"\\1\t","g",id_aa2)
    
  if ( repseq == 1 ) {
    printf "%s\t%s\t%s\n", \
    array_id2cluster[id_aa],id_aa2"_repseq",array_id2abund[id_aa];
  }
    
  if ( repseq == 0 ) {
    printf "%s\t%s\t%s\n", \
    array_id2cluster[id_aa],id_aa2,array_id2abund[id_aa];
  }
}' "${COVERAGE_TSV}" "${CLUSTER_TSV}" > "${OUTPUT}"

   
   
