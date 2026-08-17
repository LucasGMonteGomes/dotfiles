return {
  {
    "nvim-mini/mini.nvim",
    version = false,
    lazy = false,
    dependencies = {
      "tpope/vim-fugitive",
    },
    config = function()
      local MiniFiles = require("mini.files")
      MiniFiles.setup({
        mappings = {
          go_in = "<CR>",
          go_in_plus = "L",
          go_out = "_",
          go_out_plus = "H",
        },
      })

      vim.keymap.set("n", "-", function()
        MiniFiles.open()
      end, { desc = "Abrir Mini Files" })

      require("mini.notify").setup({
        content = {
          format = function(notification)
            return notification.msg
          end,
        },
      })

      require("mini.cmdline").setup({
        autocorrect = { enable = false },
      })

      require("mini.surround").setup()

      local MiniPick = require("mini.pick")
      local MiniExtra = require("mini.extra")
      MiniPick.setup()
      MiniExtra.setup()

      vim.keymap.set("n", "<C-A-j>", function()
        MiniPick.builtin.help()
      end, { desc = "Mini: buscar ajuda" })

      vim.keymap.set("n", "<C-A-k>", function()
        MiniExtra.pickers.keymaps()
      end, { desc = "Mini: buscar atalhos" })

      vim.keymap.set("n", "<C-A-m>", "<cmd>tabnew | Git | only<CR>", {
        desc = "Git: abrir Fugitive em nova aba",
      })
    end,
  },
}
