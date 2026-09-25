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

profile_name='Lucas One Dark'
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

profile_id=
for id in "${profile_ids[@]}"; do
  if [[ "$(gsettings get "$(profile_schema "$id")" visible-name)" == "'$profile_name'" ]]; then
    profile_id=$id
    break
  fi
done

mkdir -p "$backup_dir"
if [[ -n "$profile_id" ]]; then
  # Reaplicar o script atualiza o perfil existente em vez de criar outro.
  dconf dump "$profiles_path/:$profile_id/" > "$backup_dir/existing-profile.dconf"
  printf '%s\n' "$profile_id" > "$backup_dir/existing-profile-id"
  action="atualizado"
else
  old_id=$(gsettings get "$profiles_schema" default | tr -d "'")
  profile_id=$(uuidgen | tr '[:upper:]' '[:lower:]')
  dconf dump "$profiles_path/:$old_id/" > "$backup_dir/original-profile.dconf"
  printf '%s\n' "$old_id" > "$backup_dir/original-profile-id"
  dconf dump "$profiles_path/:$old_id/" | dconf load "$profiles_path/:$profile_id/"

  profile_ids+=("$profile_id")
  action="criado"
fi
# Regrava a lista sempre, descartando entradas que não são UUIDs.
dconf dump "$profiles_path/" > "$backup_dir/profiles-list.dconf"
updated_profiles=$(printf "'%s', " "${profile_ids[@]}")
gsettings set "$profiles_schema" list "[${updated_profiles%, }]"
new_schema=$(profile_schema "$profile_id")

gsettings set "$new_schema" visible-name "$profile_name"
gsettings set "$new_schema" use-system-font false
gsettings set "$new_schema" font 'JetBrainsMono Nerd Font Mono 10'
gsettings set "$new_schema" use-theme-colors false
gsettings set "$new_schema" foreground-color '#ABB2BF'
gsettings set "$new_schema" background-color '#282C34'
gsettings set "$new_schema" cursor-shape 'underline'
gsettings set "$new_schema" bold-is-bright false
gsettings set "$new_schema" palette "['#282C34', '#E06C75', '#98C379', '#E5C07B', '#61AFEF', '#C678DD', '#56B6C2', '#ABB2BF', '#5C6370', '#E06C75', '#98C379', '#E5C07B', '#61AFEF', '#C678DD', '#56B6C2', '#FFFFFF']"

if gsettings list-keys "$new_schema" | grep -Fqx cell-height-scale; then
  gsettings set "$new_schema" cell-height-scale 1.2
fi
if gsettings list-keys "$new_schema" | grep -Fqx cell-width-scale; then
  gsettings set "$new_schema" cell-width-scale 1.0
fi
if gsettings list-keys "$new_schema" | grep -Fqx use-transparent-background; then
  gsettings set "$new_schema" use-transparent-background true
fi
if gsettings list-keys "$new_schema" | grep -Fqx background-transparency-percent; then
  gsettings set "$new_schema" background-transparency-percent 15
fi

gsettings set "$profiles_schema" default "$profile_id"

echo "Perfil '$profile_name' $action e definido como padrão."
if [[ -n "${old_id:-}" ]]; then
  echo "O perfil anterior ($old_id) foi preservado."
fi
echo "Backup: $backup_dir"
echo 'Feche e abra o GNOME Terminal para conferir o resultado.'
