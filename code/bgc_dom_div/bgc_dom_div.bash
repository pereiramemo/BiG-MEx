#!/bin/bash -l

# set -x
set -o pipefail

###############################################################################
# 1. Load general configuration
###############################################################################

source /bioinfo/software/conf

###############################################################################
# 2. Set parameters
###############################################################################

show_usage(){
  cat <<EOF
  Usage: run_bgc_dom_div.bash sample <input file> <R1> <R2> <SR> \
<output directory> <options>
  
  [-h|--help] [-b|--blast t|f] [-c|--coverage t|f] [-d|--domains CHAR] 
  [-f|--font_size NUM] [-fts|--font_tree_size NUM] [-id|--identity NUM] 
  [-n|--num_iter NUM] [-oa|--output_assembly t|f] [-or|--only_rep t|f] 
  [-p|--plot_tree t|f]  [-ph|--plot_height NUM] [-pw|--plot_width NUM] 
  [-pth|--plot_tree_height NUM] [-ptw|--plot_tree_width NUM] [-t|--nslots NUM] 
  [-v|--verbose t|f] [-w|--overwrite t|f]


-h, --help	print this help
-b, --blast	t or f, run blast against reference database (default f)
-c, --coverage	t or f, use coverage to compute diversity (default f) 
-d, --domains	target domain names: comma separated list
-f, --font_size	violin plot font size (default 3). R parameter
-fts, --font_tree_size	tree plot font size (default 1). R parameter
-id, --identity	clustering minimum identity (default 0.7). mmseqs cluster parameter
-n, --num_iter	number of iterations to estimate diversity distribution (default 100)
-oa, --output_assembly	t or f, keep all assembly output directory in output (default f)
-or, --only_rep t or f, use only representative cluster sequences in tree placement (default t)
-p, --plot_tree t or f, place sequences in reference tree and generate plot
-ph, --plot_height	tree plot height (default 3). R parameter
-pw, --plot_width	tree plot width (default 3). R parameter
-pth, --plot_tree_height	plot height (default 12). R parameter
-ptw, --plot_tree_width	plot width (default 14). R parameter
-t, --nslots	number of slots (default 2). metaSPAdes, FragGeneScan, \
hmmsearch, mmseqs cluster, bwa mem and samtools parameter  
-v, --verbose	t or f, run verbosely (default f)
-w, --overwrite t or f, overwrite current directory (default f)
EOF
}

###############################################################################
# 3. Parse parameters 
###############################################################################

while :; do
  case "${1}" in

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
  -c|--coverage)
  if [[ -n "${2}" ]]; then
   COVERAGE="${2}"
   shift
  fi
  ;;
  --coverage=?*)
  COVERAGE="${1#*=}" # Delete everything up to "=" and assign the remainder.
  ;;
  --coverage=) # Handle the empty case
  printf "ERROR: --coverage requires a non-empty option argument.\n"  >&2
  exit 1
  ;;   
#############
  -d|--domains)
  if [[ -n "${2}" ]]; then
   DOMAINS="${2}"
   shift
  fi
  ;;
  --domains=?*)
  DOMAINS="${1#*=}" # Delete everything up to "=" and assign the remainder.
  ;;
  --domains=) # Handle the empty case
  printf "ERROR: --domains requires a non-empty option argument.\n"  >&2
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
  -i|--input)
  if [[ -n "${2}" ]]; then
   INPUT="${2}"
   shift
  fi
  ;;
  --input=?*)
  INPUT="${1#*=}" # Delete everything up to "=" and assign the remainder.
  ;;
  --input=) # Handle the empty case
  printf "ERROR: --input requires a non-empty option argument.\n"  >&2
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
  -oa|--output_assembly)
   if [[ -n "${2}" ]]; then
     OUTPUT_ASSEM="${2}"
     shift
   fi
  ;;
  --output_assembly=?*)
  OUTPUT_ASSEM="${1#*=}" # Delete everything up to "=" and assign the 
                         # remainder.
  ;;
  --output_assembly=) # Handle the empty case
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
  PLOT_TREE="${1#*=}" # Delete everything up to "=" and assign the 
                      # remainder.
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
  PLOT_WIDTH="${1#*=}" # Delete everything up to "=" and assign the 
                       # remainder.
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
  PLOT_HEIGHT="${1#*=}" # Delete everything up to "=" and assign the 
                        # remainder.
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
 -R1| --reads)
   if [[ -n "${2}" ]]; then
     R1="${2}"
     shift
   fi
  ;;
  --reads=?*)
  R1="${1#*=}" # Delete everything up to "=" and assign the remainder.
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
  --reads2=) # Handle the empty case
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

