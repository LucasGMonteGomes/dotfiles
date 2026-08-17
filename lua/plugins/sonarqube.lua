return {
  "iamkarasik/sonarqube.nvim",
  ft = { "java" },
  dependencies = {
    "lewis6991/gitsigns.nvim",
  },
  config = function()
    local extension_path = vim.fn.stdpath("data")
      .. "/mason/packages/sonarlint-language-server/extension"
    local java = [[C:\Program Files\Java\jdk-21\bin\java.exe]]

    require("sonarqube").setup({
      lsp = {
        cmd = {
          java,
          "-jar",
          extension_path .. "/server/sonarlint-ls.jar",
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
