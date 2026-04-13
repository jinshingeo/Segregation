# ============================================================
# 파일명 : morgan1983_PC_star.R
# 목적   : Morgan(1983) 거리감쇄 기반 상호작용 지수(PC*) 구현
# 출처   : Morgan, B.S. (1983) "A distance-decay based interaction
#          index to measure residential segregation",
#          Area, 15(3), 211-217.
# 실행법 : RStudio에서 이 파일을 열고 전체 선택(Ctrl+A) 후 실행(Ctrl+Enter)
#          또는 터미널에서: Rscript morgan1983_PC_star.R
# ============================================================


# ============================================================
# [1단계] 패키지 로드
# ============================================================
# [설명]
#   - R에서 추가 기능을 불러올 때 library() 함수를 사용함
#   - 여기서는 표 출력을 예쁘게 하기 위해 knitr 패키지 사용
#   - knitr가 없어도 핵심 함수들은 모두 정상 동작함
# [설치 방법]
#   - 만약 knitr가 없다는 오류가 나면 아래 주석을 제거하고 한 번만 실행:
#     install.packages("knitr")

if (!requireNamespace("knitr", quietly = TRUE)) {
  message("knitr 패키지가 없어 기본 출력 방식으로 대체합니다.")
}


# ============================================================
# [함수 1] compute_P_star() : 기본 P* 지수 계산
# ============================================================
# [해당 수식]
#   aPb* = Σ_i (a_i / Σa_i) * (b_i / t_i)
#
# [의미]
#   - A 집단 구성원이 자신의 소구역(tract) 안에서
#     B 집단 구성원을 만날 확률
#   - 0에 가까울수록 분리(segregation) 심화
#   - 1에 가까울수록 혼합(integration) 강화
#
# [입력 인수]
#   - a : 각 소구역의 집단 A 인구 수 (숫자 벡터, 길이 n)
#   - b : 각 소구역의 집단 B 인구 수 (숫자 벡터, 길이 n)
#   - t : 각 소구역의 총 인구 수     (숫자 벡터, 길이 n)
#
# [출력]
#   - 스칼라(숫자 1개): 0과 1 사이의 상호작용 확률
#
# [주의사항]
#   - a, b, t 의 길이(벡터 원소 수)는 반드시 같아야 함
#   - t 중 0인 값이 있으면 0/0 오류 → 해당 구역 제외 처리

compute_P_star <- function(a, b, t) {

  # [입력값 검증]
  #   - sum(a) == 0 이면 A 집단이 없으므로 계산 불가
  total_a <- sum(a)
  if (total_a == 0) stop("집단 A의 전체 인구가 0입니다. 데이터를 확인하세요.")

  # [핵심 계산]
  #   - a / total_a : 도시 전체 A 인구 중 i 구역 A 인구의 비중 (가중치)
  #   - b / t       : i 구역의 총 인구 중 B 집단의 비율
  #   - 두 값을 곱해 모든 구역에 대해 합산
  sum((a / total_a) * (b / t))
}


# ============================================================
# [함수 2] compute_C_matrix() : 접촉률 행렬 Cij 계산
# ============================================================
# [해당 수식]
#   log(C_ij) = a_param - b_param * d_ij^m    (m <= 0.5)
#   => C_ij = 10^(a_param - b_param * d_ij^m)
#
# [의미]
#   - C_ij : tract i 거주자가 zone j에서 1,000명당 접촉하는 횟수
#   - 거리가 멀수록 접촉률이 감소 (거리감쇄 효과)
#   - 'single-log 모형': Taylor(1971)이 결혼 거리 데이터에서 최적임을 제안
#
# [입력 인수]
#   - dist_matrix : tract i에서 zone j까지의 거리 행렬
#                  (행 = tract, 열 = zone, 단위 km 권장)
#                  크기: n_tracts x n_zones 행렬
#   - a_param     : 절편 상수 (거리 0 근방의 접촉률 기준값)
#   - b_param     : 기울기 상수 (거리 증가에 따른 감소 속도)
#   - m           : 거리 변환 지수 (기본값 0.5, 반드시 0.5 이하)
#
# [출력]
#   - n_tracts x n_zones 크기의 행렬: 각 tract-zone 쌍의 접촉률
#
# [주의사항]
#   - m > 0.5 이면 경고 메시지 출력 (논문 권고 위반)
#   - 거리가 0이면 d^m = 0, 따라서 C = 10^a_param (최대 접촉률)
#     -> 같은 tract 내부 거리는 0이 아닌 작은 양수(예: 0.5km)로 설정 권장

