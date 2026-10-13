# Cox 비례위험모형 + 비례위험 가정 검정 --------------------------------------
suppressPackageStartupMessages({
  library(survival)
  library(survminer)
  library(dplyr)
})
source("R/config.R")
surv_df <- readRDS(file.path(OUTPUT_DIR, "surv_df.rds"))

# 수준이 2개 이상이고 결측이 적은 공변량만 사용
usable <- Filter(function(v) v %in% names(surv_df) &&
                   nlevels(droplevels(factor(surv_df[[v]]))) >= 2 &&
                   mean(is.na(surv_df[[v]])) < 0.3, COVARIATES)
if (length(usable) == 0) stop("Cox 모형에 사용할 공변량이 없습니다.")

d <- surv_df %>% filter(if_all(all_of(usable), ~ !is.na(.))) %>%
  mutate(across(all_of(usable), ~ droplevels(factor(.)))) %>%
  as.data.frame()
f <- as.formula(paste("Surv(time, event) ~", paste(usable, collapse = " + ")))
fit <- coxph(f, data = d, ties = "efron")

sink(file.path(OUTPUT_DIR, "cox.txt"))
cat("모형:", deparse(f), "\n분석 과제 수:", nrow(d), " 사건 수:", sum(d$event), "\n\n")
print(summary(fit))
cat("\n== 비례위험 가정 검정 (Schoenfeld residuals) ==\n")
zph <- cox.zph(fit)
print(zph)
sink()
cat(readLines(file.path(OUTPUT_DIR, "cox.txt")), sep = "\n")

hr <- data.frame(
  term = names(coef(fit)),
  HR = exp(coef(fit)),
  lower = exp(confint(fit))[, 1],
  upper = exp(confint(fit))[, 2],
  p = summary(fit)$coefficients[, "Pr(>|z|)"]
)
write.csv(hr, file.path(OUTPUT_DIR, "cox_hr.csv"), row.names = FALSE, fileEncoding = "UTF-8")

ggsave(file.path(OUTPUT_DIR, "cox_forest.png"), ggforest(fit, data = d),
       width = 8, height = 6, dpi = 300)
png(file.path(OUTPUT_DIR, "cox_zph.png"), width = 2400, height = 1800, res = 300, family = PLOT_FONT)
plot(zph)
dev.off()
