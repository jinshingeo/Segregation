# Word 문서 생성 스크립트 (officer 패키지 사용)
# 실행 후 overview.docx 파일이 생성됨

library(officer)
library(flextable)
library(magrittr)

doc <- read_docx()

# ---- 제목 ----
doc <- doc %>%
  body_add_par("Morgan(1983) 거리감쇄 기반 상호작용 지수 패키지 설명서",
               style = "heading 1") %>%
  body_add_par(
    "논문 출처: Morgan, B.S. (1983). A distance-decay based interaction index to measure residential segregation. Area, 15(3), 211-217.",
    style = "Normal") %>%
  body_add_par("", style = "Normal")

# ---- 1. 논문 개요 ----
doc <- doc %>%
  body_add_par("1. 논문 개요", style = "heading 2") %>%
  body_add_par("1.1 연구 목적", style = "heading 3") %>%
  body_add_par(
    paste0(
      "이 논문은 주거 분리(residential segregation)를 측정하는 새로운 상호작용 지수인 PC*를 제안한다. ",
      "기존의 P* 지수가 같은 동네(tract) 안에서만 접촉 확률을 계산했다면, ",
      "PC*는 거리감쇄(distance-decay) 함수를 활용해 도시 전역(city-wide)의 접촉 확률을 추정한다."
    ),
    style = "Normal") %>%
  body_add_par("", style = "Normal") %>%
  body_add_par("1.2 기존 지수의 한계", style = "heading 3") %>%
  body_add_par(
    "D(비유사성 지수): 공간적 패턴보다 인구 구성 불균형에 치중",
    style = "Normal") %>%
  body_add_par(
    "P*(상호작용 지수): 같은 소구역 내 접촉만 반영. 실제로 사람들은 동네를 넘어 도시 전역에서 접촉함.",
    style = "Normal") %>%
  body_add_par("", style = "Normal")

# ---- 2. 핵심 수식 ----
doc <- doc %>%
  body_add_par("2. 핵심 수식", style = "heading 2") %>%
  body_add_par("2.1 기본 P* 지수 (Lieberson 1981)", style = "heading 3") %>%
  body_add_par(
    "수식: aPb* = sum_i (a_i / sum(a_i)) * (b_i / t_i)",
    style = "Normal") %>%
  body_add_par("", style = "Normal")

# 변수 설명 표
var_tbl1 <- data.frame(
  기호     = c("a_i", "b_i", "t_i", "sum(a_i)"),
  의미     = c(
    "i번째 소구역의 집단 A 인구 수",
    "i번째 소구역의 집단 B 인구 수",
    "i번째 소구역의 총 인구 수",
    "도시 전체 집단 A 인구 수"
  )
)
ft1 <- flextable(var_tbl1) %>%
  set_header_labels(기호 = "기호", 의미 = "의미") %>%
  autofit() %>%
  theme_vanilla()
doc <- doc %>%
  body_add_flextable(ft1) %>%
  body_add_par("", style = "Normal") %>%
  body_add_par(
    "해석: A 집단 구성원이 자신의 소구역 내에서 B 집단 구성원을 만날 확률. 0에 가까울수록 분리, 1에 가까울수록 혼합.",
    style = "Normal") %>%
  body_add_par("", style = "Normal")

# ---- 2.2 PC* 지수 ----
doc <- doc %>%
  body_add_par("2.2 PC* 지수 (Morgan 1983의 핵심 제안)", style = "heading 3") %>%
  body_add_par(
    "수식: aPCb* = sum_i (a_i / sum(a_i)) * [sum_j P_ij * (b_j / t_j)]",
    style = "Normal") %>%
  body_add_par(
    "P_ij 정의: P_ij = (C_ij * t_j) / sum_j(C_ij * t_j),   sum_j P_ij = 1.0",
    style = "Normal") %>%
  body_add_par("", style = "Normal")

var_tbl2 <- data.frame(
  기호 = c("a_i", "b_j", "t_j", "P_ij", "C_ij"),
  의미 = c(
    "tract i의 집단 A 인구 수",
    "zone j의 집단 B 인구 수",
    "zone j의 총 인구 수",
    "tract i 거주자가 zone j에서 접촉할 확률",
    "tract i와 zone j 간 추정 접촉률 (zone j 인구 1,000명당)"
  )
)
ft2 <- flextable(var_tbl2) %>% autofit() %>% theme_vanilla()
doc <- doc %>%
  body_add_flextable(ft2) %>%
  body_add_par("", style = "Normal") %>%
  body_add_par(
    "해석: A 집단 구성원이 도시 전역 어디에서든 B 집단 구성원을 만날 확률.",
    style = "Normal") %>%
  body_add_par("", style = "Normal")

# ---- 2.3 거리감쇄 함수 ----
doc <- doc %>%
  body_add_par("2.3 접촉률 C_ij 의 추정: 거리감쇄 함수", style = "heading 3") %>%
  body_add_par(
    "수식 (Taylor 1971 single-log 모형): log(C_ij) = a - b * d_ij^m   (m <= 0.5)",
    style = "Normal") %>%
  body_add_par("", style = "Normal")

var_tbl3 <- data.frame(
  기호 = c("C_ij", "d_ij", "m", "a", "b"),
  의미 = c(
    "tract i와 zone j 간 접촉률",
    "tract i 중심에서 zone j 중심까지의 거리 (km)",
    "거리 변환 지수 (0.5 이하 권고)",
    "절편 상수 (거리 0에서의 접촉률 기준값)",
    "기울기 상수 (거리 증가에 따른 접촉률 감소 속도)"
  )
)
ft3 <- flextable(var_tbl3) %>% autofit() %>% theme_vanilla()
doc <- doc %>%
  body_add_flextable(ft3) %>%
  body_add_par("", style = "Normal")

