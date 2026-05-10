# Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"
plugins=(git)
source $ZSH/oh-my-zsh.sh

# Starship
eval "$(starship init zsh)"

# fnm
eval "$(fnm env --use-on-cd --resolve-engines)"

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# PATH
export PATH="$HOME/.local/bin:$PATH"

# Claude Code (회사 계정)
alias cclaude='CLAUDE_CONFIG_DIR=~/.claude-work claude'

# Local-only secrets / overrides (gitignored)
[ -f ~/.zshrc.local ] && source ~/.zshrc.local
