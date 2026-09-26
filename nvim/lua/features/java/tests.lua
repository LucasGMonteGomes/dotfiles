-- Execucao de testes JUnit/TestNG pelo java-test carregado no jdtls. Os
-- testes rodam como sessoes do nvim-dap: breakpoints funcionam e as falhas
-- vao para a quickfix.
local M = {}

local function notify(message, level)
  vim.notify(message, level or vim.log.levels.INFO, { title = "Java" })
end

-- Os comandos dependem do jdtls anexado ao buffer e do bundle java-test.
local function with_jdtls(action)
  return function()
    if not vim.lsp.get_clients({ bufnr = 0, name = "jdtls" })[1] then
      notify("O servidor Java ainda nao esta conectado a este arquivo", vim.log.levels.WARN)
      return
    end
    action()
  end
end

local actions = {
  { "<leader>tc", function() require("jdtls").test_class() end, "Java: testar a classe" },
  { "<leader>tm", function() require("jdtls").test_nearest_method() end, "Java: testar o metodo sob o cursor" },
  { "<leader>tp", function() require("jdtls").pick_test() end, "Java: escolher um teste da classe" },
  { "<leader>tt", function() require("jdtls.tests").goto_subjects() end, "Java: alternar entre classe e teste" },
  { "<leader>tn", function() require("jdtls.tests").generate() end, "Java: gerar classe de teste" },
}

function M.setup()
  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("JavaTestKeymaps", { clear = true }),
    pattern = "java",
    callback = function(event)
      for _, action in ipairs(actions) do
        vim.keymap.set("n", action[1], with_jdtls(action[2]), {
          buffer = event.buf,
          silent = true,
          desc = action[3],
        })
      end
    end,
  })
end

return M
