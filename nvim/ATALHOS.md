# Atalhos do Neovim

Abra este guia a qualquer momento com `:Atalhos`. A notacao `Ctrl+Alt` usa as duas teclas; `Espaco` e a tecla lider (`<leader>`); letras sozinhas sao usadas no modo **NORMAL**, salvo quando indicado.

Para aprender os modos e os comandos de edicao do Vim (`ciw`, `di(`, `V`, `Ctrl+V`, `:%s`...), `:ManualVim` abre no navegador o [manual com exemplos animados em Java](manual-vim.html).

## Sumario

- [Modos e edicao](#modos-e-edicao)
- [Arquivos, Explorer e busca](#arquivos-explorer-e-busca)
- [Java: navegacao e LSP](#java-navegacao-e-lsp)
- [Geracao de codigo (Java)](#geracao-de-codigo-java)
- [Refatoracao (Java)](#refatoracao-java)
- [Snippets (Java)](#snippets-java)
- [Maven e pom.xml](#maven-e-pomxml)
- [Build (Maven/Gradle)](#build-mavengradle)
- [Testes (Java)](#testes-java)
- [Cobertura de testes (JaCoCo)](#cobertura-de-testes-jacoco)
- [Depuracao (Java)](#depuracao-java)
- [Spring Boot](#spring-boot)
- [HTTP](#http)
- [Git, terminal e paineis](#git-terminal-e-paineis)
- [Markdown e Zettelkasten](#markdown-e-zettelkasten)
- [Utilitarios](#utilitarios)

## Modos e edicao

| Atalho | Acao |
|---|---|
| `i` / `a` | Entrar em INSERT antes / depois do cursor |
| `I` / `A` | Entrar em INSERT no inicio / fim da linha |
| `o` / `O` | Abrir uma linha nova abaixo / acima e entrar em INSERT |
| `Esc` | Voltar ao NORMAL (de INSERT, VISUAL ou REPLACE) |
| `v` / `V` / `Ctrl+V` | Entrar em VISUAL por caracteres / linhas / bloco (coluna) |
| `R` | Entrar em REPLACE (digitar por cima do texto) |
| `u` ou `Ctrl+Z` | Desfazer a ultima alteracao |
| `Ctrl+R` ou `Ctrl+Alt+Z` | Refazer alteracao |
| `y` / `p` | Copiar / colar; usam a area de transferencia do sistema |
| `Ctrl+C` no VISUAL | Copiar a selecao |
| `Ctrl+V` no INSERT | Colar sem reindentar |
| `Ctrl+Tab` | Alternar entre arquivos abertos em divisao, ignorando Explorer e terminal |
| `Ctrl+Backspace` | Apagar uma palavra inteira |
| `Ctrl+Delete` | Apagar a proxima palavra |
| `Ctrl+Seta esquerda/direita` | Ir ao inicio/fim do trecho, incluindo pontuacao como `;` |
| `Ctrl+X` | Apagar sem copiar para a area de transferencia |
| `Ctrl+D` / `Ctrl+U` | Rolar para baixo/cima mantendo o cursor centralizado |
| `Espaco r w` | Preparar substituicao da palavra sob o cursor no arquivo |
| `p` sobre uma selecao | Colar sem perder o texto que ja estava copiado |
| `J` / `K` com linhas selecionadas | Mover a selecao para baixo / cima |
| `<` / `>` com linhas selecionadas | Desindentar / indentar sem perder a selecao |
| `J` no NORMAL | Unir a proxima linha sem mover o cursor |
| `gcc` / `gc` com selecao | Comentar/descomentar a linha / as linhas selecionadas |
| `Ctrl+Espaco` no NORMAL, depois repetidamente | Selecionar o trecho de codigo sob o cursor e expandir (ex.: `nome` > `this.nome = nome`) |
| `Backspace` com selecao | Reduzir a selecao estrutural um nivel |
| `an` / `in` no VISUAL | Expandir / reduzir a selecao (padrao do Neovim) |
| `ii` / `ai` no VISUAL ou com operador | Selecionar o bloco indentado (sem / com as linhas de borda) |
| `[i` / `]i` | Ir ao inicio / fim do bloco indentado |

### Delimitadores (mini.surround)

Para aspas, parenteses, chaves e tags. Ex.: `saiw"` envolve a palavra em aspas; `sd"` remove as aspas; `sr"'` troca aspas duplas por simples.

| Atalho | Acao |
|---|---|
| `sa` + movimento + caractere | Envolver o trecho (no VISUAL, `sa` + caractere envolve a selecao) |
| `sd` + caractere | Remover o delimitador em volta do cursor |
| `sr` + atual + novo | Trocar o delimitador |
| `sf` / `sF` + caractere | Ir ao delimitador da direita / esquerda |
| `sh` + caractere | Destacar o delimitador |

## Arquivos, Explorer e busca

| Atalho | Onde | Acao |
|---|---|---|
| `Ctrl+E` | Editor | Abrir o Explorer na raiz do projeto, com o arquivo atual selecionado |
| `Ctrl+E` ou `Esc` | Explorer | Fechar o Explorer e voltar ao arquivo |
| `Enter` ou `l` | Explorer | Abrir o arquivo (o Explorer fecha) ou expandir/recolher a pasta (`src` expande sua estrutura Java) |
| `Ctrl+L` | Explorer, sobre um arquivo | Abrir o arquivo em uma divisao vertical a direita |
| `h` | Explorer | Recolher a pasta atual |
| `/` | Explorer | Filtrar a arvore pelo nome; `Esc` volta a arvore |
| `a` ou `Ctrl+A` | Explorer | Criar arquivo ou pasta na pasta selecionada, com as pastas do caminho (`impl/ClienteServiceImpl.java`); o arquivo abre em seguida |
| `r` | Explorer | Renomear arquivo ou pasta |
| `d` | Explorer | Excluir (usa a Lixeira quando disponivel) |
| `c` / `m` / `p` | Explorer | Copiar / mover / colar |
| `Ctrl+C` | Explorer | Sem acao; nao muda mais a pasta exibida |
| `Ctrl+P` | Editor ou Explorer | Buscar arquivos e pastas do projeto; uma pasta abre no Explorer, ja expandida |
| `Ctrl+F` | Editor ou Explorer | Buscar texto em todo o projeto |
| `Ctrl+A` | Editor | Buscar todos os arquivos, inclusive os ignorados |
| `Ctrl+Alt+W` | Editor | Buscar a palavra (ou selecao) no projeto |
| `Ctrl+Alt+B` | Editor | Listar buffers abertos |
| `Ctrl+Alt+S` | Editor | Buscar classe, metodo ou simbolo do arquivo |
| `Ctrl+Alt+Y` | Editor | Buscar simbolo em todo o projeto |

O Explorer e uma janela no centro da tela com a arvore do projeto inteiro: as pastas expandem no lugar. Ele abre sozinho quando o Neovim e iniciado sem arquivo (`nvim`, `nvim .` ou `nvim pasta/`); com um arquivo (`nvim README.md`), o arquivo abre direto e `Ctrl+E` mostra a arvore com ele selecionado. A raiz e o repositorio Git do arquivo (ou a raiz do projeto Maven/Gradle).

Marcadores no Explorer:

| Marcador | Significado |
|---|---|
| `●` laranja depois do nome | Alteracoes nao salvas (numa pasta recolhida: algum arquivo dentro dela) |
| `M` a direita | Modificado em relacao ao ultimo commit |
| `A` a direita | Arquivo novo adicionado ao stage (`git add`) |
| `?` a direita | Nao rastreado pelo Git |
| `!` a direita e nome apagado | Ignorado pelo `.gitignore` (`target/`, `build/`...); `I` esconde/mostra |
| `D` / `R` a direita | Removido / renomeado |
| sem marcador | Salvo e sem mudancas em relacao ao Git |

Alteracoes que ja estao no stage aparecem com a letra numa cor propria. `]g` / `[g` pulam para o proximo/anterior arquivo com mudanca no Git.

### Busca de arquivos e pastas (`Ctrl+P`)

A busca abre num retangulo no alto da tela. Cada resultado mostra o nome em destaque e a pasta ao lado; a busca tambem considera o caminho (`serv impl` encontra os arquivos de `service/impl`), e arquivos usados ha pouco aparecem primeiro. `Enter` abre o arquivo; numa pasta, abre o Explorer com ela selecionada e expandida. `Ctrl+V` abre o arquivo numa divisao vertical e `Esc` fecha a busca.

Ao abrir `src`, o Explorer abre somente `main/java` e a cadeia principal do pacote (`com/example/...`); ele para nas pastas estruturais como `controller`, `service` e `model`. Para criar uma pasta, informe um nome terminado em `/`, por exemplo `controller/`. Sem a barra final, o Explorer cria um arquivo, e as pastas que faltarem no caminho sao criadas junto. A criacao ocorre dentro da pasta que esta selecionada (o campo mostra qual). Um arquivo novo abre na hora; se for `.java`, o seletor de esqueleto aparece em seguida.

### Arquivo Java novo

Ao abrir um arquivo `.java` novo ou vazio (criado pelo Explorer ou com `:e Nome.java`), um seletor oferece o esqueleto: classe, interface, record, enum, classe abstrata, excecao ou teste JUnit e, em projetos Spring, `@RestController`, `@Service`, `JpaRepository`, `@Configuration` e `@Component`. O `package` vem do caminho (`src/main/java/com/acme/Foo.java` gera `package com.acme;`). O modelo que combina com o nome aparece primeiro: `UserController` sugere o controller e `UserServiceTest` (ou qualquer arquivo em `src/test`) sugere o teste, com JUnit 5 ou 4 conforme o projeto. `Tab` avanca entre os campos do modelo; `Esc` no seletor deixa o arquivo vazio.

## Java: navegacao e LSP

| Atalho | Acao |
|---|---|
| `gd` / `gD` | Ir para definicao / declaracao (em bibliotecas, abre o codigo-fonte com o Javadoc) |
| `grr` / `gri` / `grt` | Listar referencias / implementacoes / ir para o tipo |
| `gO` | Listar simbolos do arquivo |
| `K` | Mostrar documentacao do simbolo |
| `Ctrl+L` | Abrir acoes de codigo (corrigir import, criar metodo...) |
| `F2` | Renomear simbolo |
| `grn` / `gra` | Renomear (igual ao `F2`) / acoes de codigo (igual ao `Ctrl+L`) |
| `Ctrl+Alt+L` | Organizar imports e formatar o arquivo |
| `grx` | Executar a lente sob o cursor (ex.: `2 references` lista as referencias) |
| `Espaco i h` | Mostrar/ocultar dicas inline (nomes de parametros) |
| `[d` / `]d` | Diagnostico anterior / proximo |
| `gl` | Mostrar diagnostico da linha |
| `Ctrl+Espaco` no INSERT | Solicitar sugestoes de autocomplete |
| `Seta cima/baixo` ou `Ctrl+P`/`Ctrl+N` no autocomplete | Escolher sugestao |
| `Enter` no autocomplete | Aceitar a sugestao escolhida; sem escolha, apenas quebra a linha |
| `Ctrl+E` no autocomplete | Fechar o menu e continuar digitando (`Esc` fecha o menu e volta ao NORMAL) |
| `Tab` / `Shift+Tab` | Pular para o proximo/anterior campo de um snippet |

A statusline mostra o estado do jdtls no arquivo Java atual: o percentual da importacao do projeto enquanto ele inicia, tarefas que passam de 1 segundo (compilacao do projeto, por exemplo), `build com problemas` quando o `pom.xml`/`build.gradle` nao pode ser importado por completo e `erro` quando o servidor falha. Pronto e sem tarefas, fica so o icone do Java em verde.

Se o jdtls ficar com erros que nao somem (classes "nao encontradas" que existem, imports quebrados depois de trocar de branch), `:JdtWipeDataAndRestart` apaga o indice do projeto e o importa de novo. `:JdtShowLogs` abre o log do servidor.

## Geracao de codigo (Java)

| Atalho ou comando | Acao |
|---|---|
| `Ctrl+G` | Abrir o menu de geracao: construtor, getters e setters (ou so getters/setters), `equals`/`hashCode`, `toString`, sobrescrever/implementar metodos ou metodos delegados |
| `:JavaGenerate` | O mesmo menu, pela linha de comando |

Comandos equivalentes de cada item: `:JavaGenerateConstructor`, `:JavaGenerateAccessors`, `:JavaGenerateGetters`, `:JavaGenerateSetters`, `:JavaGenerateEqualsHashCode`, `:JavaGenerateToString`, `:JavaOverrideMethods` e `:JavaGenerateDelegateMethods`.

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

## Refatoracao (Java)

| Atalho | Acao |
|---|---|
| `Espaco r v` | Extrair a expressao sob o cursor (ou a selecao) para uma variavel |
| `Espaco r V` | Extrair variavel substituindo todas as ocorrencias da expressao |
| `Espaco r c` | Extrair constante (`private static final`) |
| `Espaco r m` | Extrair metodo; no modo visual, das linhas selecionadas |

Depois da extracao, o campo de renomear abre com o nome sugerido pelo jdtls: digite o nome ou pressione `Esc` para manter a sugestao.

## Snippets (Java)

Digite o prefixo e escolha o item no autocomplete; `Tab` avanca entre os campos. O jdtls ja oferece `sysout`, `foreach`, `fori`, `try_catch`, `ifnull`, `switch` e outros; estes cobrem testes, Spring e logging:

| Prefixo | Gera |
|---|---|
| `test` | Metodo `@Test` com as secoes given/when/then |
| `ptest` | `@ParameterizedTest` com `@CsvSource` |
| `before` | `@BeforeEach void setUp()` |
| `athrows` | `assertThrows` guardando a excecao numa variavel |
| `mockito` | Classe de teste com `@ExtendWith(MockitoExtension.class)`, `@Mock` e `@InjectMocks` |
| `mock` | Campo `@Mock` |
| `springtest` / `webmvctest` | Classe `@SpringBootTest` / `@WebMvcTest` com `MockMvc` |
| `mvcget` / `mvcpost` | Requisicao no `MockMvc` com a verificacao do status |
| `getmap` / `postmap` / `putmap` / `deletemap` | Endpoint com `ResponseEntity`, `@PathVariable` e `@RequestBody @Valid` |
| `valprop` | Campo com `@Value("${propriedade}")` |
| `jpaid` | `@Id` com `@GeneratedValue(strategy = GenerationType.IDENTITY)` |
| `logger` | `Logger` do SLF4J da classe atual |
| `stream` | `lista.stream().filter(...).map(...).toList()` |

Snippets nao adicionam imports: depois de usar um, `Ctrl+Alt+L` importa os tipos. Para `when`, `assertThat` e outros metodos estaticos, prefira o autocomplete normal, que ja adiciona o import estatico.

## Maven e pom.xml

| Atalho ou comando | Acao |
|---|---|
| `Ctrl+Alt+D` no `pom.xml` | Buscar uma dependencia no Maven Central e adiciona-la ao pom |
| `:MavenAddDependency` | O mesmo buscador, pela linha de comando |

No `pom.xml`, o autocomplete sugere as tags validas do Maven para o ponto do arquivo (dentro de `<dependency>`: `scope`, `optional`, `exclusions`...) e tags erradas ficam marcadas. `Ctrl+Alt+L` formata o XML mantendo a indentacao que o arquivo ja usa (TAB ou espacos).

## Build (Maven/Gradle)

O build roda em segundo plano, na raiz do projeto (o pom pai em projetos multi-modulo), com o `mvnw`/`gradlew` do projeto quando existir. Ao falhar, os erros de compilacao e os testes que falharam vao para a quickfix, aberta no Trouble: `Enter` num item leva ao arquivo e a linha.

| Atalho ou comando | Acao |
|---|---|
| `Espaco b c` | Compilar |
| `Espaco b t` | Rodar todos os testes |
| `Espaco b b` | Escolher a tarefa: compilar, testar, empacotar, `verify`, `install`, `clean install`, `clean` ou outro comando |
| `Espaco b l` | Repetir o ultimo build |
| `Espaco b o` | Ver a saida completa do ultimo build |
| `:JavaBuild clean verify` | Rodar o Maven/Gradle com os argumentos informados (sem argumentos, abre o menu) |

Se o `mvnw`/`gradlew` tiver quebras de linha do Windows (clones feitos no Windows), o build avisa e mostra o comando que corrige o arquivo.

## Testes (Java)

Ha duas formas de rodar testes. Os atalhos do jdtls funcionam com JUnit 4 e 5 e rodam pelo depurador; o neotest (JUnit 5) marca cada teste na margem e tem um painel com a arvore do projeto.

### Pelo jdtls (JUnit 4 e 5)

| Atalho | Acao |
|---|---|
| `Espaco t c` | Rodar todos os testes da classe |
| `Espaco t m` | Rodar o teste sob o cursor |
| `Espaco t p` | Escolher um teste da classe para rodar |
| `Espaco t t` | Alternar entre a classe e o seu teste |
| `Espaco t n` | Gerar uma classe de teste para a classe atual |

Os testes rodam pelo depurador: breakpoints marcados com `Ctrl+F8` param a execucao. As falhas vao para a lista quickfix (`:copen`), com a linha e a mensagem da assercao.

### Pelo neotest (JUnit 5)

O neotest marca cada teste com um icone de passou/falhou na margem, mostra a mensagem da falha na propria linha da assercao e abre as falhas no Trouble.

| Atalho | Acao |
|---|---|
| `Espaco t s` | Abrir/fechar o painel com a arvore de testes do projeto (`r` roda o item, `o` mostra a saida) |
| `Espaco t r` | Rodar o teste sob o cursor |
| `Espaco t f` | Rodar os testes do arquivo |
| `Espaco t a` | Rodar todos os testes do projeto |
| `Espaco t l` | Repetir a ultima execucao |
| `Espaco t d` | Depurar o teste sob o cursor (para nos breakpoints do `Ctrl+F8`) |
| `Espaco t o` | Ver a saida completa do teste sob o cursor |
| `Espaco t x` | Interromper a execucao |

Na primeira vez, `:NeotestJava setup` baixa o JUnit Console Launcher que o neotest usa. Ele roda apenas JUnit 5; em projetos com JUnit 4, esses atalhos avisam e os do jdtls (`Espaco t c`, `Espaco t m`...) continuam funcionando.

## Cobertura de testes (JaCoCo)

Roda os testes com o JaCoCo sem alterar o `pom.xml`/`build.gradle` e marca a margem: verde para linha coberta, amarelo para parcial (um `if` testado so para um dos lados, por exemplo) e vermelho para linha que nenhum teste executou. Enquanto a cobertura esta visivel, a margem ganha uma segunda coluna para os sinais do Git continuarem aparecendo.

| Atalho | Acao |
|---|---|
| `Espaco c r` | Rodar os testes com cobertura e mostrar o resultado (testes que falham nao impedem o relatorio) |
| `Espaco c l` | Carregar um relatorio ja gerado (por um `mvn verify` do projeto, por exemplo) |
| `Espaco c t` | Mostrar/esconder a cobertura |
| `Espaco c s` | Resumo por arquivo, com a porcentagem de cada um |
| `]u` / `[u` | Proxima / anterior linha sem cobertura |

Em projetos multi-modulo, a cobertura mostrada e a do modulo do arquivo atual.

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

O painel abre ao iniciar e fecha ao terminar. Nele, `S`/`W`/`B`/`T`/`E`/`R`/`C` trocam de aba e `g?` mostra a ajuda. Salvar um arquivo durante a depuracao aplica a alteracao na JVM em execucao (hot code replace). Para depurar um teste, use `Espaco t m` ou `Espaco t d` (ver Testes).

## Spring Boot

Em projetos com Spring Boot, o Spring Boot Language Server (o mesmo do VS Code) completa e valida `application.yml`/`application.properties`: `server.po` sugere `server.port`, e propriedades inexistentes ficam marcadas. `gd` sobre uma propriedade leva a classe que a define.

| Atalho ou comando | Acao |
|---|---|
| `Ctrl+Alt+I` ou `:SpringInitializr` | Criar um projeto pelo Spring Initializr |
| `Espaco s r` ou `:SpringBootRun` | Rodar a aplicacao (`spring-boot:run`/`bootRun`); se ja estiver rodando, mostrar/esconder os logs |
| `Espaco s s` ou `:SpringBootStop` | Encerrar a aplicacao |
| `Espaco s e` | Buscar endpoints (`@/users -- GET`) e ir ate o mapeamento |
| `Espaco s b` | Buscar beans do projeto |
| `:SpringBoot` | Buscar anotacoes, beans, endpoints ou prototypes (resultado na quickfix) |

A aplicacao roda num terminal proprio, na pasta do modulo do arquivo atual, usando o `mvnw`/`gradlew` do projeto quando existir. Esconder o terminal nao encerra a aplicacao. Para depurar, use `F9` (ver Depuracao).

## HTTP

Em arquivos `.http` (kulala):

| Atalho | Acao |
|---|---|
| `Ctrl+Alt+R` ou `Enter` | Executar a requisicao sob o cursor |
| `Ctrl+Alt+A` | Executar todas as requisicoes do arquivo |
| `Ctrl+Alt+P` | Repetir a ultima requisicao |
| `Ctrl+Alt+N` | Abrir nova requisicao |
| `Espaco R n` / `Espaco R p` | Proxima / anterior requisicao do arquivo |
| `Espaco R e` | Escolher o ambiente (`http-client.env.json`) |
| `Espaco R c` / `Espaco R C` | Copiar a requisicao como cURL / colar um cURL como requisicao |
| `Espaco R t` | Alternar entre cabecalhos e corpo da resposta |
| `Espaco R i` | Inspecionar a requisicao atual |
| `Espaco R q` | Fechar a janela da resposta |

## Git, terminal e paineis

| Atalho | Acao |
|---|---|
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
| `Ctrl+Alt+C` | Tornar o arquivo atual executavel (`chmod +x`) |
| `:Atalhos` | Abrir este guia |
| `:ManualVim` | Abrir no navegador o manual dos modos e comandos do Vim, com exemplos em Java |
| `:DockerLint` | Validar Dockerfile e Compose, quando os arquivos existirem |
| `:PackAdd` / `:PackUpdate` / `:PackDel` | Adicionar / atualizar / remover plugins nativos (`vim.pack`) |
