# 원자료 -> 분석용 생존 데이터 -----------------------------------------------
suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
})
source("R/config.R")

raw <- read_csv(DATA_PATH, col_types = cols(.default = col_character()),
                locale = locale(encoding = "UTF-8"))

stopifnot(all(c("project_id", "designation_date", "sandbox_type") %in% names(raw)))

parse_date <- function(x) as.Date(ifelse(is.na(x) | trimws(x) == "", NA, x))

surv_df <- raw %>%
  mutate(
    designation_date = parse_date(designation_date),
    law_amended_date = parse_date(law_amended_date),
    termination_date = parse_date(termination_date)
  ) %>%
  filter(!is.na(designation_date), designation_date <= CUTOFF_DATE) %>%
  mutate(
    # 관측 종료일 이후의 사건은 관측되지 않은 것으로 처리
    law_amended_date = if_else(law_amended_date > CUTOFF_DATE, as.Date(NA), law_amended_date),
    termination_date = if_else(termination_date > CUTOFF_DATE, as.Date(NA), termination_date),
    amended_first = !is.na(law_amended_date) &
      (is.na(termination_date) | law_amended_date <= termination_date),
    terminated_first = !is.na(termination_date) & !amended_first,
    end_date = case_when(
      amended_first    ~ law_amended_date,
      terminated_first ~ termination_date,
      TRUE             ~ CUTOFF_DATE
    ),
    # 0 = 중도절단, 1 = 법령 정비, 2 = 법령 정비 전 종료(경쟁위험)
    status = case_when(amended_first ~ 1L, terminated_first ~ 2L, TRUE ~ 0L),
    event  = as.integer(status == 1L),
    time   = as.numeric(end_date - designation_date) / TIME_UNIT,
    designation_year = factor(format(designation_date, "%Y")),
    sandbox_type = factor(sandbox_type),
    field        = factor(if ("field" %in% names(.)) field else NA),
    company_size = factor(if ("company_size" %in% names(.)) company_size else NA)
  )

bad <- surv_df %>% filter(time < 0)
if (nrow(bad) > 0) {
  warning("사건일이 지정일보다 빠른 과제를 제외합니다: ", paste(bad$project_id, collapse = ", "))
  surv_df <- surv_df %>% filter(time >= 0)
}
# 지정 당일 사건은 0이 되지 않도록 반나절로 보정
surv_df <- surv_df %>% mutate(time = pmax(time, 0.5 / 30.4375))

saveRDS(surv_df, file.path(OUTPUT_DIR, "surv_df.rds"))

cat("과제 수:", nrow(surv_df), "\n")
print(table(status = factor(surv_df$status, 0:2, c("중도절단", "법령정비", "중단(경쟁위험)"))))
