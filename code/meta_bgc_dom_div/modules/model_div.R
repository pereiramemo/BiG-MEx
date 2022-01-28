model_div <- function(x = x, n_iter = 100) {

  div_i_list <- list()

  for (i in 1:nrow(x)) {
  
    ODU_SAMPLE <- x[i,]
    SAMPLE_NAME <- rownames(x)[i]
  
    if (is.null(names(ODU_SAMPLE)) ) {
      names(ODU_SAMPLE) <- 1:length(ODU_SAMPLE)
    } 
    
    X <- ODU_SAMPLE %>% 
         round(., digits = 0) %>% 
         rep(names(.), .)
  
    MAX <- length(X)
    
    div_k_list <- list()
    for (k in 1:n_iter) {
    
      set.seed(seed = k)
        
      ODU_SUBSAMPLE <- sample(x = X,
                              size = sample(MAX),
                              replace = F) %>%
                              table() %>%
                              as.data.frame()
    
      d <- diversity(x = ODU_SUBSAMPLE$Freq,
                     index = "shannon", 
                     MARGIN = 1, base = exp(1))
      
      div_k_list[[k]] <- d
      
    }
    div_i_list[[SAMPLE_NAME]] <- plyr::ldply(div_k_list, data.frame)
  }
  
  div_i_df <- plyr::ldply(div_i_list, data.frame)
  colnames(div_i_df) <- c("domain", "diversity")
  return(div_i_df)
}  
