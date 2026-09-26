# Atalhos do seu Neovim

Abra este guia a qualquer momento com `:Atalhos`. A notacao `Ctrl+Alt` usa as duas teclas; `Espaco` e a tecla lider (`<leader>`); letras sozinhas sao usadas no modo **NORMAL**, salvo quando indicado.

## Modos e edicao

| Atalho | Acao |
|---|---|
| `Ctrl+C` no NORMAL | Entrar em INSERT |
| `Ctrl+C` no INSERT | Voltar ao NORMAL |
| `Ctrl+Tab` | Alternar entre arquivos abertos em divisao, ignorando Explorer e terminal |
| `Esc` no INSERT | Fecha apenas o menu de autocomplete; permanece em INSERT |
| `Ctrl+Z` | Desfazer a ultima alteracao |
| `Ctrl+Alt+Z` | Refazer alteracao |
| `Ctrl+Backspace` | Apagar uma palavra inteira |
| `Ctrl+Seta esquerda/direita` | Ir ao inicio/fim do trecho, incluindo pontuacao como `;` |
| `Ctrl+X` | Apagar sem copiar para a area de transferencia |
| `Ctrl+D` / `Ctrl+U` | Rolar para baixo/cima mantendo o cursor centralizado |
| `Ctrl+R` | Preparar substituicao da palavra sob o cursor no arquivo |
| `p` sobre uma selecao | Colar sem perder o texto que ja estava copiado |
| `J` / `K` com linhas selecionadas | Mover a selecao para baixo / cima |
| `<` / `>` com linhas selecionadas | Desindentar / indentar sem perder a selecao |
| `J` no NORMAL | Unir a proxima linha sem mover o cursor |

## Arquivos, Explorer e busca

| Atalho | Onde | Acao |
|---|---|---|
| `Ctrl+N` | Editor | Abrir/fechar o Explorer |
| `Ctrl+N` | Explorer | Fechar o Explorer |
| `Ctrl+E` | Editor | Levar o cursor ao Explorer sem fecha-lo |
| `Esc` | Explorer | Voltar ao editor |
| `Enter` ou `l` | Explorer | Abrir arquivo ou expandir pasta (`src` expande sua estrutura Java) |
| `Ctrl+L` | Explorer, sobre um arquivo | Abrir o arquivo em uma divisao vertical a direita |
| `h` | Explorer | Recolher a pasta atual |
| `a` ou `Ctrl+A` | Explorer | Criar arquivo/pasta dentro da pasta selecionada |
| `r` | Explorer | Renomear arquivo ou pasta |
| `d` | Explorer | Excluir (usa a Lixeira quando disponivel) |
| `c` / `m` / `p` | Explorer | Copiar / mover / colar |
| `Ctrl+C` | Explorer | Sem acao; nao muda mais a pasta exibida |
| `Ctrl+P` | Editor ou Explorer | Busca inteligente: buffers, recentes e arquivos |
| `Ctrl+F` | Editor ou Explorer | Buscar texto em todo o projeto |
| `Ctrl+A` | Editor | Buscar todos os arquivos, inclusive os ignorados |
| `Ctrl+Alt+W` | Editor | Buscar a palavra (ou selecao) no projeto |
| `Ctrl+Alt+B` | Editor | Listar buffers abertos |
| `Ctrl+Alt+S` | Editor | Buscar classe, metodo ou simbolo do arquivo |
| `Ctrl+Alt+Y` | Editor | Buscar simbolo em todo o projeto |
| `-` | Editor | Abrir a pasta atual no Oil |
| `q` ou `Esc` | Oil | Fechar o Oil |

Ao abrir `src`, o Explorer abre somente `main/java` e a cadeia principal do pacote (`com/example/...`); ele para nas pastas estruturais como `controller`, `service` e `model`. Para criar uma pasta, informe um nome terminado em `/`, por exemplo `controller/`. Sem a barra final, o Explorer cria um arquivo. A criacao ocorre dentro da pasta que esta selecionada.

## Java, Spring e Maven

