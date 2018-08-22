#!/bin/bash

set -o pipefail

#############################################################################
# 1. Load general configuration
#############################################################################

source /bioinfo/software/conf
#source /home/memo/Google_Drive/Doctorado/workspace/ufBGCtoolbox/bgc_dom_div/tmp_vars.bash
#############################################################################
# 2. set parameters
#############################################################################

while :; do
  case "${1}" in
#############  
    -c|--clust2abund_tsv) # Takes an option argument, ensuring it has been
                # specified.
    if [[ -n "${2}" ]]; then
      CLUST2ABUND_TSV="${2}"
      shift
    else
      printf 'ERROR: "--clust2abund_tsv" requires a non-empty option argument.\n' >&2
      exit 1
    fi
    ;;
    --clust2abund_tsv=?*)
    CLUST2ABUND_TSV=${1#*=} # Delete everything up to "=" and assign the remainder.
    ;;
    --clust2abund_tsv=)     # Handle the case of an empty --file=
    printf 'ERROR: "--clust2abund_tsv" requires a non-empty option argument.\n' >&2
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
    --prefix=)     # Handle the case of an empty --file=
    printf 'ERROR: "--prefix" requires a non-empty option argument.\n' >&2
    exit 1
    ;;
#############
    -tp|--tmp_prefix) # Takes an option argument, ensuring it has been
                # specified.
    if [[ -n "${2}" ]]; then
      TMP_NAME="${2}"
      shift
    else
      printf 'ERROR: "--tmp_prefix" requires a non-empty option \
argument.\n' >&2
      exit 1
    fi
    ;;
    --tmp_prefix=?*)
    TMP_NAME=${1#*=} # Delete everything up to "=" and assign the
# remainder.
    ;;
    --tmp_prefix=)     # Handle the case of an empty --file=
    printf 'ERROR: "--tmp_prefix" requires a non-empty option argument.\n' >&2
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
# 3. collapse table
#############################################################################

awk 'BEGIN {OFS="\t"}; {

  cluster = $1;
  id = $2;
  
  array_cluster2abund[cluster] = array_cluster2abund[cluster] + $3;
  
  if ( array_cluster2id[cluster] == ""  ) {
    array_cluster2id[cluster] = id;
  }
  
} END {
  for (c in array_cluster2abund) {
    print  c,array_cluster2id[c],array_cluster2abund[c]
  }
}' "${CLUST2ABUND_TSV}" > "${TMP_NAME}_onlyrep_cluster2abund.tsv"

#############################################################################
# 4. extract headers
#############################################################################

cut -f2 "${TMP_NAME}_onlyrep_cluster2abund.tsv" | sed "s/_repseq$//" > \
"${TMP_NAME}.onlyrep_headers"

#############################################################################
# 5. extract seqs
#############################################################################

"${filterbyname}" \
in="${NAME}_subseqs.faa" \
out="${TMP_NAME}_onlyrep_subseqs.faa" \
names="${TMP_NAME}.onlyrep_headers" \
include=t \
overwrite=t

