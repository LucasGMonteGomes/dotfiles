vim.g.netrw_banner = 0

vim.opt.number = true
vim.opt.relativenumber = false

vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

vim.opt.wrap = false
vim.opt.smartindent = true
vim.opt.inccommand = "split"

vim.opt.splitbelow = true
vim.opt.splitright = true

vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.laststatus = 3

vim.opt.swapfile = false
vim.opt.backup = false
local undo_dir = vim.fn.stdpath("data") .. "/undodir"
if vim.fn.isdirectory(undo_dir) == 0 then
  local created, create_error = pcall(vim.fn.mkdir, undo_dir, "p")
  if not created and vim.fn.isdirectory(undo_dir) == 0 then
    error("Não foi possível criar o diretório de undo: " .. create_error)
  end
end
vim.opt.undodir = undo_dir
vim.opt.undofile = true

vim.opt.completeopt = "menuone,noselect,fuzzy,nosort"
vim.opt.shortmess:append("c")
vim.opt.clipboard:append("unnamedplus")
vim.opt.isfname:append("@-@")
vim.opt.guicursor = "n-v-c-sm:block,i-ci-ve:ver25,r-cr-o:hor20,t:block"
vim.opt.scrolloff = 8
vim.opt.cursorline = true
vim.opt.cursorlineopt = "line,number"

vim.opt.colorcolumn = "0"
vim.opt.signcolumn = "yes"
vim.o.cmdheight = 0
vim.opt.mouse = "a"
vim.opt.termguicolors = true
-- Usado por interfaces graficas; no terminal, a fonte e definida pelo Windows Terminal.
vim.opt.guifont = "JetBrainsMono Nerd Font Mono:h13"

vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("HighlightYank", { clear = true }),
  desc = "Highlight when yanking (copying) text",
  callback = function()
    vim.hl.on_yank()
  end,
})
