# Morgan(1983) 거리감쇄 기반 상호작용 지수 패키지 설명서

**논문 출처:** Morgan, B.S. (1983). "A distance-decay based interaction index to measure residential segregation." *Area*, 15(3), 211–217.

---

## 1. 논문 개요

### 1.1 연구 목적

이 논문은 주거 분리(residential segregation)를 측정하는 새로운 상호작용 지수인 **PC\*** 를 제안한다. 기존의 P\* 지수가 같은 동네(tract, 소구역) 안에서만 접촉 확률을 계산했다면, PC\*는 **거리감쇄(distance-decay) 함수**를 활용해 도시 전역(city-wide)의 접촉 확률을 추정한다.

### 1.2 기존 지수의 한계

- **D(비유사성 지수, Dissimilarity Index):** 공간적 패턴보다 인구 구성 불균형에 치중
- **P\*(상호작용 지수, Interaction Index):** 같은 소구역 내 접촉만 반영 → 실제로 사람들은 동네를 넘어 도시 전역에서 접촉함

---

## 2. 핵심 수식

### 2.1 기본 P\* 지수 (Lieberson 1981)

$$_aP^*_b = \sum_i \frac{a_i}{\sum_i a_i} \cdot \frac{b_i}{t_i}$$

**변수 설명:**

| 기호 | 의미 |
|------|------|
| $a_i$ | i번째 소구역(tract)의 집단 A 인구 수 |
| $b_i$ | i번째 소구역의 집단 B 인구 수 |
| $t_i$ | i번째 소구역의 총 인구 수 |
| $\sum_i a_i$ | 도시 전체 집단 A 인구 수 |

**해석:**
- A 집단 구성원이 자신의 소구역 내에서 B 집단 구성원을 만날 확률
- 0에 가까울수록 분리(격리), 1에 가까울수록 혼합

**한계:**
- 오직 같은 tract 안에서의 접촉만 고려 → 실제 도시 생활에서 사람들은 직장, 학교, 교회 등을 통해 더 넓은 범위에서 접촉함

---

### 2.2 PC\* 지수 (Morgan 1983의 핵심 제안)

$$_aPC^*_b = \sum_i \frac{a_i}{\sum_i a_i} \left[ \sum_j P_{ij} \cdot \frac{b_j}{t_j} \right]$$

**변수 설명:**

| 기호 | 의미 |
|------|------|
| $a_i$ | tract i의 집단 A 인구 수 |
| $b_j$ | zone j의 집단 B 인구 수 |
| $t_j$ | zone j의 총 인구 수 |
| $P_{ij}$ | tract i 거주자가 zone j에서 접촉할 확률 (아래 수식 참조) |

**$P_{ij}$ 의 정의:**

$$P_{ij} = \frac{C_{ij} \cdot t_j}{\sum_j C_{ij} \cdot t_j}, \qquad \text{단, } \sum_j P_{ij} = 1.0$$

| 기호 | 의미 |
|------|------|
| $C_{ij}$ | tract i와 zone j 간 추정 접촉률 (zone j의 인구 1,000명당 접촉 건수) |
| $t_j$ | zone j의 인구 수 |

**PC\*의 해석:**
- A 집단 구성원이 **도시 전역 어디에서든** B 집단 구성원을 만날 확률
- tract i 거주 A 집단이 zone j를 방문할 확률($P_{ij}$)에 zone j의 B 집단 비율($b_j/t_j$)을 곱해 합산

---

### 2.3 접촉률 $C_{ij}$의 추정: 거리감쇄 함수

Morgan(1983)은 Taylor(1971)의 'single-log' 모형을 최적 함수로 제안한다:

$$\log C_{ij} = a - b \cdot d_{ij}^m, \qquad m \leq 0.5$$

**변수 설명:**

| 기호 | 의미 |
|------|------|
| $C_{ij}$ | tract i와 zone j 간 접촉률 |
| $d_{ij}$ | tract i 중심에서 zone j 중심까지의 거리 (km) |
| $m$ | 거리 변환 지수 (0.5 이하 권장) |
| $a$ | 절편 상수 (거리 0에서의 접촉률 기준값) |
| $b$ | 기울기 상수 (거리 증가에 따른 접촉률 감소 속도) |

**특성:**
- 거리가 증가할수록 접촉률이 감소 (거리감쇄 효과)
- m ≤ 0.5: 거리에 대해 제곱근 척도로 변환 → 근거리에서 더 급격한 감소
- $\log$는 상용로그($\log_{10}$)를 사용

**실증 근거 (Table 1 in Morgan 1983):**

뉴질랜드 크라이스트처치의 결혼 거리 데이터(1971년):

| 거리(km) | 신랑당 평균 신부 수 | 1,000명당 결혼 건수 | 결혼 확률 |
|-----------|-------------------|---------------------|-----------|
| 0.00–0.99 | 118 | 2.032 | 0.2398 |
| 1.00–1.99 | 304 | 0.736 | 0.2237 |
| 2.00–2.99 | 363 | 0.568 | 0.2062 |
| 3.00–3.99 | 295 | 0.597 | 0.1760 |
| 4.00–4.99 | 191 | 0.386 | 0.0736 |
| 5.00–5.99 | 88 | 0.558 | 0.0491 |
| 6.00 이상 | 67 | 0.471 | 0.0316 |

