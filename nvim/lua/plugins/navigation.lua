local ignored_paths = require("features.files").ignored_paths

-- Cria o arquivo ou a pasta a partir da pasta selecionada, com as pastas
-- intermediarias (`service/impl/ClienteServiceImpl.java`). Um arquivo novo
-- abre em seguida; em .java, o arquivo vazio dispara o seletor de esqueleto
-- (features/java/newfile.lua). Uma pasta fica selecionada no explorador.
local function add_and_open(picker)
  local Tree = require("snacks.explorer.tree")
  local Actions = require("snacks.explorer.actions")
  local dir = picker:dir()
  local where = vim.fs.relpath(picker:cwd(), dir) or dir
  Snacks.input({
    prompt = "Novo arquivo ou pasta em " .. (where == "." and "./" or where .. "/") .. " (pastas terminam com /)",
  }, function(value)
    if not value or vim.trim(value) == "" then
      return
    end
    local path = vim.fs.normalize(dir .. "/" .. vim.trim(value))
    local is_file = value:sub(-1) ~= "/"
    local folder = is_file and vim.fs.dirname(path) or path
    if vim.uv.fs_stat(path) then
      vim.notify("Ja existe: " .. vim.fn.fnamemodify(path, ":~:."), vim.log.levels.WARN, { title = "Explorador" })
      return
    end
    vim.fn.mkdir(folder, "p")
    if is_file then
      io.open(path, "w"):close()
      picker:close()
      vim.schedule(function()
        vim.cmd.edit(vim.fn.fnameescape(path))
      end)
      return
    end
    Tree:refresh(dir)
    Tree:open(folder)
    Actions.update(picker, { target = folder, refresh = true })
  end)
end

