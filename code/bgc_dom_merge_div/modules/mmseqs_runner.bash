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
   -id|--identity) # Takes an option argument, ensuring it has been
                   # specified.
    if [[ -n "${2}" ]]; then
      ID="${2}"
      shift
    else
      printf 'ERROR: "--identity" requires a non-empty option \
argument.\n' >&2
      exit 1
    fi
    ;;
    --identity=?*)
    ID=${1#*=} # Delete everything up to "=" and assign the
               # remainder.
    ;;
    --identity=)     # Handle the case of an empty --file=
    printf 'ERROR: "--identity" requires a non-empty option argument.\n' >&2
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
    --tmp_prefix=)   # Handle the case of an empty --file=
    printf 'ERROR: "--tmp_prefix" requires a non-empty option argument.\n' >&2
    exit 1
    ;; 
#############
   -tf|--tmp_folder) # Takes an option argument, ensuring it has been
                     # specified.
    if [[ -n "${2}" ]]; then
      TMP_FOLDER="${2}"
      shift
    else
      printf 'ERROR: "--tmp_folder" requires a non-empty option \
argument.\n' >&2
      exit 1
    fi
    ;;
    --tmp_prefix=?*)
    TMP_FOLDER=${1#*=} # Delete everything up to "=" and assign the
                       # remainder.
    ;;
    --tmp_folder=)     # Handle the case of an empty --file=
    printf 'ERROR: "--tmp_folder" requires a non-empty option argument.\n' >&2
    exit 1
    ;; 
#############
   -t|--threads) # Takes an option argument, ensuring it has been
                 # specified.
    if [[ -n "${2}" ]]; then
      NSLOTS="${2}"
      shift
    else
      printf 'ERROR: "--threads" requires a non-empty option \
argument.\n' >&2
      exit 1
    fi
    ;;
    --threads=?*)
    NSLOTS=${1#*=} # Delete everything up to "=" and assign the
                   # remainder.
    ;;
    --threads=)    # Handle the case of an empty --file=
    printf 'ERROR: "--threads" requires a non-empty option argument.\n' >&2
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

###############################################################################
# 3. Cluster seqs
###############################################################################

if [[ -d "${TMP_FOLDER}" ]]; then
  rm -r "${TMP_FOLDER}"
fi  
    
"${mmseqs}" createdb "${TMP_NAME}_all.faa" "${TMP_NAME}_db" 
 
mkdir "${TMP_FOLDER}"

"${mmseqs}" cluster "${TMP_NAME}_db" "${TMP_NAME}_all_clu" \
   "${TMP_FOLDER}" \
  --min-seq-id "${ID}" \
  --remove-tmp-files \
  --cascaded \
  -c 0.4 \
  -s 7.5 \
  --threads "${NSLOTS}"

"${mmseqs}" createtsv "${TMP_NAME}_db" "${TMP_NAME}_db" \
"${TMP_NAME}_all_clu" "${TMP_NAME}_all_clu".tsv 
