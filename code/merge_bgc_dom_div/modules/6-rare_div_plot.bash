#!/bin/bash -l

# set -x

set -o pipefail

###############################################################################
# 1. Load general configuration
###############################################################################

source "/software/conf"

if [[ "$?" -ne "0" ]]; then
  echo "Sourcing /software/conf failed"
  exit 1
fi

###############################################################################
# 2. Parse parameters 
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
  ENV="${1#*=}"
  ;;
  --env=)
  printf "ERROR: --env requires a non-empty argument\n"  >&2
  exit 1
  ;;
#############
  --plot_rare_curve)
  if [[ -n "${2}" ]]; then
    PLOT_RARE_CURVE="${2}"
    shift
  fi
  ;;
  --plot_rare_curve=?*)
  PLOT_RARE_CURVE="${1#*=}"
  ;;
  --plot_rare_curve=)
  printf '--plot_rare_curve: Using default parameter\n' >&2
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

if [[ "$?" -ne "0" ]]; then
  echo "Sourcing ${ENV} failed"
  exit 1
fi

###############################################################################
# 4. Define output
###############################################################################

THIS_OUTPUT_TMP_RARE_TSV="${THIS_JOB_TMP_DIR}/${DOMAIN}_rare_div_est.tsv"
THIS_OUTPUT_TMP_SUMM_TSV="${THIS_JOB_TMP_DIR}/\
${DOMAIN}_summary_rare_div_est.tsv"
THIS_OUTPUT_TMP_IMAGE="${THIS_JOB_TMP_DIR}/${DOMAIN}_rare_div_est.png"

###############################################################################
# 5. Diversity estimates
###############################################################################

(
"${r_interpreter}" --vanilla --slave <<RSCRIPT

  options(warn=-1)
  library(vegan, quietly = TRUE, warn.conflicts = FALSE)
  library(dplyr, quietly = TRUE, warn.conflicts = FALSE)
  library(tidyr, quietly = TRUE, warn.conflicts = FALSE)
  library(tibble, quietly = TRUE, warn.conflicts = FALSE)
  library(ggplot2, quietly = TRUE, warn.conflicts = FALSE)
  options(warn=0)

  ### load data
  CLUSTER <- read.table(file = "${NAME}_cluster2abund.tsv",
			 sep = "\t", header = F)
  colnames(CLUSTER) <- c("clust_id","sample_id","seq_id","abund")
  ### 

  ### format table
  ODU_TABLE <- CLUSTER %>% 
               group_by(clust_id, sample_id) %>%
               summarize(clust_abund = sum(abund)) %>%
               spread(key = clust_id, value = clust_abund) %>% 
	           remove_rownames(.) %>% 
               as.data.frame(.) %>%
               tibble::remove_rownames(.) %>%
               tibble::column_to_rownames("sample_id") %>%
               round(., digits = 0)
             
  ODU_TABLE[is.na(ODU_TABLE)] <- 0
  ###

  ### rarefy and compute diversity 
  s <- "${SAMPLE_INCREMENT}" %>% as.numeric()
  N <- "${NUM_ITER}" %>% as.numeric()
  w <- "${PLOT_WIDTH}" %>% as.numeric()
  h <- "${PLOT_HEIGHT}" %>% as.numeric()
  f1 <- "${FONT_SIZE}" %>% as.numeric()
  f2 <- f1 +2 
  
  source("${SOFTWARE_DIR}/rare_div.R")

  if ( s > min(rowSums(ODU_TABLE)) ) {
       s <- min(rowSums(ODU_TABLE))
       text <- paste("increment size reset to", s, sep = " ")
       print(text)
  }


  ODU_TABLE_div_est <- rare_div(x = ODU_TABLE,
                                n_iter = N, 
                                by = s)
                                                            
  ODU_TABLE_div_est_summary <- ODU_TABLE_div_est %>%
                               group_by(sample_id, size) %>%
                               arrange(size) %>% 
                               summarize(mean = mean(diversity), sd = sd(diversity)) %>% 
                               ungroup()
                              
  ### format diversity table for rarefying plot
  if ( "${PLOT_RARE_CURVE}" %in% c("t","T")) {
  
    p <- ggplot(ODU_TABLE_div_est_summary, aes(x = size, y = mean, color = sample_id)) +
                geom_line( size = 1, alpha = 0.9) +
                geom_errorbar(aes(ymin=mean-sd, ymax=mean+sd), alpha = 0.6) +
                xlab("Sample size") +
                ylab("Shannon index") +
                theme_light() +
                scale_color_hue(c=70, l=40,h.start = 200, name = "Sample") +
                theme(axis.text.y = element_text(size = f1, color = "black"), 
                      axis.text.x = element_text(size = f1, color = "black",
                                                 angle = 45, hjust = 1),
                      axis.title.x = element_text(size = f2, color = "black"),
                      axis.title.y = element_text(size = f2, color = "black",
                                                  margin = unit(c(0, 5, 0, 0),"mm"))) 


    ggsave(p, file = "${THIS_OUTPUT_TMP_IMAGE}", width = w, height = h, dpi = 350, device = "png")

  }  

  ### write output tables
  ODU_TABLE_div_est_rare <- ODU_TABLE_div_est %>% 
                            select(-subsample_id) %>%
                            as.data.frame() 
      
  write.table(file = "${THIS_OUTPUT_TMP_RARE_TSV}",
              x = ODU_TABLE_div_est,
              sep = "\t", quote = F, 
              row.names = F, col.names = T)

  write.table(file = "${THIS_OUTPUT_TMP_SUMM_TSV}",
              x = ODU_TABLE_div_est_summary,
              sep = "\t",
              quote = F, 
              row.names = F, 
              col.names = T)

RSCRIPT

) 

if [[ "$?" -ne "0" ]]; then
  echo "Generating ${THIS_OUTPUT_TMP_IMAGE}, ${THIS_OUTPUT_TMP_RARE_TSV}, and/or ${THIS_OUTPUT_TMP_SUMM_TSV} failed"
  exit 1
fi
