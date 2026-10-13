# ICT 규제샌드박스 생존분석 (R)

ICT 규제샌드박스 지정과제가 **지정(승인) 후 관련 법령이 정비되기까지 걸리는 기간**을 생존분석으로 추정하는 R 코드입니다.

## 연구 설계

| 항목 | 정의 |
|---|---|
| 분석 단위 | ICT 규제샌드박스 지정과제 (실증특례·임시허가) |
| 시작점 | 심의위원회 지정일 (`designation_date`) |
| 사건 | 관련 법령 개정 완료 (`law_amended_date`) |
| 경쟁위험 | 법령 정비 전 특례 취소·포기·사업 중단 (`termination_date`) |
| 중도절단 | 관측 종료일(`CUTOFF_DATE`)까지 미정비 |
| 시간 단위 | 개월 |

## 분석 내용

1. `R/01_prepare.R`: 원자료를 생존시간(`time`)과 상태(`status`: 0 중도절단, 1 법령정비, 2 경쟁위험)로 변환합니다.
2. `R/02_km_logrank.R`: Kaplan-Meier 누적 법령정비율(12/24/36/48개월)을 구하고, 특례유형·분야·기업규모·지정연도별 Log-rank 검정을 합니다.
3. `R/03_cox.R`: Cox 비례위험모형으로 HR과 95% CI를 추정하고, Schoenfeld 잔차로 비례위험 가정을 검정하며 forest plot을 그립니다.
4. `R/04_competing_risks.R`: Aalen-Johansen 누적발생함수(CIF)와 Fine-Gray 부분분포 위험모형을 적합합니다. 사업 중단 과제를 단순 중도절단으로 처리하면 정비확률이 과대추정되기 때문에 이 분석을 함께 합니다.

결과는 `output/`에 텍스트, CSV, PNG로 저장됩니다.

## 사용법

```r
install.packages(c("survival", "survminer", "dplyr", "readr", "ggplot2"))
```

1. `data/sandbox_projects_template.csv`를 `data/sandbox_projects.csv`로 복사합니다. 변수 정의는 `data/codebook.md`를 참고해 과제별로 채웁니다.
2. `R/config.R`에서 `CUTOFF_DATE`(데이터 수집 기준일)와 `COVARIATES`를 지정합니다.
3. 이 폴더를 작업 디렉터리로 지정한 뒤 실행합니다.

```bash
Rscript run_all.R
```

## 데이터 수집

다음 공개자료로 과제 목록을 구성합니다. 출처는 `data/codebook.md`에도 정리되어 있습니다.

- ICT 규제샌드박스 포털(과기정통부·NIPA)의 지정과제 목록
- 규제샌드박스 통합포털(국무조정실)의 법령 정비 현황
- 과기정통부 심의위원회 결과 보도자료
- 국가법령정보센터의 개정 법령 시행일

## 분석 시 유의점

- 같은 법령 개정으로 여러 과제가 동시에 정비되면 관측치가 독립이 아닙니다. 이 경우 `coxph(..., cluster = 법령ID)`로 강건 분산을 쓰는 것을 검토하세요.
- 2022년 정보통신융합법 개정 전후로 실증특례 연장·임시허가 전환 규정이 달라졌습니다. 지정연도(코호트)를 공변량이나 층(strata)으로 고려하세요.
- `law_amended_date`의 기준(공포일 또는 시행일)은 하나로 통일해야 합니다.