if [[ ! -f "${INPUT}" ]]; then
 echo "missing input file: uproc annotation"
 exit 1;
fi

if [[ -z "${R1}" ]] && [[ -z "${SR}" ]]; then
 echo "missing input reads"
 exit 1;
fi

if [[ -z "${DOMAINS}" ]]; then
 echo "missing target domains"
 exit 1;
fi

if [[ -z "${ID}" ]]; then
  ID="0.7"
fi

if [[ -z "${SUBSAMPLE_NUMBER}" ]]; then
  SUBSAMPLE_NUMBER="30"
fi

if [[ -z "${PLOT_WIDTH}" ]]; then
  PLOT_WIDTH="3"
fi  

if [[ -z "${PLOT_HEIGHT}" ]]; then
  PLOT_HEIGHT="3"
fi  

if [[ -z "${FONT_SIZE}" ]]; then
  FONT_SIZE="3"
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

if [[ -z "${NUM_ITER}" ]]; then
  NUM_ITER=100
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
# 6. Create output directories
###############################################################################

THIS_JOB_TMP_DIR="${SCRATCH}/${OUTDIR_EXPORT}"
mkdir -p "${THIS_JOB_TMP_DIR}"
  
###############################################################################
# 7. Subset sequence data to speed up later searches
###############################################################################

DOM_ALL_TMP="${THIS_JOB_TMP_DIR}/dom_all.list"
ALL_HEADERS="${THIS_JOB_TMP_DIR}/all.headers"
ALL_DOMAINS="${THIS_JOB_TMP_DIR}/all.domains"

echo "${DOMAINS}" | sed 's/\,/\n/g' > "${DOM_ALL_TMP}"
zcat "${INPUT}" | egrep -w -f "${DOM_ALL_TMP}" | sort | uniq > "${ALL_DOMAINS}"
cut -f2 -d"," "${ALL_DOMAINS}" | sort | uniq > "${ALL_HEADERS}"

# check nuber of sequences found
NSEQ=$( wc -l "${ALL_HEADERS}" | cut -f1 -d" ")
if [[ "${NSEQ}" -lt "0" ]]; then
  echo "no reads found"
  exit 1
fi

# base file names
R1_REDU="${THIS_JOB_TMP_DIR}/redu_r1.fasta"
R2_REDU="${THIS_JOB_TMP_DIR}/redu_r2.fasta"
SR_REDU="${THIS_JOB_TMP_DIR}/redu_sr.fasta"

# get redu fasta
if [[ -n "${R1}" ]] && [[ -n "${R2}" ]]; then

  "${filterbyname}" \
  in="${R1}" \
  in2="${R2}" \
  out="${R1_REDU}" \
  out2="${R2_REDU}" \
  names="${ALL_HEADERS}" \
  include=t \
  overwrite=t 2>&1 | handleoutput

  if [[ "$?" -ne "0" ]]; then
    echo "filterbyname R1 and R2 failed"
    exit 1
  fi
  
fi  
  
if [[ -n "${SR}" ]]; then
  
  "${filterbyname}" \
  in="${SR}" \
  out="${SR_REDU}" \
  names="${ALL_HEADERS}" \
  include=t \
  overwrite=t 2>&1 | handleoutput
  
  if [[ "$?" -ne "0" ]]; then
    echo "filterbyname SR failed"
    exit 1
  fi
    
fi

###############################################################################
# 8. Search, assembly and cluster for each domain
###############################################################################

