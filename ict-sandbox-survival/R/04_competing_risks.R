# 경쟁위험 분석: 법령정비 전 사업 중단을 경쟁사건으로 처리 -------------------
# 중단 과제를 단순 중도절단하면 법령정비 누적확률을 과대추정하므로,
# Aalen-Johansen 누적발생함수(CIF)와 Fine-Gray 부분분포 위험모형을 함께 봅니다.
suppressPackageStartupMessages({
  library(survival)
  library(dplyr)
  library(ggplot2)
})
source("R/config.R")
surv_df <- readRDS(file.path(OUTPUT_DIR, "surv_df.rds"))

if (sum(surv_df$status == 2) == 0) {
  message("경쟁사건(법령정비 전 종료)이 없어 경쟁위험 분석을 건너뜁니다.")
} else {

d <- surv_df %>%
  mutate(cr = factor(status, 0:2, c("censor", "amended", "terminated")))

aj <- survfit(Surv(time, cr) ~ 1, data = d)
sink(file.path(OUTPUT_DIR, "competing_risks.txt"))
cat("== Aalen-Johansen 누적발생함수 ==\n")
print(summary(aj, times = c(12, 24, 36, 48), extend = TRUE))

cif <- data.frame(time = aj$time,
                  amended = aj$pstate[, which(aj$states == "amended")],
                  terminated = aj$pstate[, which(aj$states == "terminated")])
plot_df <- rbind(data.frame(time = cif$time, cif = cif$amended, event = "법령정비"),
                 data.frame(time = cif$time, cif = cif$terminated, event = "정비 전 종료"))
p <- ggplot(plot_df, aes(time, cif, colour = event)) + geom_step(linewidth = 0.8) +
  labs(x = "지정 후 경과 기간(개월)", y = "누적발생확률", colour = NULL) +
  scale_x_continuous(breaks = seq(0, 120, 12))
ggsave(file.path(OUTPUT_DIR, "cif.png"), p, width = 8, height = 5, dpi = 300)

usable <- Filter(function(v) v %in% names(d) &&
                   nlevels(droplevels(factor(d[[v]]))) >= 2 &&
                   mean(is.na(d[[v]])) < 0.3, COVARIATES)
if (length(usable) > 0) {
  dd <- d %>% filter(if_all(all_of(usable), ~ !is.na(.))) %>%
    mutate(across(all_of(usable), ~ droplevels(factor(.))))
  fg_data <- finegray(Surv(time, cr) ~ ., data = dd[, c("time", "cr", usable)],
                      etype = "amended")
  f <- as.formula(paste("Surv(fgstart, fgstop, fgstatus) ~",
                        paste(usable, collapse = " + ")))
  fg <- coxph(f, data = fg_data, weights = fgwt)
  cat("\n== Fine-Gray 부분분포 위험모형 (사건 = 법령정비) ==\n")
  print(summary(fg))
}
sink()
cat(readLines(file.path(OUTPUT_DIR, "competing_risks.txt")), sep = "\n")
}
