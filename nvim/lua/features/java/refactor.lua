-- Refatoracoes de extracao do jdtls (variavel, constante e metodo), como o
-- Ctrl+Alt+V/C/M do IntelliJ. No terminal, Ctrl+Alt+V ja e do Diffview,
-- Ctrl+Alt+C do chmod e Ctrl+Alt+M chega igual a Alt+Enter; por isso os
-- atalhos ficam em <leader>r.
local M = {}

local function notify(message, level)
  vim.notify(message, level or vim.log.levels.INFO, { title = "Java" })
end

-- O jdtls escolhe um nome (`string`, `extracted`) e deixa o cursor sobre ele.
-- O rename abre em seguida com esse nome preenchido; Esc mantem a sugestao.
local function rename_extracted()
  vim.schedule(function()
    vim.lsp.buf.rename(nil, { name = "jdtls" })
  end)
end

-- `entity`: variable, variable_all, constant ou method. `visual` usa a
-- selecao ('< e '>) no lugar da expressao sob o cursor.
function M.extract(entity, visual)
  if not vim.lsp.get_clients({ bufnr = 0, name = "jdtls" })[1] then
    notify("O servidor Java ainda nao esta conectado a este arquivo", vim.log.levels.WARN)
    return
  end
  require("jdtls")["extract_" .. entity]({ visual = visual, name = rename_extracted })
end

local actions = {
  { "v", "variable", "Java: extrair variavel" },
  { "V", "variable_all", "Java: extrair variavel (todas as ocorrencias)" },
  { "c", "constant", "Java: extrair constante" },
  { "m", "method", "Java: extrair metodo" },
}

function M.setup()
  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("JavaRefactorKeymaps", { clear = true }),
    pattern = "java",
    callback = function(event)
      for _, action in ipairs(actions) do
        local lhs, entity, desc = "<leader>r" .. action[1], action[2], action[3]
        vim.keymap.set("n", lhs, function()
          M.extract(entity, false)
        end, { buffer = event.buf, silent = true, desc = desc })
        -- As marcas '< e '> so sao gravadas ao sair do modo visual.
        vim.keymap.set("x", lhs, function()
          vim.cmd("normal! \27")
          M.extract(entity, true)
        end, { buffer = event.buf, silent = true, desc = desc .. " da selecao" })
      end
    end,
  })
end

return M
