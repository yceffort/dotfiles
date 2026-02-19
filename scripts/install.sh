#!/bin/bash

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

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
mkdir -p ~/.claude/commands
ln -sf "$DOTFILES_DIR/claude/CLAUDE.md" ~/.claude/CLAUDE.md
ln -sf "$DOTFILES_DIR/claude/settings.json" ~/.claude/settings.json
for cmd in "$DOTFILES_DIR/claude/commands"/*.md; do
  ln -sf "$cmd" ~/.claude/commands/
done
echo "✓ claude 설정 완료"

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

echo ""
echo "=== dotfiles 설치 완료 ==="
echo ""
echo "추가 작업:"
echo "  1. Homebrew 패키지 설치: brew bundle --file=$DOTFILES_DIR/Brewfile"
echo "  2. 폰트 설치: brew install --cask font-jetbrains-mono-nerd-font"
echo "  3. 나눔폰트 설치: https://github.com/naver/nanumfont"
