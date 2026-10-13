# ict-sandbox-survival 디렉터리에서 실행: Rscript run_all.R
for (s in c("R/01_prepare.R", "R/02_km_logrank.R", "R/03_cox.R", "R/04_competing_risks.R")) {
  cat("\n>>>", s, "\n")
  source(s, encoding = "UTF-8")
}
