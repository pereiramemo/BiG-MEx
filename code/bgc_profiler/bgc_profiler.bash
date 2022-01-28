#!/bin/bash -l

set -o pipefail

###############################################################################
# 1. Load general configuration
###############################################################################

source "/software/conf"

if [[ "$?" -ne "0" ]]; then
  echo "Sourcing /software/conf failed"
  exit 1
fi

# source /home/epereira/workspace/repositories/BiG-MEx/bgc_profiler/resources/conf_test

###############################################################################
# 2. Define help
###############################################################################

show_usage(){
  cat <<EOF
  Usage: run_bgc_profiler.bash <input files> <input models> <output directory> <options>
  
--help              print this help
--barplots t|f      create bar plots of the domain counts and class abundance profiles (default f)
--class_abund t|f   compute class abundance predictions (default t)
--dom2class t|f     map classes to domain count table (default f)
--intype CHAR       type of input data (must be prot or dna)
--nslots NUM        number of slots (UProC parameter; default 2)
--overwrite t|f     overwrite current directory (default f)
--sample CHAR       sample name (default metagenomeX)
--verbose t|f       reduced verbose (default t)
--verbose_all t|f   complete verbose (default f)


<input files> sequence data to annotate the BGC domains (up to three different files: R1 and R2 and/or single read fasta/fastq files)
<input models> BGC class abundance models (optional; .RData file)
<output directory> name of the output directory

EOF
}

###############################################################################
# 3. Parse parameters 
###############################################################################

while :; do
  case "${1}" in
#############
  --help) # Call a "show_usage" function to display a synopsis, then exit.
  show_usage
  exit 1;
  ;;
#############
  --barplots)
  if [[ -n "${2}" ]]; then
    BARPLOTS="${2}"
    shift
  fi
  ;;
  --barplots=?*)
  BARPLOTS="${1#*=}" # Delete everything up to "=" and assign the remainder.
  ;;
  --barplots=) # Handle the empty case
  printf "--barplots: Using default parameter\n"  >&2
  ;;    
#############
  --class_abund)
  if [[ -n "${2}" ]]; then
    CLASS_ABUND="${2}"
    shift
  fi
  ;;
  --class_abund=?*)
  CLASS_ABUND="${1#*=}"
  ;;
  --class_abund=)
  printf "--class_abund: Using default parameter\n"  >&2
  ;;      
#############
  --dom2class)
  if [[ -n "${2}" ]]; then
    DOM2CLASS="${2}"
    shift
  fi
  ;;
  --dom2class=?*)
  DOM2CLASS="${1#*=}"
  ;;
  --dom2class=)
  printf "--dom2class: Using default parameter\n"  >&2
  ;;        
#############
  --bgc_models)
  if [[ -n "${2}" ]]; then
    BGC_MODELS="${2}"
    shift
  fi
  ;;
  --bgc_models=?*)
  BGC_MODELS="${1#*=}"
  ;;
  --bgc_models=) 
  printf "--bgc_models: Using default parameter\n"  >&2
  ;;  
#############
  --reads1)
  if [[ -n "${2}" ]]; then
    R1="${2}"
    shift
  fi
  ;;
  --reads1=?*)
  R1="${1#*=}"
  ;;
  --reads1=) 
  printf "ERROR: --reads1 requires a non-empty argument\n"  >&2
  exit 1
  ;;
#############
  --reads2)
  if [[ -n "${2}" ]]; then
    R2="${2}"
    shift
  fi
  ;;
  --reads2=?*)
  R2="${1#*=}"
  ;;
  --reads2=) 
  printf "ERROR: --reads2 requires a non-empty argument\n"  >&2
  exit 1
  ;;
#############
  --single_reads)
  if [[ -n "${2}" ]]; then
    SR="${2}"
    shift
  fi
  ;;
  --single_reads=?*)
  SR="${1#*=}" 
  ;;
  --single_reads=) 
  printf "ERROR: --single_reads requires a non-empty argument\n"  >&2
  exit 1
  ;;  
