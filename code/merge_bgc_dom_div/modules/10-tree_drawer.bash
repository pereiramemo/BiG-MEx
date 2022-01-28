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

##############################################################################
# 2. Parse parameters 
##############################################################################

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
# 4. Define input and output variables
###############################################################################

THIS_JOB_TMP_DIR="${THIS_JOB_TMP_DIR}/${DOMAIN}_tree_data"
INFO_PPLACE="${THIS_JOB_TMP_DIR}/${DOMAIN}_query_info.csv"
INPUT_TREE="${THIS_JOB_TMP_DIR}/${DOMAIN}_query.newick"
THIS_OUTPUT_TMP_IMAGE="${THIS_JOB_TMP_DIR}/${DOMAIN}_placements_tree.png"

###############################################################################
# 5. Clean abund2clust.tsv table
###############################################################################

awk 'BEGIN {OFS="\t"} {
  gsub(/:|\./,"_",$2)
  gsub(/_repseq$/,"",$2)
  print $0;
}' "${ABUND_TABLE}" > "${THIS_JOB_TMP_DIR}/abund2clust_clean.tsv"

if [[ "$?" -ne "0" ]]; then
  echo "Generating ${THIS_JOB_TMP_DIR}/abund2clust_clean.tsv failed"
fi

ABUND_TABLE="${THIS_JOB_TMP_DIR}/abund2clust_clean.tsv"

###############################################################################
# 6. Make image
###############################################################################

(
"${r_interpreter}" --vanilla --slave <<RSCRIPT

  ### Upload libraries and data
  options(warn=-1)
  library(ggplot2, quietly = TRUE, warn.conflicts = FALSE)
  library(ggtree, quietly = TRUE, warn.conflicts = FALSE)
  library(dplyr, quietly = TRUE, warn.conflicts = FALSE)
  options(warn=0)
  
  NWK <- read.tree("${INPUT_TREE}")
  ABUND_TABLE <- read.table("${ABUND_TABLE}", sep = "\t", header = F, row.names = 2)
  colnames(ABUND_TABLE) <- c("cluser_id","abund","sample_id")
  INFO_PPLACE <- read.table("${INFO_PPLACE}", sep = ",", header = T)

  
  ### Define node2part2ids dataframe
  all_ids <- NWK\$tip.label %>% as.character() # get all ids
  n <- nodeid(NWK, all_ids) # convert tree label to internal node number
  node2ids <- data.frame(node = n, ids = all_ids, stringsAsFactors = F)
  EDGES <- data.frame(NWK\$edge)
  colnames(EDGES)=c("parent", "node")
  nodes2parent2ids <- dplyr::inner_join(x = EDGES, 
                                        y = node2ids, 
                                        by = "node")

  ### Define meta_data dataframe
  meta_data <- data.frame(row.names = NWK\$tip.label) # define metadata table (empty) 
  meta_data[nodes2parent2ids\$ids, "node"] <- nodes2parent2ids\$node
  meta_data[nodes2parent2ids\$ids, "parent"] <- nodes2parent2ids\$parent

  ### Define color for placed and ref ids in meta_data
  tippoint_color <- "indianred"
  ref_color <- "gray40"
  placed_ids <- INFO_PPLACE\$name %>% as.character() # get placed ids
  meta_data[placed_ids, "color" ] <- tippoint_color
  meta_data[ ! all_ids %in% placed_ids, "color" ] <- ref_color

  ### Define abund in meta_data
  abund <- ABUND_TABLE[placed_ids, "abund"]
  meta_data[placed_ids, "abund" ] <- abund
  meta_data[! all_ids %in% placed_ids, "abund" ] <- NA
 
  ### Define sample in meta_data
  samples <- ABUND_TABLE[placed_ids, "sample_id"] %>% as.character()
  meta_data[placed_ids, "samples"] <- samples
  meta_data[! all_ids %in% placed_ids, "samples"] <- NA

  ### Format headers and define meta_data_redu (only with placed ids)
  NWK\$tip.label <- sub(x = NWK\$tip.label, pattern = "_bf_", replacement = "-", perl = F )
  meta_data_redu <- meta_data[placed_ids,c("node","color","abund","samples")]
  rownames(meta_data_redu) <- sub(x = rownames(meta_data_redu), pattern = "-", replacement = "", perl = F )
  rownames(meta_data) <- sub(x =  rownames(meta_data), pattern = "-", replacement = "", perl = F )

  ### Define sizes
  w <- "${PLOT_TREE_WIDTH}" %>% as.numeric()
  h <- "${PLOT_TREE_HEIGHT}" %>% as.numeric()
  f <- "${FONT_TREE_SIZE}" %>% as.numeric()
 
  ### Plot 
  p <- ggtree(NWK, layout='circular') %<+% meta_data_redu + 
              geom_tiplab(size = f, align = TRUE, 
              aes(angle = angle, color = samples),
                  linesize = 0,
                  linetype = "dotted",
                  show.legend = FALSE) + 
              geom_tippoint(alpha = 0.7, aes(size = abund, color = samples)) +
              scale_color_hue(c=70, l=40, h.start = 200, breaks=c(samples %>% unique %>% sort)) +
              guides(color = guide_legend(title="Sample",
                                          order = 1),
              size = guide_legend(title="Abundance", 
                                  order = 2,
                                  override.aes = list(alpha = 0.3, color = "black"))) +
              theme(legend.position="right" )


  ### Export image
  
  ggsave(p, file = "${THIS_OUTPUT_TMP_IMAGE}", width = w, height = h, dpi = 500, device = "png")
  
RSCRIPT

)

if [[ "$?" -ne "0" ]]; then
  echo "Generating ${THIS_OUTPUT_TMP_IMAGE} failed"
  exit 1
fi

###############################################################################
# 7. Clean
###############################################################################

#rm "${THIS_JOB_TMP_DIR}/abund2clust_clean.tsv"


