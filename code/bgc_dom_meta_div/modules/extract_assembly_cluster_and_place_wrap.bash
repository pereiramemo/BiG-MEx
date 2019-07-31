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
  --env=)   # Handle the case of an empty --file=
  printf 'ERROR: "--env" requires a non-empty option argument.\n' >&2
  exit 1
  ;;
############
  --)      # End of all options.
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
# 3. Load environment
###############################################################################

source "${ENV}"

###############################################################################
# 4. Load handleoutput
###############################################################################

source /bioinfo/software/handleoutput 

###############################################################################
# 5. Define output vars
###############################################################################

# define domain specific variables
TMP_NAME="${THIS_JOB_TMP_DIR}/tmp_${DOMAIN}"
NAME="${THIS_JOB_TMP_DIR}/${DOMAIN}"
HMM="${HMM_DIR}/${DOMAIN}.hmm"  

###############################################################################
# 6. Extract headers
###############################################################################

egrep -w "${DOMAIN}" "${INPUT_SUBSET}" | cut -f2 -d"," | sort | uniq > \
"${NAME}.headers"
  
############################################################################### 
# 7. Check number of sequences found
############################################################################### 

NSEQ=$(wc -l "${NAME}.headers" | cut -f1 -d" ")

if [[ "${NSEQ}" -eq "0" ]]; then
  echo "Warning. ${DOMAIN}: no sequences found"
  exit 0
fi

###############################################################################
# 8. Check number of domains to analyze (rename if ndom == 1) and get seqs
###############################################################################

NDOM=$(wc -l "${DOM_ALL_TMP}" | cut -f1 -d" ")

if [[ "${NDOM}" == 1 ]]; then
      
  if [[ -f "${R1_REDU}" ]] && [[ -f "${R2_REDU}" ]]; then
    mv "${R1_REDU}" "${TMP_NAME}_r1.fasta" 
    mv "${R2_REDU}" "${TMP_NAME}_r2.fasta" 
  fi
      
  if [[ -f "${SR_REDU}" ]]; then
    mv "${SR_REDU}" "${TMP_NAME}_sr.fasta" 
  fi
    
else

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

###############################################################################
# 9. Assemble
###############################################################################
    
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

###############################################################################
# 10. Get ORFs
###############################################################################

"${fraggenescan}" \
-genome="${ASSEM_DIR}_assem/contigs.fasta" \
-out="${TMP_NAME}_orfs" \
-complete=0 \
-train=illumina_5 \
-thread="${NSLOTS}" 2>&1 | handleoutput
   
if [[ "$?" -ne "0" ]]; then
  echo "${DOMAIN}: fraggenescan failed"
  exit 1
fi 
    
#############################################################################
# 11. hmmsearch
#############################################################################

"${hmmsearch}" \
--cpu "${NSLOTS}" \
--pfamtblout  "${TMP_NAME}.hout" \
"${HMM}" "${TMP_NAME}_orfs.faa" 2>&1 | handleoutput

if [[ "$?" -ne "0" ]]; then
  echo "${DOMAIN}: hmmsearch failed"
  exit 1
fi
    
# Note: --pfamtblout is a "succinct  tabular  (space-delimited)  file  
# summarizing  the  per-target output, with one data line per homologous target 
# model found".

###############################################################################
# 12. Subset seq coordinates
###############################################################################

L=$(egrep -n "Domain scores"  "${TMP_NAME}.hout"  | cut -f1 -d":")
tail -n +"${L}"  "${TMP_NAME}.hout"  | egrep -v "\#" | \
awk 'BEGIN {OFS="\t"} {print $1,$8-1,$9}' > "${TMP_NAME}_aa.bed"
# Note: coordinates are formatted to be used with bedools: zero-based

"${fastafrombed}" \
-fi "${TMP_NAME}_orfs.faa" \
-bed "${TMP_NAME}_aa.bed" \
-fo "${NAME}_dom_seqs.faa" 2>&1 | handleoutput
    
if [[ "$?" -ne "0" ]]; then
  echo "${DOMAIN}: fastaFromBed failed"
  exit 1
fi
 
############################################################################### 
# 13. Check number of domain sequences found
###############################################################################

NSEQ=$(egrep -c ">" "${NAME}_dom_seqs.faa")

if [[ "${NSEQ}" -lt "5" ]]; then
  echo "Warning. ${DOMAIN}: not enough sequences found. Only ${NSEQ} sequences."
  exit 0
fi
  
###############################################################################
# 14. Cluster
###############################################################################
  
