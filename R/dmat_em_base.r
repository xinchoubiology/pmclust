### This file contains major functions for EM iterations.

### E-step.
e.step.dmat <- function(PARAM, update.logL = TRUE){
  for(i.k in 1:PARAM$K){
    logdmvnorm.dmat(PARAM, i.k)
  }

  update.expectation.dmat(PARAM, update.logL = update.logL)
  invisible()
} # End of e.step.dmat().

### z_nk / sum_k z_n might have numerical problems if z_nk all underflowed.
update.expectation.dmat <- function(PARAM, update.logL = TRUE){
  if(exists("X.dmat", envir = .pmclustEnv)){
    X.dmat <- get("X.dmat", envir = .pmclustEnv)
  }

  N <- PARAM$N
  K <- PARAM$K

  ### WCC: original
  # .pmclustEnv$U.dmat <- sweep(.pmclustEnv$W.dmat, 2, PARAM$log.ETA)
  # .pmclustEnv$Z.dmat <- exp(.pmclustEnv$U.dmat)
  ### WCC: debugging
  tmp.1 <- sweep(.pmclustEnv$W.dmat, 2, PARAM$log.ETA)
  tmp.2 <- exp(.pmclustEnv$U.dmat)
  .pmclustEnv$U.dmat <- tmp.1
  .pmclustEnv$Z.dmat <- tmp.2

  ### WCC: original
  # tmp.id <- rowSums(.pmclustEnv$U.dmat < .pmclustEnv$CONTROL$exp.min) == K |
  #           rowSums(.pmclustEnv$U.dmat > .pmclustEnv$CONTROL$exp.max) > 0
  ### WCC: debugging
  tmp.1 <- .pmclustEnv$U.dmat < .pmclustEnv$CONTROL$exp.min
  tmp.2 <- rowSums(tmp.1)
  tmp.3 <- tmp.2 == K
  tmp.4 <- .pmclustEnv$U.dmat > .pmclustEnv$CONTROL$exp.max
  tmp.5 <- rowSums(tmp.4)
  tmp.6 <- tmp.5 > 0
  tmp.7 <- tmp.3 | tmp.6
  tmp.id <- tmp.7

  ### WCC: original
  # tmp.flag <- sum(tmp.id)
  ### WCC: debugging
  tmp.1 <- sum(tmp.id)
  tmp.flag <- tmp.1
  if(tmp.flag > 0){
    ### WCC: original
    # tmp.dmat <- .pmclustEnv$U.dmat[tmp.id,]
    ### WCC: debugging
    tmp.1 <- tmp.id
    tmp.2 <- .pmclustEnv$U.dmat[tmp.1,]
    tmp.dmat <- tmp.2

    if(tmp.flag == 1){
      ### WCC: original
      # tmp.scale <- max(tmp.dmat) - .pmclustEnv$CONTROL$exp.max / K
      ### WCC: debugging
      tmp.1 <- max(tmp.dmat)
      tmp.2 <- tmp.1 - .pmclustEnv$CONTROL$exp.max / K
      tmp.scale <- tmp.2
    } else{
      ### WCC: original
      # tmp.scale <- apply(tmp.dmat, 1, max) - .pmclustEnv$CONTROL$exp.max / K
      ### WCC: debugging
      tmp.1 <- apply(tmp.dmat, 1, max)
      tmp.2 <- tmp.1 - .pmclustEnv$CONTROL$exp.max / K
      tmp.scale <- tmp.2
    }
    ### WCC: original
    # .pmclustEnv$Z.dmat[tmp.id,] <- exp(tmp.dmat - tmp.scale)
    ### WCC: debugging
    tmp.1 <- exp(tmp.dmat - tmp.scale)
    tmp.2 <- tmp.id
    .pmclustEnv$Z.dmat[tmp.2,] <- tmp.1 
  }

  ### WCC: original
  # .pmclustEnv$W.rowSums <- as.vector(rowSums(.pmclustEnv$Z.dmat))
  # .pmclustEnv$Z.dmat <- .pmclustEnv$Z.dmat / .pmclustEnv$W.rowSums
  ### WCC: debugging
  tmp.1 <- rowSums(.pmclustEnv$Z.dmat)
  tmp.2 <- as.vector(tmp.1)
  .pmclustEnv$W.rowSums <- tmp.2 
  tmp.1 <- .pmclustEnv$Z.dmat / .pmclustEnv$W.rowSums
  .pmclustEnv$Z.dmat <- tmp.1

  ### For semi-supervised clustering.
  # if(SS.clustering){
  #   .pmclustEnv$Z.spmd[SS.id.spmd,] <- SS..pmclustEnv$Z.spmd
  # }

  ### WCC: original
  # .pmclustEnv$Z.colSums <- as.vector(colSums(.pmclustEnv$Z.dmat))
  ### WCC: debugging
  tmp.1 <- colSums(.pmclustEnv$Z.dmat)
  tmp.2 <- as.vector(tmp.1)
  .pmclustEnv$Z.colSums <- tmp.2

  if(update.logL){
    .pmclustEnv$W.rowSums <- log(.pmclustEnv$W.rowSums)
    if(tmp.flag){
      .pmclustEnv$W.rowSums[tmp.id] <-
        .pmclustEnv$W.rowSums[tmp.id] + tmp.scale
    }
  }
  invisible()
} # End of update.expectation.dmat().


