#!/bin/bash -l

# set -x

set -o pipefail

#############################################################################
### 1 - Load general configuration
#############################################################################

source /bioinfo/software/conf
#source /home/memo/Google_Drive/Doctorado/workspace/ufBGCtoolbox/bgc_dom_div/tmp_vars.bash
##############################################################################
#### 2 - parse parameters 
##############################################################################

while :; do
  case "${1}" in
#############
  -a|--abund_table)
  if [[ -n "${2}" ]]; then
   ABUND_TABLE="${2}"
   shift
  fi
  ;;
  --abund_table=?*)
  ABUND_TABLE="${1#*=}" # Delete everything up to "=" and assign the remainder.
  ;;
  --abund_table=) # Handle the empty case
  printf "ERROR: --abund_table requires a non-empty option argument.\n"  >&2
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
  -pc|--plot_model_violin)
   if [[ -n "${2}" ]]; then
     PLOT_MODEL_VIOLIN="${2}"
     shift
   fi
  ;;
  --plot_model_violin=?*)
  PLOT_MODEL_VIOLIN="${1#*=}" # Delete everything up to "=" and assign the 
# remainder.
  ;;
  --plot_model_violin=) # Handle the empty case
  printf 'Using default environment.\n' >&2
  ;;
#############
  -pr|--prefix)
   if [[ -n "${2}" ]]; then
     PREFIX="${2}"
     shift
   fi
  ;;
  --prefix=?*)
  PREFIX="${1#*=}" # Delete everything up to "=" and assign the 
# remainder.
  ;;
  --prefix=) # Handle the empty case
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
  -s|--sample_increment)
   if [[ -n "${2}" ]]; then
     SAMPLE_INCREMENT="${2}"
     shift
   fi
  ;;
  --sample_increment=?*)
  SAMPLE_INCREMENT="${1#*=}" # Delete everything up to "=" and assign the 
# remainder.
  ;;
  --sample_increment=) # Handle the empty case
  printf 'Using default environment.\n' >&2
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

#############################################################################
### 3 - Define output
#############################################################################

THIS_JOB_TMP_DIR="${OUTDIR_EXPORT}"
THIS_OUTPUT_TMP_MODEL_TSV="${THIS_JOB_TMP_DIR}/${PREFIX}_model_div_est.tsv"
THIS_OUTPUT_TMP_SUMM_TSV="${THIS_JOB_TMP_DIR}/${PREFIX}_summary_model_div_est.tsv"
THIS_OUTPUT_TMP_IMAGE="${THIS_JOB_TMP_DIR}/${PREFIX}_violin_div_est.pdf"

#############################################################################
### 4 - diversiy estimates
#############################################################################

"${r_interpreter}" --vanilla --slave <<RSCRIPT

  options(warn=-1)
  library(vegan, quietly = TRUE, warn.conflicts = FALSE)
  library(dplyr, quietly = TRUE, warn.conflicts = FALSE)
  library(tidyr, quietly = TRUE, warn.conflicts = FALSE)
  library(tibble, quietly = TRUE, warn.conflicts = FALSE)
  library(ggplot2, quietly = TRUE, warn.conflicts = FALSE)
  options(warn=0)
  
  ### load data
  CLUSTER <- read.table(file = "${ABUND_TABLE}",
             sep = "\t",
             header = F)
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
                                 
  ODU_TABLE_div_est\$domain <- "${PREFIX}"                                  
                                                            
  ### format diversity table for rarefying plot
  if ( "${PLOT_MODEL_VIOLIN}" %in% c("t","T")) {
  
    p <- ggplot(ODU_TABLE_div_est, aes(x = domain, y = diversity)) +
     geom_violin( size = 1, alpha = 0.5, fill = "darkred") +
     stat_summary(fun.y = median ,geom='point', size = 1) + 
     xlab("") +
     ylab("Shannon index") +
     theme_light() +
     theme(axis.text.y = element_text(size = f1, color = "black"), 
           axis.text.x = element_text(size = f1, color = "black"),
           axis.title.x = element_text(size = f2, color = "black"),
           axis.title.y = element_text(size = f2, color = "black",
                                       margin = unit(c(0, 5, 0, 0),"mm"))) 

    pdf(file = "${THIS_OUTPUT_TMP_IMAGE}", width = w, height = h)
    print(p)		          
    dev.off()
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
