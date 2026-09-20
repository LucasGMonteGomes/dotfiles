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

old_id=$(gsettings get "$profiles_schema" default | tr -d "'")
new_id=$(uuidgen | tr '[:upper:]' '[:lower:]')
old_path="/org/gnome/terminal/legacy/profiles:/:$old_id/"
new_path="/org/gnome/terminal/legacy/profiles:/:$new_id/"
new_schema="$profile_schema_name:$new_path"
timestamp=$(date +%Y%m%d-%H%M%S)
backup_dir="$HOME/.config-backups/gnome-terminal-$timestamp"

mkdir -p "$backup_dir"
dconf dump "$old_path" > "$backup_dir/original-profile.dconf"
printf '%s\n' "$old_id" > "$backup_dir/original-profile-id"
dconf dump "$old_path" | dconf load "$new_path"

current_profiles=$(gsettings get "$profiles_schema" list)
if [[ "$current_profiles" == '[]' ]]; then
  updated_profiles="['$new_id']"
else
  updated_profiles="${current_profiles%]}, '$new_id']"
fi
gsettings set "$profiles_schema" list "$updated_profiles"

gsettings set "$new_schema" visible-name 'Lucas One Dark'
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

gsettings set "$profiles_schema" default "$new_id"

echo "Perfil 'Lucas One Dark' criado e definido como padrão."
echo "O perfil anterior ($old_id) foi preservado."
echo "Backup: $backup_dir"
echo 'Feche e abra o GNOME Terminal para conferir o resultado.'
