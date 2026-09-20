local ignored_paths = {
  ".git",
  ".gradle",
  ".idea",
  ".vscode",
  "build",
  "dist",
  "node_modules",
  "target",
}

local function get_explorer()
  return Snacks.picker.get({ source = "explorer" })[1]
end

local function toggle_explorer()
  local explorer = get_explorer()
  if explorer then
    explorer:close()
  else
    Snacks.explorer.open()
  end
end

local function focus_explorer()
  local explorer = get_explorer()
  if explorer then
    explorer:focus("list", { show = true })
  else
    Snacks.explorer.open()
  end
end

local function focus_editor(picker)
  if picker.main and vim.api.nvim_win_is_valid(picker.main) then
    vim.api.nvim_set_current_win(picker.main)
  end
end

local function open_smart_picker()
  Snacks.picker.smart()
end

local function open_project_search()
  Snacks.picker.grep()
end

local function toggle_terminal()
  vim.cmd("ToggleTerm direction=horizontal")
end

local function picker_stop_insert()
  vim.cmd.stopinsert()
end

local function picker_noop() end

local function open_in_right_split(picker, item)
  -- Uma pasta continua sendo aberta com Enter/l. Ctrl+L e reservado para
  -- visualizar o arquivo selecionado em uma segunda coluna, sem fechar o
  -- Explorer.
  if not item or item.dir then
    return
  end
  require("snacks.picker.actions").jump(picker, item, { cmd = "vsplit" })
end

local function open_or_expand_java_source(picker, item, action)
  if not item or not item.dir or vim.fs.basename(item.file) ~= "src" or item.open then
    require("snacks.explorer.actions").actions.confirm(picker, item, action)
    return
  end

  local tree = require("snacks.explorer.tree")
  local function expand_directory(node)
    tree:expand(node)
    node.open = true
  end

  local function directory_named(node, name)
    for _, child in pairs(node.children or {}) do
      if child.dir and child.type == "directory" and vim.fs.basename(child.file) == name then
        return child
      end
    end
    return nil
  end

  local function only_directory_child(node)
    local directory
    for _, child in pairs(node.children or {}) do
      if child.dir and child.type == "directory" then
        if directory then
          return nil
        end
        directory = child
      end
    end
    return directory
  end

  -- `src` mostra somente a estrutura de uma aplicacao Java: src/main/java,
  -- depois a cadeia de pacotes (com/example/demo). Ao chegar a uma pasta com
  -- mais de uma subpasta, como controller/service/model, ela para. Assim nao
  -- despeja os arquivos internos de toda a aplicacao de uma vez.
  local source = tree:find(item.file)
  expand_directory(source)

  local main = directory_named(source, "main")
  if main then
    expand_directory(main)
    local java = directory_named(main, "java")
    if java then
      expand_directory(java)
      local package_directory = java
      while true do
        local child = only_directory_child(package_directory)
        if not child then
          break
        end
        expand_directory(child)
        package_directory = child
      end
    end
  end

  require("snacks.explorer.actions").update(picker, {
    target = item.file,
    refresh = true,
  })
end

