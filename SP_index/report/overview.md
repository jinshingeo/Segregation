# White(1983) 공간 인접성 지수(SP) 패키지 설명서

**논문 출처:** White, M.J. (1983). "The Measurement of Spatial Segregation." *American Journal of Sociology*, 88(5), 1008–1018.

**관련 참고:** Massey, D.S. & Denton, N.A. (1988). "The Dimensions of Residential Segregation." *Social Forces*, 67, 281–315.

---

## 1. 논문 개요

### 1.1 연구 배경

Massey & Denton(1988)은 주거 분리를 **5개 차원**으로 분류하였다.

| 차원 | 영문명 | 개념 |
|------|--------|------|
| 균등성 | Evenness | 집단 비율이 도시 전체 비율과 얼마나 일치하는가 |
| 노출 | Exposure | 소수집단과 다수집단이 얼마나 이웃하는가 |
| 집중 | Concentration | 소수집단이 차지하는 물리적 공간의 크기 |
| 중심화 | Centralization | 소수집단이 도심부에 얼마나 집중되어 있는가 |
| **군집** | **Clustering** | **소수집단 거주지역들이 서로 얼마나 인접하여 덩어리를 이루는가** |

SP 지수는 **군집성(Clustering)** 차원의 표준 지표로 선정되었다.

### 1.2 SP 지수가 선택된 이유 (Massey & Denton 1988 기준)

- 군집성 요인 분석에서 가장 뚜렷하고 강력한 요인 적재치 보유
- 계산 과정이 명확하고 결과 해석(1.0 기준)이 직관적
- 단순 인접을 넘어 거리 감쇄 함수로 실제 공간적 응집력 포착

### 1.3 기존 D 지수와의 차이

| 구분 | D (비유사성 지수) | SP (공간 인접성 지수) |
|------|-----------------|----------------------|
| 질문 | 각 지역의 집단 비율이 도시 전체 비율에서 얼마나 벗어나는가? | 같은 집단 사람들끼리 서로 얼마나 가까운 위치에 있는가? |
| 공간 고려 | 없음 (aspatial) | 있음 (거리 기반) |
| 체커보드 문제 | 해결 불가 | 해결 가능 |

---

## 2. 핵심 수식

### 2.1 거리 계산

**구역 간 거리 (tract i와 tract j의 중심점 간 유클리드 거리):**

$$d_{ij} = \sqrt{(x_i - x_j)^2 + (y_i - y_j)^2}$$

**같은 구역 내부 평균 거리 (within-tract distance, i = j):**

$$d_{ii} \approx 0.6\sqrt{A_i}$$

| 기호 | 의미 |
|------|------|
| $x_i, y_i$ | tract i 중심점의 좌표 |
| $A_i$ | tract i의 면적 (km²) |

- 같은 tract 안에 사는 두 사람 간의 평균 거리를 면적의 함수로 근사
- 이상적으로는 개인 단위로 계산해야 하지만, census tract 단위로 집계 데이터를 사용하므로 이 근사치를 사용

---

### 2.2 근접성 함수 (Proximity Function)

$$c_{ij} = f(d_{ij}) = \exp(-d_{ij})$$

| 기호 | 의미 |
|------|------|
| $c_{ij}$ | tract i와 tract j 간의 근접성 (공간적 상호작용 강도) |
| $d_{ij}$ | tract i와 tract j 간의 거리 |
| $\exp$ | 지수함수(자연상수 e의 거듭제곱) |

- 거리가 0일 때: $c_{ij} = 1$ (최대 근접)
- 거리가 증가할수록 $c_{ij}$ 감소 → 거리감쇄 효과
- 대안: $c_{ij} = 1/d_{ij}$ (역거리 가중치) — 논문에 따라 다름

---

### 2.3 집단별 평균 근접도 (Average Proximity)

**집단 X(소수집단) 내 평균 근접도:**

$$P_{xx} = \frac{\sum_{i=1}^{n}\sum_{j=1}^{n} x_i \, x_j \, c_{ij}}{X^2}$$

**집단 Y(다수집단) 내 평균 근접도:**

