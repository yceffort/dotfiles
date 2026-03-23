# dotfiles

macOS 개발 환경 설정 파일 모음

## 구조

```
dotfiles/
├── zsh/
│   ├── .zshrc          # zsh 설정 (oh-my-zsh + starship)
│   └── .zprofile       # zsh 프로필
├── git/
│   ├── .gitconfig      # git 설정
│   └── .gitignore_global
├── ssh/
│   └── config          # SSH 설정
├── claude/
│   ├── CLAUDE.md       # Claude Code 전역 지침
│   ├── settings.json   # Claude Code 설정
│   ├── statusline-command.sh  # 상태줄 스크립트
│   ├── commands/       # 커스텀 슬래시 명령어
│   │   └── commit.md   # /commit 명령어
│   └── skills/         # Claude Code 스킬
│       ├── find-skills/
│       ├── finfe-bot/
│       ├── review-chapter/
│       └── vercel-react-best-practices/
├── gh/
│   └── config.yml      # GitHub CLI 설정
├── starship/
│   └── starship.toml   # Starship 프롬프트 설정
├── husky/
│   └── .huskyrc        # Husky NVM 로더
├── vscode/
│   ├── settings.json   # VSCode 설정
│   ├── keybindings.json
│   └── extensions.txt  # 확장 목록
├── Brewfile            # Homebrew 패키지 목록
├── scripts/
│   └── install.sh      # 설치 스크립트
└── README.md
```

## 설치

### 1. 저장소 클론

```bash
git clone https://github.com/yceffort/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

### 2. 설치 스크립트 실행

```bash
chmod +x scripts/install.sh
./scripts/install.sh
```

### 3. Homebrew 패키지 설치

```bash
# Homebrew 설치 (없는 경우)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 패키지 설치
brew bundle --file=Brewfile
```

### 4. 폰트 설치

```bash
# JetBrains Mono Nerd Font (Brewfile에 포함됨)
brew install --cask font-jetbrains-mono-nerd-font

# 나눔고딕코딩
# https://github.com/naver/nanumfont
```

### 5. oh-my-zsh 설치

```bash
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

## 수동 설정

설치 스크립트가 심볼릭 링크를 생성하므로, dotfiles 저장소를 수정하면 자동으로 반영됩니다.

### 개별 항목 링크

```bash
# zsh만 링크
ln -sf ~/dotfiles/zsh/.zshrc ~/.zshrc

# vscode만 링크
ln -sf ~/dotfiles/vscode/settings.json ~/Library/Application\ Support/Code/User/settings.json
```

## 설정 업데이트

```bash
cd ~/dotfiles
git pull
```

심볼릭 링크이므로 별도 재설치 불필요.

## 새 기기에서 설정 동기화

1. 저장소 클론
2. `./scripts/install.sh` 실행
3. `brew bundle` 실행
4. 폰트 설치

## 주요 도구

- **Shell**: zsh + oh-my-zsh + Starship (Gruvbox Dark 테마)
- **Editor**: VSCode (Tokyo Night Storm 테마)
- **Font**: JetBrains Mono Nerd Font, 나눔고딕코딩, 나눔스퀘어네오
- **Terminal**: Warp
- **AI**: Claude Code, GitHub Copilot

## 참고

- VSCode 확장은 `extensions.txt`에 목록만 저장
- 민감한 정보(토큰, API 키)는 포함하지 않음
- 회사 관련 설정은 제외됨