"${SOFTWARE_DIR}"/mmseqs_runner.bash \
--env "${ENV}" \
--prefix "${NAME}" \
--tmp_prefix "${TMP_NAME}" \
--tmp_folder "${THIS_JOB_TMP_DIR}"/tmp  2>&1 | handleoutput
 
if [[ "$?" -ne "0" ]]; then
  echo "${DOMAIN}: mmseqs_runner.bash failed"
  exit 1
fi
     
###############################################################################
# 15. Create cluster table with or without coverage
############################################################################### 

if [[ "${COVERAGE}" == "t" ]]; then

    "${SOFTWARE_DIR}"/coverage_compute.bash \
    --env "${ENV}" \
    --tmp_prefix "${TMP_NAME}" \
	--prefix "${NAME}" 2>&1 | handleoutput
            
    if [[ "$?" -ne "0" ]]; then
      echo "${DOMAIN}: coverage_compute.bash failed"
	  exit 1
    fi
     
else
     
  "${SOFTWARE_DIR}"/create_cluster2abund_table.bash \
  --env "${ENV}" \
  --prefix "${NAME}" \
  --tmp_prefix "${TMP_NAME}" 2>&1 | handleoutput 
     
  if [[ "$?" -ne "0" ]]; then
    echo "${DOMAIN}: cluster_seqs_with_no_cov.bash failed"
    exit 1
  fi
fi 

###############################################################################
# 15. Compute diversity
###############################################################################
    
"${SOFTWARE_DIR}"/model_div_plot.bash \
--domain "${DOMAIN}" \
--env "${ENV}" \
--prefix "${NAME}" \
--plot_model_violin t 2>&1  | handleoutput
    
if [[ "$?" -ne "0" ]]; then
  echo "${DOMAIN}: model_div_plot.bash failed"
  exit 1
fi 

###############################################################################
# 16. Blast search
############################################################################### 
 
 if [[ "${BLAST}" == "t" ]]; then
  "${SOFTWARE_DIR}"/blast_runner.bash \
  --env "${ENV}" \
  --domain "${DOMAIN}" \
  --prefix "${NAME}" 2>&1 | handleoutput
      
  if [[ "$?" -ne "0" ]]; then
    echo "${DOMAIN}: blast_runner.bash failed"
    exit 1
  fi
fi

###############################################################################
# 17. Tree placement and drawing
###############################################################################
  
if [[ "${PLOT_TREE}" == "t" ]]; then
    
  if [[ ! -d "${REF_PKG_DIR}/${DOMAIN}.refpkg" ]]; then
    echo "Warning. No refpkg for ${DOMAIN}. Skipping tree placement ..."
    exit 0
  fi
  
  if [[ "${ONLY_REP}" == "t" ]]; then
    "${SOFTWARE_DIR}"/extract_only_rep_seqs.bash \
    --env "${ENV}" \
    --prefix "${NAME}" \
    --tmp_prefix "${TMP_NAME}"  2>&1 | handleoutput
    
    if [[ "$?" -ne "0" ]]; then
      echo "${DOMAIN}: extract_only_rep_seqs.bash failed"
      exit 1
    fi

    # to be used in tree_pplacer.bash
    TREE_INPUT_SEQ="${TMP_NAME}_onlyrep_dom_seqs.faa"
    # to be used in tree_drawer.bash 
    TREE_CLUST_ABUND="${TMP_NAME}_onlyrep_cluster2abund.tsv"

  else

    # to be used in tree_pplacer.bash
    TREE_INPUT_SEQ="${NAME}_dom_seqs.faa" 
    # to be used in tree_drawer.bash 
    TREE_CLUST_ABUND="${NAME}_cluster2abund.tsv" 

  fi
    
  "${SOFTWARE_DIR}"/tree_pplacer.bash \
  --domain "${DOMAIN}" \
  --env "${ENV}" \
  --input "${TREE_INPUT_SEQ}" 2>&1 | handleoutput
     
  if [[ "$?" -ne "0" ]]; then
    echo "${DOMAIN}: tree_pplacer.bash failed"
    exit 1
  fi
 
  "${SOFTWARE_DIR}"/tree_drawer.bash \
  --domain "${DOMAIN}" \
  --env "${ENV}" \
  --abund_table "${TREE_CLUST_ABUND}" 2>&1 | handleoutput
     
  if [[ "$?" -ne "0" ]]; then
    echo "${DOMAIN}: tree_drawer.bash failed"
    exit 1
  fi
fi