for DOMAIN in $( cat "${DOM_ALL_TMP}" ); do

  # define domain specific variables
  TMP_NAME="${THIS_JOB_TMP_DIR}/tmp_${DOMAIN}"
  NAME="${THIS_JOB_TMP_DIR}/${DOMAIN}"
  HMM="${HMM_DIR}/${DOMAIN}.hmm"  
  
  # extract headers
  egrep -w "${DOMAIN}" "${ALL_DOMAINS}" | cut -f2 -d"," | \
  sort | uniq > "${NAME}.headers"
  
  # check nuber of sequences found
  NSEQ=$( wc -l "${NAME}.headers" | cut -f1 -d" ")
  if [[ "${NSEQ}" -lt 0 ]]; then
    echo "${DOMAIN}: no sequences found"
    continue
  fi
  
  # check nuber of domains to analyze: just rename if ndom == 1
  NDOM=$( wc -l "${DOM_ALL_TMP}" | cut -f1 -d" ")
  if [[ "${NDOM}" == 1 ]]; then
      
    if [[ -f "${R1_REDU}" ]] && [[ -f "${R2_REDU}" ]]; then
      mv "${R1_REDU}" "${TMP_NAME}_r1.fasta" 
      mv "${R2_REDU}" "${TMP_NAME}_r2.fasta" 
    fi
      
    if [[ -f "${SR_REDU}" ]]; then
      mv "${SR_REDU}" "${TMP_NAME}_sr.fasta" 
    fi
    
  else
  
  #############################################################################
  # 8.1. Get domain seqs
  #############################################################################

    if [[ -f "${R1_REDU}" ]] && [[ -f "${R2_REDU}" ]]; then
      "${filterbyname}" \
      in="${R1_REDU}" \
      in2="${R2_REDU}" \
      out="${TMP_NAME}_r1.fasta" \
      out2="${TMP_NAME}_r2.fasta" \
      names="${NAME}.headers" \
      include=t \
      overwrite=t 2>&1 | handleoutput
        
      if [[ "$?" -ne "0" ]]; then
        echo "${DOMAIN}: filterbyname R1_REDU and R2_REDU failed"
        exit 1
      fi
    fi  

    if [[ -f "${SR_REDU}" ]]; then
      "${filterbyname}" \
      in="${SR_REDU}" \
      out="${TMP_NAME}_sr.fasta" \
      names="${NAME}.headers" \
      include=t \
      overwrite=t 2>&1 | handleoutput

      if [[ "$?" -ne "0" ]]; then
        echo "${DOMAIN}: filterbyname SR_REDU failed"
        exit 1
      fi
      
    fi
  fi
  
  #############################################################################
  # 8.2. Assemble
  #############################################################################
    
  if [[ "${OUTPUT_ASSEM}" == "t" ]]; then
    ASSEM_DIR="${NAME}"
  else
    ASSEM_DIR="${TMP_NAME}"
  fi

  if [[ ! -f "${TMP_NAME}_sr.fasta" ]]; then
    "${metaspades}" \
    --meta \
    --only-assembler \
    -1 "${TMP_NAME}_r1.fasta" \
    -2 "${TMP_NAME}_r2.fasta" \
    --threads "${NSLOTS}" \
    -o "${ASSEM_DIR}_assem" 2>&1 | handleoutput
    
    if [[ "$?" -ne "0" ]]; then
      echo "${DOMAIN}: metaspades assembly failed"
      exit 1
    fi
  fi  
   
  if [[ -f "${TMP_NAME}_sr.fasta" ]]; then
    "${metaspades}" \
    --meta \
    --only-assembler \
    -1 "${TMP_NAME}_r1.fasta" \
    -2 "${TMP_NAME}_r2.fasta" \
    -s "${TMP_NAME}_sr.fasta" \
    --threads "${NSLOTS}" \
    -o "${ASSEM_DIR}_assem" 2>&1 | handleoutput
  

    if [[ "$?" -ne "0" ]]; then
      echo "${DOMAIN}: metaspades assembly failed"
      exit 1
    fi
  fi  
      
  #############################################################################
  # 8.3. Get ORFs
  #############################################################################
  
  "${fraggenescan}" \
  -genome="${ASSEM_DIR}_assem"/contigs.fasta \
  -out="${TMP_NAME}_orfs" \
  -complete=0 \
  -train=illumina_5 \
  -thread="${NSLOTS}" 2>&1 | handleoutput
    
  if [[ "$?" -ne "0" ]]; then
    echo "${DOMAIN}: fraggenescan ORFs identification failed"
    exit 1
  fi 
    
  #############################################################################
  # 8.4. hmmsearch
  #############################################################################
  "${hmmsearch}" \
  --cpu "${NSLOTS}" \
  --pfamtblout  "${TMP_NAME}.hout" \
  "${HMM}" "${TMP_NAME}_orfs.faa" 2>&1 | handleoutput

  if [[ "$?" -ne "0" ]]; then
    echo "${DOMAIN}: hmmsearch failed"
    exit 1
  fi
    
  L=$( egrep -n "Domain scores"  "${TMP_NAME}.hout"  | cut -f1 -d":" )
  tail -n +"${L}"  "${TMP_NAME}.hout"  | egrep -v "\#" | \
  awk 'BEGIN {OFS="\t"} {print $1,$8-1,$9 }' > "${TMP_NAME}_aa.bed"

  #############################################################################
  # 8.5. Subset seq coordinates
  #############################################################################
  "${fastafrombed}" \
  -fi "${TMP_NAME}_orfs.faa" \
  -bed "${TMP_NAME}_aa.bed" \
  -fo "${NAME}_subseqs.faa" 2>&1 | handleoutput
    
  if [[ "$?" -ne "0" ]]; then
    echo "${DOMAIN}: fastaFromBed failed"
    exit 1
  fi
    
  # check number of subsequences found
  NSEQ=$(egrep -c ">" "${NAME}_subseqs.faa")
  if [[ "${NSEQ}" -lt "5" ]]; then
    echo "Not enough ${DOMAIN} subsequences found: ${NSEQ}"
    continue
  fi
    
  #############################################################################
  # 8.6. Cluster
  #############################################################################
  
  "${SOFTWARE_DIR}"/mmseqs_runner.bash \
  --prefix "${NAME}" \
  --tmp_prefix "${TMP_NAME}" \
  --tmp_folder "${THIS_JOB_TMP_DIR}"/tmp \
  --identity "${ID}" \
  --threads "${NSLOTS}" 2>&1 | handleoutput
 
  if [[ "$?" -ne "0" ]]; then
    echo "${DOMAIN}: mmseqs_runner.bash failed"
    continue
  fi
   
  #############################################################################
  # 8.7. Create cluster table with coverage
  #############################################################################    
    if [[ "${COVERAGE}" == "t" ]]; then

      if [[ ! -f "${TMP_NAME}_sr.fasta" ]]; then

        "${SOFTWARE_DIR}"/coverage_compute.bash \
        --bed "${TMP_NAME}" \
        --input_orfs "${TMP_NAME}_orfs" \
        --reads1 "${TMP_NAME}_r1.fasta" \
        --reads2 "${TMP_NAME}_r2.fasta" \
        --tmp_prefix "${TMP_NAME}" \
	--prefix "${NAME}" \
	--clust_tsv  "${TMP_NAME}_clu".tsv \
        --nslots "${NSLOTS}" 2>&1 | handleoutput
            
      if [[ "$?" -ne "0" ]]; then
        echo "${DOMAIN}: coverage compute failed"
	exit 1
      fi
      
    else

      "${SOFTWARE_DIR}"/coverage_compute.bash \
      --bed "${TMP_NAME}" \
      --input_orfs "${TMP_NAME}_orfs" \
      --reads1 "${TMP_NAME}_r1.fasta" \
      --reads2 "${TMP_NAME}_r2.fasta" \
      --single_reads "${TMP_NAME}_sr.fasta" \
      --tmp_prefix "${TMP_NAME}" \
      --prefix "${NAME}" \
      --clust_tsv  "${TMP_NAME}_clu".tsv \
      --nslots "${NSLOTS}" 2>&1 | handleoutput
            
      if [[ "$?" -ne "0" ]]; then
        echo "${DOMAIN}: coverage compute failed"
        exit 1
      fi
    fi

  else
    
    ###########################################################################
    # 8.8. Create cluster table with no coverage
    ###########################################################################
     
    "${SOFTWARE_DIR}"/cluster_seqs_with_no_cov.bash \
    --clust_tsv  "${TMP_NAME}_clu".tsv \
    --prefix "${NAME}"
     
    if [[ "$?" -ne "0" ]]; then
      echo "${DOMAIN}: cluster_seqs_with_no_cov.bash failed"
      exit 1
    fi
  fi  
    
  #############################################################################
  # 8.9. Compute diversity
  #############################################################################
    
  "${SOFTWARE_DIR}"/model_div_plot.bash \
  --abund_table "${NAME}_cluster2abund".tsv \
  --font_size "${FONT_SIZE}" \
  --outdir "${THIS_JOB_TMP_DIR}" \
  --prefix "${DOMAIN}" \
  --plot_width  "${PLOT_WIDTH}" \
  --plot_height "${PLOT_HEIGHT}" \
  --num_iter "${NUM_ITER}" \
  --plot_model_violin t 2>&1  | handleoutput
    
  if [[ "$?" -ne "0" ]]; then
    echo "${DOMAIN}: diversity model failed"
    exit 1
  fi  
  
  #############################################################################
  # 8.10. Blast search
  ############################################################################# 
  
  if [[ "${BLAST}" == "t" ]]; then
    "${SOFTWARE_DIR}"/blast_runner.bash \
    --domain "${DOMAIN}" \
    --input "${NAME}_subseqs.faa" \
    --output "${NAME}_subseqs.blout" 2>&1 | handleoutput
      
    if [[ "$?" -ne "0" ]]; then
      echo "${DOMAIN}: blast failed"
      exit 1
    fi
  fi
  
  #############################################################################
  # 8.11. Tree placement and drawing
  #############################################################################
  
  if [[ "${PLOT_TREE}" == "t" ]]; then
    
    if [[ ! -d "${REF_PKG_DIR}/${DOMAIN}.refpkg" ]]; then
      echo echo "No refpkg for ${DOMAIN}. Skipping tree placement ..."
      continue
    fi  
  
    if [[ "${ONLY_REP}" == "t" ]]; then

      "${SOFTWARE_DIR}"/extract_only_rep_seqs.bash \
      --clust2abund_tsv  "${NAME}_cluster2abund".tsv \
      --prefix "${NAME}" \
      --tmp_prefix "${TMP_NAME}"  2>&1 | handleoutput
     
      if [[ "$?" -ne "0" ]]; then
        echo "${DOMAIN}: extract_only_rep_seqs.bash failed"
        exit 1
      fi

      TREE_INPUT_SEQ="${TMP_NAME}_onlyrep_subseqs.faa"
      TREE_CLUST_ABUND="${TMP_NAME}_onlyrep_cluster2abund.tsv"

    else

      TREE_INPUT_SEQ="${NAME}_subseqs.faa"
      TREE_CLUST_ABUND="${NAME}_cluster2abund.tsv"

    fi
    
    "${SOFTWARE_DIR}"/tree_pplacer.bash \
    --domain "${DOMAIN}" \
    --input "${TREE_INPUT_SEQ}" \
    --nslots "${NSLOTS}" \
    --outdir "${THIS_JOB_TMP_DIR}" 2>&1 | handleoutput
      
    if [[ "$?" -ne "0" ]]; then
      echo "${DOMAIN}: tree placing failed"
      exit 1
    fi

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
done;

###############################################################################
# 9. Clean
###############################################################################
    
rm -r "${THIS_JOB_TMP_DIR}"/tmp*
rm "${THIS_JOB_TMP_DIR}"/*.headers
rm -r "${DOM_ALL_TMP}"
rm -r "${ALL_DOMAINS}"

if [[ -f "${R1_REDU}" ]]; then
  rm -r "${R1_REDU}"
  rm -r "${R2_REDU}"
fi
  
if [[ -f "${SR_REDU}" ]]; then
 rm -r "${SR_REDU}"
fi

###############################################################################
# 10. Move output for export
###############################################################################

rsync -a --delete "${THIS_JOB_TMP_DIR}" "${OUTDIR_LOCAL}"