compute_C_matrix <- function(dist_matrix, a_param, b_param, m = 0.5) {

  # [입력값 검증]
  if (m > 0.5) {
    warning("m > 0.5 입니다. 논문(Morgan 1983)은 m <= 0.5를 권고합니다.")
  }
  if (any(dist_matrix < 0)) {
    stop("거리 행렬에 음수값이 있습니다.")
  }

  # [핵심 계산]
  #   - dist_matrix^m : 거리 행렬의 각 원소에 m 제곱 적용
  #   - a_param - b_param * (...) : log 값 계산
  #   - 10^(...) : 상용로그의 역함수로 실제 접촉률 C 복원
  10^(a_param - b_param * dist_matrix^m)
}


# ============================================================
# [함수 3] compute_P_ij() : 상호작용 확률 행렬 Pij 계산
# ============================================================
# [해당 수식]
#   P_ij = (C_ij * t_j) / Σ_j(C_ij * t_j)
#   조건: Σ_j P_ij = 1  (각 tract에 대해 모든 zone의 확률 합 = 1)
#
# [의미]
#   - P_ij : tract i 거주자가 다음 접촉 상대를 zone j에서 만날 확률
#   - C_ij(접촉률) x t_j(zone 인구)를 zone 간 정규화하여 확률로 변환
#   - zone 인구가 많을수록, 거리가 가까울수록 P_ij 값이 커짐
#
# [입력 인수]
#   - C_matrix  : compute_C_matrix()의 출력 (n_tracts x n_zones 행렬)
#   - pop_zones : 각 zone j의 총 인구 수 (숫자 벡터, 길이 n_zones)
#
# [출력]
#   - n_tracts x n_zones 크기의 행렬
#   - 각 행의 합 = 1.0 (확률 분포)

compute_P_ij <- function(C_matrix, pop_zones) {

  # [입력값 검증]
  #   - C_matrix의 열 수와 pop_zones의 길이가 같아야 함
  if (ncol(C_matrix) != length(pop_zones)) {
    stop("C_matrix의 열 수와 pop_zones의 길이가 다릅니다.")
  }

  # [단계 1] C_ij * t_j 계산
  #   - sweep() : 행렬의 각 열에 pop_zones 벡터를 곱하는 함수
  #   - 결과: 각 원소 C_ij에 해당 zone의 인구 t_j를 곱한 행렬
  weighted <- sweep(C_matrix, 2, pop_zones, `*`)
  #   sweep(X, MARGIN, STATS, FUN) 설명:
  #   - X      : 연산할 행렬
  #   - MARGIN : 2 = 열 방향으로 적용
  #   - STATS  : 적용할 값(여기서는 pop_zones 벡터)
  #   - FUN    : 적용할 연산자(`*` = 곱셈)

  # [단계 2] 행별 합산: Σ_j (C_ij * t_j)
  #   - rowSums() : 행렬의 각 행(tract)의 합을 계산
  row_sums <- rowSums(weighted)

  # [단계 3] 행별 정규화: P_ij = (C_ij * t_j) / Σ_j(C_ij * t_j)
  #   - sweep()의 MARGIN=1 : 행 방향으로 나눗셈 적용
  sweep(weighted, 1, row_sums, `/`)
  #   결과: 각 행의 합이 1.0인 확률 행렬
}


