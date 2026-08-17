-- Caminho: C:\Users\Lucas\AppData\Local\nvim\init.lua

require("vim._core.ui2").enable({})

vim.g.mapleader = " "
vim.g.maplocalleader = " "

require("options")
require("keymaps")
require("commands")
require("spring_initializr").setup()
require("maven_dependency").setup()
require("java_codegen").setup()

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
