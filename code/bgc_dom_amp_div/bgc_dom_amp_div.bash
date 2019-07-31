#!/bin/bash -l

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
  Usage: run_bgc_dom_div.bash amp <R> <output directory> <options>
  
--help                  print this help
--blast t|f             run blast against reference database (default f) 
--domain CHAR           target domain name
--font_size NUM         violin plot font size (default 3). R parameter
--font_tree_size NUM    tree plot font size (default 1). R parameter
--identity NUM          clustering minimum identity (default 0.7). mmseqs cluster parameter
--num_iter NUM          number of iterations to estimate diversity distribution (default 100)
--only_rep t|f          place only representative cluster domain sequences onto reference tree (default t)
--plot_tree t|f         place sequences onto reference tree and generate plot
--plot_height NUM       violin plot height (default 3). R parameter
--plot_width NUM        violin plot width (default 3). R parameter
--plot_tree_height NUM  tree plot height (default 12). R parameter
--plot_tree_width NUM   tree plot width (default 14). R parameter
--nslots NUM            number of slots (default 2). FragGeneScan, and mmseqs cluster
--verbose t|f           run verbosely (default f)
--overwrite t|f         overwrite current directory (default f)

<R> is the amplicon sequence file (fasta or fastq)
<output directory> is the directory name to be used

EOF
}

###############################################################################
# 3. Parse parameters
###############################################################################

while :; do
  case "${1}" in
#############
  --help) # Call a "show_usage" function to display a synopsis, then
                 # exit.
  show_usage
  exit 1;
  ;;
#############
  --blast)
  if [[ -n "${2}" ]]; then
    BLAST="${2}"
    shift
  fi
  ;;
  --blast=?*)
  BLAST="${1#*=}" # Delete everything up to "=" and assign the remainder.
  ;;
  --blast=) # Handle the empty case
  printf "ERROR: --blast requires a non-empty option argument.\n"  >&2
  exit 1
  ;;
#############
  --domain)
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
  --font_size)
   if [[ -n "${2}" ]]; then
     FONT_SIZE="${2}"
     shift
   fi
  ;;
  --font_size=?*)
  FONT_SIZE="${1#*=}" # Delete everything up to "=" and assign the remainder.
  ;;
  --font_size=) # Handle the empty case
  printf 'Using default environment.\n' >&2
  ;;
#############
  --font_tree_size)
  if [[ -n "${2}" ]]; then
    FONT_TREE_SIZE="${2}"
    shift
  fi
  ;;
  --font_tree_size=?*)
  FONT_TREE_SIZE="${1#*=}" # Delete everything up to "=" and assign the 
                             # remainder.
  ;;
  --font_tree_size=) # Handle the empty case
  printf 'Using default environment.\n' >&2
  ;; 
#############
  --identity)
  if [[ -n "${2}" ]]; then
    ID="${2}"
    shift
  fi
  ;;
  --identity=?*)
  ID="${1#*=}" # Delete everything up to "=" and assign the remainder.
  ;;
  --identity=) # Handle the empty case
  printf "ERROR: --input_dirs requires a non-empty option argument.\n"  >&2
  exit 1
  ;;
 #############
  --num_iter)
  if [[ -n "${2}" ]]; then
    NUM_ITER="${2}"
    shift
  fi
  ;;
  --num_iter=?*)
  NUM_ITER="${1#*=}" # Delete everything up to "=" and assign the remainder.
  ;;
  --num_iter=) # Handle the empty case
  printf 'Using default environment.\n' >&2
  ;;
#############
  --only_rep)
  if [[ -n "${2}" ]]; then
    ONLY_REP="${2}"
    shift
  fi
  ;;
  --only_rep=?*)
  ONLY_REP="${1#*=}" # Delete everything up to "=" and assign the remainder.
  ;;
  --only_rep=) # Handle the empty case
  printf 'Using default environment.\n' >&2
  ;;
