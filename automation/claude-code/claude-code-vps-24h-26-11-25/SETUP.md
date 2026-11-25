# SETUP.md — Claude에게 주는 셋업 지시서

> 이 문서는 Claude Code가 읽고 따르는 지시서입니다. 사람이 읽을 안내는 README.md에 있습니다.
> v1.0 (2026-11-25) — 영상에서 맥으로 처음부터 끝까지 돌린 판입니다. 윈도우 경로는 4단계의 주의를 따릅니다.

## 너(Claude)의 역할

너는 지금 Claude 데스크톱 앱의 SSH 대화로 사용자의 Hostinger VPS에 root로 붙어 있다. 사용자는 이 연결을 **root 비밀번호**로 만들었을 가능성이 크다(가장 빠른 시작 방법). 이 문서의 단계를 순서대로, **한 번에 한 단계씩** 사용자와 함께 진행한다. 사용자는 개발자가 아닐 수 있다. 쉬운 말로 설명한다.

### 지켜야 할 규칙

1. **한 단계씩.** 단계를 시작할 때 무엇을 왜 하는지 한두 문장으로 말하고, 서버 명령은 실행 전에 보여 준 뒤 실행하고 결과를 짧게 알린다. 사용자 확인이 필요한 단계는 답을 받을 때까지 다음으로 넘어가지 않는다.
2. **비밀 값은 대화로 받지 않는다.** root 비밀번호, Claude 로그인 코드, GitHub 로그인 코드, 텔레그램 봇 토큰을 대화창에 붙여 넣으라고 하지 않는다. 사용자가 붙여 넣으면 쓰지 말고, 대화 기록에 남았으니 새로 바꾸라고(비밀번호 재설정, BotFather `/revoke`) 알려 준다.
3. **비밀 값을 화면에 찍지 않는다.** `~/.claude/channels/*/.env` 같은 비밀 파일을 `cat`하거나 내용을 출력하지 않는다. 확인은 `vps-secret check telegram`처럼 값을 숨기는 명령으로 한다.
4. **공개 키(.pub 내용)와 텔레그램 페어링 코드는 받아도 된다.** 개인 키 파일 내용은 절대 받지 않는다.
5. **잠그는 단계는 열쇠 접속이 된 것을 확인한 뒤에만.** 비밀번호 끄기·방화벽은 되돌리는 법(Hostinger Web Console)을 먼저 알려 주고 진행한다.
6. **사용자가 할 일은 어디서·무엇을 누르는지 번호로.** 기기(노트북·휴대폰), 앱, 창 이름을 적는다.
7. 각 단계 끝에 `[완료] n단계` 한 줄로 알리고, 9단계에서 요약 표를 보여 준 뒤 10단계(서버 관리 노트)를 묻는다.
8. **노트북 운영체제를 처음에 한 번 묻고, 그 운영체제 명령만 보여 준다.** 1단계를 시작할 때 "노트북이 맥이에요, 윈도우예요?"라고 묻고 기억한다. 4단계(열쇠 만들기·확인)처럼 노트북에서 치는 명령은 그 운영체제 것만 코드 블록으로 준다(맥 = 터미널 앱, 윈도우 = PowerShell). 모르겠다고 하면 둘 다 보여 준다. 중간 단계부터 이어 받은 새 대화(4-3-1, 5단계 5번 등)에서 운영체제를 모르면 노트북 명령을 주기 전에 다시 묻는다.
9. **노트북 명령은 네가 실행할 수 없다.** 너는 서버에서 돌고 있다. `ssh-keygen`·`ssh-add`·`pbcopy`·PowerShell 명령·`ssh root@…` 같은 노트북 명령을 서버에서 실행하지 않는다. 사용자에게 복사해서 노트북에서 치라고 하고, 결과(나온 글자)를 알려 달라고 한다. 반대로 서버 명령(`vps-session`, `apt-get`, `systemctl` 등)은 사용자에게 시키지 않고 네가 실행한다. 예외는 비밀 값을 넣는 명령(`claude auth login`, `vps-secret set telegram`, `gh auth login`)으로, 사용자가 앱 Terminal 창(서버 터미널)에서 친다.

### 사용자가 직접 하는 일

- 앱 Terminal 창 열기: 대화 창 위쪽 **Terminal**을 누른다. 앱 안에 **서버** 터미널이 열린다(노트북 터미널이 아니다). 로그인 코드·토큰은 여기에 넣는다.
- 노트북 터미널: 맥은 **터미널** 앱(Spotlight에서 "터미널"), 윈도우는 **PowerShell**(시작 메뉴에서 "PowerShell"). 열쇠 만들기·접속 확인에만 쓴다.
- 브라우저 로그인 승인, 노트북에서 열쇠 만들기, 앱 연결 설정 바꾸기, 텔레그램 BotFather.

---

## 1단계 — 서버 확인

먼저 묻는다: "노트북이 맥이에요, 윈도우예요?" (규칙 8. 답을 기억한다.)

실행: `whoami; hostname; . /etc/os-release && echo "$PRETTY_NAME"; command -v claude && claude --version`

- root, Ubuntu 24.04, Claude Code 버전이 보이면 다음으로.
- `claude`가 없으면: `curl -fsSL https://claude.ai/install.sh | bash` 로 설치하고, `~/.profile`에 `export PATH="$HOME/.local/bin:$PATH"`가 없으면 더한다.

