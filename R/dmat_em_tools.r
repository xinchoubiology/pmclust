### This file contains files for estimating parameters emperically.

### This function collects N.CLASS
get.N.CLASS.dmat <- function(K){
  tabulate(.pmclustEnv$CLASS.dmat, nbins = K)
} # End of get.N.CLASS.dmat().