#############
  --intype)
  if [[ -n "${2}" ]]; then
    INTYPE="${2}"
    shift
  fi
  ;;
  --intype=?*)
  INTYPE="${1#*=}" 
  ;;
  --intype=)
  printf "ERROR: --intype requires a non-empty argument\n"  >&2
  exit 1
  ;;
#############
  --outdir)
  if [[ -n "${2}" ]]; then
    OUTDIR_EXPORT="${2}"
    shift
  fi
  ;;
  --outdir=?*)
  OUTDIR_EXPORT="${1#*=}" 
  ;;
  --outdir=)
  printf "ERROR: --outdir requires a non-empty argument\n" >&2
  exit 1
  ;;
#############
  --sample)
  if [[ -n "${2}" ]]; then
    SAMPLE="${2}"
    shift
  fi
  ;;
  --sample=?*)
  SAMPLE="${1#*=}"
  ;;
  --sample=) 
  printf '--sample: Using default parameter\n' >&2
  ;;
#############
  --nslots)
  if [[ -n "${2}" ]]; then
    NSLOTS="${2}"
    shift
  fi
  ;;
  --nslots=?*)
  NSLOTS="${1#*=}"
  ;;
  --nslots=)
  printf '--nslots: Using default parameter\n' >&2
  ;;
 #############
  --verbose)
  if [[ -n "${2}" ]]; then
    VERBOSE="${2}"
    shift
  fi
  ;;
  --verbose=?*)
  VERBOSE="${1#*=}"
  ;;
  --verbose=)
  printf '--verbose: Using default parameter\n' >&2
  ;;
#############
  --verbose_all)
  if [[ -n "${2}" ]]; then
    VERBOSE_ALL="${2}"
    shift
  fi
  ;;
  --verbose_all=?*)
  VERBOSE_ALL="${1#*=}"
  ;;
  --verbose_all=) 
  printf '--verbose_all: Using default parameter\n' >&2
  ;;  
#############
  --overwrite)
  if [[ -n "${2}" ]]; then
    OVERWRITE="${2}"
    shift
  fi
  ;;
  --overwrite=?*)
  OVERWRITE="${1#*=}" 
  ;;
  --overwrite=) 
  printf '--overwrite: Using default parameter\n' >&2
  ;;  
############
  --)      # End of all options.
  shift
  break
  ;;
  -?*)
  printf 'WARN: Unknown argument (ignored): %s\n' "$1" >&2
  ;;
  *) # Default case: If no more options then break out of the loop.
  break
  esac
  shift
done

###############################################################################
# 4. Check mandatory parameters
###############################################################################

if [[ -z "${INTYPE}" ]]; then
  echo "intype not defined. Use --intype dna or --intype prot"
  exit 1
fi

if [[ -n "${R1}" && -z "${R2}" ]]; then
  echo "R2 file missing."
  exit 1
fi

###############################################################################
# 5. Define defaults
###############################################################################

if [[ -z "${BARPLOTS}" ]]; then
  BARPLOTS="f"
fi  

if [[ -z "${CLASS_ABUND}" ]]; then
  CLASS_ABUND="t"
fi  

if [[ -z "${DOM2CLASS}" ]]; then
  DOM2CLASS="f"
fi  

if [[ -z "${NSLOTS}" ]]; then
  NSLOTS="2"
fi

if [[ -z "${OVERWRITE}" ]]; then
  OVERWRITE="f"
fi

if [[ -z "${SAMPLE}" ]]; then
  SAMPLE="metagenomeX"
fi

if [[ -z "${VERBOSE}" ]]; then
  VERBOSE="t"
fi

if [[ -z "${VERBOSE_ALL}" ]]; then
  VERBOSE_ALL="f"
fi

if [[ "${VERBOSE_ALL}" == "t" ]]; then
  VERBOSE="t"
fi

###############################################################################
# 6. Load handleoutput
###############################################################################

source "/software/handleoutput_functions"

