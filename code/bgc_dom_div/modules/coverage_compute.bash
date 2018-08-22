#!/bin/bash

set -o pipefail

#############################################################################
# 1. Load general configuration
#############################################################################

source /bioinfo/software/conf
#source /home/memo/Google_Drive/Doctorado/workspace/ufBGCtoolbox/bgc_dom_div/tmp_vars.bash

#############################################################################
# 2. set parameters
#############################################################################

while :; do
  case "${1}" in
#############
    -b|--bed) # Takes an option argument, ensuring it has been
                # specified.
    if [[ -n "${2}" ]]; then
      BED="${2}"
      shift
    else
      printf 'ERROR: "--bed" requires a non-empty option argument.\n' >&2
      exit 1
    fi
    ;;
    --bed=?*)
    BED=${1#*=} # Delete everything up to "=" and assign the remainder.
    ;;
    --bed=)     # Handle the case of an empty --file=
    printf 'ERROR: "--bed" requires a non-empty option argument.\n' >&2
    exit 1
    ;;
#############
    -c|--clust_tsv) # Takes an option argument, ensuring it has been
                # specified.
    if [[ -n "${2}" ]]; then
      CLUST_TSV="${2}"
      shift
    else
      printf 'ERROR: "--clust_tsv" requires a non-empty option argument.\n' >&2
      exit 1
    fi
    ;;
    --clust_tsv=?*)
    CLUST_TSV=${1#*=} # Delete everything up to "=" and assign the remainder.
    ;;
    --clust_tsv=)     # Handle the case of an empty --file=
    printf 'ERROR: "--clust_tsv" requires a non-empty option argument.\n' >&2
    exit 1
    ;;    
#############
    -i|--input_orfs) # Takes an option argument, ensuring it has been
                # specified.
    if [[ -n "${2}" ]]; then
      FGS_ORFS="${2}"
      shift
    else
      printf 'ERROR: "--input_orfs" requires a non-empty option argument.\n' >&2
      exit 1
    fi
    ;;
    --input_orfs=?*)
    FGS_ORFS=${1#*=} # Delete everything up to "=" and assign the remainder.
    ;;
    --input_orfs=)     # Handle the case of an empty --file=
    printf 'ERROR: "--input_orfs" requires a non-empty option argument.\n' >&2
    exit 1
    ;;
#############
    -p|--prefix) # Takes an option argument, ensuring it has been
                # specified.
    if [[ -n "${2}" ]]; then
      NAME="${2}"
      shift
    else
      printf 'ERROR: "--prefix" requires a non-empty option \
argument.\n' >&2
      exit 1
    fi
    ;;
    --prefix=?*)
    NAME=${1#*=} # Delete everything up to "=" and assign the
# remainder.
    ;;
    --prefix=)     # Handle the case of an empty --file=
    printf 'ERROR: "--prefix" requires a non-empty option argument.\n' >&2
    exit 1
    ;;    
#############
    -r1|--reads1) # Takes an option argument, ensuring it has been
                # specified.
    if [[ -n "${2}" ]]; then
      R1_DOM_FASTQ="${2}"
      shift
    else
      printf 'ERROR: "--reads1" requires a non-empty option argument.\n' >&2
      exit 1
    fi
    ;;
    --reads1=?*)
    R1_DOM_FASTQ=${1#*=} # Delete everything up to "=" and assign the remainder.
    ;;
    --reads1=)     # Handle the case of an empty --file=
    printf 'ERROR: "--reads1" requires a non-empty option argument.\n' >&2
    exit 1
    ;;
#############
    -r2|--reads2) # Takes an option argument, ensuring it has been
                # specified.
    if [[ -n "${2}" ]]; then
      R2_DOM_FASTQ="${2}"
      shift
    else
      printf 'ERROR: "--reads2" requires a non-empty option argument.\n' >&2
      exit 1
    fi
    ;;
    --reads2=?*)
    R2_DOM_FASTQ=${1#*=} # Delete everything up to "=" and assign the remainder.
    ;;
    --reads2=)     # Handle the case of an empty --file=
    printf 'ERROR: "--reads2" requires a non-empty option argument.\n' >&2
    exit 1
    ;;
#############
    -sr|--single_reads) # Takes an option argument, ensuring it has been
                # specified.
    if [[ -n "${2}" ]]; then
      SR_DOM_FASTQ="${2}"
      shift
    else
      printf 'ERROR: "--single_reads" requires a non-empty option \
argument.\n' >&2
      exit 1
    fi
    ;;
    --single_reads=?*)
    SR_DOM_FASTQ=${1#*=} # Delete everything up to "=" and assign the remainder.
    ;;
    --single_reads=)     # Handle the case of an empty --file=
    printf 'ERROR: "--single_reads" requires a non-empty option argument.\n' >&2
    exit 1
    ;;
#############
    -tp|--tmp_prefix) # Takes an option argument, ensuring it has been
                # specified.
    if [[ -n "${2}" ]]; then
      TMP_NAME="${2}"
      shift
    else
      printf 'ERROR: "--tmp_prefix" requires a non-empty option \
argument.\n' >&2
      exit 1
    fi
    ;;
    --tmp_prefix=?*)
    TMP_NAME=${1#*=} # Delete everything up to "=" and assign the
# remainder.
    ;;
    --tmp_prefix=)     # Handle the case of an empty --file=
    printf 'ERROR: "--tmp_prefix" requires a non-empty option argument.\n' >&2
    exit 1
    ;;