| Atalho | Acao |
|---|---|
| `Ctrl+G` | Abrir o menu: construtor, getters/setters ou `equals`/`hashCode` |
| `Ctrl+L` | Abrir acoes de codigo do Java |
| `Ctrl+Alt+L` | Organizar imports e formatar o arquivo |
| `F2` | Renomear simbolo |
| `gd` / `gD` / `gi` / `gr` | Ir para definicao / declaracao / implementacao / referencias |
| `K` | Mostrar documentacao do simbolo |
| `[d` / `]d` | Diagnostico anterior / proximo |
| `gl` | Mostrar diagnostico da linha |
| `Ctrl+Espaco` | Solicitar sugestoes de autocomplete |
| `Seta cima/baixo` ou `Ctrl+P`/`Ctrl+N` no autocomplete | Escolher sugestao |
| `Enter` no autocomplete | Aceitar a sugestao escolhida; sem escolha, apenas quebra a linha |
| `Tab` / `Shift+Tab` | Pular para o proximo/anterior campo de um snippet |
| `Ctrl+Espaco` repetidamente | Expandir a selecao estrutural do codigo |
| `Ctrl+Alt+D` | No `pom.xml`, abrir buscador de dependencias Maven |
| `Ctrl+Alt+I` | Abrir o Spring Initializr |

Comandos equivalentes de geracao: `:JavaGenerateConstructor`, `:JavaGenerateAccessors` e `:JavaGenerateEqualsHashCode`.

## HTTP, Git e paineis

| Atalho | Acao |
|---|---|
| `Ctrl+Alt+R` em `.http` | Executar requisicao atual |
| `Ctrl+Alt+A` em `.http` | Executar todas as requisicoes |
| `Ctrl+Alt+P` em `.http` | Repetir a ultima requisicao |
| `Ctrl+Alt+N` em `.http` | Abrir nova requisicao |
| `Ctrl+T` | Abrir/fechar terminal no rodape |
| `Esc` no terminal | Fechar o terminal |
| `Ctrl+H` / `Ctrl+J` / `Ctrl+K` no terminal | Ir para janela a esquerda / abaixo / acima |
| `Ctrl+W` no terminal | Iniciar comando de janela do Neovim |
| `Ctrl+Alt+X` | Problemas de todo o projeto |
| `Ctrl+Alt+T` | Problemas do arquivo atual |
| `Ctrl+Alt+K` | Ativar/desativar modo foco |
| `Ctrl+Alt+H` | Mostrar/ocultar contexto fixo no topo |
| `Ctrl+Alt+U` | Abrir historico de desfazer |
| `]h` / `[h` | Proximo/anterior bloco alterado do Git |
| `Ctrl+S` | Adicionar bloco alterado ao stage |
| `Ctrl+Q` | Desfazer bloco alterado |
| `Ctrl+B` | Mostrar autoria da linha |
| `Ctrl+G` fora de Java | Visualizar o bloco alterado |
| `ih` em operador/visual | Selecionar um bloco alterado do Git |
| `Ctrl+Alt+V` | Abrir/fechar Diffview |

## Markdown e Zettelkasten

| Atalho | Acao |
|---|---|
| `Espaco m`, depois `e` | Voltar diretamente para o arquivo Markdown editavel |
| `Espaco m`, depois `p` | Alternar preview HTML no navegador, com estilo de documento do VS Code |
| `Espaco m`, depois `i` | Alternar preview interno rapido no painel do Nvim |
| `Espaco m`, depois `b` | Abrir o preview HTML no navegador |
| `]s` / `[s` | Ir para a proxima/anterior palavra marcada pelo corretor |
| `z=` | Mostrar sugestoes para a palavra sob o cursor |
| `zg` | Adicionar a palavra sob o cursor ao dicionario pessoal |
| `zG` | Desfazer a ultima adicao ao dicionario pessoal |

Em arquivos `.md`, o corretor usa portugues do Brasil somente na janela de
edicao. Ele apenas marca e sugere correcoes: nunca altera o texto que voce
digitou. O preview nao exibe sublinhados de ortografia.

## Utilitarios

| Atalho ou comando | Acao |
|---|---|
| `za` / `zM` / `zR` | Alternar dobra atual / fechar todas / abrir todas |
| `Ctrl+Alt+Q` | Reiniciar a configuracao do Neovim |
| `:Atalhos` | Abrir este guia |
| `:DockerLint` | Validar Dockerfile e Compose, quando os arquivos existirem |
