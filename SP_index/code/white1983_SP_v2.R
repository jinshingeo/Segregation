# ============================================================
# 파일명 : white1983_SP_v2.R
# 목적   : White(1983) 공간 인접성 지수(SP) 패키지 — 사용자 친화 버전
# 변경점 : v1 대비
#   - SP_index() 래퍼 함수 추가: 한 줄로 SP 계산 완료
#   - SP_batch() 추가: 여러 시나리오 일괄 계산
#   - 입력 형식 유연화: data.frame+열이름 / 벡터 직접 / 혼용 모두 지원
#   - 좌표 자동 생성: 입력 없을 시 expand.grid로 격자 자동 생성
#   - within_coef 파라미터 노출: 기본값 0.6, 사용자 변경 가능
#   - 반환값: SP + 중간값 + 요약표 포함 리스트
# 출처   : White, M.J. (1983) "The Measurement of Spatial Segregation",
#          American Journal of Sociology, 88(5), 1008-1018.
# 실행법 : Rscript white1983_SP_v2.R
#          또는 RStudio에서 전체 선택 후 실행 (Ctrl+A → Ctrl+Enter)
# ============================================================


# ============================================================
# [PART 1] 내부 헬퍼 함수 (사용자가 직접 호출할 필요 없음)
#           함수 이름 앞에 점(.)을 붙여 내부용임을 표시
# ============================================================

# ------------------------------------------------------------
# .resolve_input() : minority/majority 입력값 해석
# ------------------------------------------------------------
# [목적]
#   - 사용자가 어떤 방식으로 인구 데이터를 입력하든 숫자 벡터로 통일
#
# [지원하는 입력 방식]
#   방식 1: data.frame + 열 이름(문자열)
#           → data=segdata, minority="A1"
#   방식 2: 숫자 벡터 직접 입력
#           → minority=c(100, 80, 20, 10)
#   방식 3: data.frame 없이 열 인덱스(숫자)
#           → minority=1  (segdata의 1번째 열 아님, 그냥 숫자 벡터)
#
# [입력 인수]
#   - data : data.frame 또는 NULL
#   - col  : 열 이름(문자열) 또는 숫자 벡터
#
# [출력]
#   - 숫자 벡터 (numeric vector)

.resolve_input <- function(data, col) {
  # [케이스 1] data.frame + 열 이름
  if (!is.null(data) && is.character(col) && length(col) == 1) {
    if (!col %in% names(data)) {
      stop(paste0("열 이름 '", col, "'을 데이터에서 찾을 수 없습니다.\n",
                  "사용 가능한 열: ", paste(names(data), collapse=", ")))
    }
    return(as.numeric(data[[col]]))
  }

  # [케이스 2] 숫자 벡터 직접 입력 (data 유무 무관)
  if (is.numeric(col)) {
    return(as.numeric(col))
  }

  # [케이스 3] 그 외 → 오류 안내
  stop(paste0(
    "minority/majority 입력 형식 오류.\n",
    "  지원 방식 1: data=mydata, minority='열이름'\n",
    "  지원 방식 2: minority=c(100, 80, 20, ...)  # 숫자 벡터 직접 입력"
  ))
}


# ------------------------------------------------------------
# .resolve_coords() : 좌표 입력값 해석 또는 자동 생성
# ------------------------------------------------------------
# [목적]
#   - 사용자가 좌표를 입력하면 그대로 사용
#   - 좌표 미입력 시 expand.grid로 정사각 격자 자동 생성
#     (교수님 코드 기준: expand.grid(1:10, 1:10) 방식)
#
# [지원하는 입력 방식]
#   방식 1: x="열이름", y="열이름"  → data에서 추출
#   방식 2: x=c(1,2,...), y=c(1,2,...) → 벡터 직접 입력
#   방식 3: x=NULL, y=NULL → 자동 격자 생성 (tract 수가 완전제곱수여야 함)
#
# [입력 인수]
#   - data : data.frame 또는 NULL
#   - x    : x좌표 열 이름 / 벡터 / NULL
#   - y    : y좌표 열 이름 / 벡터 / NULL
#   - n    : 총 tract 수 (자동 생성 시 격자 크기 결정에 사용)
#
# [출력]
#   - n x 2 행렬 (1열=x좌표, 2열=y좌표)

