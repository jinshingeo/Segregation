# White(1983) 공간 인접성 지수(SP) 패키지 제작 보고서

**작성자:** 진  
**작성일:** 2026년 4월 13일  
**파일:** `SP_index/code/white1983_SP_v3.R`  
**참고 논문:** White, M.J. (1983). The Measurement of Spatial Segregation. *American Journal of Sociology*, 88(5), 1008–1018.

---

## 1. 패키지 제작 배경

### 1.1 왜 이 지수를 구현했는가

- Massey & Denton(1988)은 주거 분리를 5개 차원(균등성·노출·집중·중심화·**군집성**)으로 분류함
- 이 중 **군집성(Clustering)** 차원의 표준 지표로 **SP 지수**를 선정
- SP 지수는 "각 집단 구성원이 서로 얼마나 가까이 모여 사는가"를 거리 기반으로 측정
- 기존 D 지수(비유사성 지수)의 한계인 **체커보드 문제**를 해결하는 공간 명시적 지표

| 구분 | D 지수 (비유사성) | SP 지수 (공간 인접성) |
|------|-------------------|----------------------|
| 측정 질문 | 집단 비율의 불균등 | 집단 간 공간적 근접성 |
| 공간 고려 | 없음 (aspatial) | 있음 (거리 기반) |
| 체커보드 문제 | 해결 불가 | 해결 가능 |

### 1.2 구현 목표

- White(1983) 논문의 수식을 정확하게 R로 구현
- 사용자가 **한 줄**로 SP 값을 얻을 수 있는 인터페이스 제공
- 교수님이 제공한 `segdata.rda` 데이터와 `expand.grid(1:10, 1:10)` 좌표 방식 완전 호환

---

## 2. SP 지수 핵심 이론

### 2.1 핵심 수식

**거리 계산:**

$$d_{ij} = \sqrt{(x_i - x_j)^2 + (y_i - y_j)^2} \qquad \text{(구역 간 유클리드 거리)}$$

$$d_{ii} \approx 0.6\sqrt{A_i} \qquad \text{(구역 내부 평균 거리 근사, White 1983)}$$

**근접성 함수:**

$$c_{ij} = \exp(-d_{ij})$$

- 거리가 0이면 $c_{ij} = 1$ (최대 근접), 거리가 커질수록 0에 수렴

**집단별 평균 근접도:**

$$P_{xx} = \frac{\sum_i \sum_j x_i \, x_j \, c_{ij}}{X^2}, \quad
P_{yy} = \frac{\sum_i \sum_j y_i \, y_j \, c_{ij}}{Y^2}, \quad
P_{tt} = \frac{\sum_i \sum_j t_i \, t_j \, c_{ij}}{T^2}$$

**SP 지수:**

$$SP = \frac{X \cdot P_{xx} + Y \cdot P_{yy}}{T \cdot P_{tt}}$$

### 2.2 SP 지수 해석 기준

| SP 값 | 의미 |
|-------|------|
| SP > 1.0 | 집단 구성원들이 자기 집단끼리 더 가깝게 군집 → **분리 강함** |
| SP = 1.0 | 두 집단의 공간 분포가 동일 → 분리 없음 |
| SP < 1.0 | 이질 집단끼리 오히려 더 가깝게 섞임 → 강한 혼합 (드문 경우) |

### 2.3 검증 항등식

$$T^2 P_{tt} = X^2 P_{xx} + 2XY P_{xy} + Y^2 P_{yy}$$

- 전체 인구 근접도 = 집단 내/간 근접도의 가중합 → 계산 오류 점검에 사용

---

## 3. 패키지 설계

### 3.1 버전 히스토리

| 버전 | 파일명 | 주요 변경 |
|------|--------|-----------|
| v1 | `white1983_SP.R` | 9개 개별 함수 (단계별 수동 호출) |
| v2 | `white1983_SP_v2.R` | `SP_index()` 래퍼 함수 추가, 데이터 입력 유연화 |
| **v3** | **`white1983_SP_v3.R`** | **데모 데이터 로드 경로 수정 (`file.choose()`)** |

### 3.2 함수 구조

패키지는 **내부 헬퍼(PART 1)**와 **사용자 인터페이스(PART 2)**로 분리되어 있음

