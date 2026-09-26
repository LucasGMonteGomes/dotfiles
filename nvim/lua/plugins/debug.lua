-- Depuracao com nvim-dap. As teclas seguem o IntelliJ: no GNOME Terminal,
-- F10 abre o menu e F11 alterna a tela cheia, entao o esquema do VS Code
-- nao chegaria ao Neovim.
local function dap_call(method)
  return function()
    require("dap")[method]()
  end
end

local function conditional_breakpoint()
  vim.ui.input({ prompt = "Condicao do breakpoint: " }, function(condition)
    if condition and condition ~= "" then
      require("dap").set_breakpoint(condition)
    end
  end)
end

-- Terminais podem enviar Shift/Ctrl+F<n> como teclas de funcao "altas"
-- (Shift+F8 = F20, Ctrl+F8 = F32, Ctrl+F2 = F26); as duas formas sao mapeadas.
local function keys_for(lhs_list, rhs, desc)
  local keys = {}
  for _, lhs in ipairs(lhs_list) do
    table.insert(keys, { lhs, rhs, desc = desc })
  end
  return keys
end

local keys = {}
for _, group in ipairs({
  keys_for({ "<F9>" }, dap_call("continue"), "Debug: iniciar/continuar"),
  keys_for({ "<F8>" }, dap_call("step_over"), "Debug: executar linha (step over)"),
  keys_for({ "<F7>" }, dap_call("step_into"), "Debug: entrar no metodo (step into)"),
  keys_for({ "<S-F8>", "<F20>" }, dap_call("step_out"), "Debug: sair do metodo (step out)"),
  keys_for({ "<C-F8>", "<F32>" }, dap_call("toggle_breakpoint"), "Debug: alternar breakpoint"),
  keys_for({ "<C-F2>", "<F26>" }, dap_call("terminate"), "Debug: encerrar sessao"),
  keys_for({ "<leader>db" }, conditional_breakpoint, "Debug: breakpoint condicional"),
  keys_for({ "<leader>dl" }, dap_call("run_last"), "Debug: repetir ultima sessao"),
  keys_for({ "<leader>du" }, "<cmd>DapViewToggle<cr>", "Debug: abrir/fechar painel"),
  keys_for({ "<leader>dh" }, "<cmd>DapViewHover<cr>", "Debug: inspecionar valor sob o cursor"),
}) do
  vim.list_extend(keys, group)
end

return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "igorlfs/nvim-dap-view",
      "mfussenegger/nvim-jdtls",
    },
    keys = keys,
    config = function()
      -- Glifos Nerd Font gerados pelo codigo para nao depender de caracteres
      -- de uso privado no arquivo: circulo, interrogacao, proibido, balao e seta.
      local glyph = vim.fn.nr2char
      vim.fn.sign_define("DapBreakpoint", { text = glyph(0xf111), texthl = "DiagnosticError" })
      vim.fn.sign_define("DapBreakpointCondition", { text = glyph(0xf059), texthl = "DiagnosticWarn" })
      vim.fn.sign_define("DapBreakpointRejected", { text = glyph(0xf05e), texthl = "DiagnosticHint" })
      vim.fn.sign_define("DapLogPoint", { text = glyph(0xf075), texthl = "DiagnosticInfo" })
      vim.fn.sign_define("DapStopped", { text = glyph(0xf061), texthl = "DiagnosticOk", linehl = "Visual" })

      -- Registra o adaptador `java` (via java-debug no jdtls) e a descoberta
      -- automatica das classes `main` ao iniciar com F9. Com hotcodereplace,
      -- salvar o arquivo durante a depuracao aplica a alteracao na JVM.
      require("jdtls").setup_dap({ hotcodereplace = "auto" })
    end,
  },
  {
    "igorlfs/nvim-dap-view",
    lazy = true,
    opts = {
      -- Abre o painel ao iniciar a sessao e fecha ao terminar.
      auto_toggle = true,
      winbar = {
        sections = { "scopes", "watches", "breakpoints", "threads", "exceptions", "repl", "console" },
        default_section = "scopes",
        controls = { enabled = true },
      },
    },
  },
}