.resolve_coords <- function(data, x, y, n) {
  if (!is.null(x) && !is.null(y)) {
    # [좌표가 제공된 경우]
    xv <- if (!is.null(data) && is.character(x)) as.numeric(data[[x]]) else as.numeric(x)
    yv <- if (!is.null(data) && is.character(y)) as.numeric(data[[y]]) else as.numeric(y)
    if (length(xv) != n || length(yv) != n) {
      stop(paste0("좌표 벡터 길이(", length(xv), ")가 tract 수(", n, ")와 다릅니다."))
    }
    return(cbind(xv, yv))
  }

  # [좌표 미입력: 자동 격자 생성]
  #   - sqrt(n) : n의 제곱근
  #   - 100개 tract → sqrt(100) = 10 → expand.grid(1:10, 1:10)
  sq <- sqrt(n)
  if (abs(sq - round(sq)) < 1e-9) {
    sq <- as.integer(round(sq))
    # [expand.grid(1:sq, 1:sq)]
    #   - 1:sq x 1:sq 의 모든 조합을 만드는 R 함수
    #   - 결과: sq^2행 x 2열 data.frame (Var1=x좌표, Var2=y좌표)
    #   - 교수님 코드: xy <- expand.grid(1:10, 1:10) 과 동일
    grid <- expand.grid(1:sq, 1:sq)
    message(sprintf(
      "[좌표 자동 생성] %d개 tract → %dx%d 격자 (expand.grid(1:%d, 1:%d))",
      n, sq, sq, sq, sq
    ))
    return(as.matrix(grid))
  }

  # [자동 생성 불가: tract 수가 완전제곱수가 아닌 경우]
  stop(paste0(
    "tract 수(", n, ")가 완전제곱수가 아니므로 좌표를 자동 생성할 수 없습니다.\n",
    "  x, y 좌표를 직접 입력하세요.\n",
    "  예시: SP_index(minority=x_vec, majority=y_vec, x=x_coords, y=y_coords)"
  ))
}


# ------------------------------------------------------------
# .resolve_area() : 면적 입력값 해석
# ------------------------------------------------------------
# [목적]
#   - 면적을 다양한 방식으로 입력받아 숫자 벡터로 통일
#
# [지원하는 입력 방식]
#   방식 1: area="열이름"  → data에서 추출
#   방식 2: area=1.0       → 모든 tract 동일 면적 (단일값)
#   방식 3: area=c(1.0, 1.2, ...) → tract마다 다른 면적 (벡터)
#
# [입력 인수]
#   - data : data.frame 또는 NULL
#   - area : 열 이름 / 단일 숫자 / 숫자 벡터
#   - n    : 총 tract 수

.resolve_area <- function(data, area, n) {
  # [열 이름인 경우]
  if (!is.null(data) && is.character(area) && length(area) == 1) {
    if (!area %in% names(data)) stop(paste0("열 이름 '", area, "'을 데이터에서 찾을 수 없습니다."))
    return(as.numeric(data[[area]]))
  }

  # [단일값 또는 벡터]
  area_v <- as.numeric(area)
  if (length(area_v) == 1) return(rep(area_v, n))  # 단일값 → 전체 tract에 복제
  if (length(area_v) == n) return(area_v)
  stop(paste0("area 길이(", length(area_v), ")가 tract 수(", n, ")와 다릅니다."))
}


# ------------------------------------------------------------
# .compute_dist_matrix() : 완전 거리 행렬 계산
# ------------------------------------------------------------
# [목적]
#   - 구역 간: 유클리드 거리 (중심점 간 직선 거리)
#   - 구역 내(대각선): 0.6 * sqrt(A_i) 근사 (within_coef 조정 가능)
#
# [입력 인수]
#   - coords      : n x 2 좌표 행렬
#   - area        : 각 tract 면적 벡터 (km²)
#   - within_coef : within-tract 거리 근사 계수 (기본값 0.6)

.compute_dist_matrix <- function(coords, area, within_coef = 0.6) {
  # [dist(coords)]
  #   - R 내장 함수: 좌표 행렬의 모든 행 쌍 간 유클리드 거리 계산
  #   - 반환값이 dist 클래스이므로 as.matrix()로 행렬 변환 필요
  d <- as.matrix(dist(coords, method = "euclidean"))

  # [대각선 교체]
  #   - diag(d) : 행렬의 대각선 원소 (i=j, 자기 자신과의 거리)
  #   - 기본값은 0이나, within-tract 거리로 덮어씀
  diag(d) <- within_coef * sqrt(area)
  d
}


