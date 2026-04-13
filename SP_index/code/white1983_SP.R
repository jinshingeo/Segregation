# ============================================================
# 파일명 : white1983_SP.R
# 목적   : White(1983) 공간 인접성 지수(SP, Spatial Proximity Index) 구현
# 출처   : White, M.J. (1983) "The Measurement of Spatial Segregation",
#          American Journal of Sociology, 88(5), 1008-1018.
# 참고   : Massey & Denton (1988) "The Dimensions of Residential Segregation",
#          Social Forces, 67, 281-315.
# 실행법 : RStudio에서 전체 선택(Ctrl+A) 후 실행(Ctrl+Enter)
#          또는 터미널에서: Rscript white1983_SP.R
# ============================================================


# ============================================================
# [함수 1] compute_within_dist() : 구역 내부 평균 거리 계산
# ============================================================
# [해당 수식]
#   d_ii ≈ 0.6 * sqrt(A_i)
#
# [의미]
#   - 같은 tract 안에 사는 두 사람 간의 평균 거리를 면적으로 근사
#   - 이상적으로는 개인 주소 좌표를 모두 알아야 하지만,
#     인구 총조사(census) 데이터는 tract 단위로만 제공되므로
#     tract 면적을 이용해 근사치를 구함
#   - White(1983)이 원형 지역을 가정하여 유도한 근사 공식
#
# [입력 인수]
#   - area : 각 tract의 면적 (숫자 벡터, 단위 km²)
#
# [출력]
#   - 각 tract의 내부 평균 거리 (숫자 벡터, 단위 km)

compute_within_dist <- function(area) {
  # [입력값 검증]
  #   - 음수 면적은 불가
  if (any(area < 0)) stop("면적에 음수값이 있습니다.")

  # [핵심 계산]
  #   - sqrt(area) : 면적의 제곱근 (R의 기본 함수)
  #   - 0.6을 곱함 : White(1983)의 근사 계수
  0.6 * sqrt(area)
}


# ============================================================
# [함수 2] compute_dist_matrix() : 완전 거리 행렬 계산
# ============================================================
# [해당 수식]
#   d_ij = sqrt((x_i - x_j)^2 + (y_i - y_j)^2)  (i ≠ j)
#   d_ii ≈ 0.6 * sqrt(A_i)                        (i = j)
#
# [의미]
#   - tract 간 거리: 두 중심점 간의 유클리드(직선) 거리
#   - tract 내부 거리: compute_within_dist()로 계산한 근사값
#   - 결과 행렬은 n x n 크기 (n = tract 수)
#
# [입력 인수]
#   - coords : tract 중심점 좌표 (n x 2 행렬, 1열=x, 2열=y, 단위 km)
#   - area   : 각 tract의 면적 (숫자 벡터, 길이 n, 단위 km²)
#
# [출력]
#   - n x n 크기의 거리 행렬 (대각선 = 내부 거리, 단위 km)

compute_dist_matrix <- function(coords, area) {
  n <- nrow(coords)

  # [단계 1] 빈 n x n 행렬 초기화 (0으로 채움)
  d_matrix <- matrix(0, nrow = n, ncol = n)

  # [단계 2] 모든 tract 쌍 (i, j)에 대해 거리 계산
  for (i in 1:n) {
    for (j in 1:n) {
      if (i == j) {
        # [i = j: 같은 tract 내부 거리]
        #   - compute_within_dist()로 면적 기반 근사값 사용
        d_matrix[i, j] <- compute_within_dist(area[i])
      } else {
        # [i ≠ j: 두 tract 중심점 간 유클리드 거리]
        #   - (x_i - x_j)^2 + (y_i - y_j)^2 의 제곱근
        dx <- coords[i, 1] - coords[j, 1]  # x 좌표 차이
        dy <- coords[i, 2] - coords[j, 2]  # y 좌표 차이
        d_matrix[i, j] <- sqrt(dx^2 + dy^2)
      }
    }
  }

  d_matrix
}


# ============================================================
# [함수 3] compute_proximity() : 근접성 행렬 c_ij 계산
# ============================================================
# [해당 수식]
#   방법 1 (기본, exp): c_ij = exp(-d_ij)
#   방법 2 (역거리):    c_ij = 1 / d_ij
#
# [의미]
#   - c_ij : tract i와 tract j 간의 공간적 근접성 (0~1)
#   - 거리가 가까울수록 c_ij 값이 커짐 (거리감쇄 효과)
#   - exp 방식: 거리 0에서 1, 거리 증가에 따라 0으로 수렴
#   - 역거리 방식: 거리에 반비례 (중력모형과 유사)
#
# [입력 인수]
#   - d_matrix : compute_dist_matrix()의 출력 (n x n 거리 행렬)
#   - method   : 근접성 함수 종류 ("exp" 또는 "inverse")
#                기본값 "exp" = exp(-d) 사용
#
# [출력]
#   - n x n 크기의 근접성 행렬 (값이 클수록 가까움)