## 2단계 — 도구 설치

먼저 필요한 프로그램을 깐다(언제나 실행):

```bash
apt-get update && apt-get install -y tmux git curl unzip ufw
```

이 가이드 파일이 `/opt/claude-vps`에 이미 있으면(사용자가 직접 올린 경우) 아래의 받기 네 줄 중 앞 세 줄은 건너뛰고 `bash /opt/claude-vps/install.sh`만 실행한다. 없으면 받는다:

```bash
rm -rf /tmp/yt-assets && git clone --depth 1 --filter=blob:none --sparse https://github.com/citizendev9c/yt-assets /tmp/yt-assets
git -C /tmp/yt-assets sparse-checkout set automation/claude-code/claude-code-vps-24h-26-11-25
rm -rf /opt/claude-vps && cp -r /tmp/yt-assets/automation/claude-code/claude-code-vps-24h-26-11-25 /opt/claude-vps
bash /opt/claude-vps/install.sh
```

`install.sh`가 `vps-session`·`vps-secret`·`vps-notify`를 `/usr/local/bin`에, 서비스 파일(24시간 세션, 로그인 알림 — 알림은 6-7에서 켬)을 `/etc/systemd/system/`에, `/24h` 스킬을 `~/.claude/skills/24h/`에 넣고 `vps-session doctor` 결과를 보여 준다.

## 3단계 — 서버 Claude 로그인 (사용자)

설명: 지금 이 대화는 노트북 앱의 로그인을 빌려 쓴다. 그래서 노트북이 꺼지면 이 대화는 언제 멈출지 모른다. 24시간 세션은 **서버 자기 로그인**으로 돌아야 한다.

사용자에게 안내:

1. 앱 Terminal 창을 연다.
2. `claude auth login` 을 치고 엔터.
3. 나온 주소를 노트북 브라우저에서 열어 승인하고, 받은 코드를 Terminal 창에 붙여 넣는다(대화창 아님).

확인(너가 실행): `vps-session doctor`의 '서버 Claude 로그인'이 ok면 다음으로. `claude auth login`이 안 되면 Terminal 창에서 `cd /root/projects && claude` → `/login`으로 같은 과정을 안내한다.

## 4단계 — 서버 잠그기: 열쇠로 바꾸고, 비밀번호 끄고, 방화벽 켜기

설명(쉽게): 지금은 root 비밀번호만 알면 누구나 서버 문을 열 수 있다. 인터넷에 있는 서버는 봇들이 하루 종일 비밀번호를 넣어 본다. 그래서 ① 열쇠(SSH 키)로만 열리게 바꾸고 ② 비밀번호로는 못 들어오게 막고 ③ 필요 없는 문은 방화벽으로 닫는다.

먼저 질문: "앱 연결을 root 비밀번호로 만드셨나요, 열쇠로 만드셨나요?" 열쇠로 이미 붙어 있으면 4-3-1(열쇠 확인)로.

### 4-1. 노트북에서 열쇠 만들기 (사용자)

설명: 자물쇠(공개 키)는 서버에, 열쇠(개인 키)는 노트북에만 둔다. 열쇠에 비밀번호(패스프레이즈)를 걸고, 앱이 묻지 않고 다시 붙도록 컴퓨터에 기억시킨다. 1단계에서 들은 운영체제의 블록만 보여 준다(규칙 8·9 — 네가 실행하지 않는다).

**맥 — 터미널 앱** (한 줄씩 붙여 넣고 엔터, 네 줄):

```bash
mkdir -p ~/.ssh && chmod 700 ~/.ssh
ssh-keygen -t ed25519 -f ~/.ssh/hostinger_claude -C "claude-vps"
ssh-add --apple-use-keychain ~/.ssh/hostinger_claude
pbcopy < ~/.ssh/hostinger_claude.pub
```

- 둘째 줄: 패스프레이즈를 두 번 묻는다(쳐도 화면에 안 보이는 게 정상). `already exists. Overwrite?`가 나오면 `n` — 예전에 만든 열쇠를 그대로 쓴다.
- 셋째 줄: 패스프레이즈를 한 번 더 묻고 맥 키체인에 기억시킨다.
- 맥을 다시 켠 뒤 앱이 서버에 못 붙으면(열쇠를 다시 불러와야 할 때) 터미널에서 `ssh-add --apple-load-keychain` 한 줄.

**윈도우 — PowerShell** 두 번에 나눈다.

① 관리자 PowerShell(시작 메뉴에서 PowerShell 오른쪽 클릭 → **관리자로 실행**)에서 두 줄 — 열쇠를 기억해 주는 프로그램(ssh-agent)을 켠다:

```powershell
Get-Service ssh-agent | Set-Service -StartupType Automatic
Start-Service ssh-agent
```

- `Cannot find any service with service name 'ssh-agent'`가 나오면 OpenSSH 클라이언트가 없는 것이다: 같은 관리자 PowerShell에서 `Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0` → 끝나면 위 두 줄을 다시.
- 관리자 PowerShell은 닫는다.

② 보통 PowerShell(관리자 아님)에서 네 줄:

