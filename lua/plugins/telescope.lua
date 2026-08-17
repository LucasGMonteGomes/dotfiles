return {
  "nvim-telescope/telescope.nvim",
  tag = "0.1.8",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
  },
  cmd = "Telescope",
  keys = {
    -- Atalho solicitado
    { "<C-p>", "<cmd>Telescope find_files<cr>", desc = "Buscar Arquivos (Find Files)" },
    { "<C-f>", "<cmd>Telescope live_grep<cr>", desc = "Buscar Texto no Projeto (Live Grep)" },

    { "<C-a>", "<cmd>Telescope find_files hidden=true no_ignore=true<cr>", desc = "Buscar Todos Arquivos (inc. ocultos)" },
    { "<C-A-w>", "<cmd>Telescope grep_string<cr>", desc = "Buscar Palavra sob o Cursor" },
    { "<C-A-b>", "<cmd>Telescope buffers<cr>", desc = "Buscar Buffers Abertos" },
    { "<C-e>", "<cmd>Telescope oldfiles<cr>", desc = "Arquivos Recentes" },
    { "<C-A-x>", "<cmd>Telescope diagnostics<cr>", desc = "Listar Erros e Avisos (LSP)" },
    { "<C-A-s>", "<cmd>Telescope lsp_document_symbols<cr>", desc = "Buscar Símbolos no Arquivo (Classes, Métodos)" },
    { "<C-A-y>", "<cmd>Telescope lsp_dynamic_workspace_symbols<cr>", desc = "Buscar Símbolos no Projeto Inteiro" },
  },
  config = function()
    local telescope = require("telescope")
    local actions = require("telescope.actions")

    telescope.setup({
      defaults = {
        prompt_prefix = "   ",
        selection_caret = " ❯ ",
        entry_prefix = "   ",
        initial_mode = "insert",
        selection_strategy = "reset",
        sorting_strategy = "ascending",
        layout_strategy = "horizontal",
        layout_config = {
          horizontal = {
            prompt_position = "top",
            preview_width = 0.55,
            results_width = 0.8,
          },
          vertical = {
            mirror = false,
          },
          width = 0.87,
          height = 0.80,
          preview_cutoff = 120,
        },
        path_display = { "filename_first" }, -- Coloca o nome do arquivo primeiro (ideal para pacotes Java longos)
        file_ignore_patterns = {
          "%.git[/\\]",
          "node_modules[/\\]",
          "target[/\\]",
          "%.gradle[/\\]",
          "build[/\\]",
          "dist[/\\]",
          "%.angular[/\\]",
          "%.idea[/\\]",
          "%.vscode[/\\]",
          "%.class$",
        },
        mappings = {
          i = {
            ["<C-n>"] = actions.move_selection_next,
            ["<C-p>"] = actions.move_selection_previous,
            ["<C-j>"] = actions.move_selection_next,
            ["<C-k>"] = actions.move_selection_previous,
            ["<C-c>"] = actions.close,
            ["<Down>"] = actions.move_selection_next,
            ["<Up>"] = actions.move_selection_previous,
            ["<CR>"] = actions.select_default,
            ["<C-v>"] = actions.select_vertical,
            ["<C-s>"] = actions.select_horizontal,
            ["<C-t>"] = actions.select_tab,
            ["<C-u>"] = actions.preview_scrolling_up,
            ["<C-d>"] = actions.preview_scrolling_down,
            ["<C-q>"] = actions.send_to_qflist + actions.open_qflist,
            ["<Esc>"] = actions.close,
          },
          n = {
            ["<Esc>"] = actions.close,
            ["q"] = actions.close,
            ["<CR>"] = actions.select_default,
            ["v"] = actions.select_vertical,
            ["s"] = actions.select_horizontal,
            ["t"] = actions.select_tab,
            ["j"] = actions.move_selection_next,
            ["k"] = actions.move_selection_previous,
            ["<C-u>"] = actions.preview_scrolling_up,
            ["<C-d>"] = actions.preview_scrolling_down,
            ["<C-q>"] = actions.send_to_qflist + actions.open_qflist,
          },
        },
      },
      pickers = {
        find_files = {
          hidden = true,
          find_command = { "rg", "--files", "--hidden", "--glob", "!**/.git/*" },
        },
        live_grep = {
          additional_args = function()
            return { "--hidden", "--glob", "!**/.git/*" }
          end,
        },
      },
    })
  end,
}
