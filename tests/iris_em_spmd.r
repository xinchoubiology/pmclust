# File name: iris_dmat.r
# Run: mpiexec -np 4 Rscript iris_dmat.r

rm(list = ls())                                       # Clean environment
library(pbdDMAT, quietly = TRUE)                      # Load library
init.grid()
if(comm.size() >= 150 )
  comm.stop("Too many processors.")

### Load data
X <- as.matrix(iris[, -5])                            # Dimension 150 by 4
X.cid <- as.numeric(iris[, 5])                        # True id

### Convert to matrix
X.spmd <- as.matrix(X)

### Standardized
X.std <- scale(X.spmd)
jid <- get.jid(nrow(X.std))
X.std <- X.std[jid,]

### Clustering
library(pmclust, quietly = TRUE)
comm.set.seed(123, diff = TRUE)

X.spmd <- X.std
PARAM.org <- set.global(K = 3)                        # Preset storage
.pmclustEnv$CONTROL$debug <- 1                        # Disable debug messages
PARAM.org <- initial.em(PARAM.org)
# PARAM.org <- initial.RndEM(PARAM.org)
PARAM.mbc <- em.step(PARAM.org)                       # model-based
em.update.class()
mb.print(PARAM.mbc, .pmclustEnv$CHECK)

### Get results.
N.CLASS <- get.N.CLASS(K = 3)
comm.cat("# of class:", N.CLASS, "\n")

### Finish
finalize()