compute_proximity <- function(d_matrix, method = "exp") {

  if (method == "exp") {
    # [지수 근접성 함수]
    #   - exp() : R의 지수함수 (자연상수 e의 거듭제곱)
    #   - -d_matrix : 거리의 부호를 반전 (거리 클수록 값 작아짐)
    #   - 거리 0: exp(0) = 1 (최대)
    #   - 거리 5km: exp(-5) ≈ 0.0067 (매우 낮음)
    exp(-d_matrix)

  } else if (method == "inverse") {
    # [역거리 가중치]
    #   - 1/d_matrix : 거리에 반비례
    #   - 주의: 거리가 0이면 무한대 → 작은 양수로 대체
    #   - ifelse(조건, 참일때값, 거짓일때값) : 조건부 치환
    result <- 1 / d_matrix
    result[!is.finite(result)] <- 1e6  # 무한대 → 매우 큰 값으로 대체
    result

  } else {
    stop("method는 'exp' 또는 'inverse'만 지원합니다.")
  }
}


# ============================================================
# [함수 4] compute_P_xx() : 집단 X 내 평균 근접도
# ============================================================
# [해당 수식]
#   P_xx = Σ_i Σ_j (x_i * x_j * c_ij) / X^2
#
# [의미]
#   - 집단 X(소수집단) 구성원들이 서로 평균적으로 얼마나 가깝게 사는가
#   - X^2으로 나누어 정규화 (전체 X 인구 쌍의 수로 나눔)
#   - 값이 클수록 집단 X가 공간적으로 밀집해 있음
#
# [입력 인수]
#   - x   : 각 tract의 집단 X 인구 수 (숫자 벡터, 길이 n)
#   - cij : compute_proximity()의 출력 (n x n 근접성 행렬)
#
# [출력]
#   - 스칼라(숫자 1개): 집단 X의 평균 근접도

compute_P_xx <- function(x, cij) {
  X <- sum(x)
  if (X == 0) stop("집단 X의 전체 인구가 0입니다.")

  # [핵심 계산]
  #   - outer(x, x) : x 벡터의 외적(outer product)
  #                   결과: n x n 행렬, [i,j] 원소 = x_i * x_j
  #   - outer(x,x) * cij : 원소별 곱셈 (element-wise multiplication)
  #   - sum(...) : 모든 원소 합산 = Σ_i Σ_j x_i * x_j * c_ij
  sum(outer(x, x) * cij) / X^2
}


# ============================================================
# [함수 5] compute_P_yy() : 집단 Y 내 평균 근접도
# ============================================================
# [해당 수식]
#   P_yy = Σ_i Σ_j (y_i * y_j * c_ij) / Y^2
#
# [의미]
#   - 집단 Y(다수집단) 구성원들이 서로 평균적으로 얼마나 가깝게 사는가
#   - P_xx와 동일한 방식, 집단만 Y로 변경
#
# [입력 인수]
#   - y   : 각 tract의 집단 Y 인구 수 (숫자 벡터, 길이 n)
#   - cij : 근접성 행렬 (n x n)
#
# [출력]
#   - 스칼라: 집단 Y의 평균 근접도

compute_P_yy <- function(y, cij) {
  Y <- sum(y)
  if (Y == 0) stop("집단 Y의 전체 인구가 0입니다.")
  sum(outer(y, y) * cij) / Y^2
}


# ============================================================
# [함수 6] compute_P_xy() : 집단 X와 Y 간 평균 근접도
# ============================================================
# [해당 수식]
#   P_xy = Σ_i Σ_j (x_i * y_j * c_ij) / (X * Y)
#
# [의미]
#   - 집단 X 구성원과 집단 Y 구성원 간의 평균 근접도
#   - P_xy가 클수록 두 집단이 공간적으로 서로 가깝게 혼합되어 있음
#   - SP 지수의 항등식 검증에 사용
#
# [입력 인수]
#   - x   : 각 tract의 집단 X 인구 수 (숫자 벡터, 길이 n)
#   - y   : 각 tract의 집단 Y 인구 수 (숫자 벡터, 길이 n)
#   - cij : 근접성 행렬 (n x n)
#
# [출력]
#   - 스칼라: 집단 X-Y 간 평균 근접도