# ------------------------------------------------------------
# .compute_proximity() : 근접성 행렬 계산
# ------------------------------------------------------------
# [수식]
#   "exp"     방식: c_ij = exp(-d_ij)
#   "inverse" 방식: c_ij = 1 / d_ij
#
# [입력 인수]
#   - d_matrix   : 거리 행렬 (n x n)
#   - prox_method: "exp" (기본값) 또는 "inverse"

.compute_proximity <- function(d_matrix, prox_method = "exp") {
  if (prox_method == "exp") return(exp(-d_matrix))
  if (prox_method == "inverse") return(ifelse(d_matrix > 0, 1 / d_matrix, 1e6))
  stop("prox_method는 'exp' 또는 'inverse'여야 합니다.")
}


# ------------------------------------------------------------
# .compute_all_P() : 집단별 평균 근접도 일괄 계산
# ------------------------------------------------------------
# [수식]
#   P_xx = (x' C x) / X^2
#   P_yy = (y' C y) / Y^2
#   P_xy = (x' C y) / (X*Y)
#   P_tt = (t' C t) / T^2
#
# [입력 인수]
#   - x   : 소수집단 인구 벡터
#   - y   : 다수집단 인구 벡터
#   - cij : 근접성 행렬
#
# [출력]
#   - 리스트: P_xx, P_yy, P_xy, P_tt

.compute_all_P <- function(x, y, cij) {
  X <- sum(x); Y <- sum(y)
  t <- x + y; T <- X + Y

  # [행렬 곱셈 %*% 설명]
  #   - x %*% cij %*% x : (1×n)(n×n)(n×1) = 스칼라
  #   - = Σ_i Σ_j x_i * c_ij * x_j
  list(
    P_xx = as.numeric(x %*% cij %*% x) / X^2,
    P_yy = as.numeric(y %*% cij %*% y) / Y^2,
    P_xy = as.numeric(x %*% cij %*% y) / (X * Y),
    P_tt = as.numeric(t %*% cij %*% t) / T^2
  )
}


# ============================================================
# [PART 2] 사용자 인터페이스 함수
# ============================================================

# ------------------------------------------------------------
# SP_index() : 메인 함수 — SP 지수 계산
# ------------------------------------------------------------
# [목적]
#   - 한 줄로 SP 지수를 계산하는 통합 함수
#   - 내부에서 거리 계산 → 근접성 변환 → 평균 근접도 → SP 순서로 자동 처리
#
# [입력 인수]
#   - data        : (선택) data.frame. 없으면 NULL
#   - minority    : 소수집단 인구.  data 있으면 "열이름", 없으면 숫자 벡터
#   - majority    : 다수집단 인구.  data 있으면 "열이름", 없으면 숫자 벡터
#   - x           : x좌표. "열이름" / 숫자 벡터 / NULL(자동 격자)
#   - y           : y좌표. "열이름" / 숫자 벡터 / NULL(자동 격자)
#   - area        : tract 면적(km²). "열이름" / 단일값 / 벡터. 기본값 1.0
#   - within_coef : within-tract 거리 근사 계수. 기본값 0.6 (White 1983)
#   - prox_method : 근접성 함수. "exp"(기본) 또는 "inverse"
#   - verbose     : TRUE면 결과를 콘솔에 출력
#
# [출력]
#   - 리스트 (결과를 변수에 저장하여 개별 접근 가능)
#     $SP             : SP 지수 값
#     $P_xx           : 소수집단 내 평균 근접도
#     $P_yy           : 다수집단 내 평균 근접도
#     $P_xy           : 집단 간 평균 근접도
#     $P_tt           : 전체 인구 평균 근접도
#     $identity_check : 항등식 검증 통과 여부 (TRUE/FALSE)
#     $n_tracts       : 총 tract 수
#     $X_total        : 소수집단 전체 인구
#     $Y_total        : 다수집단 전체 인구
#     $within_coef    : 사용된 within 계수
#     $prox_method    : 사용된 근접성 함수
#     $summary        : 요약 data.frame