if [[ "$?" -ne "0" ]]; then
  echo "Sourcing /software/handleoutput_functions failed"
  exit 1
fi

# source /home/epereira/workspace/repositories/BiG-MEx/bgc_profiler/resources/handleoutput

###############################################################################
# 7. Check output directories
###############################################################################

if [[ -d "${OUTDIR_LOCAL}/${OUTDIR_EXPORT}" ]]; then
  if [[ "${OVERWRITE}" != "t" ]]; then
    echo "${OUTDIR_EXPORT} already exists. Use \"--overwrite t\" to overwrite."
    exit 0
  fi
  
  if [[ "${OVERWRITE}" == "t" ]]; then
    rm -r "${OUTDIR_LOCAL}/${OUTDIR_EXPORT}"
    if [[ $? -ne "0" ]]; then
      echo "Failed to remove output directory ${OUTDIR_EXPORT}"
      exit 1
    fi  
  fi
  
fi  

###############################################################################
# 8. Create output directories
###############################################################################

THIS_JOB_TMP_DIR="${OUTDIR_LOCAL}/${OUTDIR_EXPORT}"

if [[ ! -d "${THIS_JOB_TMP_DIR}" ]]; then
  mkdir -p  "${THIS_JOB_TMP_DIR}"
fi

###############################################################################
# 9. Identify BGC reads: R1 and R2
###############################################################################

echo \
"#######################################################################
Profiling the BGC domain and class composition
#######################################################################" | \
handleoutput

UPROC_PE_OUT="${THIS_JOB_TMP_DIR}/pe_bgc_dom.gz"
UPROC_SE_OUT="${THIS_JOB_TMP_DIR}/se_bgc_dom.gz"

if [[ "${R2}" != "NULL" ]] && [[ -n "${R2}" ]]; then

   if [[ "${INTYPE}" == "dna" ]]; then
   
     echo "Running R1 and R2 domain annotation with uproc-dna ..." | handleoutput

    "${uproc_dna}" \
    --pthresh 3 \
    --short \
    --zoutput "${UPROC_PE_OUT}" \
    --preds \
    --threads "${NSLOTS}" \
    "${DBDIR}" "${MODELDIR}" "${R1}" "${R2}"
    
     if [[ "$?" -ne "0" ]]; then
       echo "uproc paired-end (dna) annotation failed" 
       exit 1
     fi
     
     ANNOT=1
   
   fi

   if [[ "${INTYPE}" == "prot" ]]; then

     echo "Running R1 and R2 domain annotation with uproc-prot ..." | handleoutput
   
     "${uproc_prot}" \
      --pthresh 3 \
      --zoutput "${UPROC_PE_OUT}" \
      --preds \
      --threads "${NSLOTS}" \
       "${DBDIR}" "${MODELDIR}" "${R1}" "${R2}" 
       
     if [[ "$?" -ne "0" ]]; then
       echo "uproc paired-end (prot) annotation failed" 
       exit 1
     fi
     
     ANNOT=1

   fi

fi

###############################################################################
# 10. Identify BGC reads: SR
###############################################################################

if [[ -f "${SR}" ]]; then

  if [[ "${INTYPE}" == "dna" ]]; then

     echo "Running SR domain annotation with uproc-dna ..." | handleoutput
  
    "${uproc_dna}" \
    --pthresh 3 \
    --short \
    --zoutput "${UPROC_SE_OUT}" \
    --preds \
    --threads "${NSLOTS}" \
    "${DBDIR}" "${MODELDIR}" "${SR}"
    
    if [[ "$?" -ne "0" ]]; then
      echo "uproc single-read (dna) annotation failed" 
      exit 1
    fi

    ANNOT=1
    
  fi

  if [[ "${INTYPE}" == "prot" ]]; then
  
     echo "Running SR domain annotation with uproc-prot ..." | handleoutput

    "${uproc_prot}" \
    --pthresh 3 \
    --zoutput "${UPROC_SE_OUT}" \
    --preds \
    --threads "${NSLOTS}" \
    "${DBDIR}" "${MODELDIR}" "${SR}"
    
    if [[ "$?" -ne "0" ]]; then
      echo "uproc single-read (prot) annotation failed" 
      exit 1
    fi
    
    ANNOT=1
    
  fi

