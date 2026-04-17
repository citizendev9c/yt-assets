# Claude Code Routines 가이드 — Schedule & API 트리거로 업무 자동화하기

![Claude routines](https://img.shields.io/badge/claude-routines-FF6D5A?style=for-the-badge&logo=Claude)

Anthropic이 2026년 4월 14일 기존 **Remote Task**를 확장하여 출시한 **Routines**를 활용해, 시간 기반 자동화(Schedule)와 이벤트 기반 자동화(API)를 구축하는 방법을 정리한 가이드입니다. 컴퓨터를 꺼놔도 클라우드에서 돌아가는 자동화 시스템을 직접 만들 수 있습니다.

> ⚠️ **Research Preview 단계**입니다. 일일 실행 횟수 제한, 최소 간격 1시간 등 현재 한계점은 [한계와 시작 전략](#한계와-시작-전략) 섹션을 참고하세요.

## 📚 목차

1. [Routines란 무엇인가](#routines란-무엇인가)
2. [Remote Task → Routines: 무엇이 달라졌나](#remote-task--routines-무엇이-달라졌나)
3. [세 가지 트리거 비교](#세-가지-트리거-비교)
4. [사전 준비사항](#사전-준비사항)
5. [데모 1 — Schedule 트리거: 매일 아침 키워드 브리핑](#데모-1--schedule-트리거-매일-아침-키워드-브리핑)
6. [데모 2 — API 트리거: 구글 폼 → 견적서 자동 생성](#데모-2--api-트리거-구글-폼--견적서-자동-생성)
7. [한계와 시작 전략](#한계와-시작-전략)
8. [자주 묻는 질문](#자주-묻는-질문)
9. [정리 및 다음 단계](#정리-및-다음-단계)

---

## Routines란 무엇인가

**Routines**는 Claude Code에서 제공하는 클라우드 기반 자동화 시스템입니다. 내 컴퓨터가 꺼져 있어도 Anthropic 클라우드에서 Claude가 작업을 실행합니다.

**기존 Remote Task의 아쉬운 점:**
- 매일 아침 9시, 매주 월요일 같은 시간 예약은 됐지만
- "고객이 견적 요청을 보냈을 때" 같은 **이벤트 기반 트리거는 불가능**했습니다

**Routines에서 해결된 것:**
- 트리거가 **Schedule / API / GitHub** 3종으로 확장
- 환경변수, 네트워크 설정, 셋업 스크립트를 루틴마다 직접 설정 가능
- 하나의 루틴에 **여러 트리거 동시 연결** 가능 (예: 매일 자동 실행 + API 수동 호출)

## Remote Task → Routines: 무엇이 달라졌나

| 구분 | 기존 Remote Task | Routines |
|------|------------------|----------|
| **트리거** | Schedule 1개 | Schedule + API + GitHub (3개) |
| **환경 설정** | 기본 클라우드 위주 | 환경변수 + 네트워크 + 셋업 스크립트 + 커넥터 |
| **다중 트리거** | ❌ 불가 | ✅ 하나의 루틴에 여러 트리거 동시 연결 |
| **이벤트 기반 실행** | ❌ 시간 예약만 | ✅ 외부 HTTP / GitHub 이벤트 지원 |

생성 방법은 동일하게 `/schedule` 명령어 또는 `routines`를 사용하지만, 결과적으로 할 수 있는 일의 범위가 완전히 달라졌습니다.

## 세 가지 트리거 비교

| 트리거 | 비유 | 사용 시점 | 인증 방식 |
|--------|------|----------|----------|
| **Schedule** | 정기 택배 | 매일/매주/매시간 자동 실행. 출근하면 결과가 와 있다 | 불필요 (최소 간격 1시간) |
| **API** | 카카오택시 | 외부에서 HTTP POST 한 번이면 즉시 실행. `text` 필드로 상황 정보 전달 | Bearer 토큰 |
| **GitHub** | 이벤트 감지기 | Pull Request·Release 이벤트에 자동 반응. 개발팀 특화 | GitHub 앱 + 필터 지원 |

> 💡 업무 자동화에 관심 있는 분들에게는 **Schedule과 API**가 훨씬 실용적입니다. GitHub 트리거는 개발팀에게 가장 강력한 옵션입니다. 본 가이드에서도 Schedule과 API 중심으로 다룹니다.

## 사전 준비사항

- **Claude Code 구독 플랜**: Pro / Max / Team / Enterprise 중 하나
- **GitHub 리포지토리**: 루틴 실행 시 매번 fresh clone됩니다. 스킬, 템플릿, 단가표 등 참조할 파일을 넣어두세요
- **GitHub 계정 연결**: `claude.ai/code/routines`에서 리포 접근 권한 부여
- **Slack 워크스페이스** (선택): 결과 전달용 — Claude Code의 기본 커넥터로 포함되어 있음
- **데모 1 추가 준비물**: YouTube Data API 키 (Google Cloud Console에서 발급)
- **데모 2 추가 준비물**: Google 계정 (Google Form + Apps Script 사용)

---

## 데모 1 — Schedule 트리거: 매일 아침 키워드 브리핑

### 시나리오

유튜브 채널 운영자나 특정 키워드를 꾸준히 모니터링해야 하는 분들을 위한 자동화입니다. 매일 아침 관심 키워드로 유튜브를 검색하고, 조회수 잘 나오는 영상의 제목 패턴을 분석하는 작업 — **30분~1시간**이 걸리는 일을 자고 있는 동안 Claude가 대신 처리합니다.

### 1. YouTube Data API 키 발급

1. [Google Cloud Console](https://console.cloud.google.com)에 접속
2. 새 프로젝트 생성
3. **API 및 서비스 > 라이브러리**에서 "YouTube Data API v3" 검색 후 활성화
4. **API 및 서비스 > 사용자 인증 정보 > + 사용자 인증 정보 만들기 > API 키** 클릭
5. 생성된 API 키를 안전한 곳에 복사 (`AIzaSy...`로 시작)

### 2. 루틴 생성

`claude.ai/code/routines`에 접속 / 데스크톱앱 `routines` → **New routine** 클릭

**이름:** `키워드 브리핑`

**프롬프트 (그대로 복사):**

```
매일 아침 관심 키워드 유튜브 트렌드 브리핑을 생성해주세요.

할 일:
1. 환경변수 YOUTUBE_API_KEY로 YouTube Data API에 접근하세요
2. 아래 키워드 각각에 대해 최근 1개월 내 업로드된 영상을 검색하세요
      - 클로드 코드
3. 키워드별 관련성 높은 상위 5개 영상의 제목, 조회수, 채널명을 정리하세요
4. 추천된 해당 영상 제목 패턴(숫자 포함, 질문형, 비교형 등)을 분석하세요
5. 우리 채널에 참고할 핵심 포인트를 3가지로 정리하세요
6. 결과를 Slack #morning-briefing 채널에 전송하세요

하지 말아야 할 것:
- 영상을 다운로드하지 마세요
- 외부 서비스에 데이터를 전송하지 마세요 (Slack 제외)
```

> 🔑 **핵심 포인트**: 루틴은 **승인 프롬프트 없이 자율 실행**됩니다. 중간에 "이거 해도 돼요?"라고 묻지 않기 때문에, 프롬프트에 **할 일과 하지 말아야 할 것**을 명확하게 적어야 합니다. 또한 명확하지 않은 지시가 있다면, 루틴에서 모델이 추가 질문을 할 수 있습니다.

### 3. 리포지토리 선택

매 실행마다 지정한 리포를 새로 클론해서 시작합니다. 분석 스크립트나 템플릿이 있다면 리포에 넣어두세요.

### 4. 환경 설정

Routines는 클라우드에서 돌아가기 때문에 내 PC의 `.env` 파일을 읽을 수 없습니다. 환경변수를 루틴에서 직접 입력합니다.

**환경변수:**
```
YOUTUBE_API_KEY=AIzaSy...여러분의키
```

**네트워크 설정:**

| 옵션 | 설명 | 사용 시점 |
|------|------|----------|
| **Trusted** | Anthropic이 관리하는 신뢰 도메인 리스트만 접근 (Google, GitHub, Slack 등 포함) | 일반적인 경우 (권장) |
| **Full** | 모든 외부 API 호출 가능 | Trusted 리스트에 없는 외부 서비스 호출 시 |
| **Custom** | 내가 설정한 도메인만 호출 가능 | 내가 지정한 리스트만 호출 원할 시 |

이번 데모는 YouTube(Google) API를 쓰므로 **Trusted**로 충분합니다.

**셋업 스크립트:** 비워두세요. 클라우드 환경에 Python, Node.js 등 기본 도구가 이미 설치되어 있고, Claude가 세션 안에서 필요한 패키지를 직접 설치할 수 있습니다. "특정 도구를 찾을 수 없습니다" 오류가 나올 때만 추가하면 됩니다.

### 5. 트리거 설정

1. 트리거에서 **Schedule** 선택
2. **Daily** 선택, 시간은 오전 10시 (한국 시간)
3. 실제 실행은 몇 분 지연될 수 있지만 **루틴마다 고정된 오프셋**이라 매일 비슷한 시간에 결과가 도착합니다

### 6. 커넥터 확인

기본으로 모든 커넥터(Slack, GitHub 등)가 포함되어 있습니다. 쓰지 않는 것만 빼면 됩니다. **Slack이 켜져 있는지 확인**하세요.

### 7. Create → 즉시 테스트

**Create** 버튼을 누르면 완료입니다. 매일 아침 10시에 자동 실행됩니다.

바로 테스트하려면 루틴 상세 페이지에서 **Run now** 버튼을 클릭합니다.

→ 세션 URL이 생성되고 Claude가 실시간으로 작업하는 과정을 볼 수 있습니다. 결과가 마음에 들지 않으면 해당 세션에서 대화를 이어가며 수정할 수도 있습니다.

### 기대 결과물 (Slack 브리핑 예시)

> **키워드 브리핑 — 2026-04-18**
> - '클로드 코드' 키워드 영상 10건
> - 조회수 1위 제목 패턴: 숫자 + 구체 결과 (예: "3시간 → 5분")
> - '클로드 코드' 키워드는 전일 대비 영상 수 2배 증가
> - **우리 채널 참고 포인트 3가지**: ...

---

## 데모 2 — API 트리거: 구글 폼 → 견적서 자동 생성

### 시나리오

고객이 견적 요청을 보낼 때마다 — 요구사항 정리, 과거 단가표 확인, 견적서 초안 작성 — 이 귀찮은 반복 작업을 **Google Form 제출 → Apps Script → Claude Routine**으로 이어지는 파이프라인으로 자동화합니다.

### 전체 흐름

```
[Google Form 제출]
    ↓ onFormSubmit 이벤트
[Apps Script] → 응답 읽기 → text 문자열 조합 → POST /fire
    ↓
[Claude Routine] → pricing-template.md 참조 → 견적서 초안 생성 → GitHub 저장
    ↓
[Slack #estimates] → 초안 요약 전달
```

> 💰 **무료 도구(Google Form + Apps Script)로 Claude 실행 엔진에 연결**하는 구조입니다.

### 1. Claude 루틴 생성 (API 트리거)

`claude.ai/code/routines` → **New routine** 클릭

**이름:** `견적서 자동 생성`

**프롬프트 (그대로 복사):**

```
고객 견적 요청 정보를 받아 견적서 초안을 생성해주세요.

입력: text 필드에 고객명, 서비스 유형, 예산, 요구사항이 전달됩니다.

할 일:
1. 리포의 reference/pricing-template.md를 참조하여 서비스별 단가를 확인하세요
2. 고객 요구사항에 맞는 항목을 선정하고 견적 금액을 산출하세요 (VAT 별도)
3. /quote-generator 스킬을 활용해 포맷에 맞게 견적서를 생성하세요
4. estimates/ 폴더에 {고객명}-{날짜}.md 형식으로 견적서를 저장하세요
5. 결과를 Slack #estimates 채널에 요약과 함께 전송하세요
6. 해당 결과물을 포함해 커밋하고 깃허브에 푸시하세요.

하지 말아야 할 것:
- 고객 정보를 Slack 이외의 외부 서비스에 전송하지 마세요
- 견적 금액을 임의로 할인하지 마세요
```

**트리거에서 `API` 선택**

### 2. API URL과 토큰 확인

API 트리거를 추가하면 **URL과 토큰**이 생성됩니다.

> ⚠️ **중요**: 토큰은 **한 번만 보여주고 다시는 안 보여줍니다.** 반드시 복사해서 안전한 곳에 저장하세요. 유출되었다면 루틴 설정에서 **Regenerate**로 즉시 교체할 수 있습니다.

### 3. 터미널에서 API 테스트 (curl)

구글 폼과 연결하기 전, curl로 먼저 잘 돌아가는지 확인합니다.

```bash
curl -X POST https://api.anthropic.com/v1/claude_code/routines/{루틴-ID}/fire \
  -H "Authorization: Bearer sk-ant-oat01-여러분의토큰" \
  -H "anthropic-beta: experimental-cc-routine-2026-04-01" \
  -H "anthropic-version: 2023-06-01" \
  -H "Content-Type: application/json" \
  -d '{"text": "고객: 구씨컴퍼니\n서비스: Claude Code 도입 컨설팅 3개월\n예산: 월 300만원 내외\n요구사항: 사내 업무 자동화 워크플로 5개 구축, 직원 교육 2회 포함"}'
```

**성공 시 응답 예시:**
```json
{
  "claude_code_session_id": "session_number",
  "claude_code_session_url": "https://claude.ai/code/session_number",
  "type": "routine_fire"
}
```

→ 반환된 `claude_code_session_url`에 접속하면 Claude가 실시간으로 견적서를 만드는 과정을 볼 수 있습니다.

> 📌 **header 설명**
> - `anthropic-beta: experimental-cc-routine-2026-04-01` — 실험 단계 API임을 표시. 버전이 바뀌어도 이전 두 개까지는 호환되므로 당장 걱정할 필요는 없습니다.
> - `anthropic-version: 2023-06-01` — Anthropic API 표준 버전
> - `Content-Type: application/json` — 필수

**`text` 필드의 역할:** 루틴의 프롬프트에 더해서 **이 text가 추가 컨텍스트로 전달**되는 구조입니다. 즉, "매번 달라지는 입력값"을 여기에 넣으면 됩니다.

### 4. Google Form 생성

[Google Forms](https://forms.google.com)에 접속 → 새 폼 생성

**이름:** `견적 요청 폼`

**필드 (4개):**

| 필드 이름 | 타입 | 필수 |
|----------|------|------|
| 고객명 | 단답형 | ✅ |
| 서비스 유형 | 객관식 또는 단답형 | ✅ |
| 예산 | 단답형 | ✅ |
| 요구사항 및 상세 설명 | 장문형 | ✅ |

### 5. Apps Script 연결

폼 편집 화면에서 **점 세 개 메뉴 (⋮) → 스크립트 편집기** 클릭

기본 코드를 지우고 아래를 그대로 붙여넣으세요:

```javascript
function onFormSubmit(e) {
  var items = e.response.getItemResponses();
  var text = "고객: " + items[0].getResponse()
    + "\n서비스: " + items[1].getResponse()
    + "\n예산: " + items[2].getResponse()
    + "\n요구사항: " + items[3].getResponse();

  var props = PropertiesService.getScriptProperties();
  UrlFetchApp.fetch(props.getProperty("ROUTINE_URL"), {
    method: "post",
    headers: {
      "Authorization": "Bearer " + props.getProperty("ROUTINE_TOKEN"),
      "anthropic-beta": "experimental-cc-routine-2026-04-01",
      "anthropic-version": "2023-06-01"
    },
    contentType: "application/json",
    payload: JSON.stringify({ text: text })
  });
}
```

**코드 동작 요약:**
1. 폼 응답 4개를 읽어서
2. 하나의 텍스트로 묶고
3. Claude Routine API에 POST 전송

### 6. 스크립트 속성에 URL과 토큰 저장

코드에 토큰을 직접 적지 않기 위해 **스크립트 속성**을 사용합니다.

**Apps Script 왼쪽 메뉴 → 프로젝트 설정 (⚙️) → 스크립트 속성 → 스크립트 속성 추가**

| 속성 이름 | 값 |
|----------|---|
| `ROUTINE_URL` | 루틴에서 생성된 API endpoint URL |
| `ROUTINE_TOKEN` | 복사해둔 Bearer 토큰 (`sk-ant-oat01-...`) |

> 🔒 이렇게 하면 토큰이 코드에 노출되지 않고, 스크립트 편집 권한이 있는 사람만 볼 수 있습니다.

### 7. 폼 제출 트리거 연결

**Apps Script 왼쪽 메뉴 → 트리거 (⏰) → 트리거 추가** 클릭

| 설정 항목 | 값 |
|----------|---|
| 실행할 함수 | `onFormSubmit` |
| 이벤트 소스 | 폼에서 |
| 이벤트 유형 | 양식 제출 시 |

**저장** 버튼 클릭 (최초 저장 시 Google 계정 권한 승인 필요)

### 8. 테스트 제출

완성된 구글 폼에 테스트 데이터를 넣어봅니다.

**테스트 예시:**
- 고객명: `구씨컴퍼니`
- 서비스 유형: `워크플로우 구축`
- 예산: `3500000`
- 요구사항: `사내 콘텐츠 제작 워크플로우 제작 문의`

**결과:**
1. 구글 폼 제출
2. Apps Script가 자동으로 Claude 루틴 호출
3. Claude가 리포의 단가표와 템플릿 참조해서 견적서 초안 생성
4. `estimates/` 폴더에 커밋·푸시
5. Slack `#estimates` 채널에 요약 도착

### 확장 가능성

구글 폼 외에도 **HTTP POST를 보낼 수 있는 모든 환경**에서 동일한 방식으로 Claude 루틴을 호출할 수 있습니다:

- Slack 버튼 / 슬래시 커맨드
- 자체 웹페이지 폼
- 다른 SaaS 서비스 (Notion webhook, Typeform 등)
- n8n, Make, Zapier 등 자동화 툴의 HTTP Request 노드
- 바이브코딩으로 만든 앱

---

## 한계와 시작 전략

Routines는 아직 **Research Preview** 단계입니다. 현실적으로 쓰려면 한계를 알고 시작해야 합니다.

### ⚠️ 현재 한계점

| 한계 | 내용 | 대응 방법 |
|------|------|----------|
| **일일 실행 횟수 제한** | Pro 5회/일, Max 15회/일, Team & Enterprise 25회/일 (변경 가능) | 정말 중요한 한두 개부터 배치. 남은 횟수는 `claude.ai/code/routines` 또는 settings > usage에서 확인 |
| **최소 간격 1시간** | 5분마다 실시간 모니터링 불가 | 실시간 용도는 `/loop` 사용. 루틴은 매시간/매일/매주 정기 작업용 |
| **로컬 파일 접근 불가** | 매번 GitHub에서 fresh clone | 필요한 데이터는 리포에 저장, 환경변수로 전달, 또는 커넥터로 외부 서비스에서 가져오기 |
| **전용 시크릿 저장소 없음** | 환경변수는 편집 권한자가 볼 수 있음 | 읽기 전용 키 위주로 저장. 민감한 Bearer 토큰은 외부 도구(Apps Script 속성 등)에서 관리 |
| **리소스 상한** | 4 vCPU / 16GB RAM / 30GB 디스크 | 대용량 데이터 처리는 분할 실행 또는 외부 스토리지 활용 |
| **내 계정으로 행동** | 루틴이 만든 커밋·PR·슬랙 메시지 모두 **내 이름으로 발행** | 프롬프트에 "하지 말아야 할 것" 목록을 반드시 명시 — 프롬프트가 유일한 제어 수단 |

### 🚀 현실적인 시작 전략

1. **보조 업무부터 시작**: 아침 브리핑, 키워드 분석, 정기 리포트 등 실수해도 업무에 치명적이지 않은 것
2. **안정성 확인**: 2~3주 운영하면서 결과물 품질과 예외 상황 확인
3. **점차 확대**: 고객 대응, 문서 생성 등 업무 영향도가 큰 영역으로 확장

> 💡 **기존에 Claude Code Skill을 만들어 쓰시던 분이라면**, 그 스킬 위에 트리거만 붙이면 됩니다. **스킬이 업무 로직, 루틴이 실행 타이밍**이라고 생각하세요.

---

## 자주 묻는 질문

### Q1. Routines는 어떤 플랜에서 쓸 수 있나요?
Claude Code 구독 플랜(Pro / Max / Team / Enterprise)에서 사용할 수 있으며, 플랜에 따라 일일 실행 횟수가 다릅니다. 정확한 최신 제한은 `claude.ai/code/routines` 또는 settings > usage 페이지에서 확인하세요.

### Q2. 내 컴퓨터에 있는 파일을 루틴에서 참조하려면?
불가능합니다. 매 실행마다 GitHub에서 fresh clone하는 구조이므로, 필요한 파일은 **리포에 커밋해두거나** 환경변수 / 커넥터로 전달해야 합니다.

### Q3. `text` 필드에는 어떤 내용을 넣어야 하나요?
루틴 프롬프트는 **고정된 지시사항**, `text`는 **매번 달라지는 입력값**이라고 생각하세요. 견적서 루틴의 경우 프롬프트에는 "견적서 생성 로직"을, `text`에는 "이번 고객 정보"를 넣는 식입니다.

### Q4. 토큰을 실수로 노출했어요.
즉시 루틴 설정에서 **Regenerate**를 눌러 기존 토큰을 무효화하고 새 토큰으로 교체하세요. 그리고 Apps Script 등 연결된 곳의 토큰도 갱신해야 합니다.

### Q5. `anthropic-beta` 헤더가 바뀌면 기존 연동이 깨지나요?
이전 두 개 버전까지는 호환됩니다. 버전이 바뀌어도 당장 연동이 깨지지는 않으니, 공지를 보고 여유를 두고 업데이트하면 됩니다.

### Q6. 여러 개의 트리거를 하나의 루틴에 붙일 수 있나요?
네. 예를 들어 "키워드 분석 루틴"에 **Schedule(매일 밤 자동 실행) + API(급할 때 수동 호출)**를 동시에 걸 수 있습니다.

### Q7. 루틴이 예상과 다르게 작동하면 어떻게 디버깅하나요?
루틴 상세 페이지의 **실행 이력**에서 각 실행 세션 URL에 접속하면 Claude의 전체 작업 과정을 볼 수 있습니다. 해당 세션에서 **대화를 이어가며 수정**할 수도 있습니다.

### Q8. n8n이나 Make 같은 자동화 툴과 연동되나요?
네. HTTP Request 노드 하나만 있으면 API 트리거를 호출할 수 있습니다. 노드 2~3개 정도로 간단히 연동할 수 있어서, 복잡한 조건 분기가 필요한 경우에 유용합니다.

---

## 정리 및 다음 단계

### 오늘 구축한 것

| 구분 | 내용 |
|------|------|
| **Schedule 트리거** | 매일 아침 키워드 브리핑이 Slack으로 자동 도착 |
| **API 트리거** | 구글 폼 제출 → 견적서 초안 자동 생성 → Slack 요약 |
| **핵심 구성 요소** | 프롬프트(할 일 + 하지 말아야 할 것) + 모델 + 환경변수 + 커넥터 + 트리거 |

### 지금 당장 해볼 수 있는 것

- 환경변수 넣기
- 커넥터 켜기
- 프롬프트 작성해서 루틴 생성
- `Run now`로 즉시 테스트

### 아직 이른 것

핵심 업무를 100% 루틴에 맡기는 것. 일일 실행 제한, 시크릿 저장소 부재, 자율 실행 리스크가 해소될 때까지는 **보조 업무 중심**으로 쓰는 것이 현실적입니다.

### 핵심 메시지

> **스킬이 업무 로직, 루틴이 실행 타이밍입니다.**
> 기존에 Claude Code Skill을 설정한 것이 있다면, 그 위에 트리거만 붙이면 바로 자동화 시스템이 됩니다.

---

## 참고 자료

- [Claude Code Routines 공식 페이지](https://claude.ai/code/routines)
- [Anthropic Console](https://console.anthropic.com/)
- [Google Cloud Console](https://console.cloud.google.com/)
- [Google Apps Script 가이드](https://developers.google.com/apps-script)

---

**시민개발자 구씨** | AI 자동화 시스템 구축 콘텐츠를 제작합니다. 구체적으로 만들어보고 싶은 루틴 아이디어가 있다면 댓글로 공유해주세요!
