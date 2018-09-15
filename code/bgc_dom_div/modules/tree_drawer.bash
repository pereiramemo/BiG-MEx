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

show_usage(){
  cat <<EOF
  Usage: ${0##*/} [-d|--domain CHAR] [-i|--seq_ids FILE] [-o|--outdir DIR] \
[-h] [-t|--tree NWK]

-h, --help	print this help
-d, --domain	domain name
-i, --seq_ids	one column list of placed sequence ids
-o, --outdir	directory where to ouput pdf image
-t, --tree	newick tree produced with places sequences
EOF
}

###############################################################################
# 3. Parse parameters 
###############################################################################

while :; do
  case "${1}" in

    -h|-\?|--help) # Call a "show_help" function to display a synopsis, then
                   # exit.
    show_usage
    exit 1;
    ;;
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
  -i|--info_pplace)
  if [[ -n "${2}" ]]; then
   INFO_PPLACE="${2}"
   shift
  fi
  ;;
  --info_pplace=?*)
  INFO_PPLACE="${1#*=}" # Delete everything up to "=" and assign the remainder.
  ;;
  --info_pplace=) # Handle the empty case
  printf "ERROR: --info_pplace requires a non-empty option argument.\n"  >&2
  exit 1
  ;;  
#############
  -d|--domain)
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
  -t|--tree)
  if [[ -n "${2}" ]]; then
   INPUT_TREE="${2}"
   shift
  fi
  ;;
  --tree=?*)
  INPUT_TREE="${1#*=}" # Delete everything up to "=" and assign the remainder.
  ;;
  --tree=) # Handle the empty case
  printf "ERROR: --tree requires a non-empty option argument.\n"  >&2
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
# 4. Define output
###############################################################################

THIS_JOB_TMP_DIR="${OUTDIR_EXPORT}"
THIS_OUTPUT_TMP_IMAGE="${THIS_JOB_TMP_DIR}/"${DOMAIN}"_placements_tree.pdf"

###############################################################################
# 5. Clean abund2clust.tsv table
###############################################################################

awk 'BEGIN {OFS="\t"} {
  gsub(/:|\./,"_",$2)
  gsub(/_repseq$/,"",$2)
  print $0;
}'  ${ABUND_TABLE} > "${THIS_JOB_TMP_DIR}/abund2clust_clean.tsv"

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
  
  NWK <- read.newick("${INPUT_TREE}")
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
  w <- "${PLOT_WIDTH}" %>% as.numeric()
  h <- "${PLOT_HEIGHT}" %>% as.numeric()
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

#############################################################################
# 7. Clean
#############################################################################

rm "${THIS_JOB_TMP_DIR}/abund2clust_clean.tsv"