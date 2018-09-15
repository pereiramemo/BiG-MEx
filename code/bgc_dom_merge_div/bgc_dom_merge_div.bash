#!/bin/bash -l

# set -x
set -o pipefail

###############################################################################
# 1. Load general configuration
###############################################################################

source /bioinfo/software/conf

###############################################################################
# 2. Set help
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

    -h|-\?|--help) # Call a "show_help" function to display a synopsis, then
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
  printf "ERROR: --input_dirs requires a non-empty option argument.\n"  >&2
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
    FONT_SIZE="${1#*=}" # Delete everything up to "=" and assign the 
                        # remainder.
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
  ONLY_REP="${1#*=}" # Delete everything up to "=" and assign the 
                     # remainder.
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
  NUM_ITER="${1#*=}" # Delete everything up to "=" and assign the 
                     # remainder.
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
  PLOT_TREE="${1#*=}" # Delete everything up to "=" and assign the 
                      # remainder.
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
  PLOT_HEIGHT="${1#*=}" # Delete everything up to "=" and assign the 
                        # remainder.
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
  PLOT_WIDTH="${1#*=}" # Delete everything up to "=" and assign the 
                       # remainder.
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
  VERBOSE="${1#*=}" # Delete everything up to "=" and assign the 
                    # remainder.
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
# 4. Set defaults and check variables
###############################################################################

if [[ -z "${DOMAIN}" ]]; then
  echo "--domain is not defiened. Please use the --domain flag: \
  E.g. --domain PKS_KS"
  exit 1
fi

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
  PLOT_WIDTH="8"
fi

if [[ -z "${PLOT_HEIGHT}" ]]; then
  PLOT_HEIGHT="4"
fi

if [[ -z "${FONT_SIZE}" ]]; then
  FONT_SIZE="10"
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

if [[ "${VERBOSE}" == "t" ]]; then
  function handleoutput {
    cat /dev/stdin | \
    while read STDIN; do 
      echo "${STDIN}"
    done  
  }
else
  function handleoutput {
  cat /dev/stdin >/dev/null
}
fi

###############################################################################
# 5. Check output directories
###############################################################################

if [[ -d "${OUTDIR_LOCAL}/${OUTDIR_EXPORT}" ]]; then
  if [[ "${OVERWRITE}" != "t" ]]; then
    echo "${OUTDIR_EXPORT} already exist. Use \"--overwrite t\" to overwrite."
    exit
  fi
fi

###############################################################################
# 6. Define output
###############################################################################

THIS_JOB_TMP_DIR="${SCRATCH}/${OUTDIR_EXPORT}"
NAME="${THIS_JOB_TMP_DIR}/${DOMAIN}"
TMP_NAME="${THIS_JOB_TMP_DIR}/tmp_${DOMAIN}"

mkdir "${THIS_JOB_TMP_DIR}"

###############################################################################
# 7. Concat and add file id to fasta files
###############################################################################

"${SOFTWARE_DIR}"/concat_faa.bash \
--input_dirs "${INPUT_DIRS}" \
--domain "${DOMAIN}" \
--output "${TMP_NAME}_all.faa"  2>&1 | handleoutput

if [[ $? != "0" ]]; then
  echo "concat_faa.bash failed"
  exit 1
fi

###############################################################################
# 8. Concat and add file id to cluster files
###############################################################################

"${SOFTWARE_DIR}"/concat_clust.bash \
--input_dirs "${INPUT_DIRS}" \
--domain "${DOMAIN}" \
--output "${TMP_NAME}_all-coverage.table"  2>&1 | handleoutput

if [[ $? != "0" ]]; then
  echo "concat coverage failed"
  exit 1
fi  

###############################################################################
# 9. Cluster seqs
###############################################################################

"${SOFTWARE_DIR}"/mmseqs_runner.bash \
--identity "${ID}" \
--tmp_prefix "${TMP_NAME}" \
--tmp_folder "${THIS_JOB_TMP_DIR}"/tmp \
--threads "${NSLOTS}"  2>&1 | handleoutput

if [[ $? != "0" ]]; then
  echo "mmseqs_runner.bash failed"
  exit 1
fi

###############################################################################
# 10. Map coverage
###############################################################################

"${SOFTWARE_DIR}"/map_coverage.bash \
--coverage_tsv "${TMP_NAME}_all-coverage.table" \
--cluster_tsv   "${TMP_NAME}_all_clu".tsv \
--output "${NAME}_cluster2abund".tsv 2>&1 | handleoutput

if [[ $? != "0" ]]; then
  echo "map_coverage.bash failed"
  exit 1
fi

###############################################################################
# 11. Estimate diversity
###############################################################################

"${SOFTWARE_DIR}"/model_div_plot.bash \
  --abund_table "${NAME}_cluster2abund".tsv \
  --font_size "${FONT_SIZE}" \
  --outdir "${THIS_JOB_TMP_DIR}" \
  --prefix "${DOMAIN}" \
  --plot_width  "${PLOT_WIDTH}" \
  --plot_height "${PLOT_HEIGHT}" \
  --num_iter "${NUM_ITER}" \
  --plot_model_points t 2>&1 | handleoutput