```
white1983_SP_v3.R
│
├── [PART 1] 내부 헬퍼 함수 (. 접두사 = 사용자 직접 호출 불필요)
│   ├── .resolve_input()      입력값(data.frame 열 이름 / 숫자 벡터) 해석
│   ├── .resolve_coords()     좌표 해석 또는 자동 격자 생성
│   ├── .resolve_area()       면적 입력값 해석
│   ├── .compute_dist_matrix() 유클리드 거리 + within-tract 거리 행렬
│   ├── .compute_proximity()  근접성 행렬 계산 (exp / inverse)
│   └── .compute_all_P()      P_xx, P_yy, P_xy, P_tt 일괄 계산
│
├── [PART 2] 사용자 함수
│   ├── SP_index()            메인 함수 — SP 지수 한 줄 계산
│   └── SP_batch()            일괄 함수 — 여러 시나리오 동시 계산
│
└── [PART 3] 데모 실행 코드
    └── segdata 로드 → pattern1/pattern2 → 6가지 테스트
```

### 3.3 설계 원칙

- **단일 진입점:** 사용자는 `SP_index()` 또는 `SP_batch()` 두 함수만 알면 됨
- **유연한 입력:** data.frame + 열 이름, 숫자 벡터 직접 입력, 혼용 모두 지원
- **자동 격자 생성:** 100개 tract → 자동으로 `expand.grid(1:10, 1:10)` 적용
- **중간값 반환:** SP뿐 아니라 P_xx, P_yy, P_xy, P_tt, 항등식 검증 결과까지 리스트로 반환
- **이식성:** `file.choose()`로 경로 하드코딩 없이 어느 컴퓨터에서도 실행 가능

---

## 4. 주요 함수 사용법

### 4.1 SP_index() — 기본 사용

```r
# [사전 준비]
load(file.choose())           # segdata.rda 선택
xy <- expand.grid(1:10, 1:10) # 10x10 격자 좌표 생성
pattern1 <- segdata[, 1:2]    # A1(소수집단), A2(다수집단)
```

```r
# [방법 1] 가장 간단한 형태 — 좌표 자동 생성
result <- SP_index(data=pattern1, minority="A1", majority="A2")

# [방법 2] 좌표 직접 지정
result <- SP_index(
  data     = pattern1,
  minority = "A1",
  majority = "A2",
  x        = xy[, 1],
  y        = xy[, 2]
)

# [결과 접근]
result$SP             # SP 지수 값
result$P_xx           # 소수집단 내 평균 근접도
result$P_yy           # 다수집단 내 평균 근접도
result$identity_check # 항등식 검증 TRUE/FALSE
result$summary        # 전체 요약 테이블
```

### 4.2 SP_index() — 파라미터 조정

```r
# within_coef 변경 (기본값 0.6)
result <- SP_index(data=pattern1, minority="A1", majority="A2",
                   x=xy[,1], y=xy[,2], within_coef=0.5)

# 근접성 함수 변경 ("exp" 기본 → "inverse" 역거리)
result <- SP_index(data=pattern1, minority="A1", majority="A2",
                   x=xy[,1], y=xy[,2], prox_method="inverse")
```

### 4.3 SP_batch() — 다중 시나리오 일괄 계산

```r
# 8개 시나리오(A~H) 한 번에 계산
col_pairs <- setNames(
  lapply(1:8, function(i) c(paste0(LETTERS[i],"1"), paste0(LETTERS[i],"2"))),
  LETTERS[1:8]
)

batch_result <- SP_batch(data=segdata, pairs=col_pairs, x=xy[,1], y=xy[,2])

# 결과 접근
batch_result$summary           # 전체 요약 테이블
batch_result$results[["A"]]$SP # A 시나리오 SP 값만 꺼내기
```

### 4.4 함수 인수 전체 목록

| 인수 | 기본값 | 설명 |
|------|--------|------|
| `data` | NULL | data.frame (없으면 벡터 직접 입력) |
| `minority` | (필수) | 소수집단 열 이름 또는 숫자 벡터 |
| `majority` | (필수) | 다수집단 열 이름 또는 숫자 벡터 |
| `x` / `y` | NULL | 좌표 (미입력 시 자동 격자 생성) |
| `area` | 1.0 | tract 면적 km² (단일값 또는 벡터) |
| `within_coef` | 0.6 | within-tract 거리 근사 계수 |
| `prox_method` | "exp" | 근접성 함수 ("exp" 또는 "inverse") |
| `verbose` | TRUE | 콘솔 출력 여부 |

---

## 5. 실행 결과

### 5.1 교수님 기준 테스트 데이터

