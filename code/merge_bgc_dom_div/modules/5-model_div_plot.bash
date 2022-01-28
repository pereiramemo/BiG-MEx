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
  --plot_model_points)
  if [[ -n "${2}" ]]; then
    PLOT_MODEL_POINTS="${2}"
    shift
  fi
  ;;
  --plot_model_points=?*)
  PLOT_MODEL_POINTS="${1#*=}" 
  ;;
  --plot_model_points=)
  printf '--plot_model_points: Using default parameter\n' >&2
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
# 5. Define output
###############################################################################

THIS_OUTPUT_TMP_MODEL_TSV="${THIS_JOB_TMP_DIR}/${DOMAIN}_model_div_est.tsv"
THIS_OUTPUT_TMP_SUMM_TSV="${THIS_JOB_TMP_DIR}/\
${DOMAIN}_summary_model_div_est.tsv"
THIS_OUTPUT_TMP_IMAGE="${THIS_JOB_TMP_DIR}/${DOMAIN}_model_div_est.png"

###############################################################################
# 6. Diversity estimates
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
  N <- "${NUM_ITER}" %>% as.numeric()
  w <- "${PLOT_WIDTH}" %>% as.numeric()
  h <- "${PLOT_HEIGHT}" %>% as.numeric()
  f1 <- "${FONT_SIZE}" %>% as.numeric()
  f2 <- f1 +2 
 
  source("${SOFTWARE_DIR}/model_div.R")

  ODU_TABLE_div_est <- model_div(x = ODU_TABLE,
                                 n_iter = N)
                                                            
  ODU_TABLE_div_est_summary <- ODU_TABLE_div_est %>%
                               group_by(sample_id) %>%
                               summarize(mean = mean(diversity), sd = sd(diversity)) %>% 
                               ungroup()
                              
  ### format diversity table for rarefying plot
  if ( "${PLOT_MODEL_POINTS}" %in% c("t","T")) {
  
    p <- ggplot(ODU_TABLE_div_est_summary, aes(x = sample_id, y = mean, color = sample_id)) +
                geom_point(size = 2, alpha = 0.9) +
                geom_errorbar( aes(ymin=mean-sd, ymax=mean+sd), alpha = 0.6, size = 1.5, width = 0) +
                xlab("Sample") +
                ylab("Shannon index") +
                theme_light() +
                ylim(0, max(ODU_TABLE_div_est_summary\$mean + ODU_TABLE_div_est_summary\$sd )) +
                scale_color_hue(c=70, l=40, h.start=200, guide = "none") +
                theme(axis.text.y = element_text(size = f1, color = "black"), 
                      axis.text.x = element_text(size = f1, color = "black",
                                                 angle = 45, hjust = 1),
                      axis.title.x = element_text(size = f2, color = "black"),
                      axis.title.y = element_text(size = f2, color = "black",
                                                  margin = unit(c(0, 5, 0, 0),"mm"))) 
    
    ggsave(p, file = "${THIS_OUTPUT_TMP_IMAGE}", width = w, height = h, dpi = 350, device = "png")
    
  }  

  ### write output tables
      
  write.table(file = "${THIS_OUTPUT_TMP_MODEL_TSV}",
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
  echo "Generating ${THIS_OUTPUT_TMP_IMAGE}, ${THIS_OUTPUT_TMP_MODEL_TSV}, and/or ${THIS_OUTPUT_TMP_SUMM_TSV} failed"
  exit 1
fi
