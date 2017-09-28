#######################################################################
############### RF abundance modeling #################################
#######################################################################

regression_model_fun <- function(bgc, data, regression_method, class2dom, seed = 111) {

  return.list <- list()
  
  for (b in bgc) {
     
     ######################################
     ### select domains ###################
     ######################################
     X_DOMS <- class2dom  %>% 
              filter(class %in% b ) %>% 
              select(domain) %>%
              .[,1] %>%
              as.character()
     
     i <- X_DOMS %in% colnames(data)
     X_DOMS <- X_DOMS[i]
     
     #######################################
     ### split data: train and test ########
     #######################################
     set.seed(seed)
     index <- sample( x = 1:nrow(data),  
                      size = round(0.7*nrow(data) ))
     
     data_train <- data[index,]
     data_test <- data[-index,]
     
     ######################################
     ### predictors and response ##########
     ######################################
      
     predictors_train <- data.frame(data_train[,X_DOMS, drop = F])
     
     response_train <- data.frame(data_train[,b, drop = F])

     predictors_test <- data.frame(data_test[,X_DOMS, drop = F] )
     
     response_test <- data.frame(data_test[,b, drop = F])
     
     ######################################
     #### train Regression Modoel #########
     ######################################
     
     set.seed(seed)
     if (regression_method == "rf") {
       model_r <- randomForest( response_train[,1] ~ . , 
                                data = predictors_train,
                                importance = T,
                                nodesize = 1 
                                )
     } 
     
     
     if (regression_method == "svm") {
       predictors_train <- predictors_train[,colSums(predictors_train) > 0, drop=FALSE  ]
      
       model_r <- svm( response_train[,1] ~ . , 
                        data = predictors_train )
     } 
     
     if (regression_method == "lm") { 

       model_r <- lm( response_train[,1] ~ . , 
                      data = predictors_train)
     } 
     
     ######################################
     ### compute predictions ##############
     ######################################
     pred_r <- predict(model_r, predictors_test )
     
     ######################################
     ### compute perfomance stat ##########
     ######################################
     x_cor <- cor.test(response_test[,1] , pred_r)
     x_mse <- mean( ( pred_r - response_test[,1] )^2 )
     x_r2 <- rSquared(response_test[,1], pred_r - response_test[,1])

     ######################################
     ### save output ######################
     ######################################
     results <- list(cor =  x_cor$estimate, 
                     cor.pvalue = x_cor$p.value,
                     mse = x_mse, 
                     r2 = x_r2, 
                     pred_vs_resp =  cbind(pred = pred_r, resp = response_test[,1]),
                     index = index,
                     regression_model = model_r
                     )
     return.list[[b]] <-  results
  }

  return(return.list)
}



#######################################################################
############### RF presence absence modeling ##########################
#######################################################################

binary_model_fun <- function(bgc, data,binary_method, class2dom, seed=111) {
  
  return.list <- list()
  for (b in bgc) {
    
    ######################################
    ### select domains ###################
    ######################################
    X_DOMS <- class2dom  %>% 
              filter(class %in% b ) %>% 
              select(domain) %>%
              .[,1] %>%
              as.character()
    
    i <- X_DOMS %in% colnames(data)
    X_DOMS <- X_DOMS[i]
    #######################################
    ### split data: train and test ########
    #######################################
    set.seed(seed)
    index <- sample( x = 1:nrow(data),  
                     size = round(0.7*nrow(data) ))
    
    data_train <- data[index,]
    data_test <- data[-index,]
    
    ######################################
    ### predictors and response ##########
    ######################################
    predictors_train <- data.frame(data_train[,X_DOMS, drop = F])

    response_train <- data.frame(data_train[,b, drop = F])
    
    predictors_test <- data.frame(data_test[,X_DOMS, drop = F] )
    
    response_test <- data.frame(data_test[,b, drop = F])
    
    ######################################
    ### binary variables #################
    ######################################
    response_binary_train <-  as.numeric( response_train !=0 )
    response_binary_test <-  as.numeric( response_test !=0 )
    
    if ( sum( response_train == 0 ) != 0 ) {
      
      ######################################
      #### train RF: presnece absence ######
      ######################################
      set.seed(seed)
      
      if (binary_method == "rf") {
        model_c <- randomForest( factor(response_binary_train) ~ ., 
                                 data = predictors_train,
                                 importance = F,
                                 ntree = 1000
                                 )
      } 
      
      if (binary_method == "svm") {
        predictors_train <- predictors_train[,colSums(predictors_train) > 0, drop=FALSE  ]
        
        model_c <- svm( factor(response_binary_train) ~ ., 
                          data =  predictors_train )
      } 
      
      ######################################
      ### compute predictions ##############
      ######################################
      pred_c <- predict(model_c, predictors_test )
    
      ######################################
      ### compute perfomance stat ##########
      ######################################
      x_tpr <- sum( pred_c == 1 & response_binary_test == 1  )/sum(response_binary_test == 1 )
      x_tnr <-  sum( pred_c == 0 & response_binary_test == 0  )/sum(response_binary_test == 0 )
      x_correct <- sum( pred_c == response_binary_test )/length(response_binary_test )
    
      ######################################
      ### save output ######################
      ######################################
      results <- list(sensitivity =  x_tpr,
                      specificity = x_tnr, 
                      correct_class = x_correct,
                      pred_c =  as.numeric(as.character(pred_c)),
                      response_test = response_binary_test,
                      binary_model = model_c
                      )

      return.list[[b]] <-  results
    
    } else {
      return.list[[b]] <- "no binary data"
    }
  }  
  return(return.list)
}
  
#######################################################################
############### RF 2 models predictions ###############################
#######################################################################

