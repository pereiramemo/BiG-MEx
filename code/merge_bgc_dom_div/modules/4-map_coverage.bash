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
# 4. Map coverage
###############################################################################

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
}' "${TMP_NAME}_all-coverage.table" "${TMP_NAME}_all_clu.tsv" > \
   "${NAME}_cluster2abund.tsv"

if [[ "$?" -ne "0" ]]; then
  echo "Generating ${NAME}_cluster2abund.tsv failed"
  exit 1
fi   