```powershell
New-Item -ItemType Directory -Force "$env:USERPROFILE\.ssh" | Out-Null
ssh-keygen -t ed25519 -f "$env:USERPROFILE\.ssh\hostinger_claude" -C "claude-vps"
ssh-add "$env:USERPROFILE\.ssh\hostinger_claude"
Get-Content "$env:USERPROFILE\.ssh\hostinger_claude.pub" | Set-Clipboard
```

- 둘째 줄: 패스프레이즈를 두 번 묻는다. `already exists. Overwrite?`가 나오면 `n`.
- 셋째 줄: 윈도우 ssh-agent가 열쇠를 기억한다(윈도우를 다시 켜도 남는다).
- 윈도우 경로는 아직 실제 윈도우 노트북에서 끝까지 시험하지 않았다. 특히 데스크톱 앱이 윈도우 ssh-agent에 기억된 열쇠를 쓰는지 확인되지 않았다. 4-3에서 앱이 패스프레이즈 때문에 못 붙으면 멈추고 사용자에게 알린다.

공통:

- 마지막 줄이 공개 키를 복사한다. **그 한 줄을 이 대화에 붙여 넣어 달라고** 한다(공개 키는 비밀이 아니다). `ssh-ed25519 `로 시작하는 한 줄이다.

### 4-2. 서버에 자물쇠 달기 (너)

받은 줄이 `ssh-ed25519 `로 시작하는 한 줄인지 확인한다(`PRIVATE KEY`가 보이면 즉시 멈추고 규칙 2대로 안내). 그다음:

```bash
install -d -m 700 /root/.ssh
grep -qxF '<받은 공개 키>' /root/.ssh/authorized_keys 2>/dev/null || echo '<받은 공개 키>' >> /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys
```

### 4-3. 앱 연결을 열쇠로 (사용자)

1. 앱의 환경 목록에서 New environment → SSH → Add SSH connection.
2. SSH host `root@서버IP`.
3. SSH key 칸에 열쇠 파일의 전체 경로를 넣는다(`.pub`가 아닌 파일). 정확한 경로는 노트북에서 이 한 줄로 확인한다:
   - 맥 터미널: `echo ~/.ssh/hostinger_claude` → `/Users/<이름>/.ssh/hostinger_claude`
   - 윈도우 PowerShell: `echo "$env:USERPROFILE\.ssh\hostinger_claude"` → `C:\Users\<이름>\.ssh\hostinger_claude`
4. 새 연결로 대화를 하나 열어 `/opt/claude-vps/SETUP.md 4-3-1부터 이어서 해 줘. 내 노트북은 맥이야`(윈도우면 `윈도우야`)라고 보낸다. 이 문장을 네가 사용자의 운영체제에 맞춰 완성해서 보여 준다.

### 4-3-1. 열쇠로 들어와지는지 확인 (사용자 + 너) — 비밀번호를 끄기 전에 꼭

주의: 데스크톱 앱은 처음 연결할 때 서버에 띄운 프로그램을 계속 다시 쓴다. 그래서 새 열쇠 연결로 대화를 열어도, 서버에서 보면 처음 비밀번호 연결처럼 보일 수 있다. 서버 쪽 접속 정보(`SSH_CONNECTION`, `who`)로는 판단하지 않는다.

1. (사용자) 노트북 터미널(맥) / PowerShell(윈도우)에서:
   - 맥: `ssh -o PasswordAuthentication=no -i ~/.ssh/hostinger_claude root@서버IP echo KEY-OK`
   - 윈도우: `ssh -o PasswordAuthentication=no -i "$env:USERPROFILE\.ssh\hostinger_claude" root@서버IP echo KEY-OK`
   → root 비밀번호를 묻지 않고 `KEY-OK`가 나오면 성공. 처음이면 `Are you sure you want to continue connecting`에 `yes`. 패스프레이즈를 물으면 4-1의 키체인(맥)·ssh-agent(윈도우) 등록 줄을 다시 한다. `Permission denied`면 4-2(공개 키 붙이기)를 다시 본다.
2. (너) 서버 기록에 열쇠 접속이 남았는지 본다:

```bash
journalctl -u ssh --since "30 min ago" | grep 'Accepted publickey' | tail -3
```

   한 줄 이상 나오면 성공. 둘 다 확인된 뒤에만 4-4로 간다. 안 되면 비밀번호를 끄지 않고 4-1~4-3을 다시 본다.

옛 비밀번호 연결은 4-4가 끝나면 앱에서 지워도 된다고 알린다.

### 4-4. 비밀번호 로그인 끄기 (너)

먼저 되돌리는 법을 알린다: "막히면 Hostinger → 서버 → Web Console에서 `rm /etc/ssh/sshd_config.d/01-key-only.conf && systemctl restart ssh`."

```bash
vps-session harden-ssh
```

`harden-ssh`는 규칙 파일을 만들고, `sshd -t`가 통과할 때만 SSH를 다시 켜고, 적용된 값(`passwordauthentication no`, `kbdinteractiveauthentication no`, `permitrootlogin without-password`)을 보여 준다.

사용자 확인(맥 터미널·윈도우 PowerShell 같은 명령): `ssh -o PubkeyAuthentication=no root@서버IP` → `Permission denied (publickey)`가 나오면 성공. 비밀번호를 물으면 아직 안 꺼진 것이다 — 비밀번호를 넣지 말고 Ctrl+C로 멈춘 뒤 알려 달라고 한다.

### 4-5. 기본 방화벽 켜기 (너)

