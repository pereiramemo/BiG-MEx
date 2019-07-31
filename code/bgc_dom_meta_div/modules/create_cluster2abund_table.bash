#!/bin/bash

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
  --env=)     # Handle the case of an empty --file=
  printf 'ERROR: "ENV" requires a non-empty option argument.\n' >&2
  exit 1
  ;;  
#############  
  --tmp_prefix) # Takes an option argument, ensuring it has been specified.
  if [[ -n "${2}" ]]; then
    TMP_NAME="${2}"
    shift
  else
    printf 'ERROR: "--tmp_prefix" requires a non-empty option argument.\n' >&2
    exit 1
  fi
  ;;
  --tmp_prefix=?*)
  TMP_NAME=${1#*=} # Delete everything up to "=" and assign the remainder.
  ;;
  --tmp_prefix=)     # Handle the case of an empty --file=
  printf 'ERROR: "--tmp_prefix" requires a non-empty option argument.\n' >&2
  exit 1
  ;;
#############
  --prefix) # Takes an option argument, ensuring it has been specified.
  if [[ -n "${2}" ]]; then
    NAME="${2}"
    shift
  else
    printf 'ERROR: "--prefix" requires a non-empty option argument.\n' >&2
    exit 1
  fi
  ;;
  --prefix=?*)
  NAME=${1#*=} # Delete everything up to "=" and assign the remainder.
  ;;
  --prefix=)   # Handle the case of an empty --file=
  printf 'ERROR: "--prefix" requires a non-empty option argument.\n' >&2
  exit 1
  ;;        
#############
  --)          # End of all options.
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
# 4. Create cluster to abundance table
###############################################################################

awk '{

  id_repseq = $1
  id_aa = $2
   
  # cluster count for each repseq
  if (!array_cluster_count[id_repseq]) {
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

if [[ $? -ne "0" ]]; then
  echo "${NAME}_cluster2abund.tsv: awk command tables failed"
  exit 1
fi 
