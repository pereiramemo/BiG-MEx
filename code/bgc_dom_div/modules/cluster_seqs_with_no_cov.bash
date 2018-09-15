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
    -c|--clust_tsv) # Takes an option argument, ensuring it has been
                    # specified.
    if [[ -n "${2}" ]]; then
      CLUST_TSV="${2}"
      shift
    else
      printf 'ERROR: "--clust_tsv" requires a non-empty option argument.\n' >&2
      exit 1
    fi
    ;;
    --clust_tsv=?*)
    CLUST_TSV=${1#*=} # Delete everything up to "=" and assign the remainder.
    ;;
    --clust_tsv=)     # Handle the case of an empty --file=
    printf 'ERROR: "--clust_tsv" requires a non-empty option argument.\n' >&2
    exit 1
    ;;
#############
    -p|--prefix) # Takes an option argument, ensuring it has been
                 # specified.
    if [[ -n "${2}" ]]; then
      NAME="${2}"
      shift
    else
      printf 'ERROR: "--prefix" requires a non-empty option \
argument.\n' >&2
      exit 1
    fi
    ;;
    --prefix=?*)
    NAME=${1#*=} # Delete everything up to "=" and assign the
                 # remainder.
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
# 3. Create cluster to abundance table
###############################################################################

awk 'BEGIN {OFS="\t"} {

  if (cluster_id != $1) {
    cluster_id = $1;
    cluster = "cluster_"n++;
    id_aa = $2
    repseq = 1
  } else {
    id_aa = $2
    repseq = 0 
  }
  
  if (repseq == 1 ) {
    print cluster,id_aa"_repseq",1
  }
  if (repseq == 0 ) {
    print cluster,id_aa,1
  }
}' "${CLUST_TSV}" > "${NAME}_cluster2abund".tsv
      