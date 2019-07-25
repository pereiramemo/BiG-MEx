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
  Usage: run_bgc_dom_div.bash sample <R> <output directory> <options>
  
  [-h|--help] [-b|--blast t|f] [-d|--domain CHAR] [-f|--font_size NUM] 
  [-fts|--font_tree_size NUM] [-id|--identity NUM] [-n|--num_iter NUM] 
  [-or|--only_rep t|f] [-p|--plot_tree t|f] [-ph|--plot_height NUM] 
  [-pw|--plot_width NUM] [-pth|--plot_tree_height NUM] 
  [-ptw|--plot_tree_width NUM] [-t|--nslots NUM] [-v|--verbose t|f]   
  [-w|--overwrite t|f]

-h, --help	print this help
-b, --blast	t or f, run blast against reference database (default f) 
-d, --domain	target domain name
-f, --font_size	violin plot font size (default 3). R parameter
-fts, --font_tree_size	tree plot font size (default 1). R parameter
-id, --identity	clustering minimum identity (default 0.7). mmseqs cluster parameter
-n, --num_iter	number of iterations to estimate diversity distribution \
(default 100)
-or, --only_rep t or f, use only representative cluster sequences in tree 
placement (default t)
-p, --plot_tree t or f, place sequences in reference tree and generate plot
-ph, --plot_height	tree plot height (default 3). R parameter
-pw, --plot_width	tree plot width (default 3). R parameter
-pth, --plot_tree_height	plot height (default 12). R parameter
-ptw, --plot_tree_width	plot width (default 14). R parameter
-t, --nslots	number of slots (default 2). FragGeneScan, \
hmmsearch, and mmseqs cluster
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
  -b|--blast)
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
  -fs|--font_size)
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
  -fts|--font_tree_size)
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
  -id|--identity)
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
  -n|--num_iter)
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
  -or|--only_rep)
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
  -p|--plot_tree)
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
  -pw|--plot_width)
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
  -ph|--plot_height)
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
  -pth|--plot_tree_height)
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
  -ptw|--plot_tree_width)
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
 -R|--reads)
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
# 12. Get ORFs
###############################################################################

"${fraggenescan}" \
-genome="${R}" \
-out="${NAME}_dom_seqs" \
-complete=0 \
-train=illumina_5 \
-thread="${NSLOTS}" 2>&1 | handleoutput
   
if [[ "$?" -ne "0" ]]; then
  echo "${DOMAIN}: fraggenescan ORFs identification failed"
  exit 1
fi 

AMP_ORFS="${NAME}_dom_seqs.faa"
    
#############################################################################
# 17. Cluster
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
  echo "${DOMAIN}: diversity model failed"
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
    echo "${DOMAIN}: blast failed"
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

    TREE_INPUT_SEQ="${TMP_NAME}_onlyrep.faa"
    TREE_CLUST_ABUND="${TMP_NAME}_onlyrep_cluster2abund.tsv"

  else

    TREE_INPUT_SEQ="${AMP_ORFS}"
    TREE_CLUST_ABUND="${NAME}_cluster2abund.tsv"

  fi
    
  "${SOFTWARE_DIR}"/tree_pplacer.bash \
  --env "${ENV}" \
  --input "${TREE_INPUT_SEQ}" 2>&1 | handleoutput
     
  if [[ "$?" -ne "0" ]]; then
    echo "${DOMAIN}: tree placing failed"
    exit 1
  fi
 
  "${SOFTWARE_DIR}"/tree_drawer.bash \
  --env "${ENV}" \
  --abund_table "${TREE_CLUST_ABUND}" 2>&1 | handleoutput
     
  if [[ "$?" -ne "0" ]]; then
    echo "${DOMAIN}: tree drawing failed"
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
