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
#############
  --prefix)
  if [[ -n "${2}" ]]; then
    NAME="${2}"
    shift
  fi
  ;;
  --prefix=?*)
  NAME=${1#*=}
  ;;
  --prefix=)
  printf 'ERROR: "--prefix" requires a non-empty argument\n' >&2
  exit 1
  ;;    
#############
  --tmp_prefix)
  if [[ -n "${2}" ]]; then
    TMP_NAME="${2}"
    shift
  fi
  ;;
  --tmp_prefix=?*)
  TMP_NAME=${1#*=}
  ;;
  --tmp_prefix=)
  printf 'ERROR: "--tmp_prefix" requires a non-empty argument\n' >&2
  exit 1
  ;;
#############
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
# 3. Load env
###############################################################################

source "${ENV}"

if [[ $? -ne "0" ]]; then
  echo "${DOMAIN}: Sourcing ${ENV} failed"
  exit 1
fi 

###############################################################################
# 4. Convert bed file coordinates
###############################################################################

awk 'OFS="\t" {print $1,$2*3,$3*3 }' \
"${TMP_NAME}_aa.bed" > "${TMP_NAME}_nuc.bed"

if [[ "$?" -ne "0" ]]; then
  echo "${DOMAIN}: Generating ${TMP_NAME}_nuc.bed failed"
  exit 1
fi  

###############################################################################
# 5. Extract sequences
###############################################################################

"${fastafrombed}" \
  -fi "${TMP_NAME}_orfs.ffn" \
  -bed "${TMP_NAME}_nuc.bed"  \
  -fo "${NAME}_dom_seqs.ffn"

if [[ "$?" -ne "0" ]]; then
  echo "${DOMAIN}: fastaFromBed failed"
  exit 1
fi

###############################################################################
# 6. Map
###############################################################################

"${bwa}" index -p "${TMP_NAME}" "${NAME}_dom_seqs.ffn"

if [[ "$?" -ne "0" ]]; then
  echo "${DOMAIN}: bwa index failed"
  exit 1
fi

"${bwa}" mem -M -t "${NSLOTS}" "${TMP_NAME}" \
"${TMP_NAME}_r1.fasta" "${TMP_NAME}_r2.fasta" > "${TMP_NAME}-PE.sam"

if [[ "$?" -ne "0" ]]; then
  echo "${DOMAIN}: bwa mem failed (R1 and R2)"
  exit 1
fi

if [[ -f "${TMP_NAME}_sr.fasta" ]]; then
  "${bwa}" mem -M -t "${NSLOTS}" "${TMP_NAME}" \
  "${TMP_NAME}_sr.fasta" > "${TMP_NAME}-SE.sam"
  
  if [[ "$?" -ne "0" ]]; then
    echo "${DOMAIN}: bwa mem failed (SR)"
    exit 1
  fi

fi
  
###############################################################################
# 7. Convert to bam
###############################################################################

"${samtools}" view -@ "${NSLOTS}" -q 10 -F 4 -b \
"${TMP_NAME}-PE.sam" > "${TMP_NAME}-PE.bam"

if [[ "$?" -ne "0" ]]; then
  echo "${DOMAIN}: samtools convert bam failed (PE)"
  exit 1
fi

if [[ -f "${TMP_NAME}-SE.sam" ]]; then
  "${samtools}" view -@ "${NSLOTS}" -q 10 -F 4 -b \
  "${TMP_NAME}-SE.sam" > "${TMP_NAME}-SE.bam"
  
  if [[ "$?" -ne "0" ]]; then
    echo "${DOMAIN}: samtools convert to bam failed (SE)"
    exit 1
  fi
  
fi

###############################################################################
# 8. Sort
###############################################################################

"${samtools}" sort  -@ "${NSLOTS}" \
"${TMP_NAME}-PE.bam" > "${TMP_NAME}-PE.sorted.bam"

if [[ "$?" -ne "0" ]]; then
  echo "${DOMAIN}: samtools sort failed (PE)"
  exit 1
fi

if [[ -f "${TMP_NAME}-SE.bam" ]]; then

  "${samtools}" sort  -@ "${NSLOTS}" \
  "${TMP_NAME}-SE.sam" > "${TMP_NAME}-SE.sorted.bam"
  
  if [[ "$?" -ne "0" ]]; then
    echo "${DOMAIN}: samtools sort failed (SE)"
    exit 1
  fi
  
fi

###############################################################################
# 9. Merge
###############################################################################

