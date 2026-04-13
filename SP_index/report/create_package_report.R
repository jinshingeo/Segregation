# ============================================================
# Word 보고서 생성 스크립트
# 파일명 : create_package_report.R
# 출력   : report/package_report.docx
# 실행법 : RStudio에서 전체 선택 후 실행 (Ctrl+A → Ctrl+Enter)
# ============================================================

library(officer)
library(flextable)
library(magrittr)

doc <- read_docx()

# ============================================================
# 표지
# ============================================================
doc <- doc %>%
  body_add_par("White(1983) 공간 인접성 지수(SP) 패키지 제작 보고서",
               style = "heading 1") %>%
  body_add_par("작성일: 2026년 4월 13일", style = "Normal") %>%
  body_add_par(
    "참고 논문: White, M.J. (1983). The Measurement of Spatial Segregation. American Journal of Sociology, 88(5), 1008-1018.",
    style = "Normal") %>%
  body_add_par(
    "파일: SP_index/code/white1983_SP_v3.R",
    style = "Normal") %>%
  body_add_par("", style = "Normal")


# ============================================================
# 1. 패키지 제작 배경
# ============================================================
doc <- doc %>%
  body_add_par("1. 패키지 제작 배경", style = "heading 2") %>%
  body_add_par("1.1 왜 이 지수를 구현했는가", style = "heading 3") %>%
  body_add_par(
    "Massey & Denton(1988)은 주거 분리를 5개 차원(균등성·노출·집중·중심화·군집성)으로 분류하였으며, 군집성(Clustering) 차원의 표준 지표로 SP 지수를 선정하였다. SP 지수는 '각 집단 구성원이 서로 얼마나 가까이 모여 사는가'를 거리 기반으로 측정하며, 기존 D 지수(비유사성 지수)의 한계인 체커보드 문제를 해결하는 공간 명시적 지표이다.",
    style = "Normal") %>%
  body_add_par("", style = "Normal")

d_vs_sp_tbl <- data.frame(
  구분        = c("D 지수 (비유사성)", "SP 지수 (공간 인접성)"),
  측정질문    = c("집단 비율의 불균등", "집단 간 공간적 근접성"),
  공간고려    = c("없음 (aspatial)", "있음 (거리 기반)"),
  체커보드    = c("해결 불가", "해결 가능"),
  stringsAsFactors = FALSE
)
ft_d_sp <- flextable(d_vs_sp_tbl) %>% autofit() %>% theme_vanilla()
doc <- doc %>%
  body_add_flextable(ft_d_sp) %>%
  body_add_par("", style = "Normal")

doc <- doc %>%
  body_add_par("1.2 구현 목표", style = "heading 3") %>%
  body_add_par("- White(1983) 논문의 수식을 정확하게 R로 구현", style = "Normal") %>%
  body_add_par("- 사용자가 한 줄로 SP 값을 얻을 수 있는 인터페이스 제공", style = "Normal") %>%
  body_add_par("- 교수님이 제공한 segdata.rda 데이터와 expand.grid(1:10, 1:10) 좌표 방식 완전 호환", style = "Normal") %>%
  body_add_par("", style = "Normal")


# ============================================================
# 2. SP 지수 핵심 이론
# ============================================================
doc <- doc %>%
  body_add_par("2. SP 지수 핵심 이론", style = "heading 2") %>%
  body_add_par("2.1 핵심 수식", style = "heading 3") %>%
  body_add_par(
    "거리 계산 (구역 간): d_ij = sqrt((x_i - x_j)^2 + (y_i - y_j)^2)",
    style = "Normal") %>%
  body_add_par(
    "거리 계산 (구역 내): d_ii = 0.6 * sqrt(A_i)  (White 1983 근사)",
    style = "Normal") %>%
  body_add_par(
    "근접성 함수: c_ij = exp(-d_ij)  (거리 0 → c=1, 거리 증가 → c→0)",
    style = "Normal") %>%
  body_add_par(
    "집단별 평균 근접도: P_xx = (Σ_i Σ_j x_i·x_j·c_ij) / X²",
    style = "Normal") %>%
  body_add_par(
    "SP 지수: SP = (X·P_xx + Y·P_yy) / (T·P_tt)",
    style = "Normal") %>%
  body_add_par("", style = "Normal")

doc <- doc %>%
  body_add_par("2.2 SP 지수 해석 기준", style = "heading 3")

