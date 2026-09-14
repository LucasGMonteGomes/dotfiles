-- Caminho: C:\Users\Lucas\AppData\Local\nvim\init.lua

vim.loader.enable()
-- A fonte Nerd Font ja esta instalada e e usada pelo Windows Terminal.
-- Este indicador habilita os glifos completos em plugins que o consultam.
vim.g.have_nerd_font = true

vim.g.mapleader = " "
vim.g.maplocalleader = " "

require("config.options")
require("config.keymaps")
require("config.commands")
require("features.docker").setup()
require("features.java.spring").setup()
require("features.java.maven").setup()
require("features.java.codegen").setup()
require("features.markdown").setup()

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

-- 2. Inicializar o Lazy.nvim
require("lazy").setup("plugins", {
  install = {
    colorscheme = { "onedark" },
  },
})
