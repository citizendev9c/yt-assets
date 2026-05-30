# Hermes Agent Codex OAuth/NoneType 패치 가이드

![Hotfix](https://img.shields.io/badge/Hermes-Codex%20Hotfix-FF6D5A?style=for-the-badge)

이 문서는 Hermes Agent에서 **`openai-codex/gpt-5.5` 호출 시 아래 에러가 발생할 때 적용하는 임시 핫픽스** 절차입니다.

```text
API call failed: TypeError
Provider: openai-codex  Model: gpt-5.5
Endpoint: https://chatgpt.com/backend-api/codex
Error: 'NoneType' object is not iterable
Non-retryable error (HTTP None)
```

> ⚠️ **임시 패치입니다.** 이 가이드는 공식 릴리스 전 핫픽스이며, 패치는 OpenAI SDK / Hermes 소스 파일을 직접 수정합니다.
> - **공식 릴리스에서 이 문제가 해결되면 공식 업데이트를 우선**하세요. 직접 패치는 정식 수정이 아닙니다.
> - 모든 패치 스크립트는 수정 전 **원본 옆에 `.bak-YYYYMMDDHHMMSS` 백업**을 만듭니다. 적용 후 반드시 [롤백 절차](#d-롤백)를 한 번 읽어두세요.
> - 이미지 재생성·업데이트 시 패치가 사라질 수 있습니다. [운영 기준](#e-운영-기준)을 참고하세요.

---

## 목차

- [1. 이 패치가 해결하는 문제](#1-이-패치가-해결하는-문제)
- [2. 설치 방식 선택](#2-설치-방식-선택)
- [3. 경로 placeholder 안내](#3-경로-placeholder-안내)
- [A. Docker Compose 버전](#a-docker-compose-버전)
- [B. 직접 설치 버전](#b-직접-설치-버전)
- [C. 정상 적용 확인](#c-정상-적용-확인)
- [D. 롤백](#d-롤백)
- [E. 운영 기준](#e-운영-기준)
- [참고](#참고)

---

## 1. 이 패치가 해결하는 문제

`openai-codex/gpt-5.5` provider로 요청을 보낼 때, 응답의 `output` 필드가 `None`으로 내려오면 OpenAI SDK 내부의 반복문이 `None`을 순회하려다 `'NoneType' object is not iterable`로 죽습니다. 패치는 두 군데를 손봅니다.

| # | 패치 | 무엇을 하나 | 역할 |
|---|---|---|---|
| 1 | **OpenAI SDK 패치** | `response.output`이 `None`일 때 빈 리스트로 처리 | 실제 `NoneType` 크래시를 막는 **핵심 패치** |
| 2 | **Hermes Codex transport 패치** | Codex backend로 `tools=None`이 넘어가지 않게 정리 | 보조 안정화 패치 |

> 💡 1번이 크래시를 막는 핵심입니다. 2번은 보조이며, 1번만으로 에러가 사라지면 생략해도 됩니다.

---

## 2. 설치 방식 선택

본인 환경에 맞는 섹션 하나를 골라 그대로 복붙하세요.

| 설치 방식 | 실행할 섹션 | 특징 | 기준 위치(예시) |
|---|---|---|---|
| **Docker Compose** (VPS 등) | [A. Docker Compose 버전](#a-docker-compose-버전) | 컨테이너 안에서 `docker compose exec`로 패치 실행 | `/docker/hermes-agent-xxxx` |
| **직접 설치** (root/사용자 venv) | [B. 직접 설치 버전](#b-직접-설치-버전) | 호스트 shell에서 venv Python으로 직접 실행 | `~/.hermes/hermes-agent` |

---

## 3. 경로 placeholder 안내

공개 문서이므로 실제 설치 경로 대신 placeholder를 씁니다. **각 코드블록 맨 위 변수만 본인 환경 값으로 한 번 바꾸면** 나머지는 그대로 복붙됩니다.

| placeholder | 의미 | 교체 예시 |
|---|---|---|
| `{{HERMES_DOCKER_DIR}}` (= `/docker/hermes-agent-xxxx`) | Docker Compose 프로젝트 폴더 (호스트 쪽) | `/docker/hermes-agent-ab12` 등 본인 실제 폴더 |
| `SVC` | Compose 서비스명 | 보통 `hermes-agent` (다르면 `docker compose ps --services`로 확인) |
| `{{HERMES_INSTALL_DIR}}` (= `~/.hermes/hermes-agent`) | 직접 설치 시 Hermes 코드/venv 위치 | `/root/.hermes/hermes-agent` 또는 `$HOME/.hermes/hermes-agent` |

> 📌 아래 스크립트의 `/app`, `/workspace`, `/opt`, `site-packages` 같은 **컨테이너 내부 검색 경로**는 placeholder가 아니라 실제 탐색 대상이므로 그대로 둡니다. 바꾸는 건 맨 위 `{{HERMES_DOCKER_DIR}}` / `{{HERMES_INSTALL_DIR}}` 변수뿐입니다.

---

## A. Docker Compose 버전

Docker Compose 프로젝트로 설치한 경우 이 섹션을 씁니다. 실행 위치는 **호스트의 Compose 프로젝트 폴더**입니다. 컨테이너 안에 직접 들어가지 않고, `docker compose exec`가 컨테이너 내부에서 패치 코드를 실행합니다.

### A-0. 사전 확인

```bash
# 본인 Docker Compose 프로젝트 폴더로 교체 (예: /docker/hermes-agent-xxxx)
HERMES_DOCKER_DIR=/docker/hermes-agent-xxxx
SVC=hermes-agent

cd "$HERMES_DOCKER_DIR"
docker compose ps
```

서비스명이 다르면 아래로 확인 후 `SVC` 값을 바꿉니다.

```bash
docker compose ps --services
```

### A-1. OpenAI SDK 패치 (핵심)

```bash
HERMES_DOCKER_DIR=/docker/hermes-agent-xxxx
SVC=hermes-agent
cd "$HERMES_DOCKER_DIR"

docker compose exec -u root -T "$SVC" python3 - <<'PY'
import datetime
import pathlib
import shutil
import sys

import openai

sdk_file = pathlib.Path(openai.__file__).resolve().parent / "lib/_parsing/_responses.py"
old = "for output in response.output:"
new = "for output in (response.output or []):"

print(f"OpenAI SDK version: {getattr(openai, '__version__', 'unknown')}")
print(f"SDK file: {sdk_file}")

src = sdk_file.read_text()

if new in src:
    print("SDK patch already applied")
elif old in src:
    backup = sdk_file.with_name(sdk_file.name + ".bak-" + datetime.datetime.now().strftime("%Y%m%d%H%M%S"))
    shutil.copy2(sdk_file, backup)
    sdk_file.write_text(src.replace(old, new, 1))
    print("SDK patch applied")
    print(f"backup: {backup}")
else:
    print("SDK patch failed: target line not found")
    sys.exit(1)
PY
```

### A-2. Hermes Codex transport 패치 (보조)

```bash
HERMES_DOCKER_DIR=/docker/hermes-agent-xxxx
SVC=hermes-agent
cd "$HERMES_DOCKER_DIR"

docker compose exec -u root -T "$SVC" python3 - <<'PY'
import datetime
import importlib.util
import pathlib
import shutil
import sys

def safe_find_spec_origin(mod):
    try:
        spec = importlib.util.find_spec(mod)
    except ModuleNotFoundError:
        return None
    except Exception as e:
        print(f"skip module lookup {mod}: {e}")
        return None

    if spec and spec.origin:
        p = pathlib.Path(spec.origin).resolve()
        if p.exists():
            return p
    return None

candidates = []

for mod in ("agent.transports.codex", "hermes_agent.agent.transports.codex"):
    p = safe_find_spec_origin(mod)
    if p:
        candidates.append(p)

for root in (
    pathlib.Path("/app"),
    pathlib.Path("/workspace"),
    pathlib.Path("/opt"),
    pathlib.Path("/root/.hermes/hermes-agent"),
    pathlib.Path("/usr/local/lib/python3.11/site-packages"),
    pathlib.Path("/usr/local/lib/python3.12/site-packages"),
):
    if root.exists():
        try:
            candidates.extend(root.rglob("agent/transports/codex.py"))
        except Exception as e:
            print(f"skip search {root}: {e}")

seen = set()
candidates = [p.resolve() for p in candidates if not (p.resolve() in seen or seen.add(p.resolve()))]

if not candidates:
    print("Transport patch failed: agent/transports/codex.py not found")
    sys.exit(1)

print("Candidate files:")
for p in candidates:
    print(f" - {p}")

patched_any = False

old = (
    '            "tools": response_tools,\n'
    '            "store": False,\n'
    '        }\n'
    '        if response_tools:\n'
    '            kwargs["tool_choice"] = "auto"\n'
    '            kwargs["parallel_tool_calls"] = True'
)

new = (
    '            "store": False,\n'
    '        }\n'
    '        if response_tools:\n'
    '            kwargs["tools"] = response_tools\n'
    '            kwargs["tool_choice"] = "auto"\n'
    '            kwargs["parallel_tool_calls"] = True'
)

for transport_file in candidates:
    src = transport_file.read_text()

    if new in src:
        print(f"Transport patch already applied: {transport_file}")
        patched_any = True
        continue

    if old in src:
        backup = transport_file.with_name(transport_file.name + ".bak-" + datetime.datetime.now().strftime("%Y%m%d%H%M%S"))
        shutil.copy2(transport_file, backup)
        transport_file.write_text(src.replace(old, new, 1))
        print(f"Transport patch applied: {transport_file}")
        print(f"backup: {backup}")
        patched_any = True
        continue

    if "response_tools" in src and '"tools": response_tools' in src:
        print(f"Source differs, but target-like lines found: {transport_file}")
        for i, line in enumerate(src.splitlines(), 1):
            if "response_tools" in line or '"tools"' in line:
                print(f"{i}: {line}")

if not patched_any:
    print("No exact transport patch applied.")
    print("This can mean the Docker image already differs from the expected source layout.")
    print("If the SDK patch fixed the NoneType error, this second patch can be skipped.")
PY
```

### A-3. Docker Hermes 재시작과 로그 확인

```bash
HERMES_DOCKER_DIR=/docker/hermes-agent-xxxx
SVC=hermes-agent
cd "$HERMES_DOCKER_DIR"

docker compose restart "$SVC"
docker compose logs --tail=120 "$SVC"
```

### A-4. Docker 업데이트 후 SDK만 빠르게 다시 패치

`Update`, `docker compose pull`, 이미지 재생성 이후 같은 `NoneType` 에러가 다시 나오면 **먼저 이 SDK-only 재패치만** 실행합니다.

```bash
HERMES_DOCKER_DIR=/docker/hermes-agent-xxxx
SVC=hermes-agent
cd "$HERMES_DOCKER_DIR"

docker compose exec -u root -T "$SVC" python3 - <<'PY'
import datetime
import pathlib
import shutil
import sys

import openai

sdk_file = pathlib.Path(openai.__file__).resolve().parent / "lib/_parsing/_responses.py"
old = "for output in response.output:"
new = "for output in (response.output or []):"

print(f"OpenAI SDK version: {getattr(openai, '__version__', 'unknown')}")
print(f"SDK file: {sdk_file}")

src = sdk_file.read_text()

if new in src:
    print("SDK patch already applied")
elif old in src:
    backup = sdk_file.with_name(sdk_file.name + ".bak-" + datetime.datetime.now().strftime("%Y%m%d%H%M%S"))
    shutil.copy2(sdk_file, backup)
    sdk_file.write_text(src.replace(old, new, 1))
    print("SDK patch applied")
    print(f"backup: {backup}")
else:
    print("SDK patch failed: target line not found")
    sys.exit(1)
PY

docker compose restart "$SVC"
docker compose logs --tail=120 "$SVC"
```

---

## B. 직접 설치 버전

Hermes를 직접 설치해서 `~/.hermes/hermes-agent` 아래에 코드와 venv가 있는 경우 이 섹션을 씁니다. Docker 명령을 쓰지 않고, 호스트 shell에서 venv Python으로 직접 실행합니다.

### B-0. 사전 확인

```bash
# 본인 Hermes 설치 경로로 교체 (root 설치면 /root/.hermes/hermes-agent)
HERMES="$HOME/.hermes/hermes-agent"
PYTHON="$HERMES/venv/bin/python"

test -x "$PYTHON" && echo "Python found: $PYTHON"
test -d "$HERMES" && echo "Hermes dir found: $HERMES"
"$PYTHON" -c "import openai; print('OpenAI SDK:', getattr(openai, '__version__', 'unknown')); print(openai.__file__)"
```

> 📌 root 계정에 설치했다면 첫 줄을 `HERMES=/root/.hermes/hermes-agent` 로 바꾸면 됩니다.

### B-1. OpenAI SDK 패치 (핵심)

```bash
HERMES="$HOME/.hermes/hermes-agent"
PYTHON="$HERMES/venv/bin/python"

"$PYTHON" - <<'PY'
import datetime
import pathlib
import shutil
import sys

import openai

sdk_file = pathlib.Path(openai.__file__).resolve().parent / "lib/_parsing/_responses.py"
old = "for output in response.output:"
new = "for output in (response.output or []):"

print(f"OpenAI SDK version: {getattr(openai, '__version__', 'unknown')}")
print(f"SDK file: {sdk_file}")

src = sdk_file.read_text()

if new in src:
    print("SDK patch already applied")
elif old in src:
    backup = sdk_file.with_name(sdk_file.name + ".bak-" + datetime.datetime.now().strftime("%Y%m%d%H%M%S"))
    shutil.copy2(sdk_file, backup)
    sdk_file.write_text(src.replace(old, new, 1))
    print("SDK patch applied")
    print(f"backup: {backup}")
else:
    print("SDK patch failed: target line not found")
    sys.exit(1)
PY
```

### B-2. Hermes Codex transport 패치 (보조)

```bash
HERMES="$HOME/.hermes/hermes-agent"
PYTHON="$HERMES/venv/bin/python"

HERMES="$HERMES" "$PYTHON" - <<'PY'
import datetime
import os
import pathlib
import shutil
import sys

hermes_dir = pathlib.Path(os.environ["HERMES"]).resolve()
candidates = []

direct = hermes_dir / "agent/transports/codex.py"
if direct.exists():
    candidates.append(direct)

for pattern_root in (
    hermes_dir,
    hermes_dir / "src",
    hermes_dir / "venv/lib/python3.11/site-packages",
    hermes_dir / "venv/lib/python3.12/site-packages",
):
    if pattern_root.exists():
        try:
            candidates.extend(pattern_root.rglob("agent/transports/codex.py"))
        except Exception as e:
            print(f"skip search {pattern_root}: {e}")

seen = set()
candidates = [p.resolve() for p in candidates if not (p.resolve() in seen or seen.add(p.resolve()))]

if not candidates:
    print("Transport patch failed: agent/transports/codex.py not found")
    sys.exit(1)

print("Candidate files:")
for p in candidates:
    print(f" - {p}")

patched_any = False

old = (
    '            "tools": response_tools,\n'
    '            "store": False,\n'
    '        }\n'
    '        if response_tools:\n'
    '            kwargs["tool_choice"] = "auto"\n'
    '            kwargs["parallel_tool_calls"] = True'
)

new = (
    '            "store": False,\n'
    '        }\n'
    '        if response_tools:\n'
    '            kwargs["tools"] = response_tools\n'
    '            kwargs["tool_choice"] = "auto"\n'
    '            kwargs["parallel_tool_calls"] = True'
)

for transport_file in candidates:
    src = transport_file.read_text()

    if new in src:
        print(f"Transport patch already applied: {transport_file}")
        patched_any = True
        continue

    if old in src:
        backup = transport_file.with_name(transport_file.name + ".bak-" + datetime.datetime.now().strftime("%Y%m%d%H%M%S"))
        shutil.copy2(transport_file, backup)
        transport_file.write_text(src.replace(old, new, 1))
        print(f"Transport patch applied: {transport_file}")
        print(f"backup: {backup}")
        patched_any = True
        continue

    if "response_tools" in src and '"tools": response_tools' in src:
        print(f"Source differs, but target-like lines found: {transport_file}")
        for i, line in enumerate(src.splitlines(), 1):
            if "response_tools" in line or '"tools"' in line:
                print(f"{i}: {line}")

if not patched_any:
    print("No exact transport patch applied.")
    print("If the SDK patch fixed the NoneType error, this second patch can be skipped.")
PY
```

### B-3. 직접 설치 Hermes 재시작과 로그 확인

Hermes CLI가 PATH에 잡혀 있으면 이것을 우선 사용합니다.

```bash
hermes gateway restart
```

root 설치 등에서 `hermes`가 PATH에 없다면 venv의 CLI를 직접 호출합니다.

```bash
# 본인 설치 경로 기준
"$HOME/.hermes/hermes-agent/venv/bin/hermes" gateway restart
```

로그는 보통 아래에서 확인합니다.

```bash
tail -n 120 ~/.hermes/logs/gateway.log
```

systemd로 gateway를 띄운 설치라면 systemd 로그도 같이 확인합니다.

```bash
systemctl status hermes-agent --no-pager
journalctl -u hermes-agent -n 120 --no-pager
```

### B-4. 직접 설치 업데이트 후 SDK만 빠르게 다시 패치

`hermes update` 이후 같은 `NoneType` 에러가 재발하면 **먼저 이 SDK-only 재패치만** 실행합니다.

```bash
HERMES="$HOME/.hermes/hermes-agent"
PYTHON="$HERMES/venv/bin/python"

"$PYTHON" - <<'PY'
import datetime
import pathlib
import shutil
import sys

import openai

sdk_file = pathlib.Path(openai.__file__).resolve().parent / "lib/_parsing/_responses.py"
old = "for output in response.output:"
new = "for output in (response.output or []):"

print(f"OpenAI SDK version: {getattr(openai, '__version__', 'unknown')}")
print(f"SDK file: {sdk_file}")

src = sdk_file.read_text()

if new in src:
    print("SDK patch already applied")
elif old in src:
    backup = sdk_file.with_name(sdk_file.name + ".bak-" + datetime.datetime.now().strftime("%Y%m%d%H%M%S"))
    shutil.copy2(sdk_file, backup)
    sdk_file.write_text(src.replace(old, new, 1))
    print("SDK patch applied")
    print(f"backup: {backup}")
else:
    print("SDK patch failed: target line not found")
    sys.exit(1)
PY

hermes gateway restart
tail -n 120 ~/.hermes/logs/gateway.log
```

`hermes`가 PATH에 없으면 마지막 두 줄을 아래로 바꿉니다.

```bash
"$HOME/.hermes/hermes-agent/venv/bin/hermes" gateway restart
tail -n 120 ~/.hermes/logs/gateway.log
```

---

## C. 정상 적용 확인

패치 후 Telegram 또는 Slack에서 짧은 요청으로 테스트합니다.

```text
테스트 응답만 해줘
```

로그에서 아래 문구가 사라지면 우선 성공입니다.

```text
'NoneType' object is not iterable
```

> 💡 Telegram과 Slack은 둘 다 같은 Hermes Gateway와 같은 `openai-codex` provider를 타기 때문에, 동시에 실패하거나 동시에 복구될 수 있습니다.

---

## D. 롤백

패치 스크립트는 원본 파일 옆에 `.bak-YYYYMMDDHHMMSS` 백업을 만듭니다. 되돌릴 때는 백업을 원본으로 복사하면 됩니다.

**Docker 버전** — 컨테이너 안에서 백업 파일을 원본으로 되돌립니다.

```bash
HERMES_DOCKER_DIR=/docker/hermes-agent-xxxx
SVC=hermes-agent
cd "$HERMES_DOCKER_DIR"
docker compose exec -u root -T "$SVC" sh -c '
  cp /path/to/_responses.py.bak-YYYYMMDDHHMMSS /path/to/_responses.py
  cp /path/to/codex.py.bak-YYYYMMDDHHMMSS /path/to/codex.py
'
```

**직접 설치 버전** — 호스트 shell에서 파일을 되돌립니다.

```bash
cp /path/to/_responses.py.bak-YYYYMMDDHHMMSS /path/to/_responses.py
cp /path/to/codex.py.bak-YYYYMMDDHHMMSS /path/to/codex.py
```

> 📌 `/path/to/...`와 `YYYYMMDDHHMMSS`는 패치 실행 시 출력된 `backup:` 경로를 그대로 붙여넣으면 됩니다.

되돌린 뒤 설치 방식에 맞게 재시작합니다.

```bash
# Docker
HERMES_DOCKER_DIR=/docker/hermes-agent-xxxx
SVC=hermes-agent
cd "$HERMES_DOCKER_DIR"
docker compose restart "$SVC"

# 직접 설치
hermes gateway restart
```

---

## E. 운영 기준

| 상황 | 먼저 할 일 | 다음 |
|---|---|---|
| 업데이트 후 `NoneType` 재발 | **SDK-only 재패치**(A-4 / B-4) | 정상화되면 끝 |
| SDK-only 재패치로도 실패 | transport 패치(A-2 / B-2) 재실행 | 로그 재확인 |
| 이미지 재생성 / 직접 설치 업데이트 | 패치가 사라질 수 있음을 인지 | 필요 시 SDK 패치부터 재적용 |
| 영구 적용이 필요 | — | 패치가 반영된 **공식 이미지/공식 릴리스** 사용 |

- 업데이트 후에는 **SDK-only 재패치를 먼저** 실행한다. (대부분 이걸로 해결)
- SDK-only 재패치 후 정상화되면 **transport 패치는 다시 건드리지 않는다.**
- SDK-only 재패치 후에도 실패하면 transport 패치를 다시 실행한다.
- 영구 적용하려면 임시 패치에 의존하지 말고, 패치가 반영된 공식 릴리스를 쓰는 것이 맞다.

---

## 참고

- **Hermes 공식 문서**: https://hermes-agent.nousresearch.com/docs
- Hermes 공식 CLI는 `hermes gateway restart` 명령을 제공합니다.
- Linux systemd 또는 macOS launchd로 gateway를 띄운 설치는 업데이트 후 자동 재시작될 수 있습니다.
- 이 문서는 공식 릴리스 전 **임시 핫픽스** 절차입니다. 공식 수정이 배포되면 그쪽을 우선하세요.
- 운영 가이드 전체 맥락은 메인 README를 참고하세요 → [Hermes Agent를 AI 직원처럼 운영하는 방법](./README.md)