if [[ -f "${TMP_NAME}_sr.fasta" ]]; then

  "${samtools}" merge \
  "${TMP_NAME}.bam" \
  "${TMP_NAME}-PE.sorted.bam" \
  "${TMP_NAME}-SE.sorted.bam"
  
  if [[ "$?" -ne "0" ]]; then
    echo "${DOMAIN}: samtools merge failed"
    exit 1
  fi
   
  "${samtools}" sort -@ "${NSLOTS}" \
  "${TMP_NAME}.bam" > "${TMP_NAME}.sorted.bam"
  
  if [[ "$?" -ne "0" ]]; then
    echo "${DOMAIN}: samtools sort failed"
    exit 1
  fi
   
else

  mv "${TMP_NAME}-PE.sorted.bam" "${TMP_NAME}.sorted.bam"
  
  if [[ "$?" -ne "0" ]]; then
    echo "${DOMAIN}: Naming ${TMP_NAME}.sorted.bam failed"
    exit 1
  fi
  
fi

###############################################################################
# 10. Index merged data
###############################################################################

"${samtools}" index -@ "${NSLOTS}" "${TMP_NAME}.sorted.bam"

if [[ "$?" -ne "0" ]]; then
  echo "${DOMAIN}: samtools index failed"
  exit 1
fi

###############################################################################
# 11. Remove duplicates
###############################################################################

java -jar "${picard}" MarkDuplicates \
        INPUT="${TMP_NAME}.sorted.bam" \
        OUTPUT="${TMP_NAME}.sorted.markdup.bam" \
        METRICS_FILE="${TMP_NAME}.sorted.markdup.metrics.txt" \
        REMOVE_DUPLICATES=TRUE \
        ASSUME_SORTED=TRUE \
        MAX_FILE_HANDLES_FOR_READ_ENDS_MAP=900

if [[ "$?" -ne "0" ]]; then
  echo "${DOMAIN}: picard MarkDuplicates failed"
  exit 1
fi        
        
###############################################################################
# 12. Compute coverage
###############################################################################

"${genomecoveragebed}" \
-d -ibam "${TMP_NAME}.sorted.markdup.bam" > "${TMP_NAME}-coverage.list"

if [[ $? -ne "0" ]]; then
  echo "${DOMAIN}: genomecoveragebed failed"
  exit 1
fi 

awk  '{ 
  
  # depth
  array_id2depth[$1] = array_id2depth[$1] + $3
  
  #breath
  if ($3 != 0) {
    array_id2covered[$1] = array_id2covered[$1] + 1 
  }
  
  # length
  array_id2length[$1]=$2
  
} END {

  for (i in array_id2depth) {
  
    coverage=array_id2depth[i]/array_id2length[i]
    breath=array_id2covered[i]/array_id2length[i]
    n=array_id2length[i]
    c=array_id2covered[i]
    
    printf "%s\t%.4f\t%.4f\t%s\t%s\n", i,coverage,breath,n,c;
  
  }  
}' "${TMP_NAME}-coverage.list" > "${TMP_NAME}-coverage.table"

if [[ "$?" -ne "0" ]]; then
  echo "${DOMAIN}: Generating ${TMP_NAME}-coverage.table failed"
  exit 1
fi 

###############################################################################
# 13. Cross tables
###############################################################################

awk '{  

  if (NR == FNR) {
  
    # convert prot to nuc coords in id
    split($1,id,":");
    split(id[2],coords,"-");
    id_aa=id[1]":"coords[1]/3"-"coords[2]/3
    
    # create id to abundance array
    array_id2abund[id_aa]=$2;
    
    next;
  }
 
  id_repseq = $1
  id_aa = $2
   
  # cluster count for each repseq
  if (array_cluster_count[id_repseq] == "") {
    array_cluster_count[id_repseq] = n++ 
  }
  
  array_id2cluster[id_aa] = array_cluster_count[id_repseq]
  array_id_aa2repseq[id_aa] = id_repseq
  
  # unusual case: no abundance assigned above to dom_seq
  if (array_id2abund[id_aa] == "") {
    array_id2abund[id_aa] = 0;
  }
  
} END {

  for (i in array_id2cluster) {
  
    cluster = "cluster_"array_id2cluster[i]
    abund = array_id2abund[i]
    
    # classify as repseq or not
    if (array_id_aa2repseq[i] == i) {
      printf "%s\t%s\t%s\n", cluster, i"_repseq", abund 
    } else {
      printf "%s\t%s\t%s\n", cluster, i, abund 
    }
  }
}' "${TMP_NAME}-coverage.table" "${TMP_NAME}_clu.tsv" > \
   "${NAME}_cluster2abund.tsv"

if [[ "$?" -ne "0" ]]; then
  echo "${DOMAIN}: Generating ${NAME}_cluster2abund.tsv failed"
  exit 1
fi 
