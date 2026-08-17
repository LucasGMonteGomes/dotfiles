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

      vim.keymap.set("n", "<leader>-", function()
        MiniFiles.open(vim.api.nvim_buf_get_name(0), false)
        MiniFiles.reveal_cwd()
      end, { desc = "Abrir Mini Files no arquivo atual" })

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

      vim.keymap.set("n", "<leader>pf", function()
        MiniPick.builtin.files()
      end, { desc = "Mini: buscar arquivos" })

      vim.keymap.set("n", "<leader>ps", function()
        MiniPick.builtin.grep({ pattern = vim.fn.expand("<cword>") })
      end, { desc = "Mini: buscar palavra" })

      vim.keymap.set("n", "<leader>vh", function()
        MiniPick.builtin.help()
      end, { desc = "Mini: buscar ajuda" })

      vim.keymap.set("n", "<leader>xx", function()
        MiniExtra.pickers.diagnostic()
      end, { desc = "Mini: listar diagnósticos" })

      vim.keymap.set("n", "<leader>pk", function()
        MiniExtra.pickers.keymaps()
      end, { desc = "Mini: buscar atalhos" })

      vim.keymap.set("n", "<leader>gg", "<cmd>tabnew | Git | only<CR>", {
        desc = "Git: abrir Fugitive em nova aba",
      })
      vim.keymap.set("n", "<leader>gd", "<cmd>Gvdiffsplit<CR>", {
        desc = "Git: abrir diff vertical",
      })
    end,
  },
}