if [[ $? != 0 ]]; then
  echo "model diversiy estimate failed"
  exit 1
fi

###############################################################################
# 12. Make rarefaction
###############################################################################

if [[ "${PLOT_RARE_CURVE}" == "t" ]]; then

  "${SOFTWARE_DIR}"/rare_div_plot.bash \
    --abund_table "${NAME}_cluster2abund".tsv \
    --font_size "${FONT_SIZE}" \
    --outdir "${THIS_JOB_TMP_DIR}" \
    --prefix "${DOMAIN}" \
    --plot_width  "${PLOT_WIDTH}" \
    --plot_height "${PLOT_HEIGHT}" \
    --num_iter "${NUM_ITER}" \
    --plot_rare_curve t \
    --sample_increment "${SAMPLE_INCREMENT}"  2>&1 | handleoutput

  if [[ $? != 0 ]]; then
    echo "subsampled diversiy estimate failed"
    exit 1
  fi
fi

###############################################################################
# 13. Tree placement and drawing
###############################################################################

if [[ "${PLOT_TREE}" == "t" ]]; then

  if [[ ! -d "${REF_PKG_DIR}/${DOMAIN}.refpkg" ]]; then
    echo "No refpkg for ${DOMAIN}. Skipping tree placement ..."
    continue
  fi
  
  #############################################################################
  # 13.1. Concat cluster2abund.tsv tables
  #############################################################################
  "${SOFTWARE_DIR}"/concat_cluster2abund.bash \
  --input_dirs "${INPUT_DIRS}" \
  --domain "${DOMAIN}" \
  --output "${TMP_NAME}_concat_cluster2abund.tsv" 2>&1 | handleoutput
  
  if [[ $? != 0 ]]; then
    echo "concat_cluster2abund.bash failed"
    exit 1
  fi
  
  if [[ "${ONLY_REP}" == "t" ]]; then
  
    ###########################################################################
    # 13.2. Extract repseqs
    ###########################################################################
    "${SOFTWARE_DIR}"/extract_only_rep_seqs.bash \
    --clust2abund_tsv "${TMP_NAME}_concat_cluster2abund.tsv" \
    --tmp_prefix "${TMP_NAME}"
      
    if [[ "$?" -ne "0" ]]; then
      echo "${DOMAIN}: extract_only_rep_seqs.bash failed"
      exit 1
    fi

    TREE_INPUT_SEQ="${TMP_NAME}_onlyrep_subseqs.faa"
    TREE_CLUST_ABUND="${TMP_NAME}_onlyrep_cluster2abund.tsv"

  else

    ###########################################################################
    # 13.3. Rename, with no repseq extraction
    ###########################################################################
    TREE_INPUT_SEQ="${TMP_NAME}_all.faa"
    TREE_CLUST_ABUND="${TMP_NAME}_concat_cluster2abund.tsv"

  fi
  
  #############################################################################
  # 13.4. Place seqs
  #############################################################################
  
  "${SOFTWARE_DIR}"/tree_pplacer.bash \
  --domain "${DOMAIN}" \
  --input "${TREE_INPUT_SEQ}" \
  --outdir "${THIS_JOB_TMP_DIR}" 2>&1 | handleoutput
      
  if [[ "$?" -ne "0" ]]; then
    echo "${DOMAIN}: tree placing failed"
    exit 1
  fi
  
  #############################################################################
  # 13.5. Make tree figure
  #############################################################################
  
  INFO_PPLACE="${THIS_JOB_TMP_DIR}/${DOMAIN}_tree_data/${DOMAIN}_query_info.csv"
  TREE="${THIS_JOB_TMP_DIR}/${DOMAIN}_tree_data/${DOMAIN}_query.newick"
      
  "${SOFTWARE_DIR}"/tree_drawer.bash \
  --domain "${DOMAIN}" \
  --info_pplace "${INFO_PPLACE}" \
  --abund_table "${TREE_CLUST_ABUND}" \
  --outdir "${THIS_JOB_TMP_DIR}/${DOMAIN}_tree_data/" \
  --plot_height "${PLOT_TREE_HEIGHT}" \
  --plot_width "${PLOT_TREE_WIDTH}" \
  --font_size "${FONT_TREE_SIZE}" \
  --tree "${TREE}" 2>&1 | handleoutput
      
  if [[ "$?" -ne "0" ]]; then
    echo "${DOMAIN}: tree drawing failed"
    exit 1
  fi
fi

###############################################################################
# 14. Clean
###############################################################################

rm -r "${TMP_NAME}"*
rm -r  "${THIS_JOB_TMP_DIR}"/tmp

###############################################################################
# 15. Move output for export
###############################################################################

rsync -a --delete "${THIS_JOB_TMP_DIR}" "${OUTDIR_LOCAL}"