→ 근거리에서 급격히 감소 후 완만해지는 패턴 확인

---

### 2.4 표준화 지수 (Bell 1954 방식 적용)

P\* 지수는 인구 구성에 민감하므로, Bell(1954)의 방법으로 0~1 범위로 표준화한다.

#### I₁ (고립 지수, Isolation Index)

$$I_1 = \frac{_aP^*_a - A}{1 - A} = \frac{_bP^*_b - B}{1 - B} = 1.0 - I_2$$

- 값이 1에 가까울수록 집단 A가 도시 내에서 공간적으로 고립되어 있음
- $_aP^*_a$: A 집단이 동일 구역 내에서 같은 A 집단을 만날 확률

#### I₂ (집단 분리 비율, Group Segregation Ratio)

$$I_2 = \frac{_aP^*_b}{B} = \frac{_bP^*_a}{A} = 1.0 - I_1$$

- 분리가 없을 때(무작위 혼합) 기댓값 = 1.0
- 값이 1보다 작을수록 분리 심화, 클수록 혼합 강화

**변수 설명:**

| 기호 | 의미 |
|------|------|
| $A$ | 전체 인구 중 집단 A의 비율 |
| $B$ | 전체 인구 중 집단 B의 비율 |
| $_aP^*_a$ | A 집단이 같은 A 집단을 만날 확률 (자기 집단 내 상호작용) |
| $_aP^*_b$ | A 집단이 B 집단을 만날 확률 (집단 간 상호작용) |

#### IC₂ (도시 전역 표준화 지수)

$$IC_2 = \frac{_aPC^*_b}{B} = 1.0 - IC_1$$

- PC\*에 같은 표준화 방식을 적용
- 도시 전역 접촉을 고려한 집단 분리 비율

---

## 3. 패키지 함수 목록

| 함수명 | 입력 | 출력 | 해당 수식 |
|--------|------|------|-----------|
| `compute_P_star(a, b, t)` | 각 구역의 A, B, 총인구 벡터 | P\* 값 (0~1) | $_aP^*_b$ |
| `compute_C_matrix(dist_matrix, a_param, b_param, m)` | 거리 행렬, 감쇄 파라미터 | 접촉률 행렬 | $C_{ij}$ |
| `compute_P_ij(C_matrix, pop_zones)` | 접촉률 행렬, zone 인구 벡터 | 정규화된 확률 행렬 | $P_{ij}$ |
| `compute_PC_star(a_tracts, b_zones, t_zones, P_ij)` | tract A 인구, zone B/총인구, Pij | PC\* 값 (0~1) | $_aPC^*_b$ |
| `compute_I1(P_aa, A)` | $_aP^*_a$, A 비율 | 고립 지수 (0~1) | $I_1$ |
| `compute_I2(P_ab, B)` | $_aP^*_b$, B 비율 | 집단 분리 비율 | $I_2$ |
| `compute_IC2(PC_ab, B)` | $_aPC^*_b$, B 비율 | 도시 전역 분리 비율 | $IC_2$ |
| `compute_IC1(IC2)` | $IC_2$ | $IC_1 = 1 - IC_2$ | $IC_1$ |

---

## 4. 사용 예시 (가상 도시 데이터)

### 데이터 구조

- 도시를 5개 tract(소구역)로 구분
- 집단 A = 백인(White), 집단 B = 흑인(Black)
- tract = zone (동일 구역 사용)
- 거리감쇄 파라미터: a=2.0, b=0.5, m=0.5

### 기대 해석

- I₂ < 1: 분리 존재 (실제보다 집단 간 접촉이 적음)
- IC₂ < I₂: PC\*가 P\*보다 낮으면, 도시 전역 접촉 고려 시에도 분리가 유의미함
- IC₂ > I₂: 도시 전역으로 넓히면 접촉 기회가 더 많아짐 (공간적 혼합)

---

## 5. 파일 목록

| 파일 | 설명 |
|------|------|
| `code/morgan1983_PC_star.R` | R 스크립트 (함수 정의 + 예시 실행) |
| `code/morgan1983_PC_star.ipynb` | Python Jupyter 노트북 (동일 알고리즘) |
| `report/overview.md` | 본 설명서 (Markdown) |
| `report/overview.docx` | 본 설명서 (Word 문서) |

---

## 6. 참고 문헌

- Bell, W. (1954). A probability model for the measurement of ecological segregation. *Social Forces*, 32, 357–364.
- Lieberson, S. (1981). An asymmetrical approach to segregation. In C. Peach, V. Robinson, and S. Smith (eds.), *Ethnic segregation in cities*. London.
- Morgan, B.S. (1983). A distance-decay based interaction index to measure residential segregation. *Area*, 15(3), 211–217.
- Taylor, P.J. (1971). Distance transformation and distance decay functions. *Geographical Analysis*, 4, 221–238.
