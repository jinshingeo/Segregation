# Word 문서 생성 스크립트 (officer + flextable 패키지 사용)
library(officer)
library(flextable)
library(magrittr)

doc <- read_docx()

# ---- 제목 ----
doc <- doc %>%
  body_add_par("White(1983) 공간 인접성 지수(SP) 패키지 설명서",
               style = "heading 1") %>%
  body_add_par(
    "논문 출처: White, M.J. (1983). The Measurement of Spatial Segregation. American Journal of Sociology, 88(5), 1008-1018.",
    style = "Normal") %>%
  body_add_par(
    "관련 참고: Massey, D.S. & Denton, N.A. (1988). The Dimensions of Residential Segregation. Social Forces, 67, 281-315.",
    style = "Normal") %>%
  body_add_par("", style = "Normal")

# ---- 1. 논문 개요 ----
doc <- doc %>%
  body_add_par("1. 논문 개요", style = "heading 2") %>%
  body_add_par("1.1 연구 배경 — Massey & Denton(1988)의 5개 분리 차원", style = "heading 3")

dim_tbl <- data.frame(
  차원 = c("균등성(Evenness)", "노출(Exposure)", "집중(Concentration)",
           "중심화(Centralization)", "군집(Clustering)"),
  개념 = c(
    "집단 비율이 도시 전체 비율과 얼마나 일치하는가",
    "소수집단과 다수집단이 얼마나 이웃하는가",
    "소수집단이 차지하는 물리적 공간의 크기",
    "소수집단이 도심부에 얼마나 집중되어 있는가",
    "소수집단 거주지역들이 서로 얼마나 인접하여 덩어리를 이루는가"
  )
)
ft1 <- flextable(dim_tbl) %>% autofit() %>% theme_vanilla() %>%
  bold(i = 5, bold = TRUE)  # 군집 행 강조
doc <- doc %>%
  body_add_flextable(ft1) %>%
  body_add_par("", style = "Normal") %>%
  body_add_par(
    "SP 지수는 군집성(Clustering) 차원의 표준 지표로 선정되었다.",
    style = "Normal") %>%
  body_add_par("", style = "Normal")

# ---- 1.2 D 지수와의 차이 ----
doc <- doc %>%
  body_add_par("1.2 기존 D 지수와의 차이", style = "heading 3")

diff_tbl <- data.frame(
  구분 = c("D (비유사성 지수)", "SP (공간 인접성 지수)"),
  질문 = c(
    "각 지역의 집단 비율이 도시 전체 비율에서 얼마나 벗어나는가?",
    "같은 집단 사람들끼리 서로 얼마나 가까운 위치에 있는가?"
  ),
  공간고려 = c("없음 (aspatial)", "있음 (거리 기반)"),
  체커보드문제 = c("해결 불가", "해결 가능")
)
ft2 <- flextable(diff_tbl) %>% autofit() %>% theme_vanilla()
doc <- doc %>%
  body_add_flextable(ft2) %>%
  body_add_par("", style = "Normal")

# ---- 2. 핵심 수식 ----
doc <- doc %>%
  body_add_par("2. 핵심 수식", style = "heading 2") %>%
  body_add_par("2.1 거리 계산", style = "heading 3") %>%
  body_add_par(
    "구역 간 거리 (유클리드): d_ij = sqrt((x_i - x_j)^2 + (y_i - y_j)^2)",
    style = "Normal") %>%
  body_add_par(
    "구역 내부 평균 거리 (White 1983 근사): d_ii ≈ 0.6 * sqrt(A_i)",
    style = "Normal") %>%
  body_add_par("", style = "Normal")

dist_var_tbl <- data.frame(
  기호 = c("x_i, y_i", "A_i", "d_ij", "d_ii"),
  의미 = c(
    "tract i 중심점의 좌표 (km)",
    "tract i의 면적 (km²)",
    "tract i와 j 중심점 간의 직선 거리",
    "같은 tract 내부 평균 거리 (면적 근사)"
  )
)
ft3 <- flextable(dist_var_tbl) %>% autofit() %>% theme_vanilla()
doc <- doc %>%
  body_add_flextable(ft3) %>%
  body_add_par("", style = "Normal")