-- Linha do explorador: o formato de arquivo do Snacks (icone, nome e a
-- letra do Git a direita) com um ● depois do nome quando ha alteracoes nao
-- salvas no arquivo, ou em algum arquivo de uma pasta recolhida.
local function unsaved_paths()
  local paths = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[buf].modified and vim.bo[buf].buftype == "" then
      local name = vim.api.nvim_buf_get_name(buf)
      if name ~= "" then
        paths[#paths + 1] = vim.fs.normalize(name)
      end
    end
  end
  return paths
end

local function format_with_unsaved(item, picker)
  local ret = require("snacks.picker.format").file(item, picker)
  local path = item.file and vim.fs.normalize(item.file)
  if not path then
    return ret
  end
  for _, unsaved in ipairs(unsaved_paths()) do
    if unsaved == path or (item.dir and not item.open and vim.startswith(unsaved, path .. "/")) then
      ret[#ret + 1] = { "●", "ExplorerUnsaved" }
      ret[#ret + 1] = { " " }
      break
    end
  end
  return ret
end

local function refresh_after_move(picker, from, to)
  local Tree = require("snacks.explorer.tree")
  Tree:refresh(vim.fs.dirname(from))
  Tree:refresh(vim.fs.dirname(to))
  require("snacks.explorer.actions").update(picker, { target = to })
end

-- Renomear (o caminho inteiro pode ser editado, o que tambem move). Arquivos
-- .java e pastas de pacote passam pelo refactor do jdtls (features/rename.lua).
local function rename_item(picker, item)
  if not item then
    return
  end
  local root = picker:cwd()
  local current = vim.fs.relpath(root, item.file) or item.file
  Snacks.input({
    prompt = "Renomear (ou mover, editando o caminho)",
    default = current,
    completion = "file",
  }, function(value)
    value = value and vim.trim(value) or ""
    if value == "" or value == current then
      return
    end
    local to = value:sub(1, 1) == "/" and value or vim.fs.joinpath(root, value)
    if vim.uv.fs_stat(to) then
      vim.notify("Ja existe: " .. value, vim.log.levels.WARN, { title = "Explorador" })
      return
    end
    Snacks.rename.rename_file({
      from = item.file,
      to = to,
      on_rename = function(new, old, ok)
        if ok then
          refresh_after_move(picker, old, new)
        end
      end,
    })
  end)
end

-- Mover: os itens marcados com Tab vao para a pasta selecionada; sem itens
-- marcados, pergunta a pasta de destino do item sob o cursor.
local function move_items(picker, item)
  local paths = vim.tbl_map(Snacks.picker.util.path, picker:selected())
  local root = picker:cwd()
  local function move(sources, target)
    for _, from in ipairs(sources) do
      local to = vim.fs.joinpath(target, vim.fs.basename(from))
      if vim.uv.fs_stat(to) then
        vim.notify("Ja existe: " .. (vim.fs.relpath(root, to) or to), vim.log.levels.WARN, { title = "Explorador" })
      else
        Snacks.rename.rename_file({ from = from, to = to })
        refresh_after_move(picker, from, to)
      end
    end
    picker.list:set_selected()
  end

  if #paths > 0 then
    local target = picker:dir()
    local what = #paths == 1 and vim.fs.basename(paths[1]) or (#paths .. " itens")
    Snacks.picker.util.confirm(
      "Mover " .. what .. " para " .. (vim.fs.relpath(root, target) or target) .. "/?",
      function()
        move(paths, target)
      end
    )
    return
  end
  if not item then
    return
  end
  local parent = vim.fs.dirname(item.file)
  Snacks.input({
    prompt = "Mover " .. vim.fs.basename(item.file) .. " para a pasta",
    default = (vim.fs.relpath(root, parent) or parent) .. "/",
    completion = "dir",
  }, function(value)
    value = value and vim.trim(value):gsub("/$", "") or ""
    if value == "" then
      return
    end
    local target = value:sub(1, 1) == "/" and value or vim.fs.joinpath(root, value)
    if target == parent then
      return
    end
    vim.fn.mkdir(target, "p")
    move({ item.file }, target)
  end)
end

-- Do explorador, a busca usa a mesma raiz exibida na arvore.
local function open_file_search(picker)
  local cwd = picker:cwd()
  picker:close()
  require("features.files").find({ cwd = cwd })
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
  -- Uma pasta continua sendo aberta com Enter/l. Ctrl+L abre o arquivo
  -- selecionado numa divisao vertical a direita.
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
    config = function(_, opts)
      require("snacks").setup(opts)
      -- Renomear/mover do explorador com o refactor do jdtls.
      require("features.rename").setup()
    end,
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
          open_file_search = open_file_search,
          add_and_open = add_and_open,
          rename_item = rename_item,
          move_items = move_items,
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
              -- modo; Ctrl+C alterna entre o campo de busca e a lista.
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
            title = "Explorador",
            hidden = true,
            -- Arquivos do .gitignore aparecem apagados (`I` esconde); a pasta
            -- .git nunca aparece.
            ignored = true,
            exclude = { ".git" },
            diagnostics = false,
            git_status = true,
            format = format_with_unsaved,
            -- Estado do Git em letras a direita: M modificado, A adicionado,
            -- D removido, R renomeado, ? nao rastreado, ! ignorado; o que
            -- esta no stage tem cor propria.
            icons = { git = { enabled = false } },
            -- Janela flutuante: fecha ao abrir um arquivo e ao clicar fora.
            jump = { close = true },
            auto_close = true,
            win = {
              -- Esc no filtro (`/`) volta para a arvore; na arvore, fecha.
              input = {
                keys = {
                  ["<Esc>"] = { "focus_list", mode = { "n", "i" } },
                },
              },
              list = {
                keys = {
                  ["<CR>"] = "open_or_expand_java_source",
                  ["l"] = "open_or_expand_java_source",
                  -- O Snacks usa Ctrl+C para `tcd` por padrao: isto troca o
                  -- diretorio do Explorer pela pasta selecionada, facil de
                  -- disparar sem querer.
                  ["<C-c>"] = "picker_noop",
                  -- No Explorer Ctrl+A cria, enquanto no editor continua
                  -- abrindo a busca de todos os arquivos.
                  ["a"] = "add_and_open",
                  ["r"] = "rename_item",
                  ["m"] = "move_items",
                  ["<C-a>"] = "add_and_open",
                  ["<C-e>"] = "close",
                  ["<C-p>"] = "open_file_search",
                  ["<C-f>"] = "open_project_search",
                  ["<C-t>"] = "toggle_terminal",
                  ["<C-l>"] = "open_in_right_split",
                  ["<Esc>"] = "close",
                },
              },
            },
            -- Centralizado, com a arvore inteira do projeto; o campo de filtro
            -- so aparece ao apertar `/`.
            layout = {
              preview = false,
              auto_hide = { "input" },
              layout = {
                backdrop = false,
                width = 0.45,
                min_width = 60,
                height = 0.85,
                border = "rounded",
                title = "{title}",
                title_pos = "center",
                box = "vertical",
                { win = "input", height = 1, border = "bottom" },
                { win = "list", border = "none" },
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
        "<C-e>",
        function()
          require("features.files").toggle_explorer()
        end,
        desc = "Abrir/fechar o explorador de arquivos",
      },
      {
        "<C-p>",
        function()
          require("features.files").find()
        end,
        desc = "Buscar arquivos e pastas do projeto",
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
}
