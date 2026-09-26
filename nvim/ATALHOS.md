# Atalhos do Neovim

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
| `Ctrl+Delete` | Apagar a proxima palavra |
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
| `Ctrl+G` | Abrir o menu de geracao: construtor, getters e setters (ou so getters/setters), `equals`/`hashCode`, `toString`, sobrescrever/implementar metodos ou metodos delegados |
| `Ctrl+L` | Abrir acoes de codigo do Java |
| `Ctrl+Alt+L` | Organizar imports e formatar o arquivo |
| `F2` | Renomear simbolo |
| `gd` / `gD` | Ir para definicao / declaracao |
| `grr` / `gri` / `grt` | Listar referencias / implementacoes / ir para o tipo |
| `grn` / `gra` | Renomear (igual ao `F2`) / acoes de codigo (igual ao `Ctrl+L`) |
| `gO` | Listar simbolos do arquivo |
| `grx` | Executar a lente sob o cursor (ex.: `2 references` lista as referencias) |
| `Espaco i h` | Mostrar/ocultar dicas inline (nomes de parametros) |
| `K` | Mostrar documentacao do simbolo |
| `[d` / `]d` | Diagnostico anterior / proximo |
| `gl` | Mostrar diagnostico da linha |
| `Ctrl+Espaco` no INSERT | Solicitar sugestoes de autocomplete |
| `Seta cima/baixo` ou `Ctrl+P`/`Ctrl+N` no autocomplete | Escolher sugestao |
| `Enter` no autocomplete | Aceitar a sugestao escolhida; sem escolha, apenas quebra a linha |
| `Tab` / `Shift+Tab` | Pular para o proximo/anterior campo de um snippet |
| `Ctrl+Espaco` no NORMAL, depois repetidamente | Selecionar o trecho de codigo sob o cursor e expandir (ex.: `nome` > `this.nome = nome`) |
| `Backspace` com selecao | Reduzir a selecao estrutural um nivel |
| `an` / `in` no VISUAL | Expandir / reduzir a selecao (padrao do Neovim) |
| `Ctrl+Alt+D` | No `pom.xml`, abrir buscador de dependencias Maven |
| `Ctrl+Alt+I` | Abrir o Spring Initializr |

Comandos equivalentes de geracao: `:JavaGenerateConstructor`, `:JavaGenerateAccessors`, `:JavaGenerateGetters`, `:JavaGenerateSetters`, `:JavaGenerateEqualsHashCode`, `:JavaGenerateToString`, `:JavaOverrideMethods` e `:JavaGenerateDelegateMethods`.

Toda geracao abre um seletor para escolher os atributos (ou metodos) usados:

| Tecla no seletor | Acao |
|---|---|
| `Tab` | Marcar/desmarcar o item sob o cursor e ir ao proximo |
| `Seta cima/baixo` | Mover entre os itens |
| digitar | Filtrar a lista (ex.: `tele` mostra `telefone`) |
| `Ctrl+A` | Marcar ou desmarcar todos |
| `Enter` | Gerar com os itens marcados (`[x]`) |
| `Esc` | Cancelar sem gerar nada |

Nos campos, todos vem marcados (no `toString`, so os atributos, sem `getClass`/`hashCode`); desmarque o que nao quiser. Nos metodos a sobrescrever e a delegar, nada vem marcado. Enter sem nenhum item marcado gera o construtor sem parametros; nas demais opcoes, nada e gerado.

## Spring Boot

Em projetos com Spring Boot, o Spring Boot Language Server (o mesmo do VS Code) completa e valida `application.yml`/`application.properties`: `server.po` sugere `server.port`, e propriedades inexistentes ficam marcadas. `gd` sobre uma propriedade leva a classe que a define.

| Atalho ou comando | Acao |
|---|---|
| `Espaco s r` | Rodar a aplicacao (`spring-boot:run`/`bootRun`); se ja estiver rodando, mostrar/esconder os logs |
| `Espaco s s` | Encerrar a aplicacao |
| `Espaco s e` | Buscar endpoints (`@/users -- GET`) e ir ate o mapeamento |
| `Espaco s b` | Buscar beans do projeto |
| `:SpringBoot` | Buscar anotacoes, beans, endpoints ou prototypes (resultado na quickfix) |