# ---- 2.4 뉴질랜드 결혼 거리 표 ----
doc <- doc %>%
  body_add_par("실증 근거 (Morgan 1983, Table 1): 뉴질랜드 크라이스트처치 결혼 거리 데이터(1971년)", style = "Normal")

marriage_tbl <- data.frame(
  "거리(km)"          = c("0.00-0.99","1.00-1.99","2.00-2.99","3.00-3.99","4.00-4.99","5.00-5.99","6.00 이상"),
  "신랑당 평균 신부 수" = c(118, 304, 363, 295, 191, 88, 67),
  "1000명당 결혼 건수"  = c(2.032, 0.736, 0.568, 0.597, 0.386, 0.558, 0.471),
  "결혼 확률"           = c(0.2398, 0.2237, 0.2062, 0.1760, 0.0736, 0.0491, 0.0316),
  check.names = FALSE
)
ft4 <- flextable(marriage_tbl) %>% autofit() %>% theme_vanilla()
doc <- doc %>%
  body_add_flextable(ft4) %>%
  body_add_par("", style = "Normal")

# ---- 2.5 표준화 지수 ----
doc <- doc %>%
  body_add_par("2.4 표준화 지수 (Bell 1954 방식)", style = "heading 3") %>%
  body_add_par(
    "I1 (고립 지수): I1 = (aPa* - A) / (1 - A) = 1.0 - I2",
    style = "Normal") %>%
  body_add_par(
    "I2 (집단 분리 비율): I2 = aPb* / B = 1.0 - I1",
    style = "Normal") %>%
  body_add_par(
    "IC2 (도시 전역 표준화): IC2 = aPCb* / B = 1.0 - IC1",
    style = "Normal") %>%
  body_add_par("", style = "Normal")

std_tbl <- data.frame(
  기호 = c("A", "B", "aPa*", "aPb*"),
  의미 = c(
    "전체 인구 중 집단 A의 비율",
    "전체 인구 중 집단 B의 비율",
    "A 집단이 같은 A 집단을 만날 확률 (자기 집단 내 상호작용)",
    "A 집단이 B 집단을 만날 확률 (집단 간 상호작용)"
  )
)
ft5 <- flextable(std_tbl) %>% autofit() %>% theme_vanilla()
doc <- doc %>%
  body_add_flextable(ft5) %>%
  body_add_par("", style = "Normal")

# ---- 3. 패키지 함수 목록 ----
doc <- doc %>%
  body_add_par("3. 패키지 함수 목록", style = "heading 2")

func_tbl <- data.frame(
  함수명 = c(
    "compute_P_star(a, b, t)",
    "compute_C_matrix(dist_matrix, a_param, b_param, m)",
    "compute_P_ij(C_matrix, pop_zones)",
    "compute_PC_star(a_tracts, b_zones, t_zones, P_ij)",
    "compute_I1(P_aa, A)",
    "compute_I2(P_ab, B)",
    "compute_IC2(PC_ab, B)",
    "compute_IC1(IC2)"
  ),
  출력 = c(
    "P* 값 (0~1)",
    "접촉률 행렬 Cij",
    "정규화 확률 행렬 Pij",
    "PC* 값 (0~1)",
    "고립 지수 I1",
    "집단 분리 비율 I2",
    "도시 전역 분리 비율 IC2",
    "IC1 = 1 - IC2"
  ),
  수식 = c("aPb*", "C_ij", "P_ij", "aPCb*", "I1", "I2", "IC2", "IC1")
)
ft6 <- flextable(func_tbl) %>% autofit() %>% theme_vanilla()
doc <- doc %>%
  body_add_flextable(ft6) %>%
  body_add_par("", style = "Normal")

# ---- 4. 파일 목록 ----
doc <- doc %>%
  body_add_par("4. 파일 목록", style = "heading 2")

file_tbl <- data.frame(
  파일 = c(
    "code/morgan1983_PC_star.R",
    "code/morgan1983_PC_star.ipynb",
    "report/overview.md",
    "report/overview.docx"
  ),
  설명 = c(
    "R 스크립트 (함수 정의 + 가상 도시 데모 실행)",
    "Python Jupyter 노트북 (동일 알고리즘 + 시각화)",
    "본 설명서 (Markdown)",
    "본 설명서 (Word 문서)"
  )
)
ft7 <- flextable(file_tbl) %>% autofit() %>% theme_vanilla()
doc <- doc %>%
  body_add_flextable(ft7) %>%
  body_add_par("", style = "Normal")

# ---- 5. 참고 문헌 ----
doc <- doc %>%
  body_add_par("5. 참고 문헌", style = "heading 2") %>%
  body_add_par(
    "Bell, W. (1954). A probability model for the measurement of ecological segregation. Social Forces, 32, 357-364.",
    style = "Normal") %>%
  body_add_par(
    "Lieberson, S. (1981). An asymmetrical approach to segregation. In C. Peach, V. Robinson, and S. Smith (eds.), Ethnic segregation in cities. London.",
    style = "Normal") %>%
  body_add_par(
    "Morgan, B.S. (1983). A distance-decay based interaction index to measure residential segregation. Area, 15(3), 211-217.",
    style = "Normal") %>%
  body_add_par(
    "Taylor, P.J. (1971). Distance transformation and distance decay functions. Geographical Analysis, 4, 221-238.",
    style = "Normal")

# ---- 저장 ----
out_path <- "/Users/jin/홍교수님 수업/R_study/Morgan1983_DistanceDecayInteraction/report/overview.docx"
print(doc, target = out_path)
cat("Word 파일 생성 완료:", out_path, "\n")
