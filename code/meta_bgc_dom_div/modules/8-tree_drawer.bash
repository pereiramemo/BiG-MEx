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
  --abund_table)
  if [[ -n "${2}" ]]; then
    ABUND_TABLE="${2}"
    shift
  fi
  ;;
  --abund_table=?*)
  ABUND_TABLE="${1#*=}"
  ;;
  --abund_table=)
  printf "ERROR: --abund_table requires a non-empty argument\n"  >&2
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
  printf 'ERROR: --env requires a non-empty argument\n' >&2
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

if [[ "$?" -ne "0" ]]; then  
  echo "${DOMAIN}: Sourcing ${ENV} failed"
  exit 1
fi

###############################################################################
# 4. Define input and output vars
###############################################################################

THIS_JOB_TMP_DIR="${THIS_JOB_TMP_DIR}/${DOMAIN}_tree_data/"
THIS_OUTPUT_TMP_IMAGE="${THIS_JOB_TMP_DIR}/"${DOMAIN}"_placements_tree.png"

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

if [[ "$?" -ne "0" ]]; then
  echo "${DOMAIN}: Generating ${THIS_JOB_TMP_DIR}/abund2clust_clean.tsv failed"
  exit 1
fi

ABUND_TABLE="${THIS_JOB_TMP_DIR}/abund2clust_clean.tsv"

###############################################################################
# 6. Make image
###############################################################################

"${r_interpreter}" --vanilla --slave <<RSCRIPT

  ### Upload libraries and data
  options(warn=-1)
  library('ggtree', quietly = TRUE, warn.conflicts = FALSE)
  library('tidyverse', quietly = TRUE, warn.conflicts = FALSE)
  options(warn=0)
  
  NWK <- read.tree("${TREE}")
  ABUND_TABLE <- read.table("${ABUND_TABLE}", sep = "\t", header = F, row.names = 2)
  colnames(ABUND_TABLE) <- c("cluser_id","abund")
  INFO_PPLACE <- read.table("${INFO_PPLACE}", sep = ",", header = T)

  ### Define node2part2ids dataframe
  all_ids <- NWK\$tip.label %>% as.character()
  n <- nodeid(NWK, all_ids) # convert tree label to internal node number
  node2ids <- data.frame(node = n, ids = all_ids, stringsAsFactors = F) # node to ids dataframe
  EDGES <- data.frame(NWK\$edge)
  colnames(EDGES)=c("parent", "node")
  nodes2parent2ids <- dplyr::inner_join(x = EDGES,
                                        y = node2ids,
                                        by = "node")

  ### Define meta_data dataframe 
  meta_data <- data.frame(row.names = NWK\$tip.label)
  meta_data[nodes2parent2ids\$ids, "node"] <- nodes2parent2ids\$node
  meta_data[nodes2parent2ids\$ids, "parent"] <- nodes2parent2ids\$parent

  ### Create class vector: placed vs. reference ids in meta_data
  placed_ids <- INFO_PPLACE\$name %>% as.character()
  meta_data[placed_ids, "class" ] <- "placed"
  meta_data[ ! all_ids %in% placed_ids, "class" ] <- "ref"
  meta_data\$class <- factor(meta_data\$class, levels = c("ref", "placed"))

  ### Define abundance in meta_data
  abund <- ABUND_TABLE[placed_ids , "abund"]
  meta_data[placed_ids, "abund" ] <- abund
  meta_data[! all_ids %in% placed_ids, "abund" ] <-  NA

  ### Define plot sizes
  w <- "${PLOT_TREE_WIDTH}" %>% as.numeric()
  h <- "${PLOT_TREE_HEIGHT}" %>% as.numeric()
  f <- "${FONT_TREE_SIZE}" %>% as.numeric()

  ### Define plot colors 
  placed_color <- "indianred"
  ref_color <- "gray40"
  
  ### Plot
  p <- ggtree(NWK, layout = 'circular')  %<+% meta_data +
       geom_tiplab(aes(angle = angle, color = class),
                   size = f, 
                   align = TRUE, 
                   linesize = 0, 
                   linetype = "dotted") + 
       geom_tippoint(aes(size = abund),
                     color = placed_color,   
                     alpha = 0.9) +
       guides(color = "none") + 
       scale_color_manual(values = c(ref_color, placed_color)) +
       guides(size = guide_legend(title="Abundance", 
                                  override.aes = list(alpha = 0.8, 
                                  color = placed_color))) +
       theme(legend.position="right")

  ### Export image
  
  ggsave(p, file = "${THIS_OUTPUT_TMP_IMAGE}", width = w, height = h, dpi = 500, device = "png")

RSCRIPT

if [[ "$?" -ne "0" ]]; then
  echo "${DOMAIN}: Generating ${THIS_OUTPUT_TMP_IMAGE} failed"
  exit 1
fi

###############################################################################
# 7. Clean
###############################################################################

rm "${THIS_JOB_TMP_DIR}/abund2clust_clean.tsv"

if [[ "$?" -ne "0" ]]; then
  echo "${DOMAIN}: Removing ${THIS_JOB_TMP_DIR}/abund2clust_clean.tsv failed"
  exit 1
fi
