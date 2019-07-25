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
  Usage: run_bgc_dom_div.bash merge <input directory 1>,<input directory 2>,\
<input directory 3> <output directory> <options>

  [-h|--help] [-d|--domain CHAR] [-fs|--font_size NUM] 
  [-fts|--font_tree_size NUM] [-id|--identity NUM] [-n|--num_iter NUM] 
  [-or|--only_rep t|f] [-pr|--plot_rare_curve t|f] [-ph|--plot_height NUM]
  [-pw|--plot_width NUM] [-pt|--plot_tree t|f] [-pth|--plot_tree_height NUM] 
  [-ptw|--plot_tree_width NUM] [-s|--sample_increment INT] [-t|--nslots INT]
  [-v|--verbose t|f] [-w|--overwrite t|f]


-h, --help	print this help
-d, --domain	domain name
-fs, --font_size	plot font size in rarefaction plot (default 10). R parameter
-fts, --font_tree_size	plot font size in tree plot (default 2). R parameter
-id, --identity	clustering minimum identity (default 0.7). mmseqs cluster parameter 
-n, --num_iter	number of iterations in each random subsampling (default 100)
-or, --only_rep	t or f, use only representative cluster sequences in tree placement (default t)
-pr, --plot_rare_curve	t or f, make rare curve plot (default f)
-ph, --plot_height	plot height (default 4). R parameter
-pw, --plot_width	plot width (default 8). R parameter
-pt, --plot_tree	t or f, make tree plot (default f)
-pth, --plot_tree_height	plot height (default 12). R parameter
-ptw, --plot_tree_width	plot width (default 14). R parameter
-s, --sample_increment 	increment in rarefaction (default 50)
-t, --nslots	number of slots (default 2). mmseqs cluster parameter
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
  -i|--input_dirs)
  if [[ -n "${2}" ]]; then
   INPUT_DIRS="${2}"
   shift
  fi
  ;;
  --input_dirs=?*)
  INPUT_DIRS="${1#*=}" # Delete everything up to "=" and assign the remainder.
  ;;
  --intput_dirs=) # Handle the empty case
  printf "ERROR: --input_dirs requires a non-empty option argument.\n"  >&2
  exit 1
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
  printf "ERROR: --identity requires a non-empty option argument.\n"  >&2
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
  -s|--sample_increment)
  if [[ -n "${2}" ]]; then
    SAMPLE_INCREMENT="${2}"
    shift
  fi
  ;;
  --sample_increment=?*)
  SAMPLE_INCREMENT="${1#*=}" # Delete everything up to "=" and assign the 
                             # remainder.
  ;;
  --sample_increment=) # Handle the empty case
  printf 'Using default environment.\n' >&2
  ;; 
#############
  -pc|--plot_rare_curve)
  if [[ -n "${2}" ]]; then
    PLOT_RARE_CURVE="${2}"
    shift
  fi
  ;;
  --plot_rare_curve=?*)
  PLOT_RARE_CURVE="${1#*=}" # Delete everything up to "=" and assign the 
                            # remainder.
  ;;
  --plot_rare_curve=) # Handle the empty case
  printf 'Using default environment.\n' >&2
  ;;
#############
  -pt|--plot_tree)
  if [[ -n "${2}" ]]; then
    PLOT_TREE="${2}"
    shift
  fi
  ;;
  --plot_tree=?*)
  PLOT_TREE="${1#*=}" # Delete everything up to "=" and assign the remainder.
  ;;
  --plot_tree=) # Handle the empty case
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
# 4. Check mandatory parameters
###############################################################################

for D in $(echo "${INPUT_DIRS}" | tr "," "\n"); do

  if [[ ! -d "${D}" ]]; then
    echo "Failed. Input directory ${D} not found"
    exit 1
  fi    
  
done

if [[ -z "${DOMAIN}" ]]; then
  echo "Failed. --domain is not defiened. Please use the --domain flag: \
  E.g. --domain PKS_KS"
  exit 1
fi

if [[ -z "${OUTDIR_EXPORT}" ]]; then
 echo "Failed. Missing output directory."
 exit 1;
fi

###############################################################################
# 5. Set defaults and check variables
###############################################################################

if [[ -z "${ID}" ]]; then
  ID="0.7"
fi

if [[ -z "${NUM_ITER}" ]]; then
  NUM_ITER="100"
fi

if [[ -z "${SAMPLE_INCREMENT}" ]]; then
  SAMPLE_INCREMENT="50"
fi

if [[ -z "${PLOT_WIDTH}" ]]; then
  PLOT_WIDTH="4"
fi

if [[ -z "${PLOT_HEIGHT}" ]]; then
  PLOT_HEIGHT="3"
fi

if [[ -z "${FONT_SIZE}" ]]; then
  FONT_SIZE="1"
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

if [[ -z "${ONLY_REP}" ]]; then
  ONLY_REP="t"
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
# 8. Define output
###############################################################################

THIS_JOB_TMP_DIR="${SCRATCH}/${OUTDIR_EXPORT}"
NAME="${THIS_JOB_TMP_DIR}/${DOMAIN}"
TMP_NAME="${THIS_JOB_TMP_DIR}/tmp_${DOMAIN}"

mkdir "${THIS_JOB_TMP_DIR}"

###############################################################################
# 9. Export variables
###############################################################################

