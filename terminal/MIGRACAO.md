# Windows Terminal para GNOME Terminal

O arquivo `settings.json` do Windows Terminal usa perfis, ações e propriedades
que não existem no GNOME Terminal. Por isso ele não deve ser copiado para o
Debian.

O script `apply-gnome-terminal.sh` traduz somente as partes equivalentes:

- fonte `JetBrainsMono Nerd Font Mono`, tamanho 10;
- fundo `#282C34` e texto `#ABB2BF`;
- paleta One Dark de 16 cores;
- cursor sublinhado;
- espaçamento vertical 1,0, para as pontas arredondadas do prompt terem a
  mesma altura dos segmentos;
- transparência de 15% quando suportada.

O script cuida de dois perfis com essa mesma aparência:

- **Lucas One Dark**: abre o Bash e é definido como padrão;
- **Lucas PowerShell**: abre `pwsh -NoLogo`; só é criado quando o `pwsh` está
  instalado.

Na primeira execução, o perfil padrão é clonado para criar cada um deles, e o
perfil anterior permanece na lista de perfis. Nas execuções seguintes, o
script encontra os perfis pelo nome e reaplica as configurações neles, sem
criar duplicatas. Os perfis afetados são salvos em
`~/.config-backups/gnome-terminal-*` antes de qualquer mudança.
