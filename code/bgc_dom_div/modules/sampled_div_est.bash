#!/bin/bash -l

# set -x

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
  -i|--input)
  if [[ -n "${2}" ]]; then
   INPUT="${2}"
   shift
  fi
  ;;
  --input=?*)
  INPUT="${1#*=}" # Delete everything up to "=" and assign the remainder.
  ;;
  --input=) # Handle the empty case
  printf "ERROR: --input requires a non-empty option argument.\n"  >&2
  exit 1
  ;;
#############
  -d|--output_dir)
  if [[ -n "${2}" ]]; then
   OUTPUT_DIR="${2}"
   shift
  fi
  ;;
  --output_dir=?*)
  OUTPUT_DIR="${1#*=}" # Delete everything up to "=" and assign the remainder.
  ;;
  --output_dir=) # Handle the empty case
  printf "ERROR: --output_dir requires a non-empty option argument.\n"  >&2
  exit 1
  ;;
#############
  -o|--output_prefix)
   if [[ -n "${2}" ]]; then
     PREFIX="${2}"
     shift
   fi
  ;;
  --output_prefix=?*)
  PREFIX="${1#*=}" # Delete everything up to "=" and assign the 
                   # remainder.
  ;;
  --output_prefix=) # Handle the empty case
  printf 'Using default environment.\n' >&2
  ;;
#############
  -p|--plot)
     PLOT="1"
  ;;
#############
 -sn|--subsample_number)
   if [[ -n "${2}" ]]; then
     SUBSAMPLE_NUMBER="${2}"
     shift
   fi
  ;;
  --subsample_number=?*)
  SUBSAMPLE_NUMBER="${1#*=}" # Delete everything up to "=" and assign the 
                             # remainder.
  ;;
  --subsample_number=) # Handle the empty case
  printf "ERROR: --subsample_number requires a non-empty option argument.\n">&2
  exit 1
  ;;
#############
 -sz|--subsample_size)
   if [[ -n "${2}" ]]; then
     SUBSAMPLE_SIZE="${2}"
     shift
   fi
  ;;
  --subsample_size=?*)
  SUBSAMPLE_SIZE="${1#*=}" # Delete everything up to "=" and assign the 
                           # remainder.
  ;;
  --subsample_size=) # Handle the empty case
  printf "ERROR: --subsample_size requires a non-empty option argument.\n"  >&2
  exit 1
  ;;  
############
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
# 3. Define variables
###############################################################################

OUT_TSV="${OUTPUT_DIR}"/"${PREFIX}.tsv"
OUT_PDF="${OUTPUT_DIR}"/"${PREFIX}.pdf"

###############################################################################
# 4. Diversity estimates
###############################################################################

"${r_interpreter}" --vanilla --slave <<RSCRIPT

options(warn=-1)
library(vegan, quietly = TRUE, warn.conflicts = FALSE)
library(dplyr, quietly = TRUE, warn.conflicts = FALSE)
library(tidyr, quietly = TRUE, warn.conflicts = FALSE)
library(tibble, quietly = TRUE, warn.conflicts = FALSE)
library(ggplot2, quietly = TRUE, warn.conflicts = FALSE)
options(warn=0)

### load data
CLUSTER <- read.table(file = "${INPUT}",
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
###

### subsample and compute diversity
ODU_TABLE_div_est <- list()

ODU_TABLE_div_est <- list()
s <- "${SUBSAMPLE_SIZE}" %>% as.numeric()
N <- "${SUBSAMPLE_NUMBER}" %>% as.numeric()
X <- ODU_TABLE %>% 
     round(. , digits = 0) %>% 
     rep(names(.), .)
     
for ( i in 1:N) {

  set.seed(seed = i)
  ODU_TABLE_subsampled <- sample(x = X,
				size = length(X),
				replace = T ) %>%
				table() %>%
				as.data.frame()
  
  ODU_TABLE_div_est[[i]] <- diversity(x = ODU_TABLE_subsampled\$Freq,
                                      index = "shannon", 
                                      MARGIN = 1, base = exp(1)
                                      )
}
###

### format diversity table for plot 
ODU_TABLE_div_est_long <- do.call(rbind, ODU_TABLE_div_est) %>%
                          as.data.frame() %>%
                          gather()    

colnames(ODU_TABLE_div_est_long) <- c("sample_id","shannon")
###


if ( "${PLOT}" == 1 ) {
  ## plot
  p <- ggplot(ODU_TABLE_div_est_long, aes(x = sample_id, y = shannon )) +
         geom_violin( alpha = .4, trim = T, scale = "width", fill = "darkred") +
         stat_summary(fun.y = median ,geom='point', size = 0.5) + 
         xlab("${PREFIX}") +
         ylab("Shannon index") +
         theme_light() +
         theme(axis.text.y =  element_text(size = 8, color = "black"), 
               axis.text.x =   element_blank(),
               axis.title.x = element_text(size = 10, color = "black"),
               axis.title.y = element_text(size = 10, color = "black", margin = 
                 unit(c(0, 5, 0, 0),"mm") ) ) +
               scale_x_discrete(position = "bottom") +
          guides(fill=FALSE)


  pdf("${OUT_PDF}", width = 5, height = 4)
  print(p)
  dev.off()
  
}

### write diversity subsampled table
ODU_TABLE_div_est_df <- do.call(rbind, ODU_TABLE_div_est) %>%
                        as.data.frame() %>% 
                        round(.,digits = 3) %>% 
                        rownames_to_column(var = "mean_n_iteration")

ODU_TABLE_div_est_means_df <- apply(X = ODU_TABLE_div_est_df[,-1,drop = F], 
                                    MARGIN = 2,
                                    FUN = mean) %>% 
                                    t() %>%
                                    as.data.frame() %>% 
                                    round(.,digits = 3) %>%
                                    cbind("mean_n_iteration" = "mean", . )     

ODU_TABLE_div_est_direct_df <- diversity(x = ODU_TABLE,
                                         index = "shannon", 
                                         MARGIN = 1, 
                                         base = exp(1)) %>% 
                                         t() %>%
                                         as.data.frame() %>%
					 round(.,digits = 3) %>%
                                         cbind("mean_n_iteration" = "direct",.)
                                         

ODU_TABLE_div_est_output_df <- rbind(ODU_TABLE_div_est_direct_df,
                                     ODU_TABLE_div_est_means_df ) %>% 
                               rbind(.,ODU_TABLE_div_est_df)
                                         
                                         
colnames(ODU_TABLE_div_est_output_df) <- c("mean/iteration", "Shannon index")
write.table(file = "${OUT_TSV}",
            x = ODU_TABLE_div_est_output_df,
            sep = "\t", quote = F, 
            row.names = F, col.names = T)
###
RSCRIPT
