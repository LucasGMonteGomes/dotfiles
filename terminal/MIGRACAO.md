# Windows Terminal para GNOME Terminal

O arquivo `settings.json` do Windows Terminal usa perfis, ações e propriedades
que não existem no GNOME Terminal. Por isso ele não deve ser copiado para o
Debian.

O script `apply-gnome-terminal.sh` traduz somente as partes equivalentes:

- fonte `JetBrainsMono Nerd Font Mono`, tamanho 10;
- fundo `#282C34` e texto `#ABB2BF`;
- paleta One Dark de 16 cores;
- cursor sublinhado;
- espaçamento vertical 1,2 quando a versão instalada oferece essa chave;
- transparência de 15% quando suportada.

Na primeira execução, o perfil padrão é clonado para criar o **Lucas One Dark**,
e o perfil anterior permanece na lista de perfis. Nas execuções seguintes, o
script encontra o perfil pelo nome e reaplica as configurações nele, sem criar
duplicatas. Em ambos os casos o perfil afetado é salvo em
`~/.config-backups/gnome-terminal-*` antes de qualquer mudança.