#############
    -t|--nslots) # Takes an option argument, ensuring it has been
                # specified.
    if [[ -n "${2}" ]]; then
      NSLTOS="${2}"
      shift
    else
      printf 'ERROR: "--nslots" requires a non-empty option \
argument.\n' >&2
      exit 1
    fi
    ;;
    --nslots=?*)
    NSLTOS=${1#*=} # Delete everything up to "=" and assign the
# remainder.
    ;;
    --nslots=)     # Handle the case of an empty --file=
    printf 'ERROR: "--nslots" requires a non-empty option argument.\n' >&2
    exit 1
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
# 3. convert bed file coordinates
###############################################################################

awk 'OFS="\t" {print $1,$2*3,$3*3 }' "${BED}"_aa.bed > "${BED}"_nuc.bed

###############################################################################
# 4. extract sequences
###############################################################################

"${fastafrombed}" \
  -fi "${FGS_ORFS}".ffn \
  -bed "${BED}"_nuc.bed \
  -fo "${NAME}"_subseqs.ffn

###############################################################################
# 5. map
###############################################################################

"${bwa}" index -p "${TMP_NAME}" "${NAME}"_subseqs.ffn

"${bwa}" mem -M -t "${NSLOTS}" "${TMP_NAME}" \
"${R1_DOM_FASTQ}" "${R2_DOM_FASTQ}" > "${TMP_NAME}"-PE.sam

if [[ -f "${SR_DOM_FASTQ}" ]]; then
  "${bwa}" mem -M -t "${NSLOTS}" "${TMP_NAME}" \
  "${SR_DOM_FASTQ}" > "${TMP_NAME}"-SE.sam
fi
  
###############################################################################
# 6. convert to bam
###############################################################################

"${samtools}" view -@ "${NSLOTS}" -q 10 -F 4 -b \
"${TMP_NAME}"-PE.sam > "${TMP_NAME}"-PE.bam

if [[ -f "${TMP_NAME}"-SE.sam ]]; then
  "${samtools}" view -@ "${NSLOTS}" -q 10 -F 4 -b \
  "${TMP_NAME}"-SE.sam > "${TMP_NAME}"-SE.bam
fi 
###############################################################################
# 7. sort
###############################################################################

"${samtools}" sort  -@ "${NSLOTS}" \
"${TMP_NAME}"-PE.bam > "${TMP_NAME}"-PE.sorted.bam

if [[ -f "${TMP_NAME}"-SE.bam ]]; then
  "${samtools}" sort  -@ "${NSLOTS}" \
  "${TMP_NAME}"-SE.sam > "${TMP_NAME}"-SE.sorted.bam
fi
###############################################################################
# 8. merge
###############################################################################

if [[ -f "${SR_DOM_FASTQ}" ]]; then
  "${samtools}" merge \
  "${TMP_NAME}".bam \
  "${TMP_NAME}"-PE.sorted.bam \
  "${TMP_NAME}"-SE.sorted.bam
  
  
  "${samtools}" sort -@ "${NSLOTS}" \
  "${TMP_NAME}".bam  > "${TMP_NAME}".sorted.bam

else
  mv "${TMP_NAME}"-PE.sorted.bam "${TMP_NAME}".sorted.bam
fi

###############################################################################
# 9. sort merged data
###############################################################################

"${samtools}" index -@ "${NSLOTS}" "${TMP_NAME}".sorted.bam

###############################################################################
# 10. remove duplicates
###############################################################################

java -jar "${picard}" MarkDuplicates \
        INPUT="${TMP_NAME}".sorted.bam \
        OUTPUT="${TMP_NAME}".sorted.markdup.bam \
        METRICS_FILE="${TMP_NAME}".sorted.markdup.metrics.txt \
        REMOVE_DUPLICATES=TRUE \
        ASSUME_SORTED=TRUE \
        MAX_FILE_HANDLES_FOR_READ_ENDS_MAP=900

###############################################################################
# 11. compute coverage
###############################################################################

"${genomecoveragebed}" -d \
-ibam "${TMP_NAME}".sorted.markdup.bam \
-g  "${NAME}"_subseqs.ffn > "${TMP_NAME}"-coverage.list

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
"${TMP_NAME}"-coverage.list > "${TMP_NAME}"-coverage.table


###############################################################################
# 12. cross tables
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
}' "${TMP_NAME}-coverage.table" "${TMP_NAME}_clu".tsv > \
   "${NAME}_cluster2abund".tsv

###############################################################################
# 13. clean
###############################################################################

rm \
"${TMP_NAME}"-PE.bam \
"${TMP_NAME}"-PE.sam \
"${TMP_NAME}".sorted.markdup.bam 


if [[ -f "${SR_DOM_FASTQ}" ]]; then
  rm \
  "${TMP_NAME}"-SE.sorted.bam \
  "${TMP_NAME}"-SE.bam \
  "${TMP_NAME}"-SE.sam
fi