### M-step.
m.step.dmat <- function(PARAM){
  if(exists("X.dmat", envir = .pmclustEnv)){
    X.dmat <- get("X.dmat", envir = .pmclustEnv)
  }

  ### MLE For ETA
  PARAM$ETA <- .pmclustEnv$Z.colSums / sum(.pmclustEnv$Z.colSums)
  PARAM$log.ETA <- log(PARAM$ETA)

  p <- PARAM$p
  p.2 <- p * p
  for(i.k in 1:PARAM$K){
    ### MLE for MU
    ### WCC: original
    # B <- colSums(X.dmat * as.vector(.pmclustEnv$Z.dmat[, i.k])) /
    #      .pmclustEnv$Z.colSums[i.k]
    # PARAM$MU[, i.k] <- as.vector(B)
    ### WCC: debugging
    tmp.1 <- as.vector(.pmclustEnv$Z.dmat[, i.k])
    tmp.2 <- X.dmat * tmp.1
    tmp.3 <- colSums(tmp.2)
    tmp.4 <- tmp.3 / .pmclustEnv$Z.colSums[i.k]
    tmp.5 <- as.vector(tmp.4)
    PARAM$MU[, i.k] <- tmp.5

    ### MLE for SIGMA
    if(PARAM$U.check[[i.k]]){
      ### WCC: original
      # B <- sweep(X.dmat, 2, PARAM$MU[, i.k]) *
      #      as.vector(sqrt(.pmclustEnv$Z.dmat[, i.k]) /
      #                .pmclustEnv$Z.colSums[i.k])
      ### WCC: debugging
      tmp.1 <- sweep(X.dmat, 2, PARAM$MU[, i.k])
      tmp.2 <- .pmclustEnv$Z.dmat[, i.k]
      tmp.3 <- sqrt(tmp.2)
      tmp.4 <- tmp.3 / .pmclustEnv$Z.colSums[i.k]
      tmp.5 <- as.vector(tmp.4)
      tmp.6 <- tmp.1 * tmp.5
      B <- tmp.6

      ### WCC: original
      # tmp.SIGMA <- as.matrix(crossprod(B))
      # dim(tmp.SIGMA) <- c(p, p)
      ### WCC: debugging
      tmp.1 <- crossprod(B)
      tmp.2 <- as.matrix(tmp.1)
      tmp.SIGMA <- tmp.2 
      dim(tmp.SIGMA) <- c(p, p)

      tmp.U <- decompsigma(tmp.SIGMA)
      PARAM$U.check[[i.k]] <- tmp.U$check
      if(tmp.U$check){
        PARAM$U[[i.k]] <- tmp.U$value
        PARAM$SIGMA[[i.k]] <- tmp.SIGMA
      }
    } else{
      if(.pmclustEnv$CONTROL$debug > 2){
        comm.cat("  SIGMA[[", i.k, "]] is fixed.\n", sep = "", quiet = TRUE)
      }
    }
  }

  PARAM
} # End of m.step.dmat().


### log likelihood.
logL.step.dmat <- function(){
  tmp.logL <- sum(.pmclustEnv$W.rowSums)
  tmp.logL
} # End of logL.step.dmat().