SP_index <- function(
  data        = NULL,
  minority,
  majority,
  x           = NULL,
  y           = NULL,
  area        = 1.0,
  within_coef = 0.6,
  prox_method = "exp",
  verbose     = TRUE
) {
  # ── [단계 1] 입력값 해석 ──────────────────────────────
  x_pop  <- .resolve_input(data, minority)
  y_pop  <- .resolve_input(data, majority)
  n      <- length(x_pop)

  if (length(y_pop) != n) stop("minority와 majority의 tract 수가 다릅니다.")

  coords <- .resolve_coords(data, x, y, n)
  area_v <- .resolve_area(data, area, n)

  # ── [단계 2] 거리 행렬 및 근접성 행렬 ────────────────
  d_mat <- .compute_dist_matrix(coords, area_v, within_coef)
  cij   <- .compute_proximity(d_mat, prox_method)

  # ── [단계 3] 집단별 평균 근접도 ──────────────────────
  P <- .compute_all_P(x_pop, y_pop, cij)

  # ── [단계 4] SP 지수 계산 ─────────────────────────────
  #   SP = (X * P_xx + Y * P_yy) / (T * P_tt)
  X <- sum(x_pop); Y <- sum(y_pop); T_total <- X + Y
  SP <- (X * P$P_xx + Y * P$P_yy) / (T_total * P$P_tt)

  # ── [단계 5] 항등식 검증 ─────────────────────────────
  #   T^2 * P_tt = X^2 * P_xx + 2*X*Y * P_xy + Y^2 * P_yy
  lhs <- T_total^2 * P$P_tt
  rhs <- X^2 * P$P_xx + 2*X*Y * P$P_xy + Y^2 * P$P_yy
  identity_ok <- abs(lhs - rhs) < 1e-6

  # ── [단계 6] 요약 테이블 생성 ────────────────────────
  summary_df <- data.frame(
    지표 = c("SP", "P_xx", "P_yy", "P_xy", "P_tt"),
    값   = round(c(SP, P$P_xx, P$P_yy, P$P_xy, P$P_tt), 6),
    설명 = c(
      "공간 인접성 지수 (기준: 1.0)",
      "소수집단 내 평균 근접도",
      "다수집단 내 평균 근접도",
      "집단 간 평균 근접도",
      "전체 인구 평균 근접도 (SP 분모 기준)"
    ),
    stringsAsFactors = FALSE
  )

  # ── [단계 7] 콘솔 출력 ───────────────────────────────
  if (verbose) {
    interpret <- if (SP > 1) "군집성 있음 (SP > 1.0)" else
                 if (SP < 1) "강한 혼합 (SP < 1.0)"  else "분리 없음 (SP = 1.0)"
    cat("\n[SP Index 결과]\n")
    cat(sprintf("  SP           = %.4f  → %s\n", SP, interpret))
    cat(sprintf("  P_xx (소수)  = %.6f\n", P$P_xx))
    cat(sprintf("  P_yy (다수)  = %.6f\n", P$P_yy))
    cat(sprintf("  P_tt (전체)  = %.6f\n", P$P_tt))
    cat(sprintf("  항등식 검증  = %s\n", ifelse(identity_ok, "PASS", "FAIL")))
    cat(sprintf("  [설정] within_coef=%.2f, prox_method='%s', n_tracts=%d\n\n",
                within_coef, prox_method, n))
  }

  # ── [반환값] invisible(): 자동 출력 방지 (result$SP 로 접근) ──
  invisible(list(
    SP             = SP,
    P_xx           = P$P_xx,
    P_yy           = P$P_yy,
    P_xy           = P$P_xy,
    P_tt           = P$P_tt,
    identity_check = identity_ok,
    n_tracts       = n,
    X_total        = X,
    Y_total        = Y,
    within_coef    = within_coef,
    prox_method    = prox_method,
    summary        = summary_df
  ))
}


# ------------------------------------------------------------
# SP_batch() : 일괄 계산 — 여러 시나리오를 한 번에 처리
# ------------------------------------------------------------
# [목적]
#   - segdata처럼 여러 시나리오(열 쌍)가 있는 데이터를 한 번에 계산
#   - 내부에서 SP_index()를 반복 호출
#
# [입력 인수]
#   - data        : data.frame (필수)
#   - pairs       : 이름 있는 리스트. 각 원소 = c("소수집단열", "다수집단열")
#                   예: list(A=c("A1","A2"), B=c("B1","B2"))
#   - x, y        : 좌표 (SP_index와 동일)
#   - area        : 면적 (SP_index와 동일)
#   - within_coef : within 계수 (기본값 0.6)
#   - prox_method : "exp" 또는 "inverse"
#   - verbose     : TRUE면 요약 테이블 출력
#
# [출력]
#   - 리스트
#     $results : 시나리오별 SP_index() 결과 리스트 (개별 접근 가능)
#     $summary : 모든 시나리오 SP 비교 data.frame

