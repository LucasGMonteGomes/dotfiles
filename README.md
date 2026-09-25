# Configurações de terminal e Neovim para Debian

Este pacote adapta as configurações enviadas do Windows para o Debian. Ele não
contém tokens, chaves SSH ou senhas.

## O que foi adaptado

| Origem | Implementação no Debian |
| --- | --- |
| Perfil do PowerShell | Perfil compatível com PowerShell 7 no Linux, sem caminhos do Git for Windows |
| Funções e aliases do PowerShell | Versão equivalente para o Bash, que é o shell padrão do Debian |
| Tema do Oh My Posh | O mesmo `lucas.omp.json`, compartilhado por Bash e PowerShell |
| Windows Terminal | Script que cria um perfil novo no GNOME Terminal com a fonte e a paleta One Dark |
| Neovim | Caminhos do Java descobertos automaticamente pelo `PATH`/`JAVA_HOME` e terminal integrado usando o shell do Linux |

O instalador cria links simbólicos de `~/.config` para este repositório, então
qualquer alteração (inclusive o `lazy-lock.json` atualizado pelo `:Lazy sync`)
aparece no `git status`. Por isso, mantenha o repositório no mesmo lugar depois
de instalar; se movê-lo, execute `./install.sh` de novo. As configurações
antigas são movidas para `~/.config-backups` pelo instalador.
O script do GNOME Terminal cria o perfil **Lucas One Dark** na primeira execução
e apenas o atualiza nas seguintes; o perfil anterior não é apagado.

## 1. Instalar os programas necessários

Instale primeiro as dependências disponíveis no Debian:

```bash
sudo apt update
sudo apt install -y \
  git curl unzip build-essential ripgrep fd-find fzf zoxide eza bat \
  wl-clipboard xclip trash-cli nodejs npm openjdk-21-jdk maven uuid-runtime
```

### Neovim 0.12 ou mais recente

O pacote `neovim` do Debian 13 fornece a série 0.10, mas esta configuração usa
APIs do Neovim 0.12. Use o instalador incluído, que instala a versão estável
oficial somente para o seu usuário:

```bash
chmod +x scripts/install-neovim-latest.sh
./scripts/install-neovim-latest.sh
exec bash
nvim --version
```

O binário fica em `~/.local/bin/nvim`; o pacote do sistema não é removido.

### Oh My Posh e a fonte

Instale o Oh My Posh seguindo o método oficial para Linux:

```bash
curl -s https://ohmyposh.dev/install.sh | bash -s
exec bash
oh-my-posh font list | grep -i jet
oh-my-posh font install JetBrainsMono
fc-cache -f
```

Se o nome `JetBrainsMono` não aparecer na listagem, escolha ali outra Nerd Font
e depois ajuste a propriedade `font` em `terminal/apply-gnome-terminal.sh`.

## 2. Aplicar as configurações

Na raiz deste pacote:

```bash
chmod +x install.sh terminal/apply-gnome-terminal.sh
./install.sh
exec bash
```

Sem opções, o instalador vincula:

- `~/.config/nvim`;
- `~/.config/shell/lucas-terminal.bash` e sua carga pelo `~/.bashrc`;
- `~/.inputrc`, que inclui o `/etc/inputrc` e faz `Ctrl+Backspace` apagar a
  palavra anterior;
- `~/.config/powershell/Microsoft.PowerShell_profile.ps1`;
- `~/.config/oh-my-posh/lucas.omp.json`, tema do prompt usado pelo Bash e pelo
  PowerShell (vinculado por `--bash` ou `--powershell`).

Para instalar somente uma parte:

```bash
./install.sh --nvim
./install.sh --bash
./install.sh --powershell
./install.sh --check
```

Depois aplique a aparência no GNOME Terminal:

```bash
./terminal/apply-gnome-terminal.sh
```

Feche e abra o terminal. O perfil criado se chama **Lucas One Dark**. A
transparência foi reduzida de 50% para 15% para preservar a legibilidade; em
versões do GNOME Terminal sem suporte a transparência, o script simplesmente
ignora essa propriedade.

Os atalhos do Windows Terminal não foram copiados literalmente. O GNOME
Terminal conserva os atalhos nativos, como `Ctrl+Shift+T` para uma aba nova, e
deixa `Ctrl+T` disponível para o terminal integrado do Neovim.

## 3. Primeira inicialização do Neovim

Abra o editor com acesso à internet:

```bash
nvim
```

O `lazy.nvim` será baixado e instalará os plugins definidos no arquivo de
trava. Em seguida, dentro do Neovim, execute:

```vim
:Lazy sync
:Mason
:MasonInstall sonarlint-language-server
:checkhealth
```

O Java é localizado nesta ordem:

1. variável `JAVA_HOME`, quando definida;
2. caminho real do comando `java` encontrado no `PATH`.

Confira no terminal:

```bash
java -version
readlink -f "$(command -v java)"
```

Para o copiar/colar do Neovim funcionar no GNOME/Wayland, `wl-copy` deve ser
encontrado. O pacote `wl-clipboard` instalado acima o fornece.

## 4. PowerShell 7 no Linux (opcional)

O Bash já recebeu as funções, os aliases do Docker, `fzf`, `zoxide`, `mise` e o
tema. Instale o PowerShell apenas se você também quiser continuar usando
`pwsh`. Use o repositório oficial da Microsoft conforme a documentação:

- <https://learn.microsoft.com/pt-br/powershell/scripting/install/install-debian>

Depois instale os módulos do perfil:

```bash
pwsh -NoLogo -Command \
  'Install-Module posh-git,Terminal-Icons,PSFzf -Scope CurrentUser -Force'
pwsh
```

Para fazer o terminal integrado do Neovim abrir o PowerShell em vez do Bash:

```bash
export NVIM_TERMINAL_SHELL='pwsh -NoLogo'
nvim
```

Se quiser tornar isso permanente, coloque o `export` no final de
`~/.config/shell/lucas-terminal.bash`.

## Comandos preservados

- `dc`, `dco`, `di`, `dn`, `dv`, `ds`: namespaces do Docker;
- `ll`, `lt`: listagem moderna com `eza` quando disponível;
- `z`: navegação por frequência com `zoxide`;
- `Ctrl+R`: histórico fuzzy do Bash/PowerShell;
- `reload`: recarrega o perfil do shell;
- `ep`: abre a configuração do shell no editor.