$$P_{yy} = \frac{\sum_{i=1}^{n}\sum_{j=1}^{n} y_i \, y_j \, c_{ij}}{Y^2}$$

**집단 X와 Y 간 평균 근접도:**

$$P_{xy} = \frac{\sum_{i=1}^{n}\sum_{j=1}^{n} x_i \, y_j \, c_{ij}}{X \cdot Y}$$

**전체 인구 내 평균 근접도:**

$$P_{tt} = \frac{\sum_{i=1}^{n}\sum_{j=1}^{n} t_i \, t_j \, c_{ij}}{T^2}$$

| 기호 | 의미 |
|------|------|
| $x_i$ | tract i의 집단 X(소수집단) 인구 수 |
| $y_i$ | tract i의 집단 Y(다수집단) 인구 수 |
| $t_i = x_i + y_i$ | tract i의 총 인구 수 |
| $X = \sum x_i$ | 도시 전체 집단 X 인구 수 |
| $Y = \sum y_i$ | 도시 전체 집단 Y 인구 수 |
| $T = X + Y$ | 도시 전체 인구 수 |
| $c_{ij}$ | tract i와 j 간의 근접성 함수 값 |
| $n$ | 전체 tract(소구역) 수 |

**수식의 직관적 해석:**

- $P_{xx}$: "집단 X 구성원들이 서로 평균적으로 얼마나 가깝게 살고 있는가?"
- $P_{yy}$: "집단 Y 구성원들이 서로 평균적으로 얼마나 가깝게 살고 있는가?"
- $P_{tt}$: "집단 구분 없이 전체 인구가 서로 평균적으로 얼마나 가깝게 살고 있는가?"

---

### 2.4 항등식 (Identity)

$$T^2 P_{tt} = X^2 P_{xx} + 2XY P_{xy} + Y^2 P_{yy}$$

이 항등식은 전체 인구의 근접도가 집단 내/간 근접도의 가중합임을 보여 준다.

---

### 2.5 SP 지수 (Index of Spatial Proximity)

$$SP = \frac{X \cdot P_{xx} + Y \cdot P_{yy}}{T \cdot P_{tt}}$$

**동치 표현 (재인용 표현):**

$$SP = \frac{X\displaystyle\sum_i\sum_j p_{xi}p_{xj}f(d_{ij}) + Y\displaystyle\sum_i\sum_j p_{yi}p_{yj}f(d_{ij})}{(X+Y)\displaystyle\sum_i\sum_j p_i p_j f(d_{ij})}$$

$$\text{단, } p_{xi} = \frac{x_i}{X}, \quad p_{yi} = \frac{y_i}{Y}, \quad p_i = \frac{t_i}{T}$$

또한:

$$SP = \frac{P_{AA} + P_{BB}}{2 P_{AB}}, \qquad P_{AA} = \sum_i\sum_j w_{ij} a_i a_j, \quad w_{ij} = \frac{1}{d_{ij}}$$

---

### 2.6 SP 지수의 해석

| SP 값 | 의미 |
|-------|------|
| SP = 1.0 | 두 집단의 공간적 분포가 동일 → 차별적인 군집성 없음 |
| SP > 1.0 | 각 집단 구성원들이 자기 집단끼리 더 가깝게 모여 삶 → **군집성 강함(분리 심화)** |
| SP < 1.0 | 이질 집단이 오히려 더 가까이 섞여 삶 → 강한 혼합 상태 (드문 경우) |

**핵심 의미:** SP는 "집단 내 평균 근접성이 전체 평균 근접성보다 얼마나 큰지를 보여 주는 비율이다."

---

## 3. 가정 및 주의사항

### 3.1 계산 가정

- 가정 1: 서로 다른 tract에 사는 사람들은 해당 tract의 중심점에 산다고 가정 → 두 tract 간 거리 = 중심점 간 거리
- 가정 2: 같은 tract 안에 사는 사람들 간의 평균 거리는 면적 $A_i$의 함수로 근사 → $d_{ii} \approx 0.6\sqrt{A_i}$
- 가정 3: 거리의 함수 $f(d_{ij})$는 사회적 교류를 측정 (중력모형 등과 유사)

