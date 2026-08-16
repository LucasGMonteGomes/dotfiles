-- Caminho: C:\Users\Lucas\AppData\Local\nvim\init.lua

-- 1. Bootstrap do Lazy.nvim (Baixa o gerenciador de plugins)
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- 2. Configurações visuais e básicas do Neovim
vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.opt.number = true
vim.opt.relativenumber = false
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.mouse = "a"
vim.opt.termguicolors = true
vim.opt.guifont = "JetBrainsMono Nerd Font:h11,JetBrains Mono:h11"

-- 3. Inicializar o Lazy.nvim
require("lazy").setup("plugins", {
  install = {
    colorscheme = { "gruvbox" }, 
  },
})