compute_P_xy <- function(x, y, cij) {
  X <- sum(x)
  Y <- sum(y)
  if (X == 0 || Y == 0) stop("집단 X 또는 Y의 전체 인구가 0입니다.")
  # [주의]
  #   - outer(x, y) : x_i * y_j (i번째 X 인구 × j번째 Y 인구)
  #   - outer(y, x)와 결과가 다름 (행과 열이 뒤바뀜)
  #   - 수식에서 P_xy = P_yx 이므로 동일 결과
  sum(outer(x, y) * cij) / (X * Y)
}


# ============================================================
# [함수 7] compute_P_tt() : 전체 인구 평균 근접도
# ============================================================
# [해당 수식]
#   P_tt = Σ_i Σ_j (t_i * t_j * c_ij) / T^2
#
# [의미]
#   - 집단 구분 없이 도시 전체 인구가 서로 평균적으로 얼마나 가깝게 사는가
#   - SP 지수의 분모에 사용 (기준값 역할)
#   - "분리가 없다면 집단 내 근접도가 이 값과 같아야 한다"는 기준
#
# [입력 인수]
#   - t   : 각 tract의 총 인구 수 (숫자 벡터, 길이 n)
#   - cij : 근접성 행렬 (n x n)
#
# [출력]
#   - 스칼라: 전체 인구 평균 근접도

compute_P_tt <- function(t, cij) {
  T_total <- sum(t)
  if (T_total == 0) stop("전체 인구가 0입니다.")
  sum(outer(t, t) * cij) / T_total^2
}


# ============================================================
# [함수 8] compute_SP() : SP 지수 계산 (논문 핵심 수식)
# ============================================================
# [해당 수식]
#   SP = (X * P_xx + Y * P_yy) / (T * P_tt)
#
# [의미]
#   - 분자: 각 집단의 내부 근접도를 인구 수로 가중 평균
#   - 분모: 전체 인구의 평균 근접도 (× 전체 인구 T)
#   - 비율 해석:
#     * SP = 1.0 → 집단 내 근접도 = 전체 평균 근접도 → 분리 없음
#     * SP > 1.0 → 집단끼리 더 가깝게 모여 삶 → 군집성(분리) 강함
#     * SP < 1.0 → 이질 집단이 오히려 더 가깝게 섞임 (드문 경우)
#
# [입력 인수]
#   - x   : 각 tract의 집단 X(소수집단) 인구 수 (숫자 벡터, 길이 n)
#   - y   : 각 tract의 집단 Y(다수집단) 인구 수 (숫자 벡터, 길이 n)
#   - cij : compute_proximity()의 출력 (n x n 근접성 행렬)
#
# [출력]
#   - 스칼라: SP 지수 (1.0 기준)

compute_SP <- function(x, y, cij) {
  # [단계 1] 전체 인구 계산
  X <- sum(x)
  Y <- sum(y)
  t_pop <- x + y       # 각 tract의 총 인구 (벡터 합산)
  T_total <- X + Y     # 도시 전체 인구

  # [단계 2] 집단별 평균 근접도 계산
  P_xx <- compute_P_xx(x, cij)   # 집단 X 내 근접도
  P_yy <- compute_P_yy(y, cij)   # 집단 Y 내 근접도
  P_tt <- compute_P_tt(t_pop, cij) # 전체 인구 근접도

  # [단계 3] SP 지수 계산
  #   - 분자: X * P_xx + Y * P_yy (각 집단 내 근접도를 인구로 가중)
  #   - 분모: T * P_tt (전체 인구 기준 근접도)
  (X * P_xx + Y * P_yy) / (T_total * P_tt)
}


# ============================================================
# [함수 9] verify_identity() : 항등식 검증
# ============================================================
# [해당 수식]
#   T^2 * P_tt = X^2 * P_xx + 2*X*Y * P_xy + Y^2 * P_yy
#
# [의미]
#   - 이 항등식은 수학적으로 항상 성립해야 함
#   - 계산 과정에서 오류가 없는지 검증하는 도구
#   - 좌변 - 우변의 절대값이 매우 작아야 함 (부동소수점 오차 허용)
#
# [입력 인수]
#   - x   : 각 tract의 집단 X 인구 수
#   - y   : 각 tract의 집단 Y 인구 수
#   - cij : 근접성 행렬
#
# [출력]
#   - 리스트: 좌변값, 우변값, 차이값, 검증 통과 여부(TRUE/FALSE)

