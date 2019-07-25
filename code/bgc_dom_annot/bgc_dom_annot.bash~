#!/bin/bash -l

# set -x
set -o pipefail

###############################################################################
# 1. Load general configuration
###############################################################################

source /bioinfo/software/conf

###############################################################################
# 2. Define help
###############################################################################

show_usage(){
  cat <<EOF
  Usage: run_bgc_dom_annot.bash <R1> <R2> <SR> <output directory> <options>
  
  [-h|--help] [-i|--intpye CHAR] [-s|--sample CHAR] [-t|--nslots INT]
  [-s|--verbose t|f] [-w|--overwrite t|f]

-h, --help	print this help
-i, --intype	type of input data (i.e. prot or dna)
-s, --sample	sample name (default "metagenomeX")
-t, --nslots	number of slots (default 2). UProC parameter
-v, --verbose	t or f, run verbosely (default f)
-w, --overwrite t or f, overwrite current directory (default f)
EOF
}

###############################################################################
# 3. Parse parameters 
###############################################################################

while :; do
  case "${1}" in
#############
  -h|-\?|--help) # Call a "show_usage" function to display a synopsis, then
                   # exit.
  show_usage
  exit 1;
  ;;
#############
  -i|--intype)
  if [[ -n "${2}" ]]; then
   INTYPE="${2}"
   shift
  fi
  ;;
  --intype=?*)
  INTYPE="${1#*=}" # Delete everything up to "=" and assign the remainder.
  ;;
  --intype=) # Handle the empty case
  printf "ERROR: --intype requires a non-empty option argument.\n"  >&2
  exit 1
  ;;
#############
  -o|--outdir)
   if [[ -n "${2}" ]]; then
     OUTDIR_EXPORT="${2}"
     shift
   fi
  ;;
  --outdir=?*)
  OUTDIR_EXPORT="${1#*=}" # Delete everything up to "=" and assign the
                          # remainder.
  ;;
  --outdir=) # Handle the empty case
  printf 'Using default environment.\n' >&2
  ;;
#############
 -R| --reads)
   if [[ -n "${2}" ]]; then
     R="${2}"
     shift
   fi
  ;;
  --reads=?*)
  R="${1#*=}" # Delete everything up to "=" and assign the remainder.
  ;;
  --reads=) # Handle the empty case
  printf "ERROR: --reads requires a non-empty option argument.\n"  >&2
  exit 1
  ;;
#############
 -R2|--reads2)
   if [[ -n "${2}" ]]; then
     R2="${2}"
     shift
   fi
  ;;
  --reads2=?*)
  R2="${1#*=}" # Delete everything up to "=" and assign the remainder.
  ;;
  --read2=) # Handle the empty case
  printf "ERROR: --reads2 requires a non-empty option argument.\n"  >&2
  exit 1
  ;;
#############
 -SR|--single_reads)
   if [[ -n "${2}" ]]; then
     SR="${2}"
     shift
   fi
  ;;
  --single_reads=?*)
  SR="${1#*=}" # Delete everything up to "=" and assign the remainder.
  ;;
  --single_reads=) # Handle the empty case
  printf "ERROR: --single_reads requires a non-empty option argument.\n"  >&2
  exit 1
  ;;
#############
  -s|--sample)
   if [[ -n "${2}" ]]; then
     SAMPLE="${2}"
     shift
   fi
  ;;
  --sample=?*)
  SAMPLE="${1#*=}" # Delete everything up to "=" and assign the remainder.
  ;;
  --sample=) # Handle the empty case
  printf 'Using default environment.\n' >&2
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
 #############
  -v|--verbose)
   if [[ -n "${2}" ]]; then
     VERBOSE="${2}"
     shift
   fi
  ;;
  --verbose=?*)
  VERBOSE="${1#*=}" # Delete everything up to "=" and assign the remainder.
  ;;
  --verbose=) # Handle the empty case
  printf 'Using default environment.\n' >&2
  ;;  
#############
  -w|--overwrite)
   if [[ -n "${2}" ]]; then
     OVERWRITE="${2}"
     shift
   fi
  ;;
  --overwrite=?*)
  OVERWRITE="${1#*=}" # Delete everything up to "=" and assign the
# remainder.
  ;;
  --overwrite=) # Handle the empty case
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

###############################################################################
# 4. Check mandatory parameters
###############################################################################

if [[ -z "${INTYPE}" ]]; then
  echo "intype not defined. Use --intype dna or --intype prot"
  exit 1
fi

###############################################################################
# 5. Load handleoutput
###############################################################################

source /bioinfo/software/handleoutput 

###############################################################################
# 6. Check output directories
###############################################################################

if [[ -d "${OUTDIR_LOCAL}/${OUTDIR_EXPORT}" ]]; then
  if [[ "${OVERWRITE}" != "t" ]]; then
    echo "${OUTDIR_EXPORT} already exist. Use \"--overwrite t\" to overwrite."
    exit
  fi
fi  

###############################################################################
# 7. Create output directories
###############################################################################

THIS_JOB_TMP_DIR="${SCRATCH}/${OUTDIR_EXPORT}"