# ============================================================
# [함수 4] compute_PC_star() : PC* 지수 계산 (논문의 핵심 수식)
# ============================================================
# [해당 수식]
#   aPCb* = Σ_i (a_i / Σa_i) * [Σ_j P_ij * (b_j / t_j)]
#
# [의미]
#   - PC* : A 집단 구성원이 도시 전역 어디에서든 B 집단을 만날 확률
#   - P* 와의 차이:
#     * P*  : 같은 소구역(tract) 내에서만 접촉 확률 계산
#     * PC* : 거리감쇄를 반영하여 다른 zone에서의 접촉도 포함
#   - P_ij(tract i에서 zone j 방문 확률) x (b_j/t_j)(zone j의 B 비율)
#     를 모든 zone에 대해 합산한 후, A 집단 가중치로 전체 합산
#
# [입력 인수]
#   - a_tracts : 각 tract i의 집단 A 인구 수 (숫자 벡터, 길이 n_tracts)
#   - b_zones  : 각 zone j의 집단 B 인구 수  (숫자 벡터, 길이 n_zones)
#   - t_zones  : 각 zone j의 총 인구 수      (숫자 벡터, 길이 n_zones)
#   - P_ij     : compute_P_ij()의 출력 (n_tracts x n_zones 행렬)
#
# [출력]
#   - 스칼라(숫자 1개): 0과 1 사이의 도시 전역 상호작용 확률

compute_PC_star <- function(a_tracts, b_zones, t_zones, P_ij) {

  # [입력값 검증]
  total_a <- sum(a_tracts)
  if (total_a == 0) stop("집단 A의 전체 인구가 0입니다.")
  if (nrow(P_ij) != length(a_tracts)) {
    stop("P_ij의 행 수와 a_tracts의 길이가 다릅니다.")
  }
  if (ncol(P_ij) != length(b_zones)) {
    stop("P_ij의 열 수와 b_zones의 길이가 다릅니다.")
  }

  # [단계 1] b_j / t_j : 각 zone의 B 집단 비율 계산
  b_ratio <- b_zones / t_zones

  # [단계 2] Σ_j P_ij * (b_j/t_j) : 각 tract에 대한 가중 합산
  #   - %*% : 행렬 곱셈 연산자
  #   - P_ij(n_tracts x n_zones) %*% b_ratio(n_zones x 1)
  #     결과: n_tracts x 1 벡터
  #   - inner_sum[i] = tract i 거주자가 도시 전역에서 B를 만날 확률
  inner_sum <- P_ij %*% b_ratio

  # [단계 3] Σ_i (a_i / Σa_i) * inner_sum[i]
  #   - a_tracts / total_a : 각 tract의 A 집단 비중 (가중치)
  #   - sum(...) : 모든 tract에 대해 합산
  sum((a_tracts / total_a) * inner_sum)
}


# ============================================================
# [함수 5] compute_I1() : 고립 지수(Isolation Index) I1
# ============================================================
# [해당 수식]
#   I1 = (aPa* - A) / (1 - A)
#      = (bPb* - B) / (1 - B)
#      = 1.0 - I2
#
# [의미]
#   - 집단 A가 자신의 소구역 내에서 얼마나 고립되어 있는지 측정
#   - 0: 고립 없음 (완전 무작위 혼합)
#   - 1: 완전 고립 (A 집단이 A 집단만 있는 구역에만 거주)
#
# [입력 인수]
#   - P_aa : compute_P_star(a, a, t)로 계산한 A 집단 내 자기 상호작용 확률
#            (_aP*_a : A 집단이 같은 A 집단을 만날 확률)
#   - A    : 전체 인구 중 집단 A의 비율 (= sum(a) / sum(t))
#
# [출력]
#   - 스칼라: 0과 1 사이의 고립 지수

compute_I1 <- function(P_aa, A) {
  # A == 1 이면 분모가 0 → 계산 불가 (도시 전체가 A 집단인 경우)
  if (A >= 1) stop("A 비율이 1 이상입니다. (전체 인구 = A 집단)")
  (P_aa - A) / (1 - A)
}