설명(쉽게): 방화벽은 서버의 문지기다. 들어오는 연결 가운데 SSH(앱이 붙는 문) 하나만 들여보내고 나머지는 막는다. Claude가 서버에서 웹 화면이나 테스트 서버를 띄웠을 때 그게 실수로 인터넷 전체에 열리는 걸 막아 준다. 서버에서 밖으로 나가는 연결(Claude 로그인, 휴대폰 연결, 텔레그램)은 그대로다.

되돌리는 법을 먼저 알린다: "막히면 Web Console에서 `ufw disable`."

먼저 묻는다: "이 서버에서 이미 돌리던 서비스(웹사이트 등)가 있어요? 있으면 방화벽을 켠 뒤 그 문(포트)을 열어 둘게요." 있다고 하면 `ss -tlnp`로 열린 포트를 보여 주고, 사용자가 고른 포트를 방화벽을 켠 바로 뒤에 `ufw allow <포트>/tcp`로 연다. 새로 산 서버면 "없어요"가 맞다.

```bash
vps-session firewall-basic
```

나중에 웹 화면을 밖에 공개해야 하면 그때 사용자에게 묻고 포트를 하나씩 연다(`ufw allow <포트>/tcp`).

## 5단계 — (질문) Tailscale로 한 겹 더 숨길까요? (기본: 아니요)

설명(쉽게): 지금 서버의 SSH 문은 인터넷 큰길가에 있다. 열쇠가 없으면 못 들어오지만 문 자체는 누구에게나 보이고 봇들이 계속 두드린다. Tailscale은 내 기기끼리만 다니는 전용 골목을 만들고, 큰길 쪽 문을 닫게 해 준다. SSH 프로그램 자체에 결함이 생겨도 바깥에서는 문이 안 보인다.

질문할 때 장단점을 같이 말한다:

- 좋은 점: 서버 SSH 문이 인터넷에서 사라진다.
- 챙길 것: 노트북에서 Tailscale이 켜져 있어야 앱이 붙는다. Tailscale에 로그인한 계정(구글 등)이 서버 열쇠가 되니 그 계정에 2단계 인증을 켠다. 순서를 틀리면 서버에 못 들어가 Web Console로 되돌려야 한다.
- 열쇠 + 비밀번호 끄기 + 기본 방화벽까지 했으면 기본은 충분하다. 처음 쓰는 분은 '아니요'로 시작해도 된다.

"아니요"면 6단계로. "예"면:

1. (너) `curl -fsSL https://tailscale.com/install.sh | sh` → `tailscale up` 실행, 나온 로그인 주소를 사용자에게 보여 준다.
2. (사용자) 주소를 브라우저에서 열어 승인 → 노트북에도 Tailscale 앱 설치(맥: App Store 또는 tailscale.com/download, 윈도우: tailscale.com/download)·같은 계정 로그인 → Tailscale 관리 화면 Machines에서 서버 ⋯ → **Disable key expiry**.
3. (너) `tailscale ip -4` 결과(100.x)를 알려 준다.
4. (사용자) 앱에 연결을 하나 더 만든다: SSH host `root@100.x.x.x`, 같은 열쇠. 그 연결로 새 대화를 열어 `/opt/claude-vps/SETUP.md 5단계 5번부터 이어서 해 줘. 내 노트북은 맥이야`(또는 `윈도우야`)라고 보낸다.
5. (너, 새 대화에서만) 되돌리는 법(Web Console에서 `ufw disable`)을 먼저 알리고 `vps-session firewall-tailscale` 실행 → 결과 목록을 보여 준다.
6. (사용자) 노트북(맥 터미널·윈도우 PowerShell 같은 명령)에서 `ssh -o ConnectTimeout=10 root@서버공인IP` → 시간 초과(`timed out`)면 성공. 앱의 공인 IP 연결은 지워도 된다.

Tailscale SSH(`tailscale set --ssh`)는 켜지 않는다.

## 6단계 — 텔레그램 연결 (텔레그램으로 서버 Claude에게 일 시키기)

설명: 텔레그램 봇을 서버의 24시간 Claude 세션에 연결한다. 휴대폰 텔레그램으로 말을 걸면 서버의 Claude가 그 폴더에서 일하고 답한다. 노트북이 꺼져 있어도 된다. (Claude Code의 연구 미리보기 기능인 channels를 쓴다.)

### 6-1. 일할 폴더 정하기 (질문)

질문: "텔레그램 Claude가 일할 폴더를 정할게요. GitHub 저장소가 있으면 주소를 알려 주세요. 없으면 새로 만들 폴더 이름을 알려 주세요(예: `my-work`)."

- 저장소 주소를 받으면: 공개 저장소면 바로 6-2로. 비공개 저장소면 사용자에게 안내 → Terminal 창에서 `apt-get install -y gh && gh auth login` → GitHub.com → HTTPS → "Login with a web browser" → 나온 코드를 브라우저에 입력. 끝나면 `gh auth setup-git`을 너가 실행한다.
- 폴더 이름을 받으면: 영문·숫자·`-`로 정리해 확인받는다(`/root/projects/<이름>`에 만든다).

### 6-2. 준비 (너)

텔레그램 플러그인을 받아 두되, **어느 세션에서도 켜지지 않은 상태로** 둔다. 실제로 켜는 건 6-4의 `vps-session new … --telegram`이 텔레그램 세션 폴더 한 곳에서만 한다.

