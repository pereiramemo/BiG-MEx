#!/bin/bash -l

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
  --prefix)
   if [[ -n "${2}" ]]; then
     NAME="${2}"
     shift
   fi
  ;;
  --prefix=?*)
  NAME="${1#*=}"
  ;;
  --prefix=)
  printf "ERROR: --prefix requires a non-empty argument\n"  >&2
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
# 3. Load environment
###############################################################################

source "${ENV}"

if [[ $? -ne "0" ]]; then
  echo "${DOMAIN}: Sourcing ${ENV} failed"
  exit 1
fi 

###############################################################################
# 4. Define output
###############################################################################

THIS_OUTPUT_TMP_MODEL_TSV="${NAME}_model_div_est.tsv"
THIS_OUTPUT_TMP_SUMM_TSV="${NAME}_summary_model_div_est.tsv"
THIS_OUTPUT_TMP_IMAGE="${NAME}_hist_div_est.png"

###############################################################################
# 5. Diversity estimates
###############################################################################

"${r_interpreter}" --vanilla --slave <<RSCRIPT

  options(warn=-1)
  library('vegan', quietly = TRUE, warn.conflicts = FALSE)
  library('tidyverse', quietly = TRUE, warn.conflicts = FALSE)
  # Note: tidyverse quietly not working now, but it will in future releases
  options(warn=0)
  
  ### load data
  CLUSTER <- read_tsv(file = "${NAME}_cluster2abund.tsv", 
                      col_names = F, col_types = "ccn")
  colnames(CLUSTER) <- c("clust_id","seq_id","abund")
  ### 

  ### format table
  ODU_TABLE <- CLUSTER %>% 
               group_by(clust_id) %>%
               summarize(clust_abund = sum(abund)) %>%
               spread(key = clust_id, value = clust_abund) %>% 
               as.data.frame(.) 
             
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
                                 
  ODU_TABLE_div_est\$domain <- "${DOMAIN}"                                  
                                                            
  ### format diversity table for rarefying plot
  if ("${PLOT_HIST}" %in% c("t","T")) {
  
    p <- ggplot(ODU_TABLE_div_est, aes(x = diversity)) +
           geom_histogram(size = 1, alpha = 0.5, fill = "gray10", bins = round(N/8)) +
          # stat_summary(fun = median, geom='point', size = 1) + 
           xlab("Shannon index") +
           ylab("Count") +
           theme_light() +
           theme(axis.text.y = element_text(size = f1, color = "black"), 
                 axis.text.x = element_text(size = f1, color = "black"),
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

  ODU_TABLE_div_est_means_df <- ODU_TABLE_div_est %>%
                                summarize(mean = mean(diversity), sd = sd(diversity) ) %>%
                                as.data.frame() %>% 
                                round(.,digits = 3) %>%
                                gather(key = "index", value = "value")

  ODU_TABLE_div_est_direct_df <- diversity(x = ODU_TABLE,
                                           index = "shannon", 
                                           MARGIN = 1, 
                                           base = exp(1)) %>% 
                                           t() %>%
                                           as.data.frame() %>%
                                           round(.,digits = 3) %>%
                                           gather(key = "index", value = "value")
  

  ODU_TABLE_div_est_direct_df[1,1] <- "diversity"


  ODU_TABLE_div_est_summary <- rbind(ODU_TABLE_div_est_direct_df,
                                     ODU_TABLE_div_est_means_df)              
              
  write.table(file = "${THIS_OUTPUT_TMP_SUMM_TSV}",
              x = ODU_TABLE_div_est_summary,
              sep = "\t",
              quote = F, 
              row.names = F, 
              col.names = T)
  ####

RSCRIPT

if [[ "$?" -ne "0" ]]; then
  echo "${DOMAIN}: Generating ${THIS_OUTPUT_TMP_IMAGE}, ${THIS_OUTPUT_TMP_MODEL_TSV}, and/or ${THIS_OUTPUT_TMP_SUMM_TSV} failed"
  exit 1
fi  
