return {
  {
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
          "regex",
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
            -- <C-s> no modo visual pertence ao stage de selecao do gitsigns.
            scope_incremental = false,
            node_decremental = "<bs>",
          },
        },
      })
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter-context",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    keys = {
      { "<C-A-h>", "<cmd>TSContext toggle<cr>", desc = "Ativar/desativar cabecalho de contexto" },
    },
    opts = {
      enable = true,
      max_lines = 2,
      min_window_height = 20,
      line_numbers = true,
      multiline_threshold = 3,
      trim_scope = "outer",
      mode = "cursor",
    },
  },
}