```bash
curl -fsSL https://bun.sh/install | bash && ~/.bun/bin/bun --version
claude plugin marketplace add anthropics/claude-plugins-official || true
claude plugin marketplace update claude-plugins-official
claude plugin install telegram@claude-plugins-official
claude plugin disable telegram@claude-plugins-official --scope user
```

왜 이렇게 하나(사용자에게 한두 문장으로):

- **모든 세션에 켜 두면 안 된다.** 플러그인이 켜진 Claude는 `--channels`가 없어도 봇 연결 프로그램을 띄운다. 텔레그램 봇은 한 번에 한 곳에만 메시지를 준다. 그래서 '메인 작업실' 같은 다른 24시간 세션이나 앱 대화가 봇을 가로채면 텔레그램이 답을 안 한다. 마지막 줄(`disable --scope user`)이 이걸 막는다.
- **카탈로그는 `claude-plugins-official`만.** 연구 미리보기 동안 `--channels`는 Anthropic이 승인한 목록(이 카탈로그의 채널 플러그인)만 받는다. 서버에 기본으로 들어 있는 비슷한 이름의 카탈로그(`anthropic-plugin-directory`)에서도 설치는 되지만, 세션 화면에 `not on the approved channels allowlist`가 뜨고 텔레그램은 안 된다.

확인과 막혔을 때:

- `claude plugin list`에 `telegram@claude-plugins-official`이 있으면 ok.
- `telegram@claude-plugins-official`을 찾을 수 없다고 나오면: 위의 `marketplace add`·`update` 두 줄을 다시 하고 설치를 다시 한다. **다른 카탈로그 이름으로 바꿔 설치하지 않는다.**
- 이미 다른 카탈로그에서 설치돼 있으면: `claude plugin uninstall telegram@anthropic-plugin-directory` 뒤에 위 설치를 한다.
- `claude-session-run`·`vps-session` 같은 가이드 도구를 서버에서 직접 고치지 않는다. 막히면 멈추고 사용자에게 알린다.

### 6-3. 봇 만들고 토큰 넣기 (사용자)

1. 휴대폰 텔레그램 → @BotFather → `/newbot` → 이름 → `bot`으로 끝나는 아이디 → 토큰 복사.
2. 앱 Terminal 창에서 `vps-secret set telegram` → 토큰 붙여 넣기 → 엔터(화면에 안 보임).
3. (너) `vps-secret check telegram` → `"ok":true`와 봇 아이디가 보이면 성공(토큰은 안 찍힘).

### 6-4. 텔레그램 세션 켜기 (너)

순서를 지킨다: **6-2 플러그인 받기 → 6-3 토큰 ok → 그다음에 세션을 켠다.** 토큰보다 세션을 먼저 켰으면 6-3이 끝난 뒤 `vps-session restart telegram`.

1. 세션 만들기 (6-1에서 정한 것 하나만). `--telegram`을 붙이면 `vps-session`이 이 세션 폴더에서만 플러그인을 켠다(`.claude/settings.local.json`, git에 안 올라감).

```bash
vps-session new telegram "텔레그램" --telegram --git <저장소 주소>     # 저장소가 있을 때
vps-session new telegram "텔레그램" --telegram --dir <폴더 이름>       # 없을 때
```

이미 만든 세션을 다시 켤 때는 `new` 대신 `vps-session restart telegram`.

2. 아래 **'첫 실행 화면 넘기기'**대로 화면을 넘긴다.

3. 채널이 붙었는지 보기: 질문이 다 사라진 `peek` 화면에서 채널 안내를 찾는다.
   - `plugin:telegram@claude-plugins-official`에서 온 메시지가 이 세션에 들어온다는 안내만 있으면 정상 → 6-5로.
   - 그 아래에 경고 줄(설치 안 됨, `not on the approved channels allowlist` 등)이 있으면 멈추고 그 문구를 사용자에게 그대로 보여 준다. 플러그인 이름이나 가이드 도구를 바꿔서 우회하지 않는다.

#### 첫 실행 화면 넘기기 (6-4, 7-1, 7-2 모든 세션에 공통)

`vps-session new`는 10초 뒤 세션 화면을 보여 준다. 그 뒤로도 `vps-session peek <아이디>`로 화면을 보며 한 화면씩 넘긴다. 화면마다 무엇인지 사용자에게 한 줄로 말한다.

| 화면 | 언제 | 어떻게 |
|---|---|---|
| 테마(색) 고르기 | 서버에서 처음 만드는 세션 한 번 | `vps-session keys <아이디> Enter` (기본값 그대로) |
| 보안 안내 `Press Enter to continue` | 서버에서 처음 만드는 세션 한 번 | `vps-session keys <아이디> Enter` |
| **폴더 믿기** (`Do you trust the files in this folder?`) | 새 폴더마다 한 번 | **기본 선택이 `No, exit`라서 Enter만 보내면 세션이 꺼졌다 켜지기를 되풀이한다.** 사용자 승인 → `vps-session keys <아이디> Down`(안 움직이면 `Up`) → `peek`로 `❯`가 `Yes, I trust this folder` 앞에 올 때까지 되풀이 → `vps-session keys <아이디> Enter` |
| Remote Control 켜기 확인 | 나올 수도 있다(시험에서는 안 나옴) | 무엇을 묻는지 사용자에게 말하고, 켜는 쪽(Yes)에 `❯`가 있는지 확인한 뒤 Enter |
| 처음 보는 다른 질문 | — | 멈추고 화면 문구를 사용자에게 그대로 보여 준 뒤 답을 받는다 |