sp_interp <- data.frame(
  SP값  = c("SP > 1.0", "SP = 1.0", "SP < 1.0"),
  의미  = c(
    "집단 구성원들이 자기 집단끼리 더 가깝게 군집 → 분리 강함",
    "두 집단의 공간 분포가 동일 → 분리 없음",
    "이질 집단끼리 오히려 더 가깝게 섞임 → 강한 혼합 (드문 경우)"
  ),
  stringsAsFactors = FALSE
)
ft_interp <- flextable(sp_interp) %>% autofit() %>% theme_vanilla() %>%
  bold(i = 1, bold = TRUE)
doc <- doc %>%
  body_add_flextable(ft_interp) %>%
  body_add_par("", style = "Normal") %>%
  body_add_par("검증 항등식: T^2·P_tt = X^2·P_xx + 2·X·Y·P_xy + Y^2·P_yy", style = "Normal") %>%
  body_add_par("전체 인구 근접도 = 집단 내/간 근접도의 가중합. 계산 오류 점검에 사용.", style = "Normal") %>%
  body_add_par("", style = "Normal")


# ============================================================
# 3. 패키지 설계
# ============================================================
doc <- doc %>%
  body_add_par("3. 패키지 설계", style = "heading 2") %>%
  body_add_par("3.1 버전 히스토리", style = "heading 3")

ver_tbl <- data.frame(
  버전  = c("v1", "v2", "v3 (최종)"),
  파일명 = c("white1983_SP.R", "white1983_SP_v2.R", "white1983_SP_v3.R"),
  주요변경 = c(
    "9개 개별 함수 (단계별 수동 호출 방식)",
    "SP_index() 래퍼 함수 추가, 데이터 입력 유연화, SP_batch() 추가",
    "데모 데이터 로드 경로 수정 (하드코딩 → file.choose())"
  ),
  stringsAsFactors = FALSE
)
ft_ver <- flextable(ver_tbl) %>% autofit() %>% theme_vanilla() %>%
  bold(i = 3, bold = TRUE)
doc <- doc %>%
  body_add_flextable(ft_ver) %>%
  body_add_par("", style = "Normal")

doc <- doc %>%
  body_add_par("3.2 함수 구조", style = "heading 3") %>%
  body_add_par(
    "[PART 1] 내부 헬퍼 함수 — 점(.) 접두사, 사용자 직접 호출 불필요",
    style = "Normal")

helper_tbl <- data.frame(
  함수명 = c(".resolve_input()", ".resolve_coords()", ".resolve_area()",
             ".compute_dist_matrix()", ".compute_proximity()", ".compute_all_P()"),
  역할 = c(
    "입력값(data.frame 열 이름 / 숫자 벡터) 해석",
    "좌표 해석 또는 자동 격자 생성 (expand.grid)",
    "면적 입력값 해석 (단일값/벡터/열이름)",
    "유클리드 거리 + within-tract 거리 행렬 계산",
    "근접성 행렬 계산 (exp 또는 inverse)",
    "P_xx, P_yy, P_xy, P_tt 일괄 계산"
  ),
  stringsAsFactors = FALSE
)
ft_helper <- flextable(helper_tbl) %>% autofit() %>% theme_vanilla()
doc <- doc %>%
  body_add_flextable(ft_helper) %>%
  body_add_par("", style = "Normal") %>%
  body_add_par(
    "[PART 2] 사용자 함수 — SP_index() (메인), SP_batch() (일괄)",
    style = "Normal") %>%
  body_add_par("", style = "Normal")

doc <- doc %>%
  body_add_par("3.3 설계 원칙", style = "heading 3") %>%
  body_add_par("- 단일 진입점: 사용자는 SP_index() / SP_batch() 두 함수만 알면 됨", style = "Normal") %>%
  body_add_par("- 유연한 입력: data.frame+열이름, 숫자 벡터 직접 입력, 혼용 모두 지원", style = "Normal") %>%
  body_add_par("- 자동 격자 생성: 100개 tract → 자동으로 expand.grid(1:10, 1:10) 적용", style = "Normal") %>%
  body_add_par("- 중간값 반환: SP뿐 아니라 P_xx, P_yy, P_tt, 항등식 검증 결과까지 리스트로 반환", style = "Normal") %>%
  body_add_par("- 이식성: file.choose()로 경로 하드코딩 없이 어느 컴퓨터에서도 실행 가능", style = "Normal") %>%
  body_add_par("", style = "Normal")


