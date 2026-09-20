return {
  "folke/trouble.nvim",
  cmd = "Trouble",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  opts = {
    focus = true,
    auto_close = true,
    warn_no_results = false,
    open_no_results = true,
    keys = {
      ["<esc>"] = "close",
    },
  },
  keys = {
    {
      "<C-A-x>",
      "<cmd>Trouble diagnostics toggle focus=true<cr>",
      desc = "Problemas de todo o projeto",
    },
    {
      "<C-A-t>",
      "<cmd>Trouble diagnostics toggle focus=true filter.buf=0<cr>",
      desc = "Problemas do arquivo atual",
    },
  },
}