- **segdata.rda:** 100개 tract(10×10 격자 가상 도시), 16개 열 (A1~H2, 8개 시나리오)
- **좌표:** `expand.grid(1:10, 1:10)` — 1~10 사이 정수 격자 좌표 100개
- **설정:** `within_coef=0.6`, `prox_method="exp"`, `area=1.0`

### 5.2 주요 결과

| 테스트 | 시나리오 | SP 값 | 해석 |
|--------|----------|-------|------|
| pattern1 | A1/A2 | **1.6636** | 소수집단 군집성 강함 (SP > 1.0) |
| pattern2 | C1/C2 | **1.0221** | 약한 군집성 (SP ≈ 1.0) |

pattern1과 pattern2의 차이 해석:
- pattern1(A 시나리오): 소수집단이 공간적으로 뚜렷하게 군집 → SP 값이 1.66으로 높음
- pattern2(C 시나리오): 두 집단의 공간 분포가 거의 유사 → SP 값이 1.02로 기준선(1.0)에 근접

### 5.3 within_coef 민감도 분석 (pattern1 기준)

| within_coef | SP 값 |
|-------------|-------|
| 0.5 | 1.6652 |
| **0.6 (기본값)** | **1.6636** |
| 0.7 | 1.6621 |

- within_coef 변화에 따른 SP 변동이 매우 작음 → 결과가 안정적(robust)

### 5.4 8개 시나리오 전체 항등식 검증

- 전체 8개 시나리오(A~H) 모두 항등식 검증 **PASS**
- 계산 오류 없음 확인: $T^2 P_{tt} = X^2 P_{xx} + 2XY P_{xy} + Y^2 P_{yy}$

---

## 6. 반환값 상세

`SP_index()` 실행 시 반환하는 리스트 구조:

| 항목 | 설명 |
|------|------|
| `$SP` | SP 지수 값 (핵심 결과) |
| `$P_xx` | 소수집단 내 평균 근접도 |
| `$P_yy` | 다수집단 내 평균 근접도 |
| `$P_xy` | 집단 간 평균 근접도 |
| `$P_tt` | 전체 인구 평균 근접도 |
| `$identity_check` | 항등식 검증 통과 여부 (TRUE/FALSE) |
| `$n_tracts` | 총 tract 수 |
| `$X_total` | 소수집단 전체 인구 합계 |
| `$Y_total` | 다수집단 전체 인구 합계 |
| `$within_coef` | 사용된 within 계수 |
| `$prox_method` | 사용된 근접성 함수 |
| `$summary` | 전체 요약 data.frame |

---

## 7. 패키지 한계 및 주의사항

- **O(n²) 계산량:** 모든 tract 쌍 (i, j) 계산 필요 → tract 수가 많을수록 느려짐
- **within-tract 거리 근사:** `d_ii ≈ 0.6√A_i`는 면적 기반 근사값으로 이상적이지 않음
- **좌표 단위 의존성:** 거리 단위(km, m 등)에 따라 `exp(-d_ij)` 값이 크게 달라짐
- **근접성 함수 비표준화:** 연구마다 `exp(-d)` vs `1/d` 등 다른 함수 사용 → 연구 간 비교 시 주의

---

## 8. 파일 목록

| 파일 | 설명 |
|------|------|
| `code/white1983_SP.R` | v1: 9개 개별 함수 (수동 호출 방식) |
| `code/white1983_SP_v2.R` | v2: SP_index() 래퍼 추가 |
| `code/white1983_SP_v3.R` | v3: 경로 이식성 수정 (제출 버전) |
| `data/segdata.rda` | 교수님 제공 테스트 데이터 (100 tract × 16열) |
| `report/overview.md` | 수식 레퍼런스 문서 |
| `report/package_report.md` | 본 패키지 제작 보고서 |
| `report/package_report.docx` | 본 보고서 (Word 버전) |

---

## 9. 참고 문헌

- White, M.J. (1983). The measurement of spatial segregation. *American Journal of Sociology*, 88(5), 1008–1018.
- Massey, D.S. & Denton, N.A. (1988). The dimensions of residential segregation. *Social Forces*, 67, 281–315.
- Jakubs, J.F. (1981). A distance-based segregation index. *Journal of Socio-Economic Planning Sciences*, 15, 129–141.
- Morgan, B.S. (1983). An alternate approach to the development of a distance-based measure of racial segregation. *American Journal of Sociology*, 88(6), 1237–1249.
