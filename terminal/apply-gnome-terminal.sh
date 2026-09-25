#!/usr/bin/env bash
set -euo pipefail

for required in gsettings dconf uuidgen; do
  if ! command -v "$required" >/dev/null 2>&1; then
    printf 'Comando necessário não encontrado: %s\n' "$required" >&2
    exit 1
  fi
done

profiles_schema='org.gnome.Terminal.ProfilesList'
profile_schema_name='org.gnome.Terminal.Legacy.Profile'
if ! gsettings list-schemas | grep -Fqx "$profiles_schema"; then
  echo 'O GNOME Terminal não está instalado ou não possui o esquema esperado.' >&2
  echo 'Esta etapa é opcional; as configurações do Bash e do Neovim continuam válidas.' >&2
  exit 1
fi

profiles_path='/org/gnome/terminal/legacy/profiles:'
timestamp=$(date +%Y%m%d-%H%M%S)
backup_dir="$HOME/.config-backups/gnome-terminal-$timestamp"

profile_schema() {
  printf '%s:%s/:%s/' "$profile_schema_name" "$profiles_path" "$1"
}

# gsettings imprime a lista como "['id', ...]" ou "@as []"; só os UUIDs importam.
mapfile -t profile_ids < <(gsettings get "$profiles_schema" list | grep -oE '[0-9a-f-]{36}' || true)

# Um perfil padrão ausente da lista fica invisível e o terminal cai nas
# configurações de fábrica; ele volta para a lista na gravação abaixo.
default_id=$(gsettings get "$profiles_schema" default | grep -oE '[0-9a-f-]{36}' || true)
if [[ -n "$default_id" && " ${profile_ids[*]} " != *" $default_id "* ]]; then
  profile_ids+=("$default_id")
fi

mkdir -p "$backup_dir"
dconf dump "$profiles_path/" > "$backup_dir/profiles-list.dconf"

# Procura o perfil pelo nome; se não existir, clona o perfil padrão atual.
# Deixa o UUID em $profile_id e a ação realizada em $action.
ensure_profile() {
  local name=$1 id
  profile_id=
  for id in "${profile_ids[@]}"; do
    if [[ "$(gsettings get "$(profile_schema "$id")" visible-name)" == "'$name'" ]]; then
      profile_id=$id
      break
    fi
  done

  if [[ -n "$profile_id" ]]; then
    # Reaplicar o script atualiza o perfil existente em vez de criar outro.
    action="atualizado"
  else
    profile_id=$(uuidgen | tr '[:upper:]' '[:lower:]')
    dconf dump "$profiles_path/:$default_id/" | dconf load "$profiles_path/:$profile_id/"
    profile_ids+=("$profile_id")
    action="criado"
  fi

  # Regrava a lista sempre, descartando entradas que não são UUIDs.
  local updated_profiles
  updated_profiles=$(printf "'%s', " "${profile_ids[@]}")
  gsettings set "$profiles_schema" list "[${updated_profiles%, }]"
}

apply_appearance() {
  local schema=$1 name=$2
  gsettings set "$schema" visible-name "$name"
  gsettings set "$schema" use-system-font false
  gsettings set "$schema" font 'JetBrainsMono Nerd Font Mono 10'
  gsettings set "$schema" use-theme-colors false
  gsettings set "$schema" foreground-color '#ABB2BF'
  gsettings set "$schema" background-color '#282C34'
  gsettings set "$schema" cursor-shape 'underline'
  gsettings set "$schema" bold-is-bright false
  gsettings set "$schema" palette "['#282C34', '#E06C75', '#98C379', '#E5C07B', '#61AFEF', '#C678DD', '#56B6C2', '#ABB2BF', '#5C6370', '#E06C75', '#98C379', '#E5C07B', '#61AFEF', '#C678DD', '#56B6C2', '#FFFFFF']"

  # Acima de 1.0 o fundo dos segmentos do Oh My Posh fica mais alto que as
  # pontas arredondadas da fonte.
  if gsettings list-keys "$schema" | grep -Fqx cell-height-scale; then
    gsettings set "$schema" cell-height-scale 1.0
  fi
  if gsettings list-keys "$schema" | grep -Fqx cell-width-scale; then
    gsettings set "$schema" cell-width-scale 1.0
  fi
  if gsettings list-keys "$schema" | grep -Fqx use-transparent-background; then
    gsettings set "$schema" use-transparent-background true
  fi
  if gsettings list-keys "$schema" | grep -Fqx background-transparency-percent; then
    gsettings set "$schema" background-transparency-percent 15
  fi
}

if [[ -n "$default_id" ]]; then
  printf '%s\n' "$default_id" > "$backup_dir/original-default-id"
  dconf dump "$profiles_path/:$default_id/" > "$backup_dir/original-default.dconf"
fi

# Perfil principal: abre o shell de login (Bash) e continua sendo o padrão.
bash_profile='Lucas One Dark'
ensure_profile "$bash_profile"
bash_id=$profile_id
schema=$(profile_schema "$bash_id")
dconf dump "$profiles_path/:$bash_id/" > "$backup_dir/bash-profile.dconf"
apply_appearance "$schema" "$bash_profile"
gsettings set "$schema" use-custom-command false
gsettings set "$profiles_schema" default "$bash_id"
echo "Perfil '$bash_profile' $action e definido como padrão (Bash)."

# Perfil secundário com a mesma aparência, abrindo o PowerShell 7.
pwsh_profile='Lucas PowerShell'
if command -v pwsh >/dev/null 2>&1; then
  ensure_profile "$pwsh_profile"
  schema=$(profile_schema "$profile_id")
  dconf dump "$profiles_path/:$profile_id/" > "$backup_dir/pwsh-profile.dconf"
  apply_appearance "$schema" "$pwsh_profile"
  gsettings set "$schema" use-custom-command true
  gsettings set "$schema" custom-command 'pwsh -NoLogo'
  echo "Perfil '$pwsh_profile' $action (abre o pwsh)."
else
  echo "pwsh não encontrado; o perfil '$pwsh_profile' não foi criado."
fi

echo "Backup: $backup_dir"
echo 'Feche e abra o GNOME Terminal para conferir o resultado.'
