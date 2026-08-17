return {
  "nvim-treesitter/nvim-treesitter",
  branch = "master",
  build = ":TSUpdate",
  event = { "BufReadPost", "BufNewFile" },
  cmd = { "TSInstall", "TSBufEnable", "TSBufDisable", "TSModuleInfo", "TSUpdate" },
  config = function()
    require("nvim-treesitter.install").compilers = { "gcc" }
    require("nvim-treesitter.install").prefer_git = true

    require("nvim-treesitter.configs").setup({
      ensure_installed = {
        "java",
        "rust",
        "json",
        "yaml",
        "toml",
        "xml",
        "markdown",
        "markdown_inline",
        "bash",
        "http",
        "dockerfile",
        "lua",
        "vim",
        "vimdoc",
        "query",
      },
      sync_install = false,
      auto_install = true,
      highlight = {
        enable = true,
        additional_vim_regex_highlighting = false,
      },
      indent = {
        enable = true,
      },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "<C-space>",
          node_incremental = "<C-space>",
          scope_incremental = "<C-s>",
          node_decremental = "<bs>",
        },
      },
    })
  end,
}
