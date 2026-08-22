#!/usr/bin/env bash
#
# Codespaces / Linux 진입점.
#
# Codespaces 는 dotfiles 저장소를 클론한 뒤 루트의 install.sh 를 찾아 실행한다
# (scripts/install.sh 는 그 목록에 없어서 그냥 무시된다).
#
# macOS 는 지금까지처럼 scripts/install.sh 가 전부 처리한다.
# 리눅스 컨테이너에서는 macOS 전용 항목(Homebrew, ~/Library, 폰트, VSCode)을
# 빼고, 컨테이너에서 의미가 있는 것만 건다.
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "$(uname -s)" = "Darwin" ]; then
  exec "$DOTFILES_DIR/scripts/install.sh"
fi

link() {
  local src="$1" dst="$2"
  [ -e "$src" ] || return 0
  mkdir -p "$(dirname "$dst")"
  ln -sfn "$src" "$dst"
}

echo "=== dotfiles 설치 (linux) ==="

# claude — 컨테이너에서 제일 중요한 부분
mkdir -p "$HOME/.claude/skills"
link "$DOTFILES_DIR/claude/CLAUDE.md"            "$HOME/.claude/CLAUDE.md"
link "$DOTFILES_DIR/claude/settings.json"        "$HOME/.claude/settings.json"
link "$DOTFILES_DIR/claude/statusline-command.sh" "$HOME/.claude/statusline-command.sh"
for skill in "$DOTFILES_DIR/claude/skills"/*/; do
  [ -d "$skill" ] || continue
  link "${skill%/}" "$HOME/.claude/skills/$(basename "$skill")"
done
echo "✓ claude"

# codex
link "$DOTFILES_DIR/claude/CLAUDE.md" "$HOME/.codex/AGENTS.md"
link "$HOME/.claude/skills"           "$HOME/.agents/skills"
echo "✓ codex"

# git — ~/.gitconfig 는 건드리지 않는다.
# git/.gitconfig 는 credential helper 를 /opt/homebrew/bin/gh 로 고정하고
# 기본 helper 를 비워버리기 때문에, 컨테이너에 그대로 걸면 push 인증이 깨진다.
# 플랫폼 중립적인 것만 가져온다.
link "$DOTFILES_DIR/git/.gitignore_global" "$HOME/.gitignore_global"
git config --global core.excludesfile "$HOME/.gitignore_global"
echo "✓ git (gitignore_global 만)"

# gh
link "$DOTFILES_DIR/gh/config.yml" "$HOME/.config/gh/config.yml"
echo "✓ gh"

# starship — starship 이 깔려 있을 때만 읽히므로 걸어두는 건 무해
link "$DOTFILES_DIR/starship/starship.toml" "$HOME/.config/starship.toml"
echo "✓ starship"

# husky
link "$DOTFILES_DIR/husky/.huskyrc" "$HOME/.huskyrc"
echo "✓ husky"

# zsh 는 링크하지 않는다.
# .zshrc 가 starship/fnm/oh-my-zsh 를, .zprofile 이 /opt/homebrew/bin/brew 를
# 무조건 eval 해서, 없는 컨테이너에서는 셸 열 때마다 에러가 쏟아진다.
# 걸려면 각 줄을 command -v 로 감싸는 게 먼저다.
echo "- zsh 건너뜀 (macOS 전용 의존성)"

echo "=== 완료 ==="