# ============================================================
# 4. 주요 함수 사용법
# ============================================================
doc <- doc %>%
  body_add_par("4. 주요 함수 사용법", style = "heading 2") %>%
  body_add_par("4.1 SP_index() 기본 사용", style = "heading 3") %>%
  body_add_par("[사전 준비]", style = "Normal") %>%
  body_add_par('  load(file.choose())            # segdata.rda 선택', style = "Normal") %>%
  body_add_par('  xy <- expand.grid(1:10, 1:10)  # 10x10 격자 좌표 생성', style = "Normal") %>%
  body_add_par('  pattern1 <- segdata[, 1:2]     # A1(소수집단), A2(다수집단)', style = "Normal") %>%
  body_add_par("", style = "Normal") %>%
  body_add_par("[방법 1] 좌표 자동 생성 (가장 간단)", style = "Normal") %>%
  body_add_par('  result <- SP_index(data=pattern1, minority="A1", majority="A2")', style = "Normal") %>%
  body_add_par("", style = "Normal") %>%
  body_add_par("[방법 2] 좌표 직접 지정", style = "Normal") %>%
  body_add_par('  result <- SP_index(data=pattern1, minority="A1", majority="A2",', style = "Normal") %>%
  body_add_par('                     x=xy[,1], y=xy[,2])', style = "Normal") %>%
  body_add_par("", style = "Normal") %>%
  body_add_par("[결과 접근]", style = "Normal") %>%
  body_add_par("  result$SP             # SP 지수 값", style = "Normal") %>%
  body_add_par("  result$P_xx           # 소수집단 내 평균 근접도", style = "Normal") %>%
  body_add_par("  result$identity_check # 항등식 검증 TRUE/FALSE", style = "Normal") %>%
  body_add_par("  result$summary        # 전체 요약 테이블", style = "Normal") %>%
  body_add_par("", style = "Normal")

doc <- doc %>%
  body_add_par("4.2 함수 인수 전체 목록", style = "heading 3")

arg_tbl <- data.frame(
  인수         = c("data", "minority", "majority", "x / y", "area", "within_coef", "prox_method", "verbose"),
  기본값       = c("NULL", "(필수)", "(필수)", "NULL", "1.0", "0.6", '"exp"', "TRUE"),
  설명         = c(
    "data.frame (없으면 벡터 직접 입력)",
    "소수집단 열 이름 또는 숫자 벡터",
    "다수집단 열 이름 또는 숫자 벡터",
    "좌표 (미입력 시 자동 격자 생성)",
    "tract 면적 km² (단일값 또는 벡터)",
    "within-tract 거리 근사 계수 (White 1983)",
    "근접성 함수 (\"exp\" 또는 \"inverse\")",
    "콘솔 출력 여부"
  ),
  stringsAsFactors = FALSE
)
ft_arg <- flextable(arg_tbl) %>% autofit() %>% theme_vanilla() %>%
  bold(j = 2, bold = FALSE) %>%
  bold(i = c(2,3), bold = TRUE)
doc <- doc %>%
  body_add_flextable(ft_arg) %>%
  body_add_par("", style = "Normal")

doc <- doc %>%
  body_add_par("4.3 SP_batch() — 다중 시나리오 일괄 계산", style = "heading 3") %>%
  body_add_par("- 8개 시나리오(A~H)를 한 번에 계산할 때 사용", style = "Normal") %>%
  body_add_par("- 내부적으로 SP_index()를 반복 호출하여 결과를 요약 테이블로 정리", style = "Normal") %>%
  body_add_par("- batch_result$summary 로 전체 시나리오 SP 값 비교 가능", style = "Normal") %>%
  body_add_par("", style = "Normal")


# ============================================================
# 5. 실행 결과
# ============================================================
doc <- doc %>%
  body_add_par("5. 실행 결과", style = "heading 2") %>%
  body_add_par("5.1 교수님 기준 테스트 데이터", style = "heading 3") %>%
  body_add_par("- segdata.rda: 100개 tract (10x10 격자 가상 도시), 16개 열 (A1~H2, 8개 시나리오)", style = "Normal") %>%
  body_add_par("- 좌표: expand.grid(1:10, 1:10) — 1~10 사이 정수 격자 좌표 100개", style = "Normal") %>%
  body_add_par("- 설정: within_coef=0.6, prox_method='exp', area=1.0", style = "Normal") %>%
  body_add_par("", style = "Normal") %>%
  body_add_par("5.2 주요 결과", style = "heading 3")

result_tbl <- data.frame(
  테스트   = c("pattern1", "pattern2"),
  시나리오 = c("A1/A2", "C1/C2"),
  SP값     = c("1.6636", "1.0221"),
  해석     = c(
    "소수집단 군집성 강함 (SP > 1.0)",
    "약한 군집성 (SP ≈ 1.0, 기준선에 근접)"
  ),
  stringsAsFactors = FALSE
)
ft_result <- flextable(result_tbl) %>% autofit() %>% theme_vanilla() %>%
  bold(j = 3, bold = TRUE)
