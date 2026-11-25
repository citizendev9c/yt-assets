---
name: 24h
description: 이 VPS에 24시간 도는 Claude Code 세션을 새로 만들어 Claude 앱 목록(휴대폰 Code·claude.ai/code)에 이름으로 띄운다. 앱 대화나 텔레그램에서 "/24h 아이디 표시이름 [폴더|깃주소]", "24시간 세션 만들어 줘", "세션 목록", "○○ 세션 꺼 줘", "서버 노트 보여 줘"라고 할 때 쓴다.
argument-hint: <영문-아이디> <표시 이름> [폴더 이름 | GitHub 주소]
---

# /24h — 24시간 세션 만들기

이 VPS에는 `vps-session` 명령이 설치돼 있다(`vps-session --help`). 24시간 세션은 서버 서비스(systemd) 안의 tmux에서 서버 자기 로그인으로 돌고, Remote Control로 앱 목록에 뜬다. 노트북이 꺼져도 돈다. 권한 방식 기본값은 auto다.

## 만들 때 순서

1. 인자를 읽는다: 첫 낱말 = 아이디(영문 소문자·숫자·`-`), 마지막이 `http`로 시작하거나 `.git`으로 끝나면 = GitHub 주소, 그 사이 = 표시 이름(한글 가능). 주소 대신 폴더 이름을 줄 수도 있는데, 표시 이름과 헷갈리면 사용자에게 확인한다.
2. 빠진 게 있으면 묻는다. 폴더는 "새로 만들까요(`/root/projects/<아이디>`), 기존 폴더나 GitHub 저장소를 쓸까요?"로 묻는다. 대답이 없으면 새로 만든다.
3. 실행 전에 명령을 보여 준다:
   - 새 폴더: `vps-session new <아이디> "<표시 이름>"`
   - 폴더 이름: `vps-session new <아이디> "<표시 이름>" --dir <폴더 이름>`
   - GitHub: `vps-session new <아이디> "<표시 이름>" --git <주소>` (비공개 저장소에서 실패하면 사용자에게 Terminal 창의 `gh auth login`을 안내)
   - 사용자가 매번 묻는 방식을 원하면 `--mode default`.
4. 실행 후 `vps-session peek <아이디>`로 화면을 보며 첫 실행 화면을 하나씩 넘긴다. 화면마다 무엇인지 사용자에게 말한다.
   - 테마 고르기, 보안 안내(`Press Enter to continue`): 서버 첫 세션에서만 나온다. `vps-session keys <아이디> Enter`.
   - **폴더 믿기**(`Do you trust the files in this folder?`): 기본 선택이 `No, exit`라서 Enter만 보내면 세션이 꺼졌다 켜지기를 되풀이한다. 사용자 승인을 받고 `vps-session keys <아이디> Down`(안 움직이면 `Up`) → `peek`로 `❯ Yes, I trust this folder`가 될 때까지 → `vps-session keys <아이디> Enter`.
   - Remote Control 켜기 확인: 나올 수도 있다. 켜는 쪽에 `❯`가 있는지 보고 Enter.
   - 처음 보는 질문: 멈추고 화면 문구를 사용자에게 그대로 보여 준다.
   - **Enter를 보내기 전에는 언제나 `peek`로 `❯` 위치를 본다.** 입력창만 보이면 끝. `vps-session list`에서 `active`가 유지되는지 본다.
5. 사용자에게 휴대폰 Claude 앱 → Code 목록, 또는 노트북 브라우저의 claude.ai/code에서 그 이름을 찾아 "안녕"을 보내 보라고 안내한다. 데스크톱 앱 사이드바에는 안 보이는 게 정상이다.

6. `/root/projects/SERVER-NOTES.md`가 있으면 '24시간 세션 표'에 새 세션을 한 줄 더하고, '바꾼 기록'에 날짜와 한 줄을 남긴다(비밀 값은 적지 않는다).

## 그 밖의 요청

- 목록: `vps-session list`
- 화면 보기: `vps-session peek <아이디>`
- 끄기·켜기·다시 켜기: `vps-session stop|start|restart <아이디>`
- 지우기: 사용자 확인 후 `vps-session remove <아이디>` (작업 폴더는 남는다). `SERVER-NOTES.md`가 있으면 세션 표와 바꾼 기록도 고친다.
- 기록: `vps-session logs <아이디>`
- "서버 노트 보여 줘": `/root/projects/SERVER-NOTES.md`를 요약해 보여 준다(없으면 SETUP 10단계대로 만들지 묻는다).

## 하지 않는 것

- 텔레그램 세션 폴더를 다른 세션의 폴더로 쓰지 않는다(봇을 가로챈다. `vps-session`이 막는다).
- 홈 폴더(`/root`)를 세션 폴더로 쓰지 않는다(폴더 믿기가 저장되지 않아 매번 멈춘다).
- 세션 안에서 `/exit`를 보내지 않는다(곧바로 다시 켜진다). 끄려면 `vps-session stop`.
- `~/.claude/channels/*/.env` 같은 비밀 파일 내용을 출력하지 않는다.
- 텔레그램 세션은 하나만(같은 봇을 두 세션이 쓰면 번갈아 끊긴다). 일반 24시간 세션에는 `--telegram`을 붙이지 않고, 텔레그램 플러그인을 `--scope user`로 켜지 않는다(모든 세션이 봇을 가로챈다). 지금 텔레그램 세션 안에서 일하고 있다면 그 세션(`telegram`)을 끄거나 지우거나 다시 켜지 않는다(답장이 끊긴다. 앱 대화에서 하라고 안내).