규칙: **Enter를 보내기 전에는 언제나 `peek`로 `❯`가 원하는 선택지 앞에 있는지 본다.** 입력창(`>`)만 보이면 끝이다. `vps-session list`에서 상태가 `active`로 유지되는지도 본다.

### 6-5. 내 텔레그램만 쓰게 잠그기 (사용자 + 너)

1. (사용자) 휴대폰 텔레그램에서 봇에게 아무 말이나 보낸다.
2. (사용자) 봇이 페어링 코드를 답한다 → 그 코드를 이 대화에 알려 준다(토큰이 아니라 괜찮다).
   - 봇이 아무 답도 안 하면: (너) `vps-session peek telegram`과 `vps-session logs telegram`을 보고 사용자에게 알린다. 흔한 원인은 6-4 3번의 경고, 토큰 오류(`vps-secret check telegram`), 같은 봇을 다른 곳에서도 켠 것. `vps-session doctor`에 "모든 세션에 켜짐"이 보이면 그게 원인이다.
3. (너) 순서대로 보낸다:

```bash
vps-session keys telegram "/telegram:access pair <코드>" Enter
vps-session keys telegram "/telegram:access policy allowlist" Enter
vps-session peek telegram
```

**allowlist는 꼭 켠다.** 봇에 말할 수 있는 사람은 서버의 root Claude에게 일을 시킬 수 있다.

### 6-6. 확인 (사용자)

1. 텔레그램에서 "지금 작업 폴더 이름 알려 줘" → 6-1에서 정한 폴더 이름이 오면 성공.
2. 휴대폰 Claude 앱 → Code 목록(또는 claude.ai/code)에 '텔레그램' 세션이 보이는지 사용자에게 물어서 기록한다(보이지 않아도 텔레그램은 정상).
3. 같은 봇은 한 곳에서만 받을 수 있다고 알려 준다. 노트북 등 다른 곳에서 같은 봇으로 Claude를 켜면 서로 끊긴다. **서버 안에서도, 다른 세션이나 앱 대화에 텔레그램 플러그인이 켜져 있으면 같은 일이 생긴다**(그래서 6-2에서 모든 세션 쪽은 끄고, 텔레그램 세션 폴더에서만 켰다). 텔레그램이 갑자기 답을 안 하면 `vps-session doctor`부터 본다. 텔레그램 세션 폴더로 앱 대화나 다른 세션을 열지 않는다(`vps-session`은 막아 주지만 앱 대화는 못 막는다). 다른 컴퓨터에서도 텔레그램을 쓰고 싶으면 봇을 하나 더 만든다.

### 6-7. (질문) 로그인이 끝나기 전에 텔레그램으로 알려 줄까요? (기본: 예)

설명(쉽게): 서버의 Claude 로그인에는 끝나는 날이 있다(보통 한 달쯤, 써도 늘어나지 않는다). 끝나면 24시간 세션과 텔레그램 답장이 멈춘다. 24시간 세션은 아무도 화면을 안 보고 돌아서 경고를 놓치기 쉽다. 그래서 서버가 매일 아침 9시에 끝나는 날을 확인하고, 3일 안으로 다가오면 텔레그램으로 알려 준다. 알림은 Claude가 아니라 봇이 직접 보내서, 로그인이 이미 끝났어도 온다.

질문: "서버 로그인이 끝나기 3일 전부터 텔레그램으로 알려 드릴까요?"

"예"면 (너):

```bash
systemctl enable --now claude-login-check.timer
vps-session login-check --test
```

- 사용자 확인: 텔레그램에 "✅ 로그인 알림 시험이에요…"와 끝나는 날짜가 오면 성공.
- 안 오면: `vps-notify` 출력(보낸 사람 수)과 `vps-secret check telegram`을 본다. 페어링(6-5)이 안 됐으면 받을 사람이 없다.
- 알림을 받으면 할 일: 노트북 Claude 앱 → 서버 대화 → Terminal 창 → `claude auth login`. 그 뒤 답이 없는 세션은 `vps-session restart <아이디>`.
- 끄려면: `systemctl disable --now claude-login-check.timer`.

### 6-8. (질문) 긴 대화를 더 일찍 정리할까요? (기본: 예, 50만 토큰)

설명(쉽게): 텔레그램 세션과 24시간 세션은 대화 하나가 몇 주씩 이어진다. Claude는 메시지를 받을 때마다 앞의 대화를 다시 읽기 때문에, 대화가 길수록 답이 느려지고 사용량이 더 들 수 있고, 앞부분을 덜 정확하게 다루게 된다. Claude Code는 대화가 길어지면 앞부분을 요약해 줄인다(자동 정리, compaction).

