#!/usr/bin/env bash
set +e  # never kill the terminal

mkdir -p artifacts/logs

ts="$(date +%Y%m%d_%H%M%S)"
log="artifacts/logs/pipeline_${ts}.log"

echo "Logging to: ${log}"
Rscript scripts/run_steps.R 2>&1 | tee "${log}"
echo
echo "Log saved: ${log}"
exit 0