#############
  --outdir)
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
  --plot_tree)
  if [[ -n "${2}" ]]; then
    PLOT_TREE="${2}"
    shift
  fi
  ;;
  --plot_tree=?*)
  PLOT_TREE="${1#*=}" # Delete everything up to "=" and assign the remainder.
  ;;
  --place_tree=) # Handle the empty case
  printf 'Using default environment.\n' >&2
  ;;  
#############
  --plot_width)
  if [[ -n "${2}" ]]; then
    PLOT_WIDTH="${2}"
    shift
  fi
  ;;
  --plot_width=?*)
  PLOT_WIDTH="${1#*=}" # Delete everything up to "=" and assign the remainder.
  ;;
  --plot_width=) # Handle the empty case
  printf 'Using default environment.\n' >&2
  ;;  
#############
  --plot_height)
  if [[ -n "${2}" ]]; then
    PLOT_HEIGHT="${2}"
    shift
  fi
  ;;
  --plot_height=?*)
  PLOT_HEIGHT="${1#*=}" # Delete everything up to "=" and assign the remainder.
  ;;
  --plot_height=) # Handle the empty case
  printf 'Using default environment.\n' >&2
  ;;  
#############
  --plot_tree_height)
  if [[ -n "${2}" ]]; then
    PLOT_TREE_HEIGHT="${2}"
    shift
  fi
  ;;
  --plot_tree_height=?*)
  PLOT_TREE_HEIGHT="${1#*=}" # Delete everything up to "=" and assign the 
                             # remainder.
  ;;
  --plot_rare_height=) # Handle the empty case
  printf 'Using default environment.\n' >&2
  ;;  
#############
  --plot_tree_width)
  if [[ -n "${2}" ]]; then
    PLOT_TREE_WIDTH="${2}"
    shift
  fi
  ;;
  --plot_tree_width=?*)
  PLOT_TREE_WIDTH="${1#*=}" # Delete everything up to "=" and assign the 
                            # remainder.
  ;;
  --plot_tree_width=) # Handle the empty case
  printf 'Using default environment.\n' >&2
  ;;  
#############
  --reads)
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
  --nslots)
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
  --verbose)
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
  --overwrite)
  if [[ -n "${2}" ]]; then
    OVERWRITE="${2}"
    shift
  fi
  ;;
  --overwrite=?*)
  OVERWRITE="${1#*=}" # Delete everything up to "=" and assign the remainder.
  ;;
  --overwrite=) # Handle the empty case
  printf 'Using default environment.\n' >&2
  ;;    
############
  --)         # End of all options.
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

if [[ -z "${OUTDIR_EXPORT}" ]]; then
 echo "Failed. Missing output directory."
 exit 1;
fi

if [[ -z "${R}" ]]; then
 echo "Failed. Missing input reads."
 exit 1;
fi

if [[ -z "${DOMAIN}" ]]; then
 echo "Failed. Missing target domain."
 exit 1;
fi

###############################################################################
# 5. Define defaults
###############################################################################

if [[ -z "${BLAST}" ]]; then
  BLAST="f"
fi

if [[ -z "${ID}" ]]; then
  ID="0.7"
fi

if [[ -z "${FONT_SIZE}" ]]; then
  FONT_SIZE="1"
fi

if [[ -z "${NUM_ITER}" ]]; then
  NUM_ITER="100"
fi

if [[ -z "${NSLOTS}" ]]; then
  NSLOTS="2"
fi

if [[ -z "${ONLY_REP}" ]]; then
  ONLY_REP="t"
fi

if [[ -z "${PLOT_WIDTH}" ]]; then
  PLOT_WIDTH="3"
fi  

if [[ -z "${PLOT_HEIGHT}" ]]; then
  PLOT_HEIGHT="4"
fi  

if [[ -z "${PLOT_TREE_WIDTH}" ]]; then
  PLOT_TREE_WIDTH="14"
fi

if [[ -z "${PLOT_TREE_HEIGHT}" ]]; then
  PLOT_TREE_HEIGHT="12"
fi

if [[ -z "${FONT_TREE_SIZE}" ]]; then
  FONT_TREE_SIZE="1"