SP_batch <- function(
  data,
  pairs,
  x           = NULL,
  y           = NULL,
  area        = 1.0,
  within_coef = 0.6,
  prox_method = "exp",
  verbose     = TRUE
) {
  if (!is.list(pairs) || is.null(names(pairs))) {
    stop(paste0(
      "pairs는 이름 있는 리스트여야 합니다.\n",
      "  예시: list(A=c('A1','A2'), B=c('B1','B2'))"
    ))
  }

  # [lapply]
  #   - 리스트의 각 원소에 함수를 적용하고 결과를 리스트로 반환
  #   - 여기서는 pairs의 각 시나리오에 SP_index()를 적용
  results <- lapply(names(pairs), function(nm) {
    cols <- pairs[[nm]]
    SP_index(
      data        = data,
      minority    = cols[1],
      majority    = cols[2],
      x           = x,
      y           = y,
      area        = area,
      within_coef = within_coef,
      prox_method = prox_method,
      verbose     = FALSE   # 개별 출력 억제 (batch 요약만 출력)
    )
  })
  names(results) <- names(pairs)

  # ── 요약 테이블 ──────────────────────────────────────
  # [sapply]
  #   - lapply와 유사하지만 결과를 벡터 또는 행렬로 단순화
  summary_tbl <- data.frame(
    시나리오     = names(pairs),
    SP           = sapply(results, function(r) round(r$SP,   4)),
    P_xx         = sapply(results, function(r) round(r$P_xx, 6)),
    P_yy         = sapply(results, function(r) round(r$P_yy, 6)),
    P_tt         = sapply(results, function(r) round(r$P_tt, 6)),
    항등식검증   = sapply(results, function(r) ifelse(r$identity_check, "PASS", "FAIL")),
    stringsAsFactors = FALSE
  )

  if (verbose) {
    cat("\n[SP Batch 결과 요약]\n")
    cat(sprintf("  within_coef=%.2f, prox_method='%s'\n\n", within_coef, prox_method))
    print(summary_tbl, row.names = FALSE)
    cat(sprintf("\n  SP > 1.0: %s\n",
        paste(summary_tbl$시나리오[summary_tbl$SP > 1], collapse=", ")))
    cat(sprintf("  SP ≤ 1.0: %s\n\n",
        paste(summary_tbl$시나리오[summary_tbl$SP <= 1], collapse=", ")))
  }

  invisible(list(results = results, summary = summary_tbl))
}


# ============================================================
# [PART 3] 데모 — 교수님 코드 기준 테스트
# ============================================================

cat(strrep("=", 60), "\n")
cat("  White(1983) SP 지수 패키지 v2 — 데모 실행\n")
cat(strrep("=", 60), "\n\n")

# ---- 데이터 로드 ----
# [load()]
#   - .rda 파일 안에 저장된 R 객체를 현재 환경으로 불러옴
#   - segdata 라는 이름의 data.frame이 로드됨
data_path <- "/Users/jin/홍교수님 수업/R_study/SP_index/data/segdata.rda"
load(data_path)
cat("[데이터 로드] segdata:", nrow(segdata), "tracts x", ncol(segdata), "열\n\n")

# ---- 교수님 코드 기준 좌표 생성 ----
# [expand.grid(1:10, 1:10)]
#   - 1~10의 값을 가진 두 변수의 모든 조합을 생성
#   - 결과: 100행 x 2열 data.frame (Var1=x, Var2=y)
#   - 교수님 원본 코드와 동일
xy <- expand.grid(1:10, 1:10)
cat("[좌표 생성] expand.grid(1:10, 1:10) →", nrow(xy), "개 좌표\n\n")

# ---- 교수님 기준 테스트 패턴 ----
# [교수님 코드]
#   pattern1 <- segdata[, 1:2]  → A1(소수), A2(다수)
#   pattern2 <- segdata[, 5:6]  → C1(소수), C2(다수)
pattern1 <- segdata[, 1:2]   # A시나리오: A1=소수집단, A2=다수집단
pattern2 <- segdata[, 5:6]   # C시나리오: C1=소수집단, C2=다수집단