verify_identity <- function(x, y, cij) {
  X <- sum(x); Y <- sum(y)
  t_pop <- x + y; T_total <- X + Y

  P_xx <- compute_P_xx(x, cij)
  P_yy <- compute_P_yy(y, cij)
  P_xy <- compute_P_xy(x, y, cij)
  P_tt <- compute_P_tt(t_pop, cij)

  lhs <- T_total^2 * P_tt                     # 좌변
  rhs <- X^2 * P_xx + 2*X*Y * P_xy + Y^2 * P_yy  # 우변
  diff <- abs(lhs - rhs)

  list(
    lhs     = lhs,
    rhs     = rhs,
    diff    = diff,
    passed  = diff < 1e-6  # 허용 오차: 0.000001 이하
  )
}


# ============================================================
# [데모] 가상 도시 데이터로 전체 계산 실행
# ============================================================
# [데이터 설명]
#   - 5개 tract(소구역)으로 이루어진 가상 도시
#   - 집단 X = 소수집단(Minority), 집단 Y = 다수집단(Majority)
#   - 북서쪽에 X 집단 집중, 남동쪽에 Y 집단 집중 (군집 상황)
#   - 좌표계: km 단위 유클리드 좌표
#   - 각 tract 면적: 1 km² (정사각형 가정)

cat("\n", strrep("=", 60), "\n")
cat("  White(1983) SP 지수 계산 데모\n")
cat(strrep("=", 60), "\n\n")

# ---- 인구 데이터 ----
# [tract별 인구 설정]
#   - tract 1~2: 북서쪽, X 집단(소수) 우세
#   - tract 3  : 도심, 혼합 지역
#   - tract 4~5: 남동쪽, Y 집단(다수) 우세

tract_names <- c("Tract1(NW)", "Tract2(N)", "Tract3(C)", "Tract4(S)", "Tract5(SE)")

x_pop <- c(180, 150,  50,  30,  20)   # 소수집단 인구
y_pop <- c( 20,  50, 100, 150, 180)   # 다수집단 인구
area  <- c(1.0, 1.0, 1.0, 1.0, 1.0)  # 각 tract 면적 (km²)

cat("[인구 데이터]\n")
pop_df <- data.frame(
  구역   = tract_names,
  X집단  = x_pop,
  Y집단  = y_pop,
  총인구 = x_pop + y_pop,
  X비율  = round(x_pop / (x_pop + y_pop), 3)
)
print(pop_df, row.names = FALSE)
cat("\n")

# ---- 좌표 데이터 ----
# [tract 중심점 좌표 (km)]
#   - (1,5): 북서쪽 끝
#   - (5,1): 남동쪽 끝
#   - (3,3): 도심 중앙

coords <- matrix(
  c(1, 5,   # Tract1(NW)
    2, 4,   # Tract2(N)
    3, 3,   # Tract3(C)
    4, 2,   # Tract4(S)
    5, 1),  # Tract5(SE)
  ncol = 2, byrow = TRUE,
  dimnames = list(tract_names, c("x좌표(km)", "y좌표(km)"))
)

cat("[중심점 좌표]\n")
print(coords)
cat("\n")

# ============================================================
# [계산 1] 거리 행렬
# ============================================================
cat(strrep("-", 50), "\n")
cat("[계산 1] 거리 행렬 (km)\n")
cat(strrep("-", 50), "\n")

d_matrix <- compute_dist_matrix(coords, area)
colnames(d_matrix) <- rownames(d_matrix) <- tract_names
cat("  (대각선 = within-tract 거리 = 0.6 * sqrt(1.0) = 0.6 km)\n\n")
print(round(d_matrix, 3))
cat("\n")

# ============================================================
# [계산 2] 근접성 행렬 (exp 방식)
# ============================================================
cat(strrep("-", 50), "\n")
cat("[계산 2] 근접성 행렬 c_ij = exp(-d_ij)\n")
cat(strrep("-", 50), "\n")

cij <- compute_proximity(d_matrix, method = "exp")
colnames(cij) <- rownames(cij) <- tract_names
print(round(cij, 4))
cat("\n")

# ============================================================
# [계산 3] 평균 근접도 (P_xx, P_yy, P_xy, P_tt)
# ============================================================
cat(strrep("-", 50), "\n")
cat("[계산 3] 평균 근접도\n")
cat(strrep("-", 50), "\n")

t_pop <- x_pop + y_pop

P_xx <- compute_P_xx(x_pop, cij)
P_yy <- compute_P_yy(y_pop, cij)
P_xy <- compute_P_xy(x_pop, y_pop, cij)
P_tt <- compute_P_tt(t_pop, cij)

