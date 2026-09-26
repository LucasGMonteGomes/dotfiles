return {
  "iamkarasik/sonarqube.nvim",
  ft = { "java" },
  dependencies = {
    "lewis6991/gitsigns.nvim",
  },
  config = function()
    local extension_path = vim.fn.stdpath("data")
      .. "/mason/packages/sonarlint-language-server/extension"
    local java = vim.fn.exepath("java")
    local server_jar = extension_path .. "/server/sonarlint-ls.jar"

    if java == "" then
      vim.notify(
        "SonarLint desativado: Java não foi encontrado no PATH",
        vim.log.levels.WARN,
        { title = "SonarQube" }
      )
      return
    end

    -- O Mason instala o pacote automaticamente (plugins/lsp.lua) e avisa
    -- quando terminar. Ate la, o SonarLint fica desligado sem interromper a
    -- abertura do arquivo com um aviso.
    if not (vim.uv or vim.loop).fs_stat(server_jar) then
      return
    end

    require("sonarqube").setup({
      lsp = {
        cmd = {
          java,
          "-jar",
          server_jar,
          "-stdio",
          "-analyzers",
          extension_path .. "/analyzers/sonarjava.jar",
          extension_path .. "/analyzers/sonarjavasymbolicexecution.jar",
        },
        -- Diagnosticos continuam ativos; apenas o log textual invasivo fica oculto.
        log_level = "OFF",
      },
      rules = {
        enabled = true,
      },
      java = {
        enabled = true,
        await_jdtls = true,
      },
      csharp = { enabled = false },
      go = { enabled = false },
      html = { enabled = false },
      iac = { enabled = false },
      javascript = { enabled = false },
      php = { enabled = false },
      python = { enabled = false },
      text = { enabled = false },
      xml = { enabled = false },
    })

    -- O plugin ainda usa a forma antiga `client.notify`. Esta adaptacao evita
    -- o aviso de API obsoleta no Neovim 0.12 sem alterar o plugin instalado.
    -- A integracao com o jdtls tambem chama `client.request(...)`, que gera
    -- o aviso `client.request is deprecated` ao abrir arquivos Java. O
    -- cliente e entregue com `request` redirecionado para `client:request`.
    local java = require("sonarqube.java")
    java.get_jdtls = function()
      return vim.tbl_map(function(client)
        return setmetatable({
          request = function(...)
            return client:request(...)
          end,
        }, { __index = client })
      end, vim.lsp.get_clients({ name = "jdtls" }))
    end

    local server = require("sonarqube.lsp.server")
    server.did_change_configuration = function(client)
      client = client or vim.lsp.get_clients({ name = "sonarqube" })[1]
      if client then
        client:notify("workspace/didChangeConfiguration", {
          settings = server.settings,
        })
      end
    end
  end,
}