fi

if [[ "${ANNOT}" -ne "1" ]]; then
  echo "BGC domain annotation was not performed"
  exit 1
fi  

###############################################################################
# 11. Concatenate annotation (if applicable)
###############################################################################

if [[ -f "${UPROC_PE_OUT}" ]] && [[ -f "${UPROC_SE_OUT}" ]]; then

  cat "${UPROC_PE_OUT}" "${UPROC_SE_OUT}" > "${THIS_JOB_TMP_DIR}/bgc_dom.gz"
  rm "${THIS_JOB_TMP_DIR}/"*_bgc_dom.gz
  
fi

###############################################################################
# 12. Make domain count tsv table
###############################################################################

echo "Parsing domain annotation" | handleoutput

ALL_BGC=$(find  "${THIS_JOB_TMP_DIR}"/  -name "*bgc_dom.gz")

if [[ "${INTYPE}" == "dna" ]]; then

  zcat "${ALL_BGC}" | cut -f7 -d"," | sort | uniq -c | \
  awk -v  s="${SAMPLE}" 'BEGIN { OFS="\t"; print "sample","domain","count" } 
  { gsub("-",".",$2); print s,$2,$1 }' > "${THIS_JOB_TMP_DIR}/bgc_dom_counts.tsv"

  if [[ "$?" -ne "0" ]]; then
    echo "Make bgc_dom_counts.tsv dna failed"
    exit 1
  fi

fi

if [[ "${INTYPE}" == "prot" ]]; then

  zcat "${ALL_BGC}" | cut -f4 -d"," | sort | uniq -c | \
  awk -v  s="${SAMPLE}" 'BEGIN { OFS="\t"; print "sample","domain","count" } 
  { gsub("-",".",$2); print s,$2,$1; }' > "${THIS_JOB_TMP_DIR}/bgc_dom_counts.tsv"

  if [[ "$?" -ne "0" ]]; then
    echo "Make bgc_dom_counts.tsv prot failed"
    exit 1
  fi
  
fi

###############################################################################
# 13. Make class to domain count tsv table
###############################################################################

if [[ "${DOM2CLASS}" == "t" ]]; then

  awk -v s="${SAMPLE}" 'BEGIN { OFS="\t"; print s,"class","domain","count" } {
    if (NR>1 && NR==FNR) {
      line[$2]=$3;
      next;
    }
    if ($2 in line) {
      print s,$1,$2,line[$2];
    }
    }' "${THIS_JOB_TMP_DIR}/bgc_dom_counts.tsv" "${CLASS2DOMAINS}" > \
       "${THIS_JOB_TMP_DIR}/class2domains2counts.tsv"

  if [[ "$?" -ne "0" ]]; then
    echo "Make class2domains2counts.tsv table awk script failed"
    exit 1
  fi
  
fi  

###############################################################################
# 14. Predict BGC class abundance
###############################################################################

if [[ "${CLASS_ABUND}" == "t" ]]; then

  echo "Predicting BGC class abundance profile" | handleoutput

  THIS_OUTPUT_TMP_FILE="${THIS_JOB_TMP_DIR}/bgc_class_abund.tsv"
  THIS_OUTPUT_TMP_DOM_IMAGE="${THIS_JOB_TMP_DIR}/bgc_dom_counts.png"
  THIS_OUTPUT_TMP_CLASS_IMAGE="${THIS_JOB_TMP_DIR}/bgc_class_abund.png"