doc <- doc %>%
  body_add_flextable(ft_result) %>%
  body_add_par("", style = "Normal") %>%
  body_add_par("해석:", style = "Normal") %>%
  body_add_par("- pattern1(A 시나리오): 소수집단이 공간적으로 뚜렷하게 군집 → SP = 1.66", style = "Normal") %>%
  body_add_par("- pattern2(C 시나리오): 두 집단의 공간 분포가 거의 유사 → SP = 1.02", style = "Normal") %>%
  body_add_par("", style = "Normal")

doc <- doc %>%
  body_add_par("5.3 within_coef 민감도 분석 (pattern1 기준)", style = "heading 3")

coef_tbl <- data.frame(
  within_coef = c("0.5", "0.6 (기본값)", "0.7"),
  SP값        = c("1.6652", "1.6636", "1.6621"),
  stringsAsFactors = FALSE
)
ft_coef <- flextable(coef_tbl) %>% autofit() %>% theme_vanilla() %>%
  bold(i = 2, bold = TRUE)
doc <- doc %>%
  body_add_flextable(ft_coef) %>%
  body_add_par("", style = "Normal") %>%
  body_add_par("within_coef 변화에 따른 SP 변동이 매우 작음 → 결과가 안정적(robust)", style = "Normal") %>%
  body_add_par("", style = "Normal") %>%
  body_add_par("5.4 항등식 검증", style = "heading 3") %>%
  body_add_par("전체 8개 시나리오(A~H) 모두 항등식 검증 PASS", style = "Normal") %>%
  body_add_par("T^2·P_tt = X^2·P_xx + 2·X·Y·P_xy + Y^2·P_yy", style = "Normal") %>%
  body_add_par("", style = "Normal")


# ============================================================
# 6. 반환값 상세
# ============================================================
doc <- doc %>%
  body_add_par("6. 반환값 상세", style = "heading 2") %>%
  body_add_par("SP_index() 실행 시 반환하는 리스트 구조:", style = "Normal") %>%
  body_add_par("", style = "Normal")

ret_tbl <- data.frame(
  항목             = c("$SP", "$P_xx", "$P_yy", "$P_xy", "$P_tt",
                       "$identity_check", "$n_tracts", "$X_total",
                       "$Y_total", "$within_coef", "$prox_method", "$summary"),
  설명             = c(
    "SP 지수 값 (핵심 결과)",
    "소수집단 내 평균 근접도",
    "다수집단 내 평균 근접도",
    "집단 간 평균 근접도",
    "전체 인구 평균 근접도",
    "항등식 검증 통과 여부 (TRUE/FALSE)",
    "총 tract 수",
    "소수집단 전체 인구 합계",
    "다수집단 전체 인구 합계",
    "사용된 within 계수",
    "사용된 근접성 함수",
    "전체 요약 data.frame"
  ),
  stringsAsFactors = FALSE
)
ft_ret <- flextable(ret_tbl) %>% autofit() %>% theme_vanilla() %>%
  bold(i = 1, bold = TRUE)
doc <- doc %>%
  body_add_flextable(ft_ret) %>%
  body_add_par("", style = "Normal")


# ============================================================
# 7. 패키지 한계 및 주의사항
# ============================================================
doc <- doc %>%
  body_add_par("7. 패키지 한계 및 주의사항", style = "heading 2") %>%
  body_add_par("- O(n^2) 계산량: 모든 tract 쌍 (i, j) 계산 필요 → tract 수가 많을수록 느려짐", style = "Normal") %>%
  body_add_par("- within-tract 거리 근사: d_ii = 0.6·sqrt(A_i)는 면적 기반 근사값", style = "Normal") %>%
  body_add_par("- 좌표 단위 의존성: 거리 단위(km, m 등)에 따라 exp(-d_ij) 값이 크게 달라짐", style = "Normal") %>%
  body_add_par("- 근접성 함수 비표준화: 연구마다 exp(-d) vs 1/d 등 다른 함수 사용 → 비교 시 주의", style = "Normal") %>%
  body_add_par("", style = "Normal")


# ============================================================
# 8. 참고 문헌
# ============================================================
doc <- doc %>%
  body_add_par("8. 참고 문헌", style = "heading 2") %>%
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

# ============================================================
# 저장
# ============================================================
out_path <- "/Users/jin/홍교수님 수업/R_study/SP_index/report/package_report.docx"
print(doc, target = out_path)
cat("Word 파일 생성 완료:", out_path, "\n")
