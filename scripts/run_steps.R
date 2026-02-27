safe_run <- function(name, fn) {
  cat("\n============================\n")
  cat("STEP:", name, "\n")
  cat("============================\n")
  ok <- TRUE
  err <- NULL
  t0 <- Sys.time()

  tryCatch(fn(), error = function(e){ ok <<- FALSE; err <<- e$message })

  cat("Elapsed:", round(as.numeric(difftime(Sys.time(), t0, units="secs")), 2), "sec\n")
  if (!ok) {
    cat("FAIL:", name, "\n")
    cat("ERROR:", err, "\n")
  } else {
    cat("OK:", name, "\n")
  }
  return(ok)
}

source("src/pipelines/run_cleaning.R")
source("src/pipelines/run_encoding.R")
source("src/pipelines/run_scaling.R")
source("src/pipelines/run_eda.R")
source("src/pipelines/run_features.R")

results <- c(
  cleaning  = safe_run("cleaning",  function() run_cleaning_pipeline(na_strategy = "drop")),
  encoding  = safe_run("encoding",  run_encoding_pipeline),
  scaling   = safe_run("scaling",   function() run_scaling_pipeline(exclude = c("id", "diagnosed_diabetes"))),
  eda       = safe_run("EDA",       run_eda_pipeline),
  features  = safe_run("features",  run_features_pipeline)
)

cat("\n============================\n")
cat("SUMMARY\n")
cat("============================\n")
print(results)

if (all(results)) {
  cat("\nALL STEPS OK\n")
} else {
  cat("\nONE OR MORE STEPS FAILED (see logs above)\n")
}