# ============================================================
# [함수 6] compute_I2() : 집단 분리 비율(Group Segregation Ratio) I2
# ============================================================
# [해당 수식]
#   I2 = aPb* / B
#      = bPa* / A
#      = 1.0 - I1
#
# [의미]
#   - 분리가 없을 때(완전 무작위 혼합)의 기댓값 = 1.0
#   - 1보다 작으면: 실제 접촉이 무작위보다 적음 → 분리 존재
#   - 1보다 크면: 실제 접촉이 무작위보다 많음 → 혼합이 강함
#
# [입력 인수]
#   - P_ab : compute_P_star(a, b, t)로 계산한 집단 간 상호작용 확률
#            (_aP*_b : A 집단이 B 집단을 만날 확률)
#   - B    : 전체 인구 중 집단 B의 비율 (= sum(b) / sum(t))
#
# [출력]
#   - 스칼라: 집단 분리 비율 (0 초과)

compute_I2 <- function(P_ab, B) {
  if (B == 0) stop("B 비율이 0입니다. 집단 B가 없습니다.")
  P_ab / B
}


# ============================================================
# [함수 7] compute_IC2() : 도시 전역 표준화 지수 IC2
# ============================================================
# [해당 수식]
#   IC2 = aPCb* / B
#       = 1.0 - IC1
#
# [의미]
#   - I2와 동일한 해석이지만 PC*(도시 전역 접촉)를 사용
#   - IC2 < I2: 도시 전역으로 넓혀도 분리가 여전히 존재
#   - IC2 > I2: 넓은 범위에서는 오히려 접촉 기회가 많아짐
#
# [입력 인수]
#   - PC_ab : compute_PC_star()로 계산한 도시 전역 상호작용 확률
#   - B     : 전체 인구 중 집단 B의 비율
#
# [출력]
#   - 스칼라: 도시 전역 집단 분리 비율

compute_IC2 <- function(PC_ab, B) {
  if (B == 0) stop("B 비율이 0입니다. 집단 B가 없습니다.")
  PC_ab / B
}

# IC1 = 1 - IC2
compute_IC1 <- function(IC2) {
  1.0 - IC2
}


# ============================================================
# [데모] 가상 도시 데이터로 전체 계산 실행
# ============================================================
# [데이터 설명]
#   - 5개 tract(소구역)으로 이루어진 가상 도시
#   - 집단 A = 백인(White), 집단 B = 흑인(Black)
#   - tract = zone (동일 공간 단위 사용)
#   - 북서쪽에 A 집단 집중, 남동쪽에 B 집단 집중 (분리 상황 가정)

cat("\n", strrep("=", 60), "\n")
cat("  Morgan(1983) PC* 지수 계산 데모\n")
cat(strrep("=", 60), "\n\n")

# ---- 인구 데이터 ----
# [tract별 인구]
#   - tract 1~2: A 집단 우세 (북서쪽 거주지)
#   - tract 4~5: B 집단 우세 (남동쪽 거주지)
#   - tract 3  : 혼합 지역 (도심)

tract_names <- c("Tract1(NW)", "Tract2(N)", "Tract3(C)", "Tract4(S)", "Tract5(SE)")

# 집단 A (백인) 인구
a_pop <- c(180, 150,  50,  30,  20)

# 집단 B (흑인) 인구
b_pop <- c( 10,  20,  80, 140, 160)

# 총 인구 (A + B + 기타)
t_pop <- c(200, 200, 200, 200, 200)

# [인구 데이터 확인]
cat("[인구 데이터]\n")
pop_df <- data.frame(
  구역    = tract_names,
  A집단   = a_pop,
  B집단   = b_pop,
  총인구  = t_pop,
  A비율   = round(a_pop / t_pop, 3),
  B비율   = round(b_pop / t_pop, 3)
)
print(pop_df, row.names = FALSE)
cat("\n")

# ---- 거리 행렬 ----
# [거리 행렬 설명]
#   - 5x5 행렬: tract i에서 zone j(=tract j)까지의 거리(km)
#   - 대각선: 0.5km (같은 tract 내부 이동 거리, 0 대신 사용)
#   - 논문의 Table 1처럼 근거리 접촉이 가장 강함을 반영
#
#        z1    z2    z3    z4    z5
# t1  [ 0.5   1.2   2.5   4.0   5.5 ]
# t2  [ 1.2   0.5   1.5   3.0   4.5 ]
# t3  [ 2.5   1.5   0.5   1.5   2.5 ]
# t4  [ 4.0   3.0   1.5   0.5   1.2 ]
# t5  [ 5.5   4.5   2.5   1.2   0.5 ]