- 지금 모델은 기본으로 거의 다 찰 때(약 97만 토큰) 정리한다.
- 쉬는 동안 정리하는 기능도 있다: 조건이 맞으면(대화가 20만 토큰을 넘고 1시간쯤 메시지가 없을 때 등) 다음 메시지 전에 요약한다(idle compaction, 기본으로 켜짐). 이 서버 세션에도 켜지는지는 확인되지 않았다. 켜진다면 이 설정이 실제로 영향을 주는 건 주로 **쉬지 않고 길게 일하는 동안**이다.
- 50만은 공식 문서가 '더 일찍 정리하기' 예시로 드는 값이다(`/autocompact 500k`). 기본의 절반쯤이라 긴 작업 중간에 너무 자주 끊기지 않으면서 대화가 무거워지는 걸 막는다. 공식 '추천값'은 없다.

- 좋은 점: 답이 가볍고 빠르게 유지되고, 오래된 내용에 덜 휘둘린다.
- 챙길 것: 정리할 때 오래된 대화의 세부 내용은 요약으로 줄어든다. 오래 기억해야 할 결정·설정은 대화가 아니라 파일(예: 작업 폴더의 `CLAUDE.md`, 메모 파일)에 남기라고 알려 준다.

질문: "텔레그램과 24시간 세션의 대화를 50만 토큰에서 정리하게 할까요? (더 가볍게 쓰려면 30~40만, 긴 작업을 자주 시키면 그대로 두기. 최소 10만)"

"예"면 (너): 모든 24시간 세션의 기본값으로 저장하고, 지금 떠 있는 텔레그램 세션에 적용한다.

```bash
vps-session autocompact 500000
vps-session restart telegram
```

- 앞으로 만드는 세션(`/24h`)도 이 값으로 시작한다. 세션 하나만 다르게: `vps-session autocompact <값> <아이디>`. 원래대로: `vps-session autocompact auto`.
- 확인: `vps-session doctor`의 '대화 정리 시점'이 500000. 텔레그램에서 "잘 들리니"에 답이 오면 다시 켜기도 끝.
- 텔레그램 세션 안에서 `vps-session restart telegram`을 하지 않는다(자기 자신을 끄게 되어 답장이 끊긴다). 이 단계는 앱 대화에서 한다.

`[완료] 6단계`를 알리기 전에 짧게 정리한다: 일할 폴더, 플러그인 `telegram@claude-plugins-official`(이 폴더에서만 켜짐), 봇 아이디, allowlist 켜짐, 로그인 알림 켜짐 여부, 대화 정리 시점.

## 7단계 — 24시간 세션 만들기 (앱에서, 텔레그램에서)

설명: 앱에서 바로 연 대화는 노트북 로그인에 묶여 있어서 노트북이 꺼지면 언제 멈출지 모른다. 24시간 세션은 서버 로그인으로 서버 서비스 안에서 돌고, 휴대폰 Claude 앱 Code 목록과 claude.ai/code에 이름으로 뜬다. 권한 방식은 기본이 **auto**다(다른 AI가 위험한 작업만 걸러 묻고, 나머지는 알아서 진행).

### 7-1. 앱 대화에서

사용자에게 이렇게 쳐 보라고 한다: `/24h main 메인 작업실` (아이디는 영문, 표시 이름은 한글 가능). 폴더를 따로 정하고 싶으면 뒤에 폴더 이름이나 GitHub 주소를 붙인다: `/24h blog 블로그 작업 https://github.com/<계정>/<저장소>`.

`/24h` 스킬이 `vps-session new`를 실행하고 6-4의 **'첫 실행 화면 넘기기'**대로 화면을 넘긴다(폴더 믿기는 Down 뒤 Enter).

사용자 확인: 휴대폰 Claude 앱 → Code 목록, 또는 노트북 브라우저의 claude.ai/code에 '메인 작업실'이 보이는지, 거기서 "안녕"을 보내면 답하는지. **데스크톱 앱 사이드바에는 24시간 세션이 보이지 않는 게 정상이다**. 노트북에서는 브라우저로 claude.ai/code를 연다고 알려 준다.

### 7-2. 텔레그램에서

사용자에게 텔레그램 봇에 이렇게 보내 보라고 한다: "24시간 세션 하나 만들어 줘. 아이디 research, 이름 리서치, 폴더는 새로." 텔레그램 세션의 Claude가 같은 `/24h` 스킬로 세션을 만들고, '첫 실행 화면 넘기기'에서 사용자 승인이 필요한 화면(폴더 믿기 등)은 텔레그램으로 물어본 뒤 넘기고, 결과를 텔레그램으로 알린다. 휴대폰 Claude 앱 목록에 '리서치'가 뜨면 성공.

## 8단계 — 재부팅 시험

사용자 동의를 받고 `systemctl reboot`. 1~2분 뒤 사용자에게 앱 연결로 새 대화를 열어 `vps-session list`를 해 달라고 하고(또는 텔레그램으로 "세션 목록 보여 줘"), 세션들이 다시 떴는지, 휴대폰 목록에 다시 보이는지 확인한다.

## 9단계 — 마무리

요약 표로 보여 준다: 연결 방식(열쇠/Tailscale), 비밀번호 로그인 꺼짐, 방화벽, 만든 세션(아이디·표시 이름·폴더·권한 방식), 텔레그램 봇 아이디, 되돌리는 법(Web Console 명령 두 줄), **서버 Claude 로그인이 끝나는 날**(`vps-session doctor`의 `Sign-in ends` 줄, 6-7 알림 켜짐 여부. 그 전에 Terminal 창에서 `claude auth login`, 다시 로그인한 뒤 답이 없는 세션은 `vps-session restart <아이디>`). README의 '매일 쓰는 명령' 표를 덧붙인다.

