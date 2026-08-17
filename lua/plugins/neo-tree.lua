return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  lazy = false, -- Garante carregamento na inicialização para interceptar `nvim .`
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "MunifTanjim/nui.nvim",
  },
  cmd = "Neotree",
  keys = {
    { "<C-n>", "<cmd>Neotree toggle<cr>", desc = "Abrir/Fechar Explorador de Arquivos (Neo-tree)" },
    { "<C-A-f>", "<cmd>Neotree focus<cr>", desc = "Focar no Explorador de Arquivos" },
    { "<C-A-o>", "<cmd>Neotree reveal<cr>", desc = "Revelar Arquivo Atual no Explorador" },
  },
  config = function()
    -- Desativa netrw padrão do Neovim
    vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1

    require("neo-tree").setup({
      close_if_last_window = true,
      popup_border_style = "rounded",
      enable_git_status = true,
      enable_diagnostics = false,
      open_files_do_not_replace_types = { "terminal", "trouble", "qf" },
      sort_case_insensitive = true,
      sources = { "filesystem" },
      source_selector = {
        winbar = false,
        statusline = false,
      },
      default_component_configs = {
        container = {
          enable_character_fade = true,
        },
        indent = {
          indent_size = 2,
          padding = 1,
          with_markers = true,
          indent_marker = "│",
          last_indent_marker = "└",
          highlight = "NeoTreeIndentMarker",
          with_expanders = true,
          expander_collapsed = "",
          expander_expanded = "",
          expander_highlight = "NeoTreeExpander",
        },
        icon = {
          folder_closed = "",
          folder_open = "",
          folder_empty = "󰜌",
          default = "󰈔",
          highlight = "NeoTreeFileIcon",
        },
        modified = {
          symbol = "●",
          highlight = "NeoTreeModified",
        },
        name = {
          trailing_slash = false,
          use_git_status_colors = true,
          highlight = "NeoTreeFileName",
        },
        git_status = {
          symbols = {
            added     = "✚",
            modified  = "",
            deleted   = "✖",
            renamed   = "󰁕",
            untracked = "",
            ignored   = "",
            unstaged  = "󰄱",
            staged    = "",
            conflict  = "",
          },
        },
      },
      window = {
        position = "left",
        width = 34,
        mapping_options = {
          noremap = true,
          nowait = true,
        },
        mappings = {
          ["<space>"] = "none",
          ["<cr>"] = "open_or_expand",
          ["l"] = "open_or_expand",
          ["h"] = "close_node",
          ["v"] = "open_vsplit",
          ["s"] = "open_split",
          ["t"] = "open_tabnew",
          ["C"] = "close_node",
          ["z"] = "close_all_nodes",
          ["a"] = {
            "add",
            config = {
              show_path = "none",
            },
          },
          ["A"] = "add_directory",
          ["d"] = "delete",
          ["r"] = "rename",
          ["y"] = "copy_to_clipboard",
          ["x"] = "cut_to_clipboard",
          ["p"] = "paste_from_clipboard",
          ["c"] = "copy",
          ["m"] = "move",
          ["q"] = "close_window",
          ["R"] = "refresh",
          ["?"] = "show_help",
          ["H"] = "toggle_hidden",
          ["I"] = "toggle_gitignore",
        },
      },
      filesystem = {
        commands = {
          open_or_expand = function(state)
            local node = state.tree:get_node()
            local commands = require("neo-tree.sources.filesystem.commands")

            local is_source_root = node and node.type == "directory" and node.name == "src"
            if is_source_root and not node:is_expanded() then
              commands.expand_all_subnodes(state, node)
              return
            end

            commands.open(state)
          end,
        },
        hijack_netrw_behavior = "open_default", -- Abre a árvore à esquerda e um buffer de edição vazio à direita!
        filtered_items = {
          visible = false,
          hide_dotfiles = false,
          hide_gitignored = false,
          hide_hidden = true,
          hide_by_name = {
            ".git",
          },
          never_show = {
            ".DS_Store",
          },
        },
        follow_current_file = {
          enabled = true,
          leave_dirs_open = false,
        },
        group_empty_dirs = false, -- Exibe cada pasta separadamente (java/com/example/demo)
        use_libuv_file_watcher = true,
      },
    })
  end,
}
