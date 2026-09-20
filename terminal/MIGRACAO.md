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

O perfil anterior é clonado antes das mudanças e permanece na lista de perfis.
O script informa o UUID anterior e o diretório do backup ao terminar.
