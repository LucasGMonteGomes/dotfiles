-- Atalhos globais do editor.

vim.keymap.set("x", "p", [["_dP]], { desc = "Paste over selection without losing yanked text" })

vim.keymap.set({ "n", "v" }, "<C-x>", [["_d]], { desc = "Apagar sem copiar" })

vim.keymap.set("i", "<C-c>", "<Esc>", { desc = "Voltar para o modo NORMAL" })
vim.keymap.set("n", "<C-c>", "i", { desc = "Entrar no modo INSERT" })

-- Alterna somente entre janelas de arquivos. Explorer, terminal e janelas
-- flutuantes nao entram no ciclo, portanto dois arquivos em split alternam
-- diretamente entre si com Ctrl+Tab.
local function next_file_window()
  local file_windows = {}
  for _, window in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local buffer = vim.api.nvim_win_get_buf(window)
    local floating = vim.api.nvim_win_get_config(window).relative ~= ""
    if not floating and vim.bo[buffer].buftype == "" and vim.bo[buffer].filetype ~= "snacks_picker_list" then
      table.insert(file_windows, window)
    end
  end

  if #file_windows < 2 then
    return
  end

  local current = vim.api.nvim_get_current_win()
  for index, window in ipairs(file_windows) do
    if window == current then
      vim.api.nvim_set_current_win(file_windows[index % #file_windows + 1])
      return
    end
  end
  vim.api.nvim_set_current_win(file_windows[1])
end

vim.keymap.set({ "n", "i" }, "<C-Tab>", next_file_window, {
  desc = "Alternar entre arquivos divididos",
})
-- Alguns terminais encaminham Ctrl+Tab como CSI-u (`Esc [ 9 ; 5 u`). A
-- segunda ligacao preserva a compatibilidade com esses emuladores.
vim.keymap.set({ "n", "i" }, "\27[9;5u", next_file_window, {
  desc = "Alternar entre arquivos divididos",
})

-- Esc pode fechar o menu de autocomplete, mas nao troca INSERT por NORMAL.
-- A troca entre os dois modos fica exclusivamente no Ctrl+C.
vim.keymap.set("i", "<Esc>", function()
  if vim.fn.pumvisible() == 1 then
    return "<C-e>"
  end
  return ""
end, {
  expr = true,
  replace_keycodes = true,
  desc = "Fechar autocomplete sem sair do modo INSERT",
})

vim.keymap.set("n", "<C-z>", "u", { desc = "Desfazer ultima alteracao" })
vim.keymap.set("i", "<C-z>", "<C-o>u", { desc = "Desfazer ultima alteracao" })
vim.keymap.set("n", "<C-A-z>", "<C-r>", { desc = "Refazer ultima alteracao" })

-- Cada terminal pode codificar Ctrl+Backspace de uma forma diferente. Estes
-- formatos cobrem terminais com CSI-u e interfaces graficas do Neovim.
local ctrl_backspace_inputs = {
  "<C-BS>",
  "<C-h>",
  "\27[127;5u",
  "\27[8;5u",
  "\27[3;5~",
}

for _, key in ipairs(ctrl_backspace_inputs) do
  vim.keymap.set("n", key, "diw", { desc = "Apagar palavra inteira" })
  vim.keymap.set("i", key, "<C-w>", { desc = "Apagar palavra anterior" })
end

-- Movimentos por WORD incluem pontuacao. Em `firstName;`, Ctrl+Right para no `;`.
vim.keymap.set("n", "<C-Right>", "E", { desc = "Ir ao final do trecho atual" })
vim.keymap.set("n", "<C-Left>", "B", { desc = "Ir ao inicio do trecho atual" })
vim.keymap.set("i", "<C-Right>", "<C-o>E", { desc = "Ir ao final do trecho atual" })
vim.keymap.set("i", "<C-Left>", "<C-o>B", { desc = "Ir ao inicio do trecho atual" })

vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "moves lines down in visual selection" })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "moves lines up in visual selection" })

vim.keymap.set("v", "<", "<gv", { desc = "Unindent and keep selection" })
vim.keymap.set("v", ">", ">gv", { desc = "Indent and keep selection" })

vim.keymap.set("n", "J", "mzJ`z", { desc = "Join lines without moving cursor" })

vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "move down in buffer with cursor centered" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "move up in buffer with cursor centered" })

vim.keymap.set("n", "n", "nzzzv", { desc = "Next search result cursor centered" })
vim.keymap.set("n", "N", "Nzzzv", { desc = "Previous search result cursor centered" })

vim.keymap.set("n", "<C-r>", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], { desc = "Substituir palavra no arquivo" })

if vim.fn.has("win32") == 0 then
  vim.keymap.set("n", "<C-A-c>", "<cmd>!chmod +x %<CR>", { silent = true, desc = "Tornar arquivo executavel" })
end

vim.keymap.set("n", "<C-A-q>", "<cmd>restart<cr>", { desc = "Reiniciar configuracao" })

-- native undotree
vim.keymap.set("n", "<C-A-u>", function()
  vim.cmd.packadd("nvim.undotree")
  require("undotree").open()
end, { desc = "Toggle Builtin Undotree" })