# ---- 2.2 근접성 함수 ----
doc <- doc %>%
  body_add_par("2.2 근접성 함수 (Proximity Function)", style = "heading 3") %>%
  body_add_par(
    "c_ij = f(d_ij) = exp(-d_ij)",
    style = "Normal") %>%
  body_add_par(
    "거리가 0일 때: c_ij = 1 (최대 근접). 거리 증가에 따라 0으로 수렴. 대안: c_ij = 1/d_ij (역거리 가중치)",
    style = "Normal") %>%
  body_add_par("", style = "Normal")

# ---- 2.3 평균 근접도 ----
doc <- doc %>%
  body_add_par("2.3 집단별 평균 근접도 (Average Proximity)", style = "heading 3") %>%
  body_add_par(
    "P_xx = [Σ_i Σ_j x_i * x_j * c_ij] / X^2",
    style = "Normal") %>%
  body_add_par(
    "P_yy = [Σ_i Σ_j y_i * y_j * c_ij] / Y^2",
    style = "Normal") %>%
  body_add_par(
    "P_xy = [Σ_i Σ_j x_i * y_j * c_ij] / (X * Y)",
    style = "Normal") %>%
  body_add_par(
    "P_tt = [Σ_i Σ_j t_i * t_j * c_ij] / T^2",
    style = "Normal") %>%
  body_add_par("", style = "Normal")

prox_var_tbl <- data.frame(
  기호 = c("x_i", "y_i", "t_i", "X", "Y", "T", "c_ij"),
  의미 = c(
    "tract i의 집단 X(소수집단) 인구 수",
    "tract i의 집단 Y(다수집단) 인구 수",
    "tract i의 총 인구 수 (= x_i + y_i)",
    "도시 전체 집단 X 인구 수",
    "도시 전체 집단 Y 인구 수",
    "도시 전체 인구 수 (= X + Y)",
    "tract i와 j 간의 근접성 함수 값"
  )
)
ft4 <- flextable(prox_var_tbl) %>% autofit() %>% theme_vanilla()
doc <- doc %>%
  body_add_flextable(ft4) %>%
  body_add_par("", style = "Normal")

# ---- 2.4 항등식 ----
doc <- doc %>%
  body_add_par("2.4 항등식 (Identity)", style = "heading 3") %>%
  body_add_par(
    "T^2 * P_tt = X^2 * P_xx + 2*X*Y * P_xy + Y^2 * P_yy",
    style = "Normal") %>%
  body_add_par(
    "전체 인구의 근접도가 집단 내/간 근접도의 가중합임을 보여 주는 항등식. 계산 오류 점검에 사용.",
    style = "Normal") %>%
  body_add_par("", style = "Normal")

# ---- 2.5 SP 지수 ----
doc <- doc %>%
  body_add_par("2.5 SP 지수 (Index of Spatial Proximity)", style = "heading 3") %>%
  body_add_par(
    "SP = (X * P_xx + Y * P_yy) / (T * P_tt)",
    style = "Normal") %>%
  body_add_par("", style = "Normal")

sp_interp_tbl <- data.frame(
  "SP 값" = c("SP > 1.0", "SP = 1.0", "SP < 1.0"),
  의미 = c(
    "각 집단 구성원들이 자기 집단끼리 더 가깝게 모여 삶 → 군집성(분리) 강함",
    "두 집단의 공간적 분포가 동일 → 차별적인 군집성 없음",
    "이질 집단이 오히려 더 가까이 섞여 삶 → 강한 혼합 상태 (드문 경우)"
  ),
  check.names = FALSE
)
ft5 <- flextable(sp_interp_tbl) %>% autofit() %>% theme_vanilla()
doc <- doc %>%
  body_add_flextable(ft5) %>%
  body_add_par("", style = "Normal")