fi

if [[ -z "${PLOT_TREE}" ]]; then
  PLOT_TREE="f"
fi

if [[ -z "${SUBSAMPLE_NUMBER}" ]]; then
  SUBSAMPLE_NUMBER="30"
fi

if [[ -z "${VERBOSE}" ]]; then
  VERBOSE="f"
fi

###############################################################################
# 6. Load handleoutput
###############################################################################

source /bioinfo/software/handleoutput 

###############################################################################
# 7. Check output directories
###############################################################################

if [[ -d "${OUTDIR_LOCAL}/${OUTDIR_EXPORT}" ]]; then
  if [[ "${OVERWRITE}" != "t" ]]; then
    echo "${OUTDIR_EXPORT} already exist. Use \"--overwrite t\" to overwrite."
    exit
  fi
fi  

###############################################################################
# 8. Create output directories
###############################################################################

THIS_JOB_TMP_DIR="${SCRATCH}/${OUTDIR_EXPORT}"
mkdir -p "${THIS_JOB_TMP_DIR}"

###############################################################################
# 9. Define output variables
###############################################################################

TMP_NAME="${THIS_JOB_TMP_DIR}/tmp_${DOMAIN}"
NAME="${THIS_JOB_TMP_DIR}/${DOMAIN}"
HMM="${HMM_DIR}/${DOMAIN}.hmm" 

###############################################################################
# 10. Export variables
###############################################################################

ENV="${THIS_JOB_TMP_DIR}/tmp_env"

echo -e "\
BLAST=${BLAST}
DOMAIN=${DOMAIN}
ID=${ID}
FONT_SIZE=${FONT_SIZE}
FONT_TREE_SIZE=${FONT_TREE_SIZE}
HMM=${HMM}
NAME=${NAME}
TMP_NAME=${TMP_NAME}
NSLOTS=${NSLOTS}
NUM_ITER=${NUM_ITER}
ONLY_REP=${ONLY_REP}
THIS_JOB_TMP_DIR=${THIS_JOB_TMP_DIR}
PLOT_TREE=${PLOT_TREE}
PLOT_WIDTH=${PLOT_WIDTH}
PLOT_HEIGHT=${PLOT_HEIGHT}
PLOT_TREE_HEIGHT=${PLOT_TREE_HEIGHT}
PLOT_TREE_WIDTH=${PLOT_TREE_WIDTH}
VERBOSE=${VERBOSE}" > "${ENV}"

###############################################################################
# 11. Check number of sequences found
###############################################################################

NSEQ=$(egrep -c ">" "${R}")

if [[ "${NSEQ}" -lt "5" ]]; then
  echo "Not enough ${DOMAIN} amplicon reads: ${NSEQ}"
  exit 1
fi

###############################################################################
# 12. Check if file is compressed
###############################################################################

GZIP_CHECK=$(egrep "gzip compressed data" <(file "${R}"))

if [[ -n "${GZIP_CHECK}" ]]; then

  UNCOMPRESSED_FILE="${THIS_JOB_TMP_DIR}/$(basename ${R/.gz/})"
  gunzip --stdout "${R}" > "${UNCOMPRESSED_FILE}"
  R="${UNCOMPRESSED_FILE}"
  
fi  

###############################################################################
# 13. Get ORFs
###############################################################################

"${fraggenescan}" \
-genome="${R}" \
-out="${NAME}_dom_seqs" \
-complete=0 \
-train=illumina_5 \
-thread="${NSLOTS}" 2>&1 | handleoutput
   
if [[ "$?" -ne "0" ]]; then
  echo "${DOMAIN}: fraggenescan failed"
  exit 1
fi 

AMP_ORFS="${NAME}_dom_seqs.faa"
    
#############################################################################
# 14. Cluster
#############################################################################
  
"${SOFTWARE_DIR}"/mmseqs_runner.bash \
--amp_orfs "${AMP_ORFS}" \
--env "${ENV}" \
--prefix "${NAME}" \
--tmp_prefix "${TMP_NAME}" \
--tmp_folder "${THIS_JOB_TMP_DIR}"/tmp  2>&1 | handleoutput
 
