#!/bin/bash -l

# set -x

set -o pipefail

###############################################################################
# 1. Load general configuration
###############################################################################

source /bioinfo/software/conf

###############################################################################
# 2. Parse parameters 
###############################################################################

while :; do
  case "${1}" in
#############
  --abund_table)
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
  --domain)
  if [[ -n "${2}" ]]; then
   DOMAIN="${2}"
   shift
  fi
  ;;
  --domain=?*)
  DOMAIN="${1#*=}" # Delete everything up to "=" and assign the remainder.
  ;;
  --DOMAIN=) # Handle the empty case
  printf "ERROR: --domain requires a non-empty option argument.\n"  >&2
  exit 1
  ;;
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
  --)               # End of all options.
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
# 3. Load environment
###############################################################################

source "${ENV}"

###############################################################################
# 4. Define input and output vars
###############################################################################

THIS_JOB_TMP_DIR="${THIS_JOB_TMP_DIR}/${DOMAIN}_tree_data/"
THIS_OUTPUT_TMP_IMAGE="${THIS_JOB_TMP_DIR}/"${DOMAIN}"_placements_tree.pdf"

INFO_PPLACE="${THIS_JOB_TMP_DIR}/${DOMAIN}_query_info.csv"
TREE="${THIS_JOB_TMP_DIR}/${DOMAIN}_query.newick"

###############################################################################
# 5. Clean abund2clust.tsv table
###############################################################################

awk 'BEGIN {OFS="\t"} {
  gsub(/:|\./,"_",$2)
  gsub(/_repseq$/,"",$2)
  print $0;
}'  "${ABUND_TABLE}" > "${THIS_JOB_TMP_DIR}/abund2clust_clean.tsv"

ABUND_TABLE="${THIS_JOB_TMP_DIR}/abund2clust_clean.tsv"

###############################################################################
# 6. Make image
###############################################################################

"${r_interpreter}" --vanilla --slave <<RSCRIPT

  options(warn=-1)
  library(ggplot2, quietly = TRUE, warn.conflicts = FALSE)
  library(ggtree, quietly = TRUE, warn.conflicts = FALSE)
  library(dplyr, quietly = TRUE, warn.conflicts = FALSE)
  options(warn=0)
  
  NWK <- read.newick("${TREE}")
  ABUND_TABLE <- read.table("${ABUND_TABLE}", sep = "\t", header = F, row.names = 2)
  colnames(ABUND_TABLE) <- c("cluser_id","abund")
  INFO_PPLACE <- read.table("${INFO_PPLACE}", sep = ",", header = T)

  #### define meta_data
  meta_data <- data.frame(row.names =  NWK\$tip.label)
  placed_ids <- INFO_PPLACE\$name %>% as.character()
  all_ids <- NWK\$tip.label %>% as.character()

  ### define parent
  n <- nodeid(NWK, all_ids)
  node2ids <- data.frame(node = n, ids = all_ids, stringsAsFactors = F)
  EDGES <- data.frame(NWK\$edge)
  colnames(EDGES)=c("parent", "node")
  nodes2parent2ids <- dplyr::inner_join(x = EDGES,
                                        y = node2ids,
                                        by = "node")
                                        
  meta_data[nodes2parent2ids\$ids, "node"] <- nodes2parent2ids\$node
  meta_data[nodes2parent2ids\$ids, "parent"] <- nodes2parent2ids\$parent

  ### define color
  tippoint_color <- "indianred"
  meta_data[placed_ids, "color" ] <- tippoint_color
  meta_data[ ! all_ids %in% placed_ids, "color" ] <- "gray40"

  ### define abund
  abund <- ABUND_TABLE[placed_ids , "abund"]
  meta_data[placed_ids, "abund" ] <- abund
  meta_data[! all_ids %in% placed_ids, "abund" ] <-  NA


  ### plot
  meta_data_redu <- meta_data[placed_ids,c("node","color","abund")]

  #### make image
  w <- "${PLOT_TREE_WIDTH}" %>% as.numeric()
  h <- "${PLOT_TREE_HEIGHT}" %>% as.numeric()
  f <- "${FONT_SIZE}" %>% as.numeric()
  
  pdf("${THIS_OUTPUT_TMP_IMAGE}", height = h, width = w)
  ggtree(NWK, layout='circular')  %<+% meta_data_redu + 
         geom_tiplab(size = f, align = TRUE, 
                     aes(angle = angle),
                     linesize = 0, 
                     color = meta_data\$color,
                     linetype = "dotted") + 
         geom_tippoint(aes(size = abund, color = color ),
                       color = tippoint_color,   
                       alpha = 0.8) +
                       guides(color = FALSE) + 
         guides(size = guide_legend(title="Abundance", 
                                    override.aes = list( alpha = 0.8, color = tippoint_color))) +
         theme(legend.position="right" )

  dev.off()

RSCRIPT

###############################################################################
# 7. Clean
###############################################################################

rm "${THIS_JOB_TMP_DIR}/abund2clust_clean.tsv"
