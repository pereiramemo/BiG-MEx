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
#############
  --prefix)     # Takes an option argument, ensuring it has been specified.
  if [[ -n "${2}" ]]; then
    NAME="${2}"
    shift
  else
    printf 'ERROR: "--prefix" requires a non-empty option argument.\n' >&2
    exit 1
  fi
  ;;
  --prefix=?*)
  NAME=${1#*=}     # Delete everything up to "=" and assign the remainder.
  ;;
  --prefix=)       # Handle the case of an empty --file=
  printf 'ERROR: "--prefix" requires a non-empty option argument.\n' >&2
  exit 1
  ;;    
#############
  --tmp_prefix) # Takes an option argument, ensuring it has been specified.
  if [[ -n "${2}" ]]; then
    TMP_NAME="${2}"
    shift
  else
    printf 'ERROR: "--tmp_prefix" requires a non-empty option argument.\n' >&2
    exit 1
  fi
  ;;
  --tmp_prefix=?*)
  TMP_NAME=${1#*=} # Delete everything up to "=" and assign the remainder.
  ;;
  --tmp_prefix=)   # Handle the case of an empty --file=
  printf 'ERROR: "--tmp_prefix" requires a non-empty option argument.\n' >&2
  exit 1
  ;;
#############
  --)   # End of all options.
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
# 3. Load env
###############################################################################

source "${ENV}"

###############################################################################
# 4. Convert bed file coordinates
###############################################################################

awk 'OFS="\t" {print $1,$2*3,$3*3 }' \
"${TMP_NAME}_aa.bed" > "${TMP_NAME}_nuc.bed"

###############################################################################
# 5. Extract sequences
###############################################################################

"${fastafrombed}" \
  -fi "${TMP_NAME}_orfs.ffn" \
  -bed "${TMP_NAME}_nuc.bed"  \
  -fo "${NAME}_dom_seqs.ffn"

###############################################################################
# 6. Map
###############################################################################

"${bwa}" index -p "${TMP_NAME}" "${NAME}_dom_seqs.ffn"

"${bwa}" mem -M -t "${NSLOTS}" "${TMP_NAME}" \
"${TMP_NAME}_r1.fasta" "${TMP_NAME}_r2.fasta" > "${TMP_NAME}-PE.sam"

if [[ -f "${TMP_NAME}_sr.fasta" ]]; then
  "${bwa}" mem -M -t "${NSLOTS}" "${TMP_NAME}" \
  "${TMP_NAME}_sr.fasta" > "${TMP_NAME}-SE.sam"
fi
  
###############################################################################
# 7. Convert to bam
###############################################################################

"${samtools}" view -@ "${NSLOTS}" -q 10 -F 4 -b \
"${TMP_NAME}-PE.sam" > "${TMP_NAME}-PE.bam"

if [[ -f "${TMP_NAME}-SE.sam" ]]; then
  "${samtools}" view -@ "${NSLOTS}" -q 10 -F 4 -b \
  "${TMP_NAME}-SE.sam" > "${TMP_NAME}-SE.bam"
fi

###############################################################################
# 8. Sort
###############################################################################

"${samtools}" sort  -@ "${NSLOTS}" \
"${TMP_NAME}-PE.bam" > "${TMP_NAME}-PE.sorted.bam"

if [[ -f "${TMP_NAME}-SE.bam" ]]; then
  "${samtools}" sort  -@ "${NSLOTS}" \
  "${TMP_NAME}-SE.sam" > "${TMP_NAME}-SE.sorted.bam"
fi

###############################################################################
# 9. Merge
###############################################################################

if [[ -f "${TMP_NAME}_sr.fasta" ]]; then

  "${samtools}" merge \
  "${TMP_NAME}.bam" \
  "${TMP_NAME}-PE.sorted.bam" \
  "${TMP_NAME}-SE.sorted.bam"
   
  "${samtools}" sort -@ "${NSLOTS}" \
  "${TMP_NAME}.bam"  > "${TMP_NAME}.sorted.bam"

else
  mv "${TMP_NAME}-PE.sorted.bam" "${TMP_NAME}.sorted.bam"
fi

###############################################################################
# 10. Sort merged data
###############################################################################

"${samtools}" index -@ "${NSLOTS}" "${TMP_NAME}.sorted.bam"

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

###############################################################################
# 12. Compute coverage
###############################################################################

"${genomecoveragebed}" \
-d -ibam "${TMP_NAME}.sorted.markdup.bam" > "${TMP_NAME}-coverage.list"

awk  '{ if ( Gp==$1 ) {
      Gp=$1;
      tot = $3 + tot;
      n = n + 1;

      if ($3!=0) {
        C = C + 1
        }

      } else {

      if (NR >=2 ) {
        mean= tot/n ;
        breadth=C/n;
        print Gp, mean, breadth, n ,C;
        tot="";
        mean="";
        breadth="";
        n="";
        C="";
        Gp=$1;
        }

        if (NR == 1 ) {
          Gp=$1;
          tot = $3 + tot;
          n = n + 1;
          if ($3!=0) { C = C + 1 }
        }
      }
    } END {
           mean= tot/n ;
           breadth=C/n;
           print Gp, mean, breadth, n ,C
           };' \
"${TMP_NAME}-coverage.list" > "${TMP_NAME}-coverage.table"


###############################################################################
# 13. Cross tables
###############################################################################

awk 'BEGIN {OFS="\t"} {  
  if (NR == FNR ) {
    split($1,id,":");
    split(id[2],coords,"-");
    id_aa=id[1]":"coords[1]/3"-"coords[2]/3
    array_id2abund[id_aa]=$2;
    next;
  }
  
  if (cluster_id != $1) {
    cluster_id = $1;
    cluster = "cluster_"n++;
    id_aa = $2
    repseq = 1
  } else {
    id_aa = $2
    repseq = 0 
  }
  
  array_id2cluster[id_aa] = cluster
  
  if ( array_id2abund[id_aa] == "" ) {
    array_id2abund[id_aa] = 0;
  }
  
  if ( repseq == 1 ) {
    printf "%s\t%s\t%s\n", \
    array_id2cluster[id_aa],id_aa"_repseq",array_id2abund[id_aa];
  }  
  if ( repseq == 0 ) {
    printf "%s\t%s\t%s\n", \
    array_id2cluster[id_aa],id_aa,array_id2abund[id_aa];
  } 
}' "${TMP_NAME}-coverage.table" "${TMP_NAME}_clu.tsv" > \
   "${NAME}_cluster2abund.tsv"

###############################################################################
# 14. Clean
###############################################################################

rm \
"${TMP_NAME}-PE.bam" \
"${TMP_NAME}-PE.sam" \
"${TMP_NAME}.sorted.markdup.bam"


if [[ -f "${SR_DOM_FASTQ}" ]]; then
  rm \
  "${TMP_NAME}-SE.sorted.bam" \
  "${TMP_NAME}-SE.bam" \
  "${TMP_NAME}-SE.sam"
fi
