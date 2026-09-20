# Configuração interativa do Bash para Debian.
# Este arquivo é carregado por ~/.bashrc; não o execute diretamente.

case $- in
  *i*) ;;
  *) return ;;
esac

case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) export PATH="$HOME/.local/bin:$PATH" ;;
esac

export FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS:---height=45% --layout=reverse --border=rounded --info=inline --cycle}"
export _ZO_FZF_OPTS="${_ZO_FZF_OPTS:---height=45% --layout=reverse --border=rounded --cycle}"

if command -v fdfind >/dev/null 2>&1; then
  export FZF_DEFAULT_COMMAND="fdfind --type f --hidden --follow --exclude .git"
elif command -v fd >/dev/null 2>&1; then
  export FZF_DEFAULT_COMMAND="fd --type f --hidden --follow --exclude .git"
fi

# Atalhos de ferramentas.
command -v nvim >/dev/null 2>&1 && alias vim='nvim'
command -v git >/dev/null 2>&1 && alias g='git'
command -v rg >/dev/null 2>&1 && alias grep='rg'
if command -v batcat >/dev/null 2>&1; then
  alias b='batcat'
elif command -v bat >/dev/null 2>&1; then
  alias b='bat'
fi

alias c='cd'
alias ..='cd ..'
alias ...='cd ../..'

unalias ls ll lt mkcd reload ep dc dco di dn dv ds 2>/dev/null || true
if command -v eza >/dev/null 2>&1; then
  function ls { command eza --icons=always --group-directories-first "$@"; }
  function ll { command eza --long --all --header --git --icons=always --group-directories-first "$@"; }
  function lt { command eza --tree --level=3 --git-ignore --icons=always --group-directories-first "$@"; }
else
  alias ll='ls -alF'
  alias lt='find . -maxdepth 3 -print'
fi

function mkcd {
  if [[ $# -ne 1 ]]; then
    printf 'uso: mkcd DIRETORIO\n' >&2
    return 2
  fi
  mkdir -p -- "$1" && cd -- "$1"
}

function reload {
  # shellcheck disable=SC1090
  source "$HOME/.bashrc"
}

function ep {
  "${EDITOR:-nvim}" "$HOME/.config/shell/lucas-terminal.bash"
}

# Wrappers consistentes para os namespaces do Docker.
if command -v docker >/dev/null 2>&1; then
  function dc { docker container "$@"; }
  function dco { docker compose "$@"; }
  function di { docker image "$@"; }
  function dn { docker network "$@"; }
  function dv { docker volume "$@"; }
  function ds { docker system "$@"; }
fi

# Completação e busca fuzzy do pacote fzf do Debian.
if [[ -r /usr/share/doc/fzf/examples/completion.bash ]]; then
  # shellcheck disable=SC1091
  source /usr/share/doc/fzf/examples/completion.bash
fi
if [[ -r /usr/share/doc/fzf/examples/key-bindings.bash ]]; then
  # shellcheck disable=SC1091
  source /usr/share/doc/fzf/examples/key-bindings.bash
fi

if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init bash)"
fi

if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate bash)"
fi

prompt_config="$HOME/.config/powershell/lucas.omp.json"
if command -v oh-my-posh >/dev/null 2>&1 && [[ -f "$prompt_config" ]]; then
  eval "$(oh-my-posh init bash --config "$prompt_config")"
fi
unset prompt_config