if [[ "$?" -ne "0" ]]; then
  echo "${DOMAIN}: mmseqs_runner.bash failed"
  exit 1
fi  

#############################################################################
# 18. Create cluster table
#############################################################################  

"${SOFTWARE_DIR}"/create_cluster2abund_table.bash \
--env "${ENV}" \
--prefix "${NAME}" \
--tmp_prefix "${TMP_NAME}" 2>&1 | handleoutput 
     
if [[ "$?" -ne "0" ]]; then
  echo "${DOMAIN}: create_cluster2abund_table.bash failed"
  exit 1
fi

#############################################################################
# 19. Compute diversity
#############################################################################
    
"${SOFTWARE_DIR}"/model_div_plot.bash \
--env "${ENV}" \
--prefix "${NAME}" \
--plot_model_violin t 2>&1  | handleoutput
    
if [[ "$?" -ne "0" ]]; then
  echo "${DOMAIN}: model_div_plot.bash failed"
  exit 1
fi 

#############################################################################
# 20. Blast search
############################################################################# 
 
 if [[ "${BLAST}" == "t" ]]; then
 
  "${SOFTWARE_DIR}"/blast_runner.bash \
  --amp_orfs "${AMP_ORFS}" \
  --env "${ENV}" \
  --prefix "${NAME}" 2>&1 | handleoutput
      
  if [[ "$?" -ne "0" ]]; then
    echo "${DOMAIN}: blast_runner.bash failed"
    exit 1
  fi
fi

#############################################################################
# 21. Tree placement and drawing
#############################################################################
  
if [[ "${PLOT_TREE}" == "t" ]]; then
    
  if [[ ! -d "${REF_PKG_DIR}/${DOMAIN}.refpkg" ]]; then
    echo echo "No refpkg for ${DOMAIN}. Skipping tree placement ..."
    continue
  fi  
  
  if [[ "${ONLY_REP}" == "t" ]]; then
    "${SOFTWARE_DIR}"/extract_only_rep_seqs.bash \
    --amp_orfs "${AMP_ORFS}" \
    --env "${ENV}" \
    --prefix "${NAME}" \
    --tmp_prefix "${TMP_NAME}"  2>&1 | handleoutput
    
    if [[ "$?" -ne "0" ]]; then
      echo "${DOMAIN}: extract_only_rep_seqs.bash failed"
      exit 1
    fi
   
    # to be used in tree_pplacer.bash
    TREE_INPUT_SEQ="${TMP_NAME}_onlyrep.faa"
    # to be used in tree_drawer.bash 
    TREE_CLUST_ABUND="${TMP_NAME}_onlyrep_cluster2abund.tsv"

  else

    # to be used in tree_pplacer.bash
    TREE_INPUT_SEQ="${AMP_ORFS}"
    # to be used in tree_drawer.bash 
    TREE_CLUST_ABUND="${NAME}_cluster2abund.tsv"

  fi
    
  "${SOFTWARE_DIR}"/tree_pplacer.bash \
  --env "${ENV}" \
  --input "${TREE_INPUT_SEQ}" 2>&1 | handleoutput
     
  if [[ "$?" -ne "0" ]]; then
    echo "${DOMAIN}: tree_pplacer.bash failed"
    exit 1
  fi
 
  "${SOFTWARE_DIR}"/tree_drawer.bash \
  --env "${ENV}" \
  --abund_table "${TREE_CLUST_ABUND}" 2>&1 | handleoutput
     
  if [[ "$?" -ne "0" ]]; then
    echo "${DOMAIN}: tree_drawer.bash failed"
    exit 1
  fi
fi

###############################################################################
# 22. Clean
###############################################################################
   
rm -r "${THIS_JOB_TMP_DIR}"/tmp*

###############################################################################
# 23. Move output for export
###############################################################################

rsync -a --delete "${THIS_JOB_TMP_DIR}" "${OUTDIR_LOCAL}"
