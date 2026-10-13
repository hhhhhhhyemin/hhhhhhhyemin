# Kaplan-Meier, 누적 법령정비율, Log-rank 검정 ------------------------------
suppressPackageStartupMessages({
  library(survival)
  library(survminer)
  library(dplyr)
})
source("R/config.R")
surv_df <- readRDS(file.path(OUTPUT_DIR, "surv_df.rds"))

save_survplot <- function(p, name) {
  png(file.path(OUTPUT_DIR, name), width = 2400, height = 2000, res = 300, family = PLOT_FONT)
  print(p, newpage = FALSE)
  dev.off()
}

sink(file.path(OUTPUT_DIR, "km_logrank.txt"))

fit_all <- survfit(Surv(time, event) ~ 1, data = surv_df)
cat("== 전체 KM ==\n")
print(fit_all)
cat("\n12/24/36/48개월 시점 누적 법령정비율 (1 - S(t)):\n")
s <- summary(fit_all, times = c(12, 24, 36, 48), extend = TRUE)
print(data.frame(month = s$time, n_risk = s$n.risk,
                 cum_amended = round(1 - s$surv, 3),
                 lower = round(1 - s$upper, 3), upper = round(1 - s$lower, 3)))

p <- ggsurvplot(fit_all, data = surv_df, ggtheme = theme_survminer(base_family = PLOT_FONT),
                fun = "event", conf.int = TRUE,
                risk.table = TRUE, xlab = "지정 후 경과 기간(개월)",
                ylab = "누적 법령정비 확률", legend = "none",
                break.time.by = 12)
save_survplot(p, "km_overall.png")

for (v in setdiff(COVARIATES, character(0))) {
  if (!v %in% names(surv_df) || nlevels(droplevels(surv_df[[v]])) < 2) next
  d <- surv_df %>% filter(!is.na(.data[[v]])) %>% mutate(grp = droplevels(.data[[v]]))
  fit <- survfit(Surv(time, event) ~ grp, data = d)
  cat("\n== Log-rank:", v, "==\n")
  print(survdiff(Surv(time, event) ~ grp, data = d))
  p <- ggsurvplot(fit, data = d, ggtheme = theme_survminer(base_family = PLOT_FONT),
                fun = "event", pval = TRUE, risk.table = TRUE,
                  legend.title = v, legend.labs = levels(d$grp),
                  xlab = "지정 후 경과 기간(개월)", ylab = "누적 법령정비 확률",
                  break.time.by = 12)
  save_survplot(p, paste0("km_by_", v, ".png"))
}
sink()
cat(readLines(file.path(OUTPUT_DIR, "km_logrank.txt")), sep = "\n")
