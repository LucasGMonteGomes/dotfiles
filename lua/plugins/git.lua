return {
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      current_line_blame = false,
      signs = {
        add = { text = "┃" },
        change = { text = "┃" },
        delete = { text = "_" },
        topdelete = { text = "‾" },
        changedelete = { text = "~" },
        untracked = { text = "┆" },
      },
      on_attach = function(bufnr)
        local gs = require("gitsigns")
        local function map(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
        end

        map("n", "]h", function()
          if vim.wo.diff then
            vim.cmd.normal({ "]c", bang = true })
          else
            gs.nav_hunk("next")
          end
        end, "Git: proximo bloco alterado")

        map("n", "[h", function()
          if vim.wo.diff then
            vim.cmd.normal({ "[c", bang = true })
          else
            gs.nav_hunk("prev")
          end
        end, "Git: bloco alterado anterior")

        map("n", "<C-s>", gs.stage_hunk, "Git: adicionar bloco ao stage")
        map("v", "<C-s>", function()
          gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end, "Git: adicionar selecao ao stage")
        map("n", "<C-q>", gs.reset_hunk, "Git: desfazer bloco")
        map("v", "<C-q>", function()
          gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end, "Git: desfazer selecao")
        map("n", "<C-g>", gs.preview_hunk, "Git: visualizar bloco")
        map("n", "<C-b>", function()
          gs.blame_line({ full = true })
        end, "Git: autoria da linha")
        map("n", "<C-y>", gs.toggle_current_line_blame, "Git: alternar autoria nas linhas")
        map("n", "<C-o>", gs.stage_buffer, "Git: adicionar arquivo ao stage")
        map("n", "<C-A-q>", function()
          local answer = vim.fn.confirm(
            "Descartar todas as alteracoes Git deste arquivo?",
            "&Nao\n&Sim",
            1
          )
          if answer == 2 then
            gs.reset_buffer()
          end
        end, "Git: desfazer alteracoes do arquivo")
        map("n", "<C-A-d>", gs.diffthis, "Git: comparar arquivo com o indice")
        map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "Git: selecionar bloco alterado")
      end,
    },
  },
  {
    "sindrets/diffview.nvim",
    cmd = {
      "DiffviewOpen",
      "DiffviewClose",
      "DiffviewFileHistory",
      "DiffviewToggleFiles",
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    keys = {
      { "<C-t>", "<cmd>DiffviewOpen<CR>", desc = "Git: visualizar todas as alteracoes" },
      { "<C-h>", "<cmd>DiffviewFileHistory %<CR>", desc = "Git: historico do arquivo" },
      { "<C-k>", "<cmd>DiffviewFileHistory<CR>", desc = "Git: historico do projeto" },
      { "<C-j>", "<cmd>DiffviewClose<CR>", desc = "Git: fechar visualizacao" },
    },
    opts = {
      enhanced_diff_hl = true,
      view = {
        merge_tool = {
          layout = "diff3_mixed",
        },
      },
    },
  },
}
