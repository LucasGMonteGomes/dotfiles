return {
  {
    "nvim-mini/mini.nvim",
    version = false,
    lazy = false,
    config = function()
      -- Mesma base de icones do repositório de referência. O mock faz com que
      -- Snacks, Lualine e outros plugins usem um único conjunto consistente.
      require("mini.icons").setup({
        style = "glyph",
      })
      MiniIcons.mock_nvim_web_devicons()

      require("mini.cmdline").setup({
        autocorrect = { enable = false },
      })

      require("mini.surround").setup()
      require("mini.pairs").setup()

      local indentscope = require("mini.indentscope")
      indentscope.setup({
        symbol = "│",
        draw = {
          delay = 0,
          animation = indentscope.gen_animation.none(),
        },
        options = {
          border = "both",
          indent_at_cursor = false,
          try_as_border = true,
        },
      })

      local scope_group = vim.api.nvim_create_augroup("MinimalIndentScope", { clear = true })
      vim.api.nvim_create_autocmd("FileType", {
        group = scope_group,
        pattern = {
          "snacks_layout_box",
          "snacks_picker_input",
          "snacks_picker_list",
          "oil",
          "trouble",
          "lazy",
          "mason",
          "help",
          "qf",
          "toggleterm",
          "terminal",
          "http",
          "markdown",
        },
        callback = function()
          vim.b.miniindentscope_disable = true
        end,
      })
      vim.api.nvim_create_autocmd("TermOpen", {
        group = scope_group,
        callback = function()
          vim.b.miniindentscope_disable = true
        end,
      })
    end,
  },
}
