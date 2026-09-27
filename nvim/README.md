# Neovim

Configuração do Neovim 0.12 pensada para desenvolvimento Java e Spring Boot,
com o conforto de uma IDE (IntelliJ como referência de atalhos) sem perder a
edição do Vim. Também atende Rust, Lua, YAML, Docker e Markdown.

<img width="1338" height="677" alt="Neovim com um projeto Java aberto" src="https://github.com/user-attachments/assets/3d205699-583f-48af-814c-d02c54e97b7c" />

Todos os atalhos estão em [ATALHOS.md](ATALHOS.md), que também abre dentro do
editor com `:Atalhos`. Para aprender os modos e os comandos de edição do Vim,
o [manual com exemplos animados em Java](manual-vim.html) abre no navegador
com `:ManualVim` (ou direto pelo arquivo).

## Java e Spring Boot

| Área | O que a configuração oferece |
| --- | --- |
| Servidor Java (jdtls) | Um índice por projeto, raiz correta em projetos multi-módulo, todos os JDKs instalados registrados (cada projeto compila na versão do `pom.xml`/`build.gradle`), Lombok e código-fonte das bibliotecas com Javadoc no `gd` |
| Andamento na statusline | Percentual da importação do projeto, tarefas longas do jdtls e aviso de build com problemas |
| Geração de código | Menu `Ctrl+G` com construtor, getters/setters, `equals`/`hashCode` (com `Objects`), `toString`, sobrescrever e delegar métodos, sempre com seletor de campos |
| Refatoração | Extrair variável, constante e método, abrindo o rename com o nome sugerido |
| Arquivo novo | Esqueleto com o `package` do caminho: classe, interface, record, enum, exceção, teste JUnit e, em projetos Spring, controller, service, repository e configuration |
| Snippets | Testes (given/when/then, parametrizado, Mockito), MockMvc, endpoints REST, `@Value`, JPA, logger e stream |
| Formatação | Perfil do Eclipse versionado ([formatter/eclipse-java-style.xml](formatter/eclipse-java-style.xml)) ajustado ao estilo do IntelliJ; organizar imports sem tipos internos do JDK (`java.awt.List`, `com.sun.*`) |
| Build | Maven/Gradle em segundo plano pelo `mvnw`/`gradlew` do projeto, com erros de compilação e testes que falharam na quickfix |
| Testes | Pelo jdtls (JUnit 4 e 5, pelo depurador) ou pelo neotest (JUnit 5, com resultado na margem e painel com a árvore do projeto) |
| Cobertura | JaCoCo sem alterar o build: linhas cobertas, parciais e sem cobertura na margem e resumo por arquivo |
| Depuração | nvim-dap com teclas do IntelliJ (`F7`/`F8`/`F9`), breakpoint condicional e hot code replace |
| Spring Boot | Spring Boot Language Server (completa e valida `application.yml`/`.properties`), busca de endpoints e beans, rodar a aplicação e criar projetos pelo Spring Initializr |
| Maven | Busca de dependências no Maven Central direto do `pom.xml`, que tem completar e validar pelo XSD (lemminx) |
| Qualidade | SonarLint com as regras do SonarQube para Java |
| HTTP | Arquivos `.http` executados no editor (kulala) |

## Requisitos

- Neovim 0.12 ou mais recente;
- JDK 21 ou mais recente para rodar o jdtls, encontrado pelo `JAVA_HOME` ou
  pelo `java` do `PATH`. Projetos em outras versões usam os demais JDKs
  instalados (em `/usr/lib/jvm` ou no SDKMAN), registrados automaticamente;
- Maven ou Gradle quando o projeto não tiver `mvnw`/`gradlew`;
- `git`, `curl`, `unzip`, um compilador C (parsers do tree-sitter), `ripgrep`
  e `fd` (buscas), Node.js com npm (servidores que o Mason instala pelo npm,
  como o do YAML) e uma Nerd Font no terminal.

O [README da raiz](../README.md) tem os comandos de instalação para o Debian.

## Primeira execução

Na primeira abertura, o `lazy.nvim` instala os plugins nas versões do
[lazy-lock.json](lazy-lock.json) e o Mason instala em segundo plano os
servidores de linguagem e as ferramentas: jdtls, java-debug-adapter,
java-test, Spring Boot Tools, SonarLint, lemminx e os demais. Cada instalação
avisa quando termina; reinicie o Neovim (`Ctrl+Alt+Q`) depois delas.

Para os testes pelo neotest, baixe uma vez o JUnit Console Launcher:

```vim
:NeotestJava setup
```

Para conferir a instalação:

```vim
:checkhealth
```

## Estrutura

```text
nvim/
├── init.lua              carrega as opções, os recursos e o lazy.nvim
├── lua/config/           opções, atalhos globais e comandos do editor
├── lua/plugins/          um arquivo por plugin ou grupo (lazy.nvim)
├── lua/features/         recursos próprios escritos para esta configuração
│   ├── java/             jdtls, geração, refatoração, build, testes,
│   │                     cobertura, Spring, Maven e statusline
│   ├── docker.lua        :DockerLint
│   └── markdown.lua      preview e corretor ortográfico
├── snippets/java.json    snippets Java carregados pelo blink.cmp
├── formatter/            perfil de formatação Java do jdtls
├── gradle/               init script do JaCoCo para projetos Gradle
├── after/queries/        ajustes de destaque de sintaxe do Java
├── ATALHOS.md            guia de atalhos (:Atalhos)
└── manual-vim.html       manual dos modos do Vim com exemplos (:ManualVim)
```

## Personalização

- `JDTLS_JVM_ARGS`: argumentos extras da JVM do jdtls, por exemplo
  `export JDTLS_JVM_ARGS="-Xmx4g"` para projetos grandes.
- `NVIM_TERMINAL_SHELL`: shell do terminal integrado (`Ctrl+T`), por exemplo
  `export NVIM_TERMINAL_SHELL='pwsh -NoLogo'`.
- Se o jdtls ficar com erros que não somem, `:JdtWipeDataAndRestart` apaga o
  índice do projeto e o importa de novo.