dist_matrix <- matrix(
  c(0.5, 1.2, 2.5, 4.0, 5.5,
    1.2, 0.5, 1.5, 3.0, 4.5,
    2.5, 1.5, 0.5, 1.5, 2.5,
    4.0, 3.0, 1.5, 0.5, 1.2,
    5.5, 4.5, 2.5, 1.2, 0.5),
  nrow = 5, ncol = 5,
  byrow = TRUE,
  dimnames = list(tract_names, tract_names)
)

cat("[거리 행렬 (km)]\n")
print(round(dist_matrix, 2))
cat("\n")

# ---- 거리감쇄 파라미터 ----
# [파라미터 설명]
#   - a_param = 2.0 : 거리 0.5km에서의 기준 접촉률
#   - b_param = 0.5 : 거리 증가에 따른 감소율
#   - m       = 0.5 : 거리를 루트(제곱근) 척도로 변환
#   => 근거리에서 급격히 감소 후 완만해지는 S자형 패턴

a_param <- 2.0
b_param <- 0.5
m       <- 0.5

# ============================================================
# [계산 1] 기본 P* 지수
# ============================================================
cat(strrep("-", 40), "\n")
cat("[계산 1] 기본 P* 지수\n")
cat(strrep("-", 40), "\n")

# A 집단이 B 집단을 만날 확률 (A→B)
P_star_ab <- compute_P_star(a_pop, b_pop, t_pop)

# B 집단이 A 집단을 만날 확률 (B→A)
P_star_ba <- compute_P_star(b_pop, a_pop, t_pop)

# A 집단이 같은 A 집단을 만날 확률 (자기 집단 내)
P_star_aa <- compute_P_star(a_pop, a_pop, t_pop)

# B 집단이 같은 B 집단을 만날 확률 (자기 집단 내)
P_star_bb <- compute_P_star(b_pop, b_pop, t_pop)

cat(sprintf("  aPb* (A가 B를 만날 확률)      = %.4f\n", P_star_ab))
cat(sprintf("  bPa* (B가 A를 만날 확률)      = %.4f\n", P_star_ba))
cat(sprintf("  aPa* (A가 A를 만날 확률)      = %.4f\n", P_star_aa))
cat(sprintf("  bPb* (B가 B를 만날 확률)      = %.4f\n", P_star_bb))
cat("\n")

# ============================================================
# [계산 2] 거리감쇄 접촉률 행렬 Cij
# ============================================================
cat(strrep("-", 40), "\n")
cat("[계산 2] 접촉률 행렬 Cij\n")
cat(strrep("-", 40), "\n")

C_matrix <- compute_C_matrix(dist_matrix, a_param, b_param, m)
cat("  (거리감쇄 파라미터: a=", a_param, ", b=", b_param, ", m=", m, ")\n")
cat("  log(Cij) = 2.0 - 0.5 * d^0.5\n\n")
cat("  Cij 행렬 (1000명당 접촉 건수):\n")
print(round(C_matrix, 3))
cat("\n")

# ============================================================
# [계산 3] 상호작용 확률 행렬 Pij
# ============================================================
cat(strrep("-", 40), "\n")
cat("[계산 3] 상호작용 확률 행렬 Pij\n")
cat(strrep("-", 40), "\n")

P_ij <- compute_P_ij(C_matrix, t_pop)
cat("  각 행의 합 = 1.0 (확인값):", all(round(rowSums(P_ij), 10) == 1.0), "\n\n")
cat("  Pij 행렬 (각 tract에서 각 zone 방문 확률):\n")
print(round(P_ij, 4))
cat("\n")

# ============================================================
# [계산 4] PC* 지수
# ============================================================
cat(strrep("-", 40), "\n")
cat("[계산 4] PC* 지수 (도시 전역 상호작용)\n")
cat(strrep("-", 40), "\n")

PC_star_ab <- compute_PC_star(a_pop, b_pop, t_pop, P_ij)
PC_star_ba <- compute_PC_star(b_pop, a_pop, t_pop, P_ij)
PC_star_aa <- compute_PC_star(a_pop, a_pop, t_pop, P_ij)
PC_star_bb <- compute_PC_star(b_pop, b_pop, t_pop, P_ij)