# ---- 3. 가정 및 주의사항 ----
doc <- doc %>%
  body_add_par("3. 가정 및 주의사항", style = "heading 2") %>%
  body_add_par(
    "가정 1: 서로 다른 tract에 사는 사람들은 해당 tract의 중심점에 산다고 가정",
    style = "Normal") %>%
  body_add_par(
    "가정 2: 같은 tract 내부 평균 거리 = 0.6 * sqrt(A_i) (면적 기반 근사)",
    style = "Normal") %>%
  body_add_par(
    "가정 3: 거리의 함수 f(d_ij)는 사회적 교류를 측정 (중력모형 등과 유사)",
    style = "Normal") %>%
  body_add_par("", style = "Normal") %>%
  body_add_par("한계:", style = "Normal") %>%
  body_add_par(
    "필요 정보량이 많음 / 계산 복잡성 O(n²) / 거리 정의 모호성 / 가중 함수 표준화 어려움",
    style = "Normal") %>%
  body_add_par("", style = "Normal")

# ---- 4. 패키지 함수 목록 ----
doc <- doc %>%
  body_add_par("4. 패키지 함수 목록", style = "heading 2")

func_tbl <- data.frame(
  함수명 = c(
    "compute_within_dist(area)",
    "compute_dist_matrix(coords, area)",
    "compute_proximity(d_matrix, method)",
    "compute_P_xx(x, cij)",
    "compute_P_yy(y, cij)",
    "compute_P_xy(x, y, cij)",
    "compute_P_tt(t, cij)",
    "compute_SP(x, y, cij)",
    "verify_identity(x, y, cij)"
  ),
  출력 = c(
    "구역 내부 거리 벡터",
    "완전 거리 행렬",
    "근접성 행렬",
    "집단 X 내 근접도",
    "집단 Y 내 근접도",
    "X-Y 간 근접도",
    "전체 인구 근접도",
    "SP 지수",
    "항등식 검증 결과"
  ),
  수식 = c(
    "d_ii ≈ 0.6√A_i",
    "d_ij (유클리드), d_ii",
    "c_ij = exp(-d_ij)",
    "P_xx",
    "P_yy",
    "P_xy",
    "P_tt",
    "SP = (X·P_xx + Y·P_yy)/(T·P_tt)",
    "T²P_tt = X²P_xx + 2XY·P_xy + Y²P_yy"
  )
)
ft6 <- flextable(func_tbl) %>% autofit() %>% theme_vanilla()
doc <- doc %>%
  body_add_flextable(ft6) %>%
  body_add_par("", style = "Normal")

# ---- 5. 파일 목록 ----
doc <- doc %>%
  body_add_par("5. 파일 목록", style = "heading 2")

file_tbl <- data.frame(
  파일 = c(
    "code/white1983_SP.R",
    "code/white1983_SP.ipynb",
    "report/overview.md",
    "report/overview.docx"
  ),
  설명 = c(
    "R 스크립트 (함수 정의 + 가상 도시 데모 + 함수별 검증)",
    "Python Jupyter 노트북 (동일 알고리즘 + 시각화 + 시나리오 비교)",
    "본 설명서 (Markdown)",
    "본 설명서 (Word 문서)"
  )
)
ft7 <- flextable(file_tbl) %>% autofit() %>% theme_vanilla()
doc <- doc %>%
  body_add_flextable(ft7) %>%
  body_add_par("", style = "Normal")

# ---- 6. 참고 문헌 ----
doc <- doc %>%
  body_add_par("6. 참고 문헌", style = "heading 2") %>%
  body_add_par(
    "White, M.J. (1983). The measurement of spatial segregation. American Journal of Sociology, 88(5), 1008-1018.",
    style = "Normal") %>%
  body_add_par(
    "Massey, D.S. & Denton, N.A. (1988). The dimensions of residential segregation. Social Forces, 67, 281-315.",
    style = "Normal") %>%
  body_add_par(
    "Jakubs, J.F. (1981). A distance-based segregation index. Journal of Socio-Economic Planning Sciences, 15, 129-141.",
    style = "Normal") %>%
  body_add_par(
    "Morgan, B.S. (1983). An alternate approach to the development of a distance-based measure of racial segregation. American Journal of Sociology, 88(6), 1237-1249.",
    style = "Normal")

# ---- 저장 ----
out_path <- "/Users/jin/홍교수님 수업/R_study/SP_index/report/overview.docx"
print(doc, target = out_path)
cat("Word 파일 생성 완료:", out_path, "\n")