return {
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    ---@type snacks.Config
    opts = {
      explorer = {
        enabled = true,
        replace_netrw = true,
        -- Exclusoes permanecem recuperaveis somente quando o sistema possui
        -- uma lixeira compativel; sem ela, o Snacks pede confirmacao.
        trash = true,
      },
      picker = {
        enabled = true,
        ui_select = true,
        layout = {
          preset = "ivy",
        },
        matcher = {
          frecency = true,
          history_bonus = true,
        },
        actions = {
          open_or_expand_java_source = open_or_expand_java_source,
          focus_editor = focus_editor,
          open_smart_picker = open_smart_picker,
          open_project_search = open_project_search,
          toggle_terminal = toggle_terminal,
          open_in_right_split = open_in_right_split,
          picker_stop_insert = picker_stop_insert,
          picker_noop = picker_noop,
        },
        win = {
          input = {
            keys = {
              -- Em interfaces temporarias, Esc fecha a interface em qualquer
              -- modo. Nos arquivos, Esc continua sem trocar INSERT/NORMAL.
              ["<Esc>"] = { "close", mode = { "n", "i" } },
              ["<C-c>"] = { "picker_stop_insert", mode = "i" },
              ["<C-e>"] = "picker_noop",
            },
          },
          list = {
            keys = {
              ["<Esc>"] = "close",
              ["<C-c>"] = "focus_input",
              ["<C-e>"] = "picker_noop",
            },
          },
          preview = {
            keys = {
              ["<Esc>"] = "close",
              ["<C-c>"] = "focus_input",
              ["<C-e>"] = "picker_noop",
            },
          },
        },
        sources = {
          explorer = {
            hidden = true,
            ignored = false,
            diagnostics = false,
            git_status = true,
            win = {
              list = {
                keys = {
                  ["<CR>"] = "open_or_expand_java_source",
                  ["l"] = "open_or_expand_java_source",
                  -- O Snacks usa Ctrl+C para `tcd` por padrao: isto troca o
                  -- diretorio do Explorer pela pasta selecionada. Para este
                  -- fluxo, Ctrl+C e exclusivamente o seletor INSERT/NORMAL.
                  ["<C-c>"] = "picker_noop",
                  -- No Explorer Ctrl+A cria, enquanto no editor continua
                  -- abrindo a busca de todos os arquivos.
                  ["<C-a>"] = "explorer_add",
                  ["<C-n>"] = "close",
                  ["<C-p>"] = "open_smart_picker",
                  ["<C-f>"] = "open_project_search",
                  ["<C-t>"] = "toggle_terminal",
                  ["<C-l>"] = "open_in_right_split",
                  ["<Esc>"] = "focus_editor",
                },
              },
            },
            layout = {
              preset = "sidebar",
              preview = false,
              auto_hide = { "input" },
              layout = {
                position = "left",
                width = 34,
              },
            },
          },
          files = {
            hidden = true,
            ignored = false,
            exclude = ignored_paths,
          },
          smart = {
            hidden = true,
            ignored = false,
            exclude = ignored_paths,
          },
          grep = {
            hidden = true,
            ignored = false,
            exclude = ignored_paths,
          },
        },
      },
      zen = {
        enabled = true,
        toggles = {
          dim = false,
          git_signs = false,
          diagnostics = false,
          inlay_hints = false,
        },
        show = {
          statusline = false,
          tabline = false,
        },
      },
      notifier = { enabled = false },
      indent = { enabled = false },
      statuscolumn = { enabled = false },
      dashboard = { enabled = false },
    },
    keys = {
      {
        "<C-n>",
        toggle_explorer,
        desc = "Abrir/fechar explorador de arquivos",
      },
      {
        "<C-e>",
        focus_explorer,
        desc = "Focar no explorador sem fecha-lo",
      },
      {
        "<C-p>",
        function()
          Snacks.picker.smart()
        end,
        desc = "Buscar buffers, recentes e arquivos do projeto",
      },
      {
        "<C-f>",
        function()
          Snacks.picker.grep()
        end,
        desc = "Buscar texto no projeto",
      },
      {
        "<C-a>",
        function()
          Snacks.picker.files({ hidden = true, ignored = true })
        end,
        desc = "Buscar todos os arquivos, inclusive ignorados",
      },
      {
        "<C-A-w>",
        function()
          Snacks.picker.grep_word()
        end,
        mode = { "n", "x" },
        desc = "Buscar palavra ou selecao no projeto",
      },
      {
        "<C-A-b>",
        function()
          Snacks.picker.buffers()
        end,
        desc = "Buscar buffers abertos",
      },
      {
        "<C-A-s>",
        function()
          Snacks.picker.lsp_symbols()
        end,
        desc = "Buscar classes e metodos no arquivo",
      },
      {
        "<C-A-y>",
        function()
          Snacks.picker.lsp_workspace_symbols()
        end,
        desc = "Buscar simbolos no projeto",
      },
      {
        "<C-A-k>",
        function()
          Snacks.zen()
        end,
        desc = "Ativar/desativar modo foco",
      },
    },
  },
  {
    "stevearc/oil.nvim",
    lazy = false,
    dependencies = { "nvim-mini/mini.nvim" },
    keys = {
      { "-", "<cmd>Oil<cr>", desc = "Editar pasta atual com Oil" },
    },
    opts = {
      default_file_explorer = false,
      columns = { "icon" },
      delete_to_trash = true,
      skip_confirm_for_simple_edits = false,
      view_options = {
        show_hidden = true,
      },
      keymaps = {
        ["<C-l>"] = false,
        ["<C-j>"] = false,
        ["q"] = "actions.close",
        ["<Esc>"] = "actions.close",
      },
    },
  },
}
