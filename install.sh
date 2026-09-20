#!/usr/bin/env bash
set -euo pipefail

bundle_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
timestamp=$(date +%Y%m%d-%H%M%S)
backup_root="$HOME/.config-backups/debian-dotfiles-$timestamp"

install_nvim=false
install_bash=false
install_powershell=false

usage() {
  cat <<'EOF'
Uso: ./install.sh [opções]

Sem opções, instala Neovim, Bash e o perfil opcional do PowerShell.

  --nvim        instala somente ~/.config/nvim
  --bash        instala somente a integração do Bash
  --powershell  instala somente o perfil do PowerShell 7
  --check       verifica os principais programas
  --help        exibe esta ajuda

As configurações existentes são copiadas para ~/.config-backups antes de
qualquer substituição.
EOF
}

backup_path() {
  local source=$1
  local relative=${source#"$HOME"/}

  if [[ -e "$source" || -L "$source" ]]; then
    mkdir -p "$backup_root/$(dirname -- "$relative")"
    cp -a -- "$source" "$backup_root/$relative"
  fi
}

check_commands() {
  local command_name
  local missing=()
  local recommended=(git curl nvim rg fzf zoxide java mvn node npm wl-copy)

  for command_name in "${recommended[@]}"; do
    command -v "$command_name" >/dev/null 2>&1 || missing+=("$command_name")
  done

  if ((${#missing[@]})); then
    printf 'Programas recomendados ainda ausentes: %s\n' "${missing[*]}"
  else
    echo 'Programas principais encontrados.'
  fi

  if command -v nvim >/dev/null 2>&1; then
    local nvim_version
    nvim_version=$(nvim --version | sed -n '1s/^NVIM v//p')
    if [[ "$(printf '%s\n' 0.12 "$nvim_version" | sort -V | head -n1)" != 0.12 ]]; then
      printf 'ATENÇÃO: Neovim %s é antigo; esta configuração requer 0.12+.\n' "$nvim_version"
    fi
  fi
}

do_install_nvim() {
  local destination="$HOME/.config/nvim"
  backup_path "$destination"
  mkdir -p "$HOME/.config"
  if [[ -e "$destination" ]]; then
    mv -- "$destination" "$destination.pre-debian-dotfiles-$timestamp"
  fi
  mkdir -p "$destination"
  cp -a -- "$bundle_dir/nvim/." "$destination/"
  echo "Neovim instalado em $destination"
}

do_install_bash() {
  local destination="$HOME/.config/shell/lucas-terminal.bash"
  local bashrc="$HOME/.bashrc"
  local source_line='[ -f "$HOME/.config/shell/lucas-terminal.bash" ] && . "$HOME/.config/shell/lucas-terminal.bash"'

  backup_path "$destination"
  backup_path "$bashrc"
  mkdir -p "$(dirname -- "$destination")"
  cp -- "$bundle_dir/shell/bash/lucas-terminal.bash" "$destination"
  touch "$bashrc"

  if ! grep -Fqx "$source_line" "$bashrc"; then
    {
      printf '\n# Configuração migrada do Windows para o Debian\n'
      printf '%s\n' "$source_line"
    } >> "$bashrc"
  fi
  echo "Bash configurado por $destination"
}

do_install_powershell() {
  local destination_dir="$HOME/.config/powershell"
  backup_path "$destination_dir/Microsoft.PowerShell_profile.ps1"
  backup_path "$destination_dir/lucas.omp.json"
  mkdir -p "$destination_dir"
  cp -- "$bundle_dir/shell/powershell/Microsoft.PowerShell_profile.ps1" "$destination_dir/"
  cp -- "$bundle_dir/shell/powershell/lucas.omp.json" "$destination_dir/"
  echo "Perfil do PowerShell instalado em $destination_dir"
}

if (($# == 0)); then
  install_nvim=true
  install_bash=true
  install_powershell=true
else
  while (($#)); do
    case "$1" in
      --nvim) install_nvim=true ;;
      --bash) install_bash=true ;;
      --powershell) install_powershell=true ;;
      --check) check_commands; exit 0 ;;
      --help|-h) usage; exit 0 ;;
      *) printf 'Opção desconhecida: %s\n' "$1" >&2; usage >&2; exit 2 ;;
    esac
    shift
  done
fi

$install_nvim && do_install_nvim
$install_bash && do_install_bash
$install_powershell && do_install_powershell

check_commands
if [[ -d "$backup_root" ]]; then
  echo "Backup criado em $backup_root"
fi
echo 'Concluído. Execute: exec bash'
