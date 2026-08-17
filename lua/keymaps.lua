vim.g.mapleader = " "

vim.keymap.set("x", "p", [["_dP]], { desc = "Paste over selection without losing yanked text" })

vim.keymap.set({ "n", "v" }, "<C-x>", [["_d]], { desc = "Apagar sem copiar" })

vim.keymap.set("i", "<C-c>", "<Esc>", { desc = "Voltar para o modo NORMAL" })
vim.keymap.set("n", "<C-c>", "i", { desc = "Entrar no modo INSERT" })

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

vim.keymap.set("n", "<C-BS>", "diw", { desc = "Apagar palavra inteira" })
vim.keymap.set("i", "<C-BS>", "<C-w>", { desc = "Apagar palavra anterior" })

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
