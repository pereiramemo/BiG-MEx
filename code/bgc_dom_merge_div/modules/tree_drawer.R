library(ggplot2)
library(ggtree)
library(dplyr)


NWK <- read.newick("/scratch/test_merg_div_est/PKS_KS_tree_data/PKS_KS_query.newick")
ABUND_TABLE <- read.table("/scratch/test_merg_div_est/PKS_KS_tree_data/abund2clust_clean.tsv", sep = "\t", header = F, row.names = 2 )
colnames(ABUND_TABLE) <- c("cluser_id","abund","sample_id")
INFO_PPLACE <- read.table("/scratch/test_merg_div_est/PKS_KS_tree_data/PKS_KS_query_info.csv", sep = ",", header = T )


#### define meta_data
meta_data <- data.frame(row.names =  NWK$tip.label)
placed_ids <- INFO_PPLACE$name %>% as.character()
all_ids <- NWK$tip.label %>% as.character()

### define parent
n <- nodeid(NWK, all_ids)
node2ids <- data.frame(node = n, ids = all_ids, stringsAsFactors = F)
EDGES <- data.frame(NWK$edge)
colnames(EDGES)=c("parent", "node")
nodes2parent2ids <- dplyr::inner_join(x = EDGES,
                                      y = node2ids,
                                      by = "node")
meta_data[nodes2parent2ids$ids, "node" ] <- nodes2parent2ids$node
meta_data[nodes2parent2ids$ids, "parent" ] <- nodes2parent2ids$parent

### define color
meta_data[placed_ids, "color" ] <- "darkred"
meta_data[ ! all_ids %in% placed_ids, "color" ] <-  "gray40"

### define abund
abund <- ABUND_TABLE[placed_ids , "abund"]
meta_data[placed_ids, "abund" ] <- abund
meta_data[! all_ids %in% placed_ids, "abund" ] <-  NA

### define sample
samples <- ABUND_TABLE[placed_ids , "sample_id" ] %>% as.character()
meta_data[placed_ids, "samples"] <- samples 
meta_data[! all_ids %in% placed_ids, "samples" ] <-  NA


NWK$tip.label <- sub(x = NWK$tip.label, pattern = ".*_bf_",replacement = "", perl = F )

### plot

meta_data_redu <- meta_data[placed_ids,c("node","color","abund","samples")]

#### make image
pdf("tree.pdf", height = 12, width = 12)

ggtree(NWK, layout='circular')  %<+% meta_data_redu + 
     geom_tiplab(size = 1.5, align = TRUE, 
                  aes(angle = angle, color = samples),
                  linesize = 0,
                  linetype = "dotted") + 
      geom_tippoint(aes(size = abund, color = samples ), 
                    alpha = 0.7) +
      scale_color_hue(c=70, l=40, h.start = 200, direction = -1, breaks=c(samples %>% unique %>% sort)) +
      guides(size = guide_legend(title="Abundance", 
                                 override.aes = list( alpha = 0.3, color = "black"))) +
      guides(color = guide_legend(title="Sample")) +
      theme(legend.position="right" )

dev.off()
