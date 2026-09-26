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
        -- Descartar um bloco apaga alteracoes que nao estao salvas no Git;
        -- por isso pede confirmacao, com "Nao" como resposta padrao.
        local function confirm_reset(range)
          if vim.fn.confirm("Descartar as alteracoes deste bloco?", "&Sim\n&Nao", 2) == 1 then
            gs.reset_hunk(range)
          end
        end
        map("n", "<C-q>", function()
          confirm_reset()
        end, "Git: desfazer bloco")
        map("v", "<C-q>", function()
          confirm_reset({ vim.fn.line("."), vim.fn.line("v") })
        end, "Git: desfazer selecao")
        -- Ctrl+G pertence ao menu de geracao nos arquivos Java. Fora deles,
        -- continua sendo o atalho rapido para visualizar o bloco do Git.
        if vim.bo[bufnr].filetype ~= "java" then
          map("n", "<C-g>", gs.preview_hunk, "Git: visualizar bloco")
        end
        map("n", "<C-b>", function()
          gs.blame_line({ full = true })
        end, "Git: autoria da linha")
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
      {
        "<C-A-v>",
        function()
          local view = require("diffview.lib").get_current_view()
          if view then
            view:close()
          else
            vim.cmd("DiffviewOpen")
          end
        end,
        desc = "Git: abrir/fechar alterações",
      },
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
