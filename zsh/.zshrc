# Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"
plugins=(git)
source $ZSH/oh-my-zsh.sh

# Starship
eval "$(starship init zsh)"

# NVM (느림 - fnm 전환 권장)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# PATH
export PATH="$HOME/.rd/bin:$PATH"
export PATH="$HOME/n2c:$PATH"
export PATH="$PATH:$(go env GOPATH)/bin"
export PATH="$HOME/.codeium/windsurf/bin:$PATH"
export PATH="$HOME/.antigravity/antigravity/bin:$PATH"

# Deno
. "$HOME/.deno/env"

export PATH="$HOME/.local/bin:$PATH"

# kubectl - bypass kuberlr and use specific version
alias kubectl="$HOME/.kuberlr/darwin-arm64/kubectl1.30.3"

### MANAGED BY RANCHER DESKTOP START (DO NOT EDIT)
export PATH="$HOME/.rd/bin:$PATH"
### MANAGED BY RANCHER DESKTOP END (DO NOT EDIT)
