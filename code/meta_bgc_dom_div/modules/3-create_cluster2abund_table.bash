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
  ENV=${1#*=} 
  ;;
  --env=) 
  printf 'ERROR: --env requires a non-empty argument\n' >&2
  exit 1
  ;;  
#############  
  --tmp_prefix)
  if [[ -n "${2}" ]]; then
    TMP_NAME="${2}"
    shift
  fi
  ;;
  --tmp_prefix=?*)
  TMP_NAME=${1#*=}
  ;;
  --tmp_prefix=)
  printf 'ERROR: --tmp_prefix requires a non-empty argument\n' >&2
  exit 1
  ;;
#############
  --prefix)
  if [[ -n "${2}" ]]; then
    NAME="${2}"
    shift
  fi
  ;;
  --prefix=?*)
  NAME=${1#*=}
  ;;
  --prefix=)
  printf 'ERROR: --prefix requires a non-empty argument\n' >&2
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

if [[ $? -ne "0" ]]; then
  echo "${DOMAIN}: Sourcing ${ENV} failed"
  exit 1
fi 

###############################################################################
# 4. Create cluster to abundance table
###############################################################################

awk '{

  id_repseq = $1
  id_aa = $2
   
  # cluster count for each repseq
  if (array_cluster_count[id_repseq] == "") {
    array_cluster_count[id_repseq] = n++ 
  }
  
  array_id2cluster[id_aa] = array_cluster_count[id_repseq]
  array_id_aa2repseq[id_aa] = id_repseq
  
} END { 

  for (i in array_id2cluster) {
  
    cluster = "cluster_"array_id2cluster[i]
    abund = 1
    
    # classify as repseq or not
    if (array_id_aa2repseq[i] == i) {
      printf "%s\t%s\t%s\n", cluster, i"_repseq", abund 
    } else {
      printf "%s\t%s\t%s\n", cluster, i, abund 
    }
  }

}' "${TMP_NAME}_clu.tsv" > "${NAME}_cluster2abund.tsv"

if [[ "$?" -ne "0" ]]; then
  echo "${DOMAIN}: Generating ${NAME}_cluster2abund.tsv failed"
  exit 1
fi 