cat(strrep("-", 50), "\n")
cat("[테스트 1] pattern1 (A1/A2) — 교수님 기준 패턴 1\n")
cat(strrep("-", 50), "\n")

# ── 사용법 예시 1: data.frame + 열이름 + 좌표 직접 입력
result1 <- SP_index(
  data        = pattern1,
  minority    = "A1",
  majority    = "A2",
  x           = xy[, 1],      # expand.grid의 Var1 (x좌표)
  y           = xy[, 2],      # expand.grid의 Var2 (y좌표)
  area        = 1.0,           # 모든 tract 면적 = 1 km²
  within_coef = 0.6,
  prox_method = "exp"
)

cat(strrep("-", 50), "\n")
cat("[테스트 2] pattern2 (C1/C2) — 교수님 기준 패턴 2\n")
cat(strrep("-", 50), "\n")

result2 <- SP_index(
  data        = pattern2,
  minority    = "C1",
  majority    = "C2",
  x           = xy[, 1],
  y           = xy[, 2],
  area        = 1.0,
  within_coef = 0.6,
  prox_method = "exp"
)

# ── 사용법 예시 2: 좌표 없이 자동 격자 생성
cat(strrep("-", 50), "\n")
cat("[테스트 3] 좌표 자동 생성 (x,y 미입력)\n")
cat(strrep("-", 50), "\n")

result3 <- SP_index(
  data        = pattern1,
  minority    = "A1",
  majority    = "A2"
  # x, y 생략 → 100개 tract → 10x10 격자 자동 생성
)

# ── 사용법 예시 3: 벡터 직접 입력 (data.frame 없이)
cat(strrep("-", 50), "\n")
cat("[테스트 4] 벡터 직접 입력 (data.frame 없이)\n")
cat(strrep("-", 50), "\n")

result4 <- SP_index(
  minority    = pattern1$A1,   # 벡터 직접
  majority    = pattern1$A2,   # 벡터 직접
  x           = xy[, 1],
  y           = xy[, 2],
  area        = 1.0
)

# ── 사용법 예시 4: within_coef 변경
cat(strrep("-", 50), "\n")
cat("[테스트 5] within_coef 비교 (0.6 vs 0.5 vs 0.7)\n")
cat(strrep("-", 50), "\n")

for (coef in c(0.5, 0.6, 0.7)) {
  r <- SP_index(data=pattern1, minority="A1", majority="A2",
                x=xy[,1], y=xy[,2], within_coef=coef, verbose=FALSE)
  cat(sprintf("  within_coef=%.1f → SP = %.4f\n", coef, r$SP))
}
cat("\n")

# ── 사용법 예시 5: SP_batch — 전체 8개 시나리오 일괄 계산
cat(strrep("-", 50), "\n")
cat("[테스트 6] SP_batch — 8개 시나리오 일괄 계산\n")
cat(strrep("-", 50), "\n")

# [as.list(setNames(...))]
#   - 8개 시나리오(A~H)의 열 쌍을 자동으로 리스트로 만드는 코드
#   - LETTERS[1:8] = c("A","B","C","D","E","F","G","H")
col_pairs <- setNames(
  lapply(1:8, function(i) c(paste0(LETTERS[i], "1"), paste0(LETTERS[i], "2"))),
  LETTERS[1:8]
)

batch_result <- SP_batch(
  data        = segdata,
  pairs       = col_pairs,
  x           = xy[, 1],
  y           = xy[, 2],
  area        = 1.0,
  within_coef = 0.6,
  prox_method = "exp"
)

# ── 개별 결과 접근 예시 ──────────────────────────────
cat(strrep("-", 50), "\n")
cat("[결과 접근 방법 예시]\n")
cat(strrep("-", 50), "\n")
cat(sprintf("  result1$SP             = %.4f\n",  result1$SP))
cat(sprintf("  result1$P_xx           = %.6f\n",  result1$P_xx))
cat(sprintf("  result1$P_yy           = %.6f\n",  result1$P_yy))
cat(sprintf("  result1$identity_check = %s\n",    result1$identity_check))
cat(sprintf("  result1$n_tracts       = %d\n",    result1$n_tracts))
cat("\n  result1$summary:\n")
print(result1$summary, row.names = FALSE)

cat("\n", strrep("=", 60), "\n")
cat("  SP 패키지 v2 데모 완료\n")
cat(strrep("=", 60), "\n\n")