ENV="${THIS_JOB_TMP_DIR}/tmp_env"

echo -e "\
DOMAIN=${DOMAIN}
ID=${ID}
INPUT_DIRS=${INPUT_DIRS}
FONT_SIZE=${FONT_SIZE}
FONT_TREE_SIZE=${FONT_TREE_SIZE}
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
SAMPLE_INCREMENT=${SAMPLE_INCREMENT}
VERBOSE=${VERBOSE}" > "${ENV}"

###############################################################################
# 8. Concat and add file id to fasta files
###############################################################################

"${SOFTWARE_DIR}"/concat_faa.bash --env "${ENV}" 2>&1 | handleoutput

if [[ $? != "0" ]]; then
  echo "concat_faa.bash failed"
  exit 1
fi

###############################################################################
# 9. Concat and add file id to cluster files
###############################################################################

"${SOFTWARE_DIR}"/concat_clust.bash --env "${ENV}" 2>&1 | handleoutput

if [[ $? != "0" ]]; then
  echo "concat coverage failed"
  exit 1
fi  

###############################################################################
# 10. Cluster seqs
###############################################################################

"${SOFTWARE_DIR}"/mmseqs_runner.bash \
--env "${ENV}" \
--tmp_prefix "${TMP_NAME}" \
--tmp_folder "${THIS_JOB_TMP_DIR}"/tmp 2>&1 | handleoutput

if [[ $? != "0" ]]; then
  echo "mmseqs_runner.bash failed"
  exit 1
fi

###############################################################################
# 11. Map coverage
###############################################################################

"${SOFTWARE_DIR}"/map_coverage.bash --env "${ENV}" 2>&1 | handleoutput

if [[ $? != "0" ]]; then
  echo "map_coverage.bash failed"
  exit 1
fi

###############################################################################
# 12. Estimate diversity
###############################################################################

"${SOFTWARE_DIR}"/model_div_plot.bash \
--env "${ENV}" \
--plot_model_points t 2>&1 | handleoutput

if [[ $? != 0 ]]; then
  echo "model diversiy estimate failed"
  exit 1
fi

###############################################################################
# 13. Make rarefaction
###############################################################################

if [[ "${PLOT_RARE_CURVE}" == "t" ]]; then

  "${SOFTWARE_DIR}"/rare_div_plot.bash \
  --env "${ENV}" \
  --plot_rare_curve t 2>&1 | handleoutput

  if [[ $? != 0 ]]; then
    echo "subsampled diversiy estimate failed"
    exit 1
  fi
fi

###############################################################################
# 14. Tree placement and drawing
###############################################################################

if [[ "${PLOT_TREE}" == "t" ]]; then

  if [[ ! -d "${REF_PKG_DIR}/${DOMAIN}.refpkg" ]]; then
    echo "No refpkg for ${DOMAIN}. Skipping tree placement ..."
    continue
  fi
  
  #############################################################################
  # 14.1. Concat cluster2abund.tsv tables
  #############################################################################
  "${SOFTWARE_DIR}"/concat_cluster2abund.bash \
   --env "${ENV}" 2>&1 | handleoutput
  
  if [[ $? != 0 ]]; then
    echo "concat_cluster2abund.bash failed"
    exit 1
  fi
  
  if [[ "${ONLY_REP}" == "t" ]]; then
  
    ###########################################################################
    # 14.2. Extract repseqs
    ###########################################################################
    "${SOFTWARE_DIR}"/extract_only_rep_seqs.bash \
    --env "${ENV}" 2>&1 | handleoutput
      
    if [[ "$?" -ne "0" ]]; then
      echo "${DOMAIN}: extract_only_rep_seqs.bash failed"
      exit 1
    fi

    TREE_INPUT_SEQ="${TMP_NAME}_onlyrep_subseqs.faa"
    TREE_CLUST_ABUND="${TMP_NAME}_onlyrep_cluster2abund.tsv"

  else

    ###########################################################################
    # 14.3. Rename, with no repseq extraction
    ###########################################################################
    TREE_INPUT_SEQ="${TMP_NAME}_all.faa"
    TREE_CLUST_ABUND="${TMP_NAME}_concat_cluster2abund.tsv"

  fi
  
  #############################################################################
  # 14.4. Place seqs
  #############################################################################
  
  "${SOFTWARE_DIR}"/tree_pplacer.bash \
  --env "${ENV}" \
  --input "${TREE_INPUT_SEQ}" 2>&1 | handleoutput
      
  if [[ "$?" -ne "0" ]]; then
    echo "${DOMAIN}: tree placing failed"
    exit 1
  fi
  
  #############################################################################
  # 14.5. Make tree figure
  #############################################################################

  "${SOFTWARE_DIR}"/tree_drawer.bash \
  --env "${ENV}" \
  --abund_table "${TREE_CLUST_ABUND}" 2>&1 | handleoutput
      
  if [[ "$?" -ne "0" ]]; then
    echo "${DOMAIN}: tree drawing failed"
    exit 1
  fi
fi

###############################################################################
# 15. Clean
###############################################################################

rm -r "${TMP_NAME}"*
rm -r  "${THIS_JOB_TMP_DIR}"/tmp*

###############################################################################
# 16. Move output for export
###############################################################################

rsync -a --delete "${THIS_JOB_TMP_DIR}" "${OUTDIR_LOCAL}"