### 3.2 한계

- 필요 정보량이 많음: 집단 구성원 및 구성원 간 위치정보, 거리정보 필요
- 계산 복잡성: 모든 지역 간 쌍 (i-j)의 계산 필요 → O(n²) 계산량
- 거리 정의의 모호성: 유클리드 거리, 네트워크 거리, 시간 거리 중 선택 문제
- 가중 함수의 표준화 어려움: 연구마다 다른 함수 사용으로 비교 가능성 저하

---

## 4. 패키지 함수 목록

| 함수명 | 입력 | 출력 | 해당 수식 |
|--------|------|------|-----------|
| `compute_within_dist(area)` | 구역 면적 벡터 | 구역 내부 거리 벡터 | $d_{ii} \approx 0.6\sqrt{A_i}$ |
| `compute_dist_matrix(coords, area)` | 좌표 행렬, 면적 벡터 | 완전 거리 행렬 | $d_{ij}$, $d_{ii}$ |
| `compute_proximity(d_matrix, method)` | 거리 행렬 | 근접성 행렬 | $c_{ij} = \exp(-d_{ij})$ |
| `compute_P_xx(x, cij)` | X 인구 벡터, 근접성 행렬 | 집단 X 내 근접도 | $P_{xx}$ |
| `compute_P_yy(y, cij)` | Y 인구 벡터, 근접성 행렬 | 집단 Y 내 근접도 | $P_{yy}$ |
| `compute_P_xy(x, y, cij)` | X, Y 인구 벡터, 근접성 행렬 | X-Y 간 근접도 | $P_{xy}$ |
| `compute_P_tt(t, cij)` | 총 인구 벡터, 근접성 행렬 | 전체 인구 근접도 | $P_{tt}$ |
| `compute_SP(x, y, cij)` | X, Y 인구 벡터, 근접성 행렬 | SP 지수 | $SP$ |
| `verify_identity(x, y, cij)` | X, Y 인구 벡터, 근접성 행렬 | 항등식 검증 결과 | $T^2P_{tt} = X^2P_{xx}+2XYP_{xy}+Y^2P_{yy}$ |

---

## 5. 사용 예시 (가상 도시 데이터)

### 데이터 구조

- 5개 tract(소구역)으로 이루어진 가상 도시
- 집단 X = 소수집단(Minority), 집단 Y = 다수집단(Majority)
- 북서쪽에 소수집단 집중, 남동쪽에 다수집단 집중 (군집 상황 가정)
- 좌표계: km 단위 유클리드 좌표
- 근접성 함수: $c_{ij} = \exp(-d_{ij})$

### 기대 해석

- SP > 1.0: 소수집단이 공간적으로 군집되어 있음
- SP ≈ 1.0: 두 집단의 공간 분포가 유사함 (분리 없음)
- SP < 1.0: 소수집단이 오히려 다수집단과 더 섞여 있음 (드문 상황)

---

## 6. 파일 목록

| 파일 | 설명 |
|------|------|
| `code/white1983_SP.R` | R 스크립트 (함수 정의 + 가상 도시 데모 실행) |
| `code/white1983_SP.ipynb` | Python Jupyter 노트북 (동일 알고리즘 + 시각화) |
| `report/overview.md` | 본 설명서 (Markdown) |
| `report/overview.docx` | 본 설명서 (Word 문서) |

---

## 7. 참고 문헌

- Massey, D.S. & Denton, N.A. (1988). The dimensions of residential segregation. *Social Forces*, 67, 281–315.
- White, M.J. (1983). The measurement of spatial segregation. *American Journal of Sociology*, 88(5), 1008–1018.
- White, M.J. (1986). Segregation and diversity: Measures in population distribution. *Population Index*, 52(2), 198–221.
- Jakubs, J.F. (1981). A distance-based segregation index. *Journal of Socio-Economic Planning Sciences*, 15, 129–141.
- Morgan, B.S. (1983). An alternate approach to the development of a distance-based measure of racial segregation. *American Journal of Sociology*, 88(6), 1237–1249.