if [[ ! -d "${THIS_JOB_TMP_DIR}" ]]; then
  mkdir -p  "${THIS_JOB_TMP_DIR}"
fi

###############################################################################
# 8. Identify BGC reads
###############################################################################

UPROC_PE_OUT="${THIS_JOB_TMP_DIR}/pe_bgc_dom.gz"
UPROC_SE_OUT="${THIS_JOB_TMP_DIR}/se_bgc_dom.gz"

if [[ "${R2}" != "NULL" ]] && [[ -n "${R2}" ]]; then

   if [[ "${INTYPE}" == "dna" ]]; then
   
     echo "running R1 and R2 domain annotation with uproc-dna ..." 2>&1 | \
     handleoutput

    "${uproc_dna}" \
    --pthresh 3 \
    --short \
    --zoutput "${UPROC_PE_OUT}" \
    --preds \
    --threads "${NSLOTS}" \
    "${DBDIR}" "${MODELDIR}" "${R}" "${R2}"
    
     if [[ "$?" -ne "0" ]]; then
       echo "uproc pair end (dna) annotation failed" 
       exit 1
     fi
   
   fi

   if [[ "${INTYPE}" == "prot" ]]; then

     echo "running R1 and R2 domain annotation with uproc-prot ..." 2>&1 | \
     handleoutput
   
     "${uproc_prot}" \
      --pthresh 3 \
      --zoutput "${UPROC_PE_OUT}" \
      --preds \
      --threads "${NSLOTS}" \
       "${DBDIR}" "${MODELDIR}" "${R}" "${R2}" 
       
     if [[ "$?" -ne "0" ]]; then
       echo "uproc pair end (prot) annotation failed" 
       exit 1
     fi

   fi

fi

if [[ -f "${SR}" ]]; then

  if [[ "${INTYPE}" == "dna" ]]; then

     echo "running SR domain annotation with uproc-dna ..." 2>&1 | \
     handleoutput
  
    "${uproc_dna}" \
    --pthresh 3 \
    --short \
    --zoutput "${UPROC_SE_OUT}" \
    --preds \
    --threads "${NSLOTS}" \
    "${DBDIR}" "${MODELDIR}" "${SR}"
    
    if [[ "$?" -ne "0" ]]; then
      echo "uproc single end (dna) annotation failed" 
      exit 1
    fi

  fi

  if [[ "${INTYPE}" == "prot" ]]; then
  
     echo "running SR domain annotation with uproc-prot ..."  2>&1 | \
     handleoutput

    "${uproc_prot}" \
    --pthresh 3 \
    --zoutput "${UPROC_SE_OUT}" \
    --preds \
    --threads "${NSLOTS}" \
    "${DBDIR}" "${MODELDIR}" "${SR}"
    
    if [[ "$?" -ne "0" ]]; then
      echo "uproc single end (prot) annotation failed" 
      exit 1
    fi
    
  fi

fi

if [[ -f "${UPROC_PE_OUT}" ]] && [[ -f "${UPROC_SE_OUT}" ]]; then

  cat "${UPROC_PE_OUT}" "${UPROC_SE_OUT}" > "${THIS_JOB_TMP_DIR}/bgc_dom.gz"
  rm "${THIS_JOB_TMP_DIR}/"*_bgc_dom.gz
  
fi

###############################################################################
# 9. Make abundance table
###############################################################################

echo "parsing domain annotation ..." 2>&1 | handleoutput

ALL_BGC=$(find  "${THIS_JOB_TMP_DIR}"/  -name "*bgc_dom.gz")

if [[ "${INTYPE}" == "dna" ]]; then

  zcat "${ALL_BGC}" | cut -f7 -d"," | sort | uniq -c | \
  awk -v  s="${SAMPLE}" 'BEGIN { OFS="\t" } 
  { gsub("-",".",$2); print s,$2,$1 }' > "${THIS_JOB_TMP_DIR}"/counts.tbl

  if [[ "$?" -ne "0" ]]; then
    echo "make counts.tbl dna failed"
    exit 1
  fi

fi

if [[ "${INTYPE}" == "prot" ]]; then

  zcat "${ALL_BGC}" | cut -f4 -d"," | sort | uniq -c | \
  awk -v  s="${SAMPLE}" 'BEGIN { OFS="\t" } 
  { gsub("-",".",$2); print s,$2,$1; }' > "${THIS_JOB_TMP_DIR}"/counts.tbl

  if [[ "$?" -ne "0" ]]; then
    echo "make counts.tbl prot failed"
    exit 1
  fi
  
fi

awk -v s="${SAMPLE}" 'BEGIN { OFS="\t" } {
    if (NR==FNR) {
      line[$2]=$3;
      next;
    }
    if ($2 in line) {
      print s,$1,$2,line[$2];
    }
  }' "${THIS_JOB_TMP_DIR}/counts.tbl" "${CLASS2DOMAINS}" > \
     "${THIS_JOB_TMP_DIR}/class2domains2abund.tbl"

if [[ "$?" -ne "0" ]]; then
  echo "make abundance table awk script failed"
  exit 1
fi

###############################################################################
# 10. Move output for export
###############################################################################

rsync -a --delete "${THIS_JOB_TMP_DIR}" "${OUTDIR_LOCAL}"

