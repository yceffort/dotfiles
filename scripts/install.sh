#!/bin/bash

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

replace_with_symlink() {
  local source="$1"
  local target="$2"

  if [ -L "$target" ]; then
    ln -sfn "$source" "$target"
    return
  fi

  if [ -e "$target" ]; then
    mv "$target" "$target.bak.$(date +%Y%m%d%H%M%S)"
  fi

  ln -s "$source" "$target"
}

ensure_uppercase_skill_entrypoints() {
  local skill

  for skill in "$HOME/.claude/skills"/*/; do
    [ -d "$skill" ] || continue

    if [ -e "$skill/skill.md" ] && [ -z "$(find "$skill" -maxdepth 1 -name 'SKILL.md' -print -quit)" ]; then
      mv "$skill/skill.md" "$skill/.skill.md.tmp"
      mv "$skill/.skill.md.tmp" "$skill/SKILL.md"
    fi
  done
}

echo "=== dotfiles 설치 시작 ==="

# zsh
ln -sf "$DOTFILES_DIR/zsh/.zshrc" ~/.zshrc
ln -sf "$DOTFILES_DIR/zsh/.zprofile" ~/.zprofile
echo "✓ zsh 설정 완료"

# git
ln -sf "$DOTFILES_DIR/git/.gitconfig" ~/.gitconfig
ln -sf "$DOTFILES_DIR/git/.gitignore_global" ~/.gitignore_global
echo "✓ git 설정 완료"

# ssh
mkdir -p ~/.ssh
ln -sf "$DOTFILES_DIR/ssh/config" ~/.ssh/config
echo "✓ ssh 설정 완료"

# gh
mkdir -p ~/.config/gh
ln -sf "$DOTFILES_DIR/gh/config.yml" ~/.config/gh/config.yml
echo "✓ gh 설정 완료"

# claude
ln -sf "$DOTFILES_DIR/claude/CLAUDE.md" ~/.claude/CLAUDE.md
ln -sf "$DOTFILES_DIR/claude/settings.json" ~/.claude/settings.json
ln -sf "$DOTFILES_DIR/claude/statusline-command.sh" ~/.claude/statusline-command.sh
mkdir -p ~/.claude/skills
for skill in "$DOTFILES_DIR/claude/skills"/*/; do
  ln -sfn "$skill" ~/.claude/skills/"$(basename "$skill")"
done
ensure_uppercase_skill_entrypoints
echo "✓ claude 설정 완료"

# codex
mkdir -p ~/.codex ~/.agents
ln -sf "$DOTFILES_DIR/claude/CLAUDE.md" ~/.codex/AGENTS.md
replace_with_symlink "$HOME/.claude/skills" ~/.agents/skills
echo "✓ codex 설정 완료"

# starship
mkdir -p ~/.config
ln -sf "$DOTFILES_DIR/starship/starship.toml" ~/.config/starship.toml
echo "✓ starship 설정 완료"

# husky
ln -sf "$DOTFILES_DIR/husky/.huskyrc" ~/.huskyrc
echo "✓ husky 설정 완료"

# vscode
VSCODE_USER_DIR="$HOME/Library/Application Support/Code/User"
mkdir -p "$VSCODE_USER_DIR"
ln -sf "$DOTFILES_DIR/vscode/settings.json" "$VSCODE_USER_DIR/settings.json"
ln -sf "$DOTFILES_DIR/vscode/keybindings.json" "$VSCODE_USER_DIR/keybindings.json"
echo "✓ vscode 설정 완료"

# vscode extensions
if command -v code &> /dev/null; then
  echo "VSCode 확장 설치 중..."
  while read extension; do
    code --install-extension "$extension" --force
  done < "$DOTFILES_DIR/vscode/extensions.txt"
  echo "✓ vscode 확장 설치 완료"
fi

# fonts (Homebrew cask에 없는 나눔 폰트)
FONT_DIR="$HOME/Library/Fonts"
NANUM_BASE_URL="https://hangeul.naver.com/hangeul_static/webfont/zips"
FONT_TMPDIR=$(mktemp -d)

install_nanum_font() {
  local zip_name="$1"
  local label="$2"

  if ls "$FONT_DIR"/${zip_name%.*}* &>/dev/null; then
    echo "✓ $label 이미 설치됨 (건너뜀)"
    return
  fi

  echo "$label 다운로드 중..."
  curl -sL "$NANUM_BASE_URL/$zip_name" -o "$FONT_TMPDIR/$zip_name"
  unzip -qo "$FONT_TMPDIR/$zip_name" -d "$FONT_TMPDIR/${zip_name%.*}"
  find "$FONT_TMPDIR/${zip_name%.*}" -name '*.otf' -exec cp {} "$FONT_DIR/" \;
  echo "✓ $label 설치 완료"
}

install_nanum_font "nanum-barun-gothic.zip" "나눔바른고딕"
install_nanum_font "NanumHuman.zip" "나눔스퀘어휴먼"

rm -rf "$FONT_TMPDIR"

echo ""
echo "=== dotfiles 설치 완료 ==="
echo ""
echo "추가 작업:"
echo "  1. Homebrew 패키지 설치: brew bundle --file=$DOTFILES_DIR/Brewfile"