cat(sprintf("  aPCb* (A가 도시 전역에서 B를 만날 확률) = %.4f\n", PC_star_ab))
cat(sprintf("  bPCa* (B가 도시 전역에서 A를 만날 확률) = %.4f\n", PC_star_ba))
cat(sprintf("  aPCa* (A가 도시 전역에서 A를 만날 확률) = %.4f\n", PC_star_aa))
cat(sprintf("  bPCb* (B가 도시 전역에서 B를 만날 확률) = %.4f\n", PC_star_bb))
cat("\n")

# ============================================================
# [계산 5] 표준화 지수 I1, I2, IC1, IC2
# ============================================================
cat(strrep("-", 40), "\n")
cat("[계산 5] 표준화 지수\n")
cat(strrep("-", 40), "\n")

# 전체 인구 비율
A_ratio <- sum(a_pop) / sum(t_pop)
B_ratio <- sum(b_pop) / sum(t_pop)

cat(sprintf("  A 집단 전체 비율 (A) = %.4f\n", A_ratio))
cat(sprintf("  B 집단 전체 비율 (B) = %.4f\n", B_ratio))
cat("\n")

# --- P* 기반 표준화 지수 ---
I1 <- compute_I1(P_star_aa, A_ratio)
I2 <- compute_I2(P_star_ab, B_ratio)

cat(sprintf("  I1 (고립 지수, P* 기반)                = %.4f\n", I1))
cat(sprintf("  I2 (집단 분리 비율, P* 기반)            = %.4f\n", I2))
cat(sprintf("  검증: I1 + I2 = %.4f (= 1이어야 함)\n", I1 + I2))
cat("\n")

# --- PC* 기반 도시 전역 표준화 지수 ---
IC2 <- compute_IC2(PC_star_ab, B_ratio)
IC1 <- compute_IC1(IC2)

cat(sprintf("  IC2 (도시 전역 집단 분리 비율, PC* 기반) = %.4f\n", IC2))
cat(sprintf("  IC1 = 1 - IC2                           = %.4f\n", IC1))
cat("\n")

# ============================================================
# [결과 요약 및 해석]
# ============================================================
cat(strrep("=", 60), "\n")
cat("  [최종 결과 요약]\n")
cat(strrep("=", 60), "\n")

cat(sprintf("\n  P*  지수 (소구역 내 접촉 기준): %.4f\n", P_star_ab))
cat(sprintf("  PC* 지수 (도시 전역 접촉 기준): %.4f\n\n", PC_star_ab))

cat(sprintf("  I2  (P*  기반 분리 비율): %.4f\n", I2))
cat(sprintf("  IC2 (PC* 기반 분리 비율): %.4f\n\n", IC2))

cat("  [해석]\n")
if (I2 < 1.0) {
  cat(sprintf("  - I2 = %.4f < 1.0 : 소구역 수준에서 분리가 존재함\n", I2))
} else {
  cat(sprintf("  - I2 = %.4f >= 1.0 : 소구역 수준에서 분리가 없음\n", I2))
}

if (IC2 < 1.0) {
  cat(sprintf("  - IC2 = %.4f < 1.0 : 도시 전역 수준에서도 분리가 존재함\n", IC2))
} else {
  cat(sprintf("  - IC2 = %.4f >= 1.0 : 도시 전역 수준에서는 분리가 없음\n", IC2))
}

if (IC2 > I2) {
  cat("  - IC2 > I2: 도시 전역으로 보면 접촉 기회가 더 많아짐\n")
  cat("              (거리감쇄 효과 반영 시 혼합이 더 강해짐)\n")
} else if (IC2 < I2) {
  cat("  - IC2 < I2: 도시 전역으로 보아도 분리가 여전히 강함\n")
  cat("              (거리감쇄 효과가 분리를 강화)\n")
} else {
  cat("  - IC2 = I2: P*와 PC*가 동일한 분리 수준을 보임\n")
}

cat("\n", strrep("=", 60), "\n\n")
