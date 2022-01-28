#!/bin/bash

set -o pipefail

###############################################################################
# 1. Load general configuration
###############################################################################

source "/software/conf"

if [[ "$?" -ne "0" ]]; then
  echo "${DOMAIN}: Sourcing /software/conf failed"
  exit 1
fi

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
  DOMAIN="${1#*=}"
  ;;
  --domain=)
  printf "ERROR: --domain requires a non-empty argument\n"  >&2
  exit 1
  ;;
#############
  --env) 
  if [[ -n "${2}" ]]; then
    ENV="${2}"
    shift
  fi
  ;;
  --env=?*)
  ENV=${1#*=} 
  ;;
  --env=)
  printf 'ERROR: "--env" requires a non-empty argument\n' >&2
  exit 1
  ;;
############
  --)      
  shift
  break
  ;;
  -?*)
  printf 'WARN: Unknown argument (ignored): %s\n' "$1" >&2
  ;;
  *)
  break
  esac
  shift
done

###############################################################################
# 3. Load environment
###############################################################################

source "${ENV}"

if [[ "$?" -ne "0" ]]; then
  echo "${DOMAIN}: Sourcing ${ENV} failed"
  exit 1
fi  

###############################################################################
# 4. Load handleoutput
###############################################################################

source "/software/handleoutput_functions"

if [[ "$?" -ne "0" ]]; then
  echo "${DOMAIN}: Sourcing /software/handleoutput_functions failed"
  exit 1
fi  

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

if [[ "$?" -ne "0" ]]; then
  "${DOMAIN}: Generating ${NAME}.headers failed"
  exit 1
fi  
  
############################################################################### 
# 7. Check number of sequences found
############################################################################### 

NSEQ=$(wc -l "${NAME}.headers" | cut -f1 -d" ")

if [[ "$?" -ne "0" ]]; then
  "${DOMAIN}: Generating ${NSEQ} variable failed"
  exit 1
fi  

if [[ "${NSEQ}" -lt "5" ]]; then
  echo "Warning: not enough ${DOMAIN} sequences annotated (${NSEQ}). ${DOMAIN} will not be analyzed"
  exit 0
fi

###############################################################################
# 8. Check number of domains to analyze (rename if ndom == 1) and get seqs
###############################################################################

NDOM=$(wc -l "${DOM_ALL_TMP}" | cut -f1 -d" ")

if [[ "$?" -ne "0" ]]; then
  echo "${DOMAIN}: Generating ${NDOM} variable failed"
  exit 1
fi

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
    overwrite=t 2>&1 | handleoutput_all
        
    if [[ "$?" -ne "0" ]]; then
      echo "${DOMAIN}: filterbyname failed (R1_REDU and R2_REDU)"
      exit 1
    fi
  fi  

  if [[ -f "${SR_REDU}" ]]; then
    "${filterbyname}" \
    in="${SR_REDU}" \
    out="${TMP_NAME}_sr.fasta" \
    names="${NAME}.headers" \
    include=t \
    overwrite=t 2>&1 | handleoutput_all

    if [[ "$?" -ne "0" ]]; then
      echo "${DOMAIN}: filterbyname failed (SR_REDU)"
      exit 1
    fi
      
  fi
fi

###############################################################################
# 9. Assemble
###############################################################################
    
echo "Assembling ${DOMAIN} sequences ..." | handleoutput    
    
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
  -o "${ASSEM_DIR}_assem" 2>&1 | handleoutput_all
    
  if [[ "$?" -ne "0" ]]; then
    echo "${DOMAIN}: metaspades assembly failed (without SR file)"
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
  -o "${ASSEM_DIR}_assem" 2>&1 | handleoutput_all
  
  if [[ "$?" -ne "0" ]]; then
    echo "${DOMAIN}: metaspades assembly failed (with SR file)"
    exit 1
  fi
fi  

###############################################################################
# 10. Get ORFs
###############################################################################

echo "Identifying ORF sequences ..." | handleoutput    

"${fraggenescan}" \
-genome="${ASSEM_DIR}_assem/contigs.fasta" \
-out="${TMP_NAME}_orfs" \
-complete=0 \
-train=illumina_5 \
-thread="${NSLOTS}" 2>&1 | handleoutput_all
   
if [[ "$?" -ne "0" ]]; then
  echo "${DOMAIN}: fraggenescan failed"
  exit 1
fi 
    
#############################################################################
# 11. hmmsearch
#############################################################################

echo "Identifying domain coordinates withing ORF sequences ..." | handleoutput    

"${hmmsearch}" \
--cpu "${NSLOTS}" \
--pfamtblout  "${TMP_NAME}.hout" \
"${HMM}" "${TMP_NAME}_orfs.faa" 2>&1 | handleoutput_all

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

echo "Extracting ${DOMAIN} sequences" | handleoutput

L=$(egrep -n "Domain scores"  "${TMP_NAME}.hout"  | cut -f1 -d":")
tail -n +"${L}"  "${TMP_NAME}.hout"  | egrep -v "\#" | \
awk 'BEGIN {OFS="\t"} {print $1,$8-1,$9}' > "${TMP_NAME}_aa.bed"

if [[ "$?" -ne "0" ]]; then
  echo "${DOMAIN}: Generating ${TMP_NAME}_aa.bed failed"
  exit 1
fi

# Note: coordinates are formatted to be used with bedools: zero-based

"${fastafrombed}" \
-fi "${TMP_NAME}_orfs.faa" \
-bed "${TMP_NAME}_aa.bed" \
-fo "${NAME}_dom_seqs.faa" 2>&1 | handleoutput_all
    
if [[ "$?" -ne "0" ]]; then
  echo "${DOMAIN}: fastaFromBed failed"
  exit 1
fi
 