### EM-step.
em.step.dmat <- function(PARAM.org){
  .pmclustEnv$CHECK <- list(algorithm = "em", i.iter = 0, abs.err = Inf,
                            rel.err = Inf, convergence = 0)
  i.iter <- 1
  PARAM.org$logL <- -.Machine$double.xmax

  ### For debugging.
  if((!is.null(.pmclustEnv$CONTROL$save.log)) && .pmclustEnv$CONTROL$save.log){
    if(! exists("SAVE.iter", envir = .pmclustEnv)){
      .pmclustEnv$SAVE.param <- NULL
      .pmclustEnv$SAVE.iter <- NULL
      .pmclustEnv$CLASS.iter.org <- unlist(apply(.pmclustEnv$Z.dmat, 1,
                                                 which.max))
    }
  }

  repeat{
    ### For debugging.
    if((!is.null(.pmclustEnv$CONTROL$save.log)) &&
        .pmclustEnv$CONTROL$save.log){
      time.start <- proc.time()
    }

    PARAM.new <- try(em.onestep.dmat(PARAM.org))
    if(class(PARAM.new) == "try-error"){
      comm.cat("Results of previous iterations are returned.\n", quiet = TRUE)
      .pmclustEnv$CHECK$convergence <- 99
      PARAM.new <- PARAM.org
      break
    }

    .pmclustEnv$CHECK <- check.em.convergence(PARAM.org, PARAM.new, i.iter)
    if(.pmclustEnv$CHECK$convergence > 0){
      break
    }

    ### For debugging.
    if((!is.null(.pmclustEnv$CONTROL$save.log)) &&
        .pmclustEnv$CONTROL$save.log){
      tmp.time <- proc.time() - time.start

      .pmclustEnv$SAVE.param <- c(.pmclustEnv$SAVE.param, PARAM.new)
      CLASS.iter.new <- unlist(apply(.pmclustEnv$Z.dmat, 1, which.max))
      tmp <- as.double(sum(CLASS.iter.new != .pmclustEnv$CLASS.iter.org))
      tmp.all <- c(tmp / PARAM.new$N, PARAM.new$logL,
                   PARAM.new$logL - PARAM.org$logL,
                   (PARAM.new$logL - PARAM.org$logL) / PARAM.org$logL)
      .pmclustEnv$SAVE.iter <- rbind(.pmclustEnv$SAVE.iter,
                                     c(tmp, tmp.all, tmp.time))
      .pmclustEnv$CLASS.iter.org <- CLASS.iter.new
    }

    PARAM.org <- PARAM.new
    i.iter <- i.iter + 1
  }

  PARAM.new
} # End of em.step.dmat().

em.onestep.dmat <- function(PARAM){
#  if(.pmclustEnv$COMM.RANK == 0){
#    Rprof(filename = "em.Rprof", append = TRUE)
#  }

  PARAM <- m.step.dmat(PARAM)
  e.step.dmat(PARAM)

#  if(.pmclustEnv$COMM.RANK == 0){
#    Rprof(NULL)
#  }

  PARAM$logL <- logL.step.dmat()

  if(.pmclustEnv$CONTROL$debug > 0){
    comm.cat(">>em.onestep: ", format(Sys.time(), "%H:%M:%S"),
             ", iter: ", .pmclustEnv$CHECK$iter, ", logL: ",
                         sprintf("%-30.15f", PARAM$logL), "\n",
             sep = "", quiet = TRUE)
    if(.pmclustEnv$CONTROL$debug > 4){
      logL <- indep.logL.dmat(PARAM)
      comm.cat("  >>indep.logL: ", sprintf("%-30.15f", logL), "\n",
               sep = "", quiet = TRUE)
    }
    if(.pmclustEnv$CONTROL$debug > 20){
      mb.print(PARAM, .pmclustEnv$CHECK)
    }
  }

  PARAM
} # End of em.onestep.dmat().


### Obtain classifications.
em.update.class.dmat <- function(){
  ### WCC: original
  # .pmclustEnv$CLASS.dmat <- apply(.pmclustEnv$Z.dmat, 1, which.max)
  # invisible()
  ### WCC: debugging
  tmp.1 <- apply(.pmclustEnv$Z.dmat, 1, which.max)
  .pmclustEnv$CLASS.dmat <- tmp.1 
  invisible()
} # End of em.update.class.dmat().