A aplicacao roda num terminal proprio, na pasta do modulo do arquivo atual, usando o `mvnw`/`gradlew` do projeto quando existir. Esconder o terminal nao encerra a aplicacao. Para depurar, use `F9` (ver Depuracao).

## Depuracao (Java)

As teclas seguem o IntelliJ. No GNOME Terminal, F10 abre o menu e F11 alterna a tela cheia, por isso o esquema do VS Code nao e usado.

| Atalho | Acao |
|---|---|
| `F9` | Iniciar a depuracao (escolhe a classe `main`) ou continuar ate o proximo breakpoint |
| `Ctrl+F8` | Marcar/desmarcar breakpoint na linha |
| `Espaco d b` | Breakpoint condicional (ex.: `i == 2`) |
| `F8` | Executar a linha (step over) |
| `F7` | Entrar no metodo (step into) |
| `Shift+F8` | Sair do metodo (step out) |
| `Ctrl+F2` | Encerrar a sessao |
| `Espaco d l` | Repetir a ultima sessao |
| `Espaco d u` | Abrir/fechar o painel (variaveis, watches, breakpoints, threads, console) |
| `Espaco d h` | Inspecionar o valor sob o cursor |

O painel abre ao iniciar e fecha ao terminar. Nele, `S`/`W`/`B`/`T`/`E`/`R`/`C` trocam de aba e `g?` mostra a ajuda. Salvar um arquivo durante a depuracao aplica a alteracao na JVM em execucao (hot code replace).

## Testes (Java)

| Atalho | Acao |
|---|---|
| `Espaco t c` | Rodar todos os testes da classe |
| `Espaco t m` | Rodar o teste sob o cursor |
| `Espaco t p` | Escolher um teste da classe para rodar |
| `Espaco t t` | Alternar entre a classe e o seu teste |
| `Espaco t n` | Gerar uma classe de teste para a classe atual |

Os testes rodam pelo depurador: breakpoints marcados com `Ctrl+F8` param a execucao. As falhas vao para a lista quickfix (`:copen`), com a linha e a mensagem da assercao.

## HTTP, Git e paineis

| Atalho | Acao |
|---|---|
| `Ctrl+Alt+R` em `.http` | Executar requisicao atual |
| `Ctrl+Alt+A` em `.http` | Executar todas as requisicoes |
| `Ctrl+Alt+P` em `.http` | Repetir a ultima requisicao |
| `Ctrl+Alt+N` em `.http` | Abrir nova requisicao |
| `Ctrl+T` | Abrir/fechar terminal no rodape |
| `Ctrl+T` no terminal | Fechar o terminal |
| `Ctrl+Tab` no terminal | Ir para a proxima janela |
| `Ctrl+\`, depois `Ctrl+N` no terminal | Ir para o modo NORMAL (rolar, copiar texto) |
| `Esc` / `Ctrl+W` / `Ctrl+K` / `Ctrl+H` no terminal | Enviados ao shell ou programa (apagar palavra, cortar linha...) |
| `Ctrl+Alt+X` | Problemas de todo o projeto |
| `Ctrl+Alt+T` | Problemas do arquivo atual |
| `Ctrl+Alt+K` | Ativar/desativar modo foco |
| `Ctrl+Alt+H` | Mostrar/ocultar contexto fixo no topo |
| `Ctrl+Alt+U` | Abrir historico de desfazer |
| `]h` / `[h` | Proximo/anterior bloco alterado do Git |
| `Ctrl+S` | Adicionar bloco alterado ao stage |
| `Ctrl+Q` | Descartar bloco alterado (pede confirmacao; padrao e Nao) |
| `Ctrl+B` | Mostrar autoria da linha |
| `Espaco g p` | Visualizar o bloco alterado |
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