############################################################################### 
# 13. Check number of domain sequences found
###############################################################################

NSEQ=$(egrep -c ">" "${NAME}_dom_seqs.faa")

if [[ "$?" -ne "0" ]]; then
  echo "${DOMAIN}: Generating ${NSEQ} variable failed"
  exit 1
fi

if [[ "${NSEQ}" -lt "5" ]]; then
  echo "Warning. ${DOMAIN}: not enough sequences assembled (${NSEQ}). ${DOMAIN} will not be analyzed"
  exit 0
fi
  
###############################################################################
# 14. Cluster
###############################################################################

echo "Clustering ${DOMAIN} sequences ..." | handleoutput

"${SOFTWARE_DIR}"/1-mmseqs_runner.bash \
--env "${ENV}" \
--prefix "${NAME}" \
--tmp_prefix "${TMP_NAME}" \
--tmp_folder "${THIS_JOB_TMP_DIR}"/tmp 2>&1 | handleoutput_all
 
if [[ "$?" -ne "0" ]]; then
  echo "${DOMAIN}: Clustering sequences failed (i.e., 1-mmseqs_runner.bash)"
  exit 1
fi
     
###############################################################################
# 15. Create cluster table with or without coverage
############################################################################### 

echo "Creating ${DOMAIN} OPU coverage table" | handleoutput

if [[ "${COVERAGE}" == "t" ]]; then

    "${SOFTWARE_DIR}"/2-coverage_compute.bash \
    --env "${ENV}" \
    --tmp_prefix "${TMP_NAME}" \
	--prefix "${NAME}" 2>&1 | handleoutput_all
            
    if [[ "$?" -ne "0" ]]; then
      echo "${DOMAIN}: Creating cluster table failed (i.e., 2-coverage_compute.bash)"
	  exit 1
    fi
     
else
     
  "${SOFTWARE_DIR}"/3-create_cluster2abund_table.bash \
  --env "${ENV}" \
  --prefix "${NAME}" \
  --tmp_prefix "${TMP_NAME}" 2>&1 | handleoutput_all
     
  if [[ "$?" -ne "0" ]]; then
    "${DOMAIN}: Creating cluster table failed (i.e., 3-cluster_seqs_with_no_cov.bash)"
    exit 1
  fi
fi 

###############################################################################
# 16. Compute diversity
###############################################################################

echo "Estimating ${DOMAIN} OPU Shannon diversity distribution" | handleoutput

"${SOFTWARE_DIR}"/4-model_div_plot.bash \
--domain "${DOMAIN}" \
--env "${ENV}" \
--prefix "${NAME}" 2>&1 | handleoutput_all
    
if [[ "$?" -ne "0" ]]; then
  echo "${DOMAIN}: Computing OPU diversity failed (i.e., 4-model_div_plot.bash)"
  exit 1
fi 

###############################################################################
# 17. Blast search
############################################################################### 
 
if [[ "${BLAST}" == "t" ]]; then

  if [[ ! -f "${REF_SEQ_DIR}/${DOMAIN}.faa" ]]; then
  
    echo "Warning. No blastdb for ${DOMAIN}. Skipping blast search."
    echo "See https://raw.githubusercontent.com/pereiramemo/BiG-MEx/master/data/supplementary_file2.tsv for supported domains"
    
  else    

    echo "Running blastp search ..." | handleoutput
  
    "${SOFTWARE_DIR}"/5-blast_runner.bash \
    --env "${ENV}" \
    --domain "${DOMAIN}" \
    --prefix "${NAME}" 2>&1 | handleoutput_all
      
    if [[ "$?" -ne "0" ]]; then
      echo "${DOMAIN}: blast search failed (i.e., 5-blast_runner.bash)"
      exit 1
    fi
    
  fi
fi

###############################################################################
# 18. Tree placement and drawing
###############################################################################
  
if [[ "${PLOT_TREE}" == "t" ]]; then

  echo "Placing ${DOMAIN} sequences onto reference tree and generating figure ..." | handleoutput    
    
  if [[ ! -d "${REF_PKG_DIR}/${DOMAIN}.refpkg" ]]; then
  
    echo "Warning. No refpkg for ${DOMAIN}. Placement onto reference tree cannot be performed"
    echo "See https://raw.githubusercontent.com/pereiramemo/BiG-MEx/master/data/supplementary_file2.tsv for supported domains"

  else
  
    if [[ "${ONLY_REP}" == "t" ]]; then
      "${SOFTWARE_DIR}"/6-extract_only_rep_seqs.bash \
      --env "${ENV}" \
      --prefix "${NAME}" \
      --tmp_prefix "${TMP_NAME}" 2>&1 | handleoutput_all
      
      if [[ "$?" -ne "0" ]]; then
        echo "${DOMAIN}: Extracting representative sequences failed (i.e., 6-extract_only_rep_seqs.bash)"
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
    
    "${SOFTWARE_DIR}"/7-tree_pplacer.bash \
    --domain "${DOMAIN}" \
    --env "${ENV}" \
    --input "${TREE_INPUT_SEQ}" 2>&1 | handleoutput_all
     
    if [[ "$?" -ne "0" ]]; then
      echo "${DOMAIN}: Placing sequences onto reference tree failed (i.e., 7-tree_pplacer.bash)"
      exit 1
    fi
 
    "${SOFTWARE_DIR}"/8-tree_drawer.bash \
    --domain "${DOMAIN}" \
    --env "${ENV}" \
    --abund_table "${TREE_CLUST_ABUND}" 2>&1 | handleoutput_all
     
    if [[ "$?" -ne "0" ]]; then
      echo "${DOMAIN}: Creating tree figure failed (i.e., 8-tree_drawer.bash)"
      exit 1
    fi
  fi
fi