cat(sprintf("  P_xx (소수집단 X 내 근접도)   = %.6f\n", P_xx))
cat(sprintf("  P_yy (다수집단 Y 내 근접도)   = %.6f\n", P_yy))
cat(sprintf("  P_xy (X-Y 집단 간 근접도)     = %.6f\n", P_xy))
cat(sprintf("  P_tt (전체 인구 근접도)        = %.6f\n", P_tt))
cat("\n")

# ============================================================
# [계산 4] SP 지수
# ============================================================
cat(strrep("-", 50), "\n")
cat("[계산 4] SP 지수\n")
cat(strrep("-", 50), "\n")

SP <- compute_SP(x_pop, y_pop, cij)
cat(sprintf("  SP = %.4f\n\n", SP))

# ============================================================
# [계산 5] 항등식 검증
# ============================================================
cat(strrep("-", 50), "\n")
cat("[계산 5] 항등식 검증\n")
cat("  T^2 * P_tt = X^2 * P_xx + 2*X*Y * P_xy + Y^2 * P_yy\n")
cat(strrep("-", 50), "\n")

chk <- verify_identity(x_pop, y_pop, cij)
cat(sprintf("  좌변 T^2 * P_tt            = %.6f\n", chk$lhs))
cat(sprintf("  우변 X^2*P_xx + 2XY*P_xy  = %.6f\n", chk$rhs))
cat(sprintf("  차이 |LHS - RHS|           = %.2e\n", chk$diff))
cat(sprintf("  검증 통과: %s\n\n", ifelse(chk$passed, "YES", "NO")))

# ============================================================
# [추가] 역거리 방식(inverse) 비교
# ============================================================
cat(strrep("-", 50), "\n")
cat("[추가] 근접성 함수 비교 (exp vs inverse)\n")
cat(strrep("-", 50), "\n")

cij_inv <- compute_proximity(d_matrix, method = "inverse")
SP_inv  <- compute_SP(x_pop, y_pop, cij_inv)
cat(sprintf("  SP (exp 방식):     %.4f\n", SP))
cat(sprintf("  SP (inverse 방식): %.4f\n", SP_inv))
cat("\n")

# ============================================================
# [결과 요약 및 해석]
# ============================================================
cat(strrep("=", 60), "\n")
cat("  [최종 결과 요약]\n")
cat(strrep("=", 60), "\n\n")

X_total <- sum(x_pop)
Y_total <- sum(y_pop)
T_total <- X_total + Y_total

cat(sprintf("  소수집단(X) 전체 인구: %d명 (%.1f%%)\n",
            X_total, 100*X_total/T_total))
cat(sprintf("  다수집단(Y) 전체 인구: %d명 (%.1f%%)\n",
            Y_total, 100*Y_total/T_total))
cat(sprintf("  도시 전체 인구:        %d명\n\n", T_total))

cat(sprintf("  P_xx (소수집단 X 내 근접도) = %.6f\n", P_xx))
cat(sprintf("  P_yy (다수집단 Y 내 근접도) = %.6f\n", P_yy))
cat(sprintf("  P_tt (전체 인구 근접도)     = %.6f\n\n", P_tt))

cat(sprintf("  SP = %.4f\n\n", SP))

cat("  [해석]\n")
if (SP > 1.0) {
  cat(sprintf("  - SP = %.4f > 1.0: 각 집단이 자기 집단끼리 더 가깝게 군집\n", SP))
  cat("    -> 공간적 군집성(분리) 존재. 소수집단이 특정 지역에 집중됨.\n")
} else if (SP < 1.0) {
  cat(sprintf("  - SP = %.4f < 1.0: 이질 집단이 오히려 서로 더 가깝게 섞임\n", SP))
  cat("    -> 강한 혼합 상태 (드문 경우).\n")
} else {
  cat(sprintf("  - SP = %.4f = 1.0: 차별적인 군집성 없음. 무작위 분포와 유사.\n", SP))
}

cat("\n  [P_xx vs P_yy 비교]\n")
if (P_xx > P_yy) {
  cat(sprintf("  - P_xx(%.6f) > P_yy(%.6f)\n", P_xx, P_yy))
  cat("    -> 소수집단이 다수집단보다 더 밀집해 있음 (enclave 형성 가능성)\n")
} else {
  cat(sprintf("  - P_xx(%.6f) <= P_yy(%.6f)\n", P_xx, P_yy))
  cat("    -> 다수집단이 소수집단보다 더 밀집해 있음\n")
}

cat("\n", strrep("=", 60), "\n\n")
