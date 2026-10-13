# 분석 설정 ------------------------------------------------------------------
DATA_PATH   <- "data/sandbox_projects.csv"
OUTPUT_DIR  <- "output"
CUTOFF_DATE <- as.Date("2026-09-30")   # 관측 종료일(데이터 수집 기준일)로 변경
TIME_UNIT   <- 365.25 / 12             # 일 -> 월
COVARIATES  <- c("sandbox_type", "field", "company_size", "designation_year")

dir.create(OUTPUT_DIR, showWarnings = FALSE, recursive = TRUE)

# 그래프 한글 폰트: Windows "Malgun Gothic", macOS "AppleGothic", Linux "NanumGothic"
PLOT_FONT <- switch(Sys.info()[["sysname"]],
                    Windows = "Malgun Gothic", Darwin = "AppleGothic", "NanumGothic")
if (requireNamespace("ggplot2", quietly = TRUE)) {
  ggplot2::theme_set(ggplot2::theme_minimal(base_family = PLOT_FONT))
}
