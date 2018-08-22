rare_div <- function(x = x, n_iter = 100, by = 20) {

  div_i_list <- list()
  for ( i in 1:nrow(x)) {
  
    ODU_SAMPLE <- x[i,]
    SAMPLE_NAME <- rownames(x)[i]
    MAX <- sum(ODU_SAMPLE)
  
    SIZES <- seq(from = by, to = MAX, by = by)
    
    if ( SIZES[length(SIZES)] != MAX ) {
      SIZES <- c(SIZES,MAX)
    }
    
    
    if ( is.null(names(ODU_SAMPLE)) ) {
      names(ODU_SAMPLE) <- 1:length(ODU_SAMPLE)
    } 
    
    X <- ODU_SAMPLE %>% 
         round(., digits = 0) %>% 
         rep(names(.), .)
    
    
    div_j_list <- list()
    for (j in SIZES) {
      
      div_k_list <- list()
      for (k in 1:n_iter) {
    
        set.seed(seed = k)
        
        ODU_SUBSAMPLE <- sample(x = X,
                                size = j,
                                replace = F) %>%
                                table() %>%
                                as.data.frame()
    
        d <- diversity(x = ODU_SUBSAMPLE$Freq,
                       index = "shannon", 
                       MARGIN = 1, base = exp(1))
      
      div_k_list[[k]] <- d
      
      }
      j_index <- paste("sample_size",j, sep="_")
      div_j_list[[j_index]] <- plyr::ldply(div_k_list, data.frame) %>% cbind(size = j, .)
    }
    div_i_list[[SAMPLE_NAME]] <- plyr::ldply(div_j_list, data.frame) %>% cbind(sample_id = SAMPLE_NAME,.)
  }
  
  div_i_df <- plyr::ldply(div_i_list, data.frame)
  colnames(div_i_df) <- c("sample_id", "subsample_id", "size", "diversity")
  div_i_df$sample_id <- factor(div_i_df$sample_id, levels = rownames(x))
  return(div_i_df)
}  