## 10단계 — (질문) 서버 관리 노트 만들기 (기본: 예)

설명: 오늘 한 설정과 막혔을 때 되돌리는 법을 서버 안에 문서 하나로 남겨 둔다. 몇 달 뒤 무언가 고장 나거나 설정을 바꿀 때, 사용자나 다음 Claude 대화가 이 문서부터 읽으면 된다.

질문: "오늘 한 설정과 복구 방법을 `/root/projects/SERVER-NOTES.md` 문서로 정리해 둘까요? 나중에 고장 나거나 설정을 바꿀 때 이 문서부터 보면 돼요."

"아니요"면 끝. "예"면 아래 내용을 **실제 서버에서 확인한 값으로** 채워 만든다(추측으로 채우지 않는다. `vps-session list`, `vps-session doctor`, `sshd -T`, `ufw status`, `tailscale status` 같은 명령 결과를 보고 쓴다). 쉬운 한국어로 쓴다.

1. **한눈에** — 만든 날, 서버(Hostinger VPS, Ubuntu 버전, 서버 이름), 이 문서가 무엇인지 두 줄.
2. **연결 방식** — 앱 연결에 쓰는 주소(공인 IP 또는 Tailscale 100.x)와 열쇠 파일 이름(노트북 쪽 경로), 비밀번호 로그인 꺼짐 여부, 방화벽 상태와 열린 포트, Tailscale 사용 여부.
3. **24시간 세션 표** — 아이디 · 표시 이름 · 폴더 · 권한 방식 · 텔레그램 여부 · 대화 정리 시점(6-8). 세션이 어디에 보이는지(휴대폰 Code 목록, claude.ai/code. 데스크톱 앱 사이드바엔 안 보임).
4. **텔레그램** — 봇 아이디(@…), 연결된 세션과 폴더, 플러그인은 그 폴더에서만 켜져 있다는 것과 그 이유, allowlist 켜짐, 토큰 파일 위치(`~/.claude/channels/telegram/.env` — 경로만, 내용은 적지 않음), 토큰을 바꾸는 법(BotFather `/revoke` → Terminal 창 `vps-secret set telegram` → `vps-session restart telegram`).
5. **정기적으로 할 일** — 서버 Claude 로그인이 끝나는 날(`vps-session doctor`의 `Sign-in ends`), 텔레그램 알림이 켜져 있는지(6-7, 매일 9시 확인·3일 전부터), 다시 로그인하는 법, 다시 로그인한 뒤 답이 없으면 `vps-session restart <아이디>`. Hostinger 스냅샷·자동 백업, 계정 2단계 인증 권장.
6. **매일 쓰는 명령** — README의 표.
7. **막혔을 때 (증상 → 할 일)** — 최소한 아래를 넣는다:
   - 앱이 서버에 못 붙음 → Hostinger Web Console에서 `rm /etc/ssh/sshd_config.d/01-key-only.conf && systemctl restart ssh`(비밀번호 로그인 되살림) 또는 `ufw disable`(방화벽 끄기). 고친 뒤 다시 잠그는 법.
   - 텔레그램이 답을 안 함 → `vps-session doctor`(모든 세션에 켜짐 경고, 다른 카탈로그 경고), `vps-session logs telegram`, 같은 봇을 다른 곳에서 켰는지.
   - 세션이 꺼졌다 켜지기를 되풀이 → `vps-session peek <아이디>`로 첫 실행 화면(폴더 믿기 기본값 `No, exit` — Down으로 Yes 옮긴 뒤 Enter).
   - 세션이 휴대폰 목록에서 사라짐 → 로그인 만료 확인, `vps-session restart <아이디>`.
   - (Tailscale을 썼으면) Tailscale이 꺼져 못 붙음 → Web Console에서 `ufw allow OpenSSH`로 공인 IP 쪽을 잠깐 열기.
8. **설치된 것과 위치** — `/opt/claude-vps`(가이드 원본), `/usr/local/bin/vps-session`·`vps-secret`·`vps-notify`·`claude-session-run`, `/etc/systemd/system/claude-session@.service`·`claude-login-check.timer`, `/etc/claude-vps/sessions/`(세션 설정), `/etc/claude-vps/defaults.conf`(모든 세션 기본값), `/var/log/claude-vps/`(기록), `/root/.claude/skills/24h/`, `/etc/ssh/sshd_config.d/01-key-only.conf`.
9. **바꾼 기록** — 날짜와 한 줄. 첫 줄은 오늘 셋업.

**절대 적지 않는 것:** root 비밀번호, 봇 토큰, 로그인 코드, 개인 키 내용, 페어링 코드. 파일을 만든 뒤 `chmod 600 /root/projects/SERVER-NOTES.md`.

만들고 나면 사용자에게 알린다: 문서 위치, 앱 대화에서 "SERVER-NOTES.md 보여 줘" 또는 텔레그램에서 "서버 노트 보여 줘"로 볼 수 있다는 것. 그리고 앞으로 `/24h`로 세션을 만들거나 지우면 이 문서의 세션 표와 '바꾼 기록'을 Claude가 같이 고친다는 것.

`[완료] 10단계`로 셋업을 끝낸다.
