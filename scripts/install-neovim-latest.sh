#!/usr/bin/env bash
set -euo pipefail

case $(uname -m) in
  x86_64) archive_name='nvim-linux-x86_64.tar.gz'; directory_name='nvim-linux-x86_64' ;;
  aarch64|arm64) archive_name='nvim-linux-arm64.tar.gz'; directory_name='nvim-linux-arm64' ;;
  *) printf 'Arquitetura não suportada por este script: %s\n' "$(uname -m)" >&2; exit 1 ;;
esac

for required in curl tar; do
  command -v "$required" >/dev/null 2>&1 || {
    printf 'Comando necessário não encontrado: %s\n' "$required" >&2
    exit 1
  }
done

install_root="$HOME/.local/opt"
install_dir="$install_root/$directory_name"
download_dir=$(mktemp -d)
trap 'rm -rf -- "$download_dir"' EXIT

curl --fail --location --show-error \
  --output "$download_dir/$archive_name" \
  "https://github.com/neovim/neovim/releases/latest/download/$archive_name"

mkdir -p "$install_root" "$HOME/.local/bin"
if [[ -d "$install_dir" ]]; then
  mv -- "$install_dir" "$install_dir.backup-$(date +%Y%m%d-%H%M%S)"
fi
tar -xzf "$download_dir/$archive_name" -C "$install_root"
ln -sfn "$install_dir/bin/nvim" "$HOME/.local/bin/nvim"

"$HOME/.local/bin/nvim" --version | sed -n '1,3p'
echo 'Neovim instalado em ~/.local/opt e disponível por ~/.local/bin/nvim.'