double_models_fun <- function(bgc, data, binary_method, regression_method, class2dom, seed = 111) {
  
  return.list <- list()
  
  for (b in bgc) {
    
    ######################################
    ### select domains ###################
    ######################################
    X_DOMS <- class2dom  %>% 
              filter(class %in% b ) %>% 
              select(domain) %>%
             .[,1] %>%
             as.character()
    
    i <- X_DOMS %in% colnames(data)
    X_DOMS <- X_DOMS[i]
    #######################################
    ### subsselect present data ###########
    #######################################
    subset <- data[,b] != 0
    data_present <- data[subset,] 
    
    if ( sum(!subset) < 10 ) {
        tmp <- regression_model_fun(bgc = b, 
                                    data = data,
                                    regression_method = regression_method,
                                    class2dom = class2dom,
                                    seed = seed
                                    )
        
        return.list[[b]] <- tmp[[b]]
      
    } else { 
    
      #######################################
      ### split data: train and test ########
      #######################################
      set.seed(seed)
      index_all <- sample( x = 1:nrow(data),  
                     size = round(0.7*nrow(data) ))
    
      data_train <- data[index_all,]
      data_test <- data[-index_all,]
    
    

      set.seed(seed)
      index_present <- sample( x = 1:nrow(data_present),  
                       size = round(0.7*nrow(data_present) ))
    
      data_present_train <- data_present[index_present,]
      data_present_test <- data_present[-index_present,]
    
      ######################################
      ### predictors and response ##########
      ######################################
      predictors_train <- data.frame(data_train[,X_DOMS, drop = F])
      
      response_train <- data.frame(data_train[,b, drop = F])
    
      predictors_test <- data.frame(data_test[,X_DOMS, drop = F] )
    
      response_test <- data.frame(data_test[,b, drop = F])
    
      ######################################
      ### binary variables #################
      ######################################
      response_binary_train <-  as.numeric( response_train !=0 )
      response_binary_test <-  as.numeric( response_test !=0 )
    
      ##############################################
      ### present data: predictors and response ####
      ##############################################
      predictors_present_train  <- data.frame(data_present_train[,X_DOMS, drop = F])
    
      response_present_train <- data.frame(data_present_train[,b, drop = F])
    
      predictors_present_test  <- data.frame(data_present_test[, X_DOMS, drop = F])
    
      response_present_test  <- data.frame(data_present_test[,b, drop = F])
    
      ######################################
      #### train RF: presnece absence ######
      ######################################
      set.seed(seed = 111)
      
      if (binary_method == "rf") {
        model_c <- randomForest( factor(response_binary_train) ~ ., 
                                 data = predictors_train,  
                                 ntree = 1000,
                                 mtry = 1,
                                 replace = T,
                                 nodesize = 10,
                                 cutoff = c(0.5,0.5)
                                )
      } 
      
      if (binary_method == "svm") {
        predictors_train <- predictors_train[,colSums(predictors_present_train) > 0, drop=FALSE  ]
        model_c <- svm( factor(response_binary_train) ~ ., 
                                   data = predictors_train )
      } 
      
      
      ######################################
      #### train RF: abundance #############
      ######################################
      set.seed(seed = 111)
      if (regression_method == "rf") {
        model_r <- randomForest( response_present_train[,1] ~ . , 
                                 data = predictors_present_train,
                                 ntree = 1000,
                                 replace = T,
                                 nodesize = 1)
      } 
      
      
      if (regression_method == "svm") { 
        predictors_present_train <- predictors_present_train[,colSums(predictors_present_train) > 0, drop=FALSE  ]
        model_r <- svm( response_present_train[,1] ~ . , 
                          data =  predictors_present_train )
      } 
      
      if (regression_method == "lm") { 
        model_r <- lm( response_present_train[,1] ~ . , 
                         data = predictors_present_train )
      } 
    
      ######################################
      ### compute predictions ##############
      ######################################
      pred_c <- predict(model_c, predictors_test )
      pred_c <- as.logical(as.numeric(as.character(pred_c)))
    
      predictors_test_redu <- data.frame(predictors_test[pred_c,])
      colnames(predictors_test_redu) <- X_DOMS
    
      pred_r <- predict(model_r,predictors_test_redu)
    
      pred_d <- pred_c 
      pred_d[ ! pred_c  ] <- 0
      pred_d[ pred_c ] <- pred_r
    
      ######################################
      ### compute perfomance stat ##########
      ######################################
      x_cor <- cor.test(response_test[,1] , pred_d)
      x_mse <- mean( (pred_d - response_test[,1] )^2 )
      x_r2 <- rSquared(response_test[,1], pred_d - response_test[,1])
    
      ######################################
      ### save output ######################
      ######################################
      results <- list(cor =  x_cor$estimate, 
                      cor.pvalue = x_cor$p.value,
                      mse = x_mse, 
                      r2 = x_r2, 
                      pred_vs_resp =  cbind(pred = pred_d, resp = response_test[,1]),
                      index = index_all,
                      binary_model = model_c,
                      regression_model = model_r
                      )
    
      return.list[[b]] <-  results
   }
  }
return(return.list)
}



#######################################################################
############### Iterate classifications ###############################
#######################################################################

iter_model_fun <- function(bgc, data, binary_method, regression_method, class2dom, iter) {
  
  return.list <- list()
  
  for (b in bgc) {
    for (i in 1:iter) {
      
      tmp <- double_models_fun(bgc = b, 
                              data = data,
                              binary_method = binary_method,
                              regression_method = regression_method,
                              seed = i,
                              class2dom = class2dom
                              )
      
      
      istr <- paste("iteration",i,sep="")
      return.list[[b]][[istr]] <- tmp[[b]]
      
    }
  }
  return(return.list)
}