(
  "${r_interpreter}" --vanilla --slave <<RSCRIPT
 
    options(warn=-1)
    library(bgcpred, quietly = TRUE, warn.conflicts = FALSE)
    library(tidyverse, quietly = TRUE, warn.conflicts = FALSE)
    options(warn=0)
  
    COUNTS <- read_tsv(file = "${THIS_JOB_TMP_DIR}/bgc_dom_counts.tsv", 
                       col_names = T, col_types = "ccn")
                    
    COUNTS_wide <- COUNTS %>% 
                   select(sample, domain, count) %>% 
                   spread(data = ., key = domain, value = count, fill = 0)

    COUNTS_wide <- COUNTS_wide %>% 
                   droplevels %>% 
                   arrange(sample) %>%
                   as.data.frame %>%
		           remove_rownames() %>%
		           column_to_rownames(., var = "sample")
 
    if ( "${BGC_MODELS}" != "" ) {
      bgc_models_current <- get(load("${BGC_MODELS}"))
      PRED <- wrap_up_predict(x = COUNTS_wide, m = bgc_models_current)
    } else {
      PRED <- wrap_up_predict(x = COUNTS_wide)
    }
  
    PRED_long <- PRED %>% gather(key = "class","abund") %>%
                 mutate(sample = "${SAMPLE}") %>%
                 select(sample, class, abund) 
  
    write.table(file = "${THIS_OUTPUT_TMP_FILE}", PRED_long, 
                sep = "\t", quote = F, col.names = T, row.names = F)
                
                
    if ( "${BARPLOTS}" == "t" ) {
      p_class <- ggplot(PRED_long, aes(x = class, y = abund, fill = class)) +
                 geom_bar(stat="identity") +
                 xlab("BGC class") +
                 ylab("Predicted abundance") +
                 theme_light() +
                 scale_fill_hue(c = 70, l = 40, h.start = 200) +
                 theme(axis.text.y = element_text(size = 10, color = "black"), 
                       axis.text.x = element_text(size = 10, color = "black", angle = 45, 
	                   hjust = 1),
                       axis.title.x = element_text(size = 12, color = "black", 
                                                   margin = unit(c(5, 0, 0, 0),"mm")),
                  axis.title.y = element_text(size = 12, color = "black", margin = 
                                              unit(c(0, 5, 0, 0),"mm"))) +
                  scale_x_discrete(position = "bottom") +
                  guides(fill="none")
    
      ggsave(p_class, file = "${THIS_OUTPUT_TMP_CLASS_IMAGE}", 
             device = "png", dpi = 500, width = 8, height = 4)
 
      p_dom <- ggplot(COUNTS, aes(x = domain, y = count, fill = domain)) +
               geom_bar(stat="identity") +
               xlab("BGC domain") +
               ylab("Sequence counts") +
               theme_light() +
               scale_fill_hue(c = 70, l = 40, h.start = 200) +
               theme(axis.text.y = element_text(size = 10, color = "black"), 
                     axis.text.x = element_text(size = 10, color = "black", angle = 45, 
	                 hjust = 1),
                     axis.title.x = element_text(size = 12, color = "black", 
                                                 margin = unit(c(5, 0, 0, 0),"mm")),
                     axis.title.y = element_text(size = 12, color = "black", 
                     margin = unit(c(0, 5, 0, 0),"mm"))) +
              scale_x_discrete(position = "bottom") +
              guides(fill="none")
    
 
      ggsave(p_dom, file = "${THIS_OUTPUT_TMP_DOM_IMAGE}", device = "png", dpi = 500, width=12, height=4 )
    }
      
RSCRIPT

) 2>&1 | handleoutput_all

EXIT_CODE="$?"  

  if [[ "${EXIT_CODE}" != 0 ]]; then
    echo "BGC class abundance prediction failed"
    exit 1
  fi

fi

###############################################################################
# 15. Exit
###############################################################################


echo \
"#######################################################################
Profiling is finished 
#######################################################################" \
| handleoutput

###############################################################################
# Move output for export
###############################################################################

# rsync -a --delete "${THIS_JOB_TMP_DIR}" "${OUTDIR_LOCAL}"
# 
# if [[ "$?" != 0 ]]; then
#   echo "rsync output failed"
#   exit 1
# fi

