-- Servidor Java (jdtls): raiz de projetos multi-modulo, um indice por
-- projeto, todos os JDKs instalados, Lombok e as extensoes de depuracao,
-- testes e Spring Boot. Ativado em plugins/lsp.lua.
local M = {}

-- Nome do ambiente de execucao (JavaSE-21, JavaSE-1.8...) lido do
-- arquivo `release` do JDK; nil quando o diretorio nao e um JDK.
local function java_runtime_name(home)
  local file = io.open(vim.fs.joinpath(home, "release"), "r")
  if not file then
    return nil
  end
  local content = file:read("*a")
  file:close()

  local version = content:match('JAVA_VERSION="([^"]+)"')
  if not version then
    return nil
  end
  local legacy = version:match("^1%.(%d+)")
  return legacy and ("JavaSE-1." .. legacy) or ("JavaSE-" .. version:match("^%d+"))
end

-- Registra todos os JDKs instalados para que cada projeto compile
-- contra a versao declarada no pom.xml/build.gradle. O JDK de
-- JAVA_HOME (ou do `java` no PATH) e o padrao.
local function java_runtimes(default_home)
  local runtimes = {}
  local by_name = {}
  local homes = { default_home }
  for _, pattern in ipairs({ "/usr/lib/jvm/*", "~/.sdkman/candidates/java/*" }) do
    vim.list_extend(homes, vim.fn.glob(pattern, false, true))
  end

  for _, home in ipairs(homes) do
    local real = (vim.uv or vim.loop).fs_realpath(vim.fn.expand(home))
    local name = real and java_runtime_name(real)
    if name and not by_name[name] then
      by_name[name] = true
      table.insert(runtimes, { name = name, path = real, default = #runtimes == 0 })
    end
  end
  return runtimes
end

local build_files = { "pom.xml", "build.gradle", "build.gradle.kts", "build.xml" }

local function has_build_file(directory)
  for _, file in ipairs(build_files) do
    if (vim.uv or vim.loop).fs_stat(vim.fs.joinpath(directory, file)) then
      return true
    end
  end
  return false
end

-- Um projeto multi-modulo deve ter um unico servidor na raiz. O
-- wrapper/settings define essa raiz; sem eles, sobe enquanto os
-- diretorios pais tambem tiverem arquivo de build (pom pai).
local function java_root(path)
  local root = vim.fs.root(path, { "mvnw", "gradlew", "settings.gradle", "settings.gradle.kts" })
  if root then
    return root
  end

  root = vim.fs.root(path, build_files)
  if root then
    local parent = vim.fs.dirname(root)
    while parent ~= root and has_build_file(parent) do
      root = parent
      parent = vim.fs.dirname(root)
    end
    return root
  end

  return vim.fs.root(path, ".git") or vim.fs.dirname(path)
end

-- Indice do projeto (-data). O lspconfig nomeia o workspace so pelo
-- nome da pasta; dois projetos `demo` dividiriam o mesmo indice. O
-- hash do caminho completo separa os dois.
local function jdtls_data_dir(root)
  return vim.fs.joinpath(
    vim.fn.stdpath("cache"),
    "jdtls",
    "workspace",
    vim.fs.basename(root) .. "-" .. vim.fn.sha256(root):sub(1, 8)
  )
end

-- :JdtWipeDataAndRestart e :JdtShowLogs do nvim-jdtls procuram `-data`
-- numa tabela `cmd`; aqui o `cmd` e uma funcao e os dois falham. As
-- versoes abaixo recalculam a pasta pela raiz do cliente.
--
-- Apaga o indice depois que o servidor encerra e sobe o jdtls de novo
-- nos buffers abertos.
local function wipe_jdtls_data(client)
  local data_dir = jdtls_data_dir(client.root_dir or vim.fn.getcwd())
  local answer = vim.fn.confirm("Apagar o indice do jdtls e reiniciar?\n" .. data_dir, "&Sim\n&Nao", 2)
  if answer ~= 1 then
    return
  end

  client:stop()
  local attempts = 0
  local function wipe_when_stopped()
    -- `is_stopped` fica verdadeiro antes de o cliente sair da lista de
    -- ativos; enquanto ele estiver la, o enable o reaproveitaria.
    if vim.lsp.get_client_by_id(client.id) then
      attempts = attempts + 1
      -- Depois de ~5 s sem encerrar, o processo e finalizado a forca.
      if attempts == 50 then
        client:stop(true)
      end
      vim.defer_fn(wipe_when_stopped, 100)
      return
    end
    vim.fn.delete(data_dir, "rf")
    -- Reexecuta o FileType do vim.lsp.enable nos buffers abertos.
    vim.lsp.enable("jdtls")
    vim.notify("Indice apagado; o projeto sera importado de novo.", vim.log.levels.INFO, { title = "JDTLS" })
  end
  wipe_when_stopped()
end

-- Cliente do buffer atual; fora de um arquivo Java (quickfix, Explorer),
-- qualquer jdtls ativo, perguntando qual quando houver mais de um.
local function with_jdtls_client(action)
  return function()
    local clients = vim.lsp.get_clients({ name = "jdtls", bufnr = 0 })
    if #clients == 0 then
      clients = vim.lsp.get_clients({ name = "jdtls" })
    end
    if #clients == 0 then
      vim.notify("Nenhum jdtls em execucao", vim.log.levels.WARN, { title = "JDTLS" })
    elseif #clients == 1 then
      action(clients[1])
    else
      vim.ui.select(clients, {
        prompt = "Qual projeto?",
        format_item = function(client)
          return client.root_dir
        end,
      }, function(client)
        if client then
          action(client)
        end
      end)
    end
  end
end

-- Log do jdtls (erros de importacao do Maven/Gradle) ao lado do log
-- do cliente LSP do Neovim.
local function show_jdtls_logs(client)
  local log = vim.fs.joinpath(jdtls_data_dir(client.root_dir or vim.fn.getcwd()), ".metadata", ".log")
  vim.cmd("split " .. vim.fn.fnameescape(log) .. " | normal! G")
  vim.cmd("vsplit " .. vim.fn.fnameescape(vim.lsp.log.get_filename()) .. " | normal! G")
end

-- Argumentos extras da JVM do jdtls, como no lspconfig:
-- JDTLS_JVM_ARGS="-Xmx4g -Dfoo=bar". O Lombok distribuido pelo
-- pacote jdtls do Mason e carregado como agente para que @Data,
-- @Getter, @Builder etc. sejam entendidos pelo servidor.
local function jdtls_jvm_args()
  local arguments = vim.split(vim.env.JDTLS_JVM_ARGS or "", "%s+", { trimempty = true })
  local lombok = vim.fs.joinpath(vim.fn.stdpath("data"), "mason", "packages", "jdtls", "lombok.jar")
  local has_agent = vim.iter(arguments):any(function(argument)
    return argument:find("lombok", 1, true) ~= nil
  end)
  if not has_agent and (vim.uv or vim.loop).fs_stat(lombok) then
    table.insert(arguments, "-javaagent:" .. lombok)
  end
  return arguments
end

-- Extensoes carregadas dentro do jdtls: java-debug (depurador) e
-- java-test (JUnit/TestNG), ambas instaladas pelo Mason acima.
local function java_bundles()
  local packages = vim.fs.joinpath(vim.fn.stdpath("data"), "mason", "packages")
  local bundles = vim.fn.glob(
    packages .. "/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar",
    true,
    true
  )
  -- O runner e o agente do JaCoCo rodam na JVM do teste, nao no jdtls.
  local excluded = {
    ["com.microsoft.java.test.runner-jar-with-dependencies.jar"] = true,
    ["jacocoagent.jar"] = true,
  }
  for _, jar in ipairs(vim.fn.glob(packages .. "/java-test/extension/server/*.jar", true, true)) do
    if not excluded[vim.fs.basename(jar)] then
      table.insert(bundles, jar)
    end
  end
  -- Extensoes do Spring Boot Tools: dao ao jdtls o classpath que o
  -- servidor do Spring consulta.
  local ok, spring_boot = pcall(require, "spring_boot")
  if ok then
    vim.list_extend(bundles, spring_boot.java_extensions())
  end
  return bundles
end

function M.setup(capabilities)
  local java_executable = vim.fn.exepath("java")
  local java_home = vim.env.JAVA_HOME
  if java_executable ~= "" and (not java_home or java_home == "") then
    local real_java = (vim.uv or vim.loop).fs_realpath(java_executable) or java_executable
    java_home = vim.fs.dirname(vim.fs.dirname(real_java))
  end

  vim.api.nvim_create_user_command("JdtWipeDataAndRestart", with_jdtls_client(wipe_jdtls_data), {
    desc = "Apagar o indice do jdtls do projeto e reiniciar o servidor",
  })
  vim.api.nvim_create_user_command("JdtShowLogs", with_jdtls_client(show_jdtls_logs), {
    desc = "Abrir o log do jdtls e o do cliente LSP",
  })

  local jdtls = require("jdtls")
  local java_extended_capabilities = vim.deepcopy(jdtls.extendedClientCapabilities)
  java_extended_capabilities.resolveAdditionalTextEditsSupport = true
  -- Getters/setters com escolha de campos (java/resolveUnimplementedAccessors),
  -- como no VS Code; o prompt e implementado em features/java/codegen.lua.
  java_extended_capabilities.advancedGenerateAccessorsSupport = true

  -- Java (jdtls)
  local jdtls_config = {
    capabilities = capabilities,
    commands = jdtls.commands,
    init_options = {
      extendedClientCapabilities = java_extended_capabilities,
      bundles = java_bundles(),
    },
    cmd = function(dispatchers, config)
      local command = { "jdtls", "-data", jdtls_data_dir(config.root_dir or vim.fn.getcwd()) }
      for _, argument in ipairs(jdtls_jvm_args()) do
        table.insert(command, "--jvm-arg=" .. argument)
      end

      return vim.lsp.rpc.start(command, dispatchers, {
        cwd = config.cmd_cwd,
        env = config.cmd_env,
        detached = config.detached,
      })
    end,
    handlers = {
      -- Dicas e lentes pedidas antes do fim da importacao do projeto
      -- voltam vazias e nao sao refeitas. Quando o jdtls avisa que
      -- esta pronto, os buffers anexados pedem de novo.
      ["language/status"] = function(_, result, ctx)
        if not result or result.type ~= "ServiceReady" then
          return
        end
        for bufnr in pairs(vim.lsp.get_client_by_id(ctx.client_id).attached_buffers) do
          for _, feature in ipairs({ vim.lsp.inlay_hint, vim.lsp.codelens }) do
            if feature.is_enabled({ bufnr = bufnr }) then
              feature.enable(false, { bufnr = bufnr })
              feature.enable(true, { bufnr = bufnr })
            end
          end
        end
      end,
    },
    root_dir = function(bufnr, on_dir)
      local name = vim.api.nvim_buf_get_name(bufnr)
      if vim.startswith(name, "jdt://") then
        -- Classes de bibliotecas abertas pelo `gd` sao anexadas pelo
        -- nvim-jdtls ao servidor ja existente; nao inicia outro.
        local client = vim.lsp.get_clients({ name = "jdtls", bufnr = vim.fn.bufnr("#") })[1]
          or vim.lsp.get_clients({ name = "jdtls" })[1]
        if client then
          on_dir(client.root_dir)
        end
        return
      end
      on_dir(name ~= "" and java_root(name) or vim.fn.getcwd())
    end,
  }

  jdtls_config.settings = {
    java = {
      configuration = {
        updateBuildConfiguration = "automatic",
      },
      -- Nomes de parametros so em argumentos literais, como no
      -- IntelliJ: `service.find(/* id: */ 42)`.
      inlayHints = {
        parameterNames = { enabled = "literals" },
      },
      -- Contagem de referencias/implementacoes acima de classes e
      -- metodos; `grx` executa a lente sob o cursor.
      referencesCodeLens = { enabled = true },
      implementationsCodeLens = { enabled = true },
      -- O perfil padrao do Eclipse indenta com TAB. Sem isto, o codigo
      -- gerado (construtores, toString, code actions) entra com TAB
      -- em arquivos indentados com 4 espacos (config/options.lua).
      -- O perfil versionado ajusta o padrao do Eclipse ao estilo do
      -- IntelliJ: comentarios nao quebram em 80 colunas nem ganham
      -- linhas com espaco no fim, e quebras feitas a mao ficam.
      format = {
        insertSpaces = true,
        tabSize = 4,
        settings = {
          url = vim.fs.joinpath(vim.fn.stdpath("config"), "formatter", "eclipse-java-style.xml"),
          profile = "dotfiles",
        },
      },
      -- equals/hashCode com Objects.equals/Objects.hash e instanceof
      -- no lugar do estilo do Java 6 (`prime * result`), chaves em
      -- todo if gerado e sem comentarios "TODO Auto-generated".
      codeGeneration = {
        hashCodeEquals = {
          useJava7Objects = true,
          useInstanceof = true,
        },
        useBlocks = true,
        generateComments = false,
      },
      -- Metodos estaticos sugeridos no autocomplete com o import
      -- estatico (`assertThat`, `when`, `get("/api")`). A lista
      -- substitui a padrao do jdtls, por isso repete a do JUnit.
      completion = {
        favoriteStaticMembers = {
          "org.junit.Assert.*",
          "org.junit.Assume.*",
          "org.junit.jupiter.api.Assertions.*",
          "org.junit.jupiter.api.Assumptions.*",
          "org.junit.jupiter.api.DynamicContainer.*",
          "org.junit.jupiter.api.DynamicTest.*",
          "org.mockito.Mockito.*",
          "org.mockito.ArgumentMatchers.*",
          "org.mockito.BDDMockito.*",
          "org.assertj.core.api.Assertions.*",
          "org.hamcrest.Matchers.*",
          "org.hamcrest.MatcherAssert.*",
          "org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*",
          "org.springframework.test.web.servlet.result.MockMvcResultMatchers.*",
        },
      },
    },
  }

  if java_home and java_home ~= "" then
    jdtls_config.cmd_env = { JAVA_HOME = java_home }
    jdtls_config.settings.java.configuration.runtimes = java_runtimes(java_home)
  else
    vim.schedule(function()
      vim.notify(
        "Java não foi encontrado. Instale openjdk-21-jdk ou defina JAVA_HOME.",
        vim.log.levels.WARN,
        { title = "Neovim / JDTLS" }
      )
    end)
  end

  vim.lsp.config("jdtls", jdtls_config)
end

return M
