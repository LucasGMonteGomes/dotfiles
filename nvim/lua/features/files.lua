-- Busca de arquivos e pastas (Ctrl+P) num retangulo no alto da tela, como o
-- "Go to File" do VS Code. Escolher uma pasta a abre no explorador.
local M = {}

-- Fora da busca e do explorador, mesmo quando nao estao no .gitignore.
M.ignored_paths = {
  ".git",
  ".gradle",
  ".idea",
  ".vscode",
  "build",
  "dist",
  "node_modules",
  "target",
}

-- Raiz do projeto de um arquivo: o repositorio Git ou, fora dele, a raiz do
-- build Java. Sem arquivo, a pasta em que o Neovim foi aberto.
function M.root(path)
  if not path or path == "" then
    return vim.fn.getcwd()
  end
  return vim.fs.root(path, ".git") or require("features.java.project").root(path)
end

local function current_file()
  local name = vim.bo.buftype == "" and vim.api.nvim_buf_get_name(0) or ""
  return name ~= "" and name or nil
end

-- Abre o explorador com a pasta (ou o arquivo) selecionada e expandida.
function M.reveal(path)
  local Tree = require("snacks.explorer.tree")
  local Actions = require("snacks.explorer.actions")
  local explorer = Snacks.picker.get({ source = "explorer" })[1]
  if explorer then
    explorer:close()
  end
  Snacks.explorer.open({
    cwd = M.root(path),
    on_show = function(picker)
      Tree:open(path)
      Actions.update(picker, { target = path, refresh = true })
    end,
  })
end

-- Arquivos e pastas pelo fd. O fd ja respeita o .gitignore; --hidden inclui
-- arquivos como .env e application.yml em pastas ocultas. Pastas chegam com
-- "/" no fim.
local function find_files_and_dirs(opts, ctx)
  local fd = require("snacks.picker.source.files").get_fd()
  if not fd then
    return function() end
  end
  local args = { "--type", "f", "--type", "d", "--type", "l", "--hidden", "--color", "never" }
  for _, path in ipairs(M.ignored_paths) do
    vim.list_extend(args, { "--exclude", path })
  end
  local cwd = opts.cwd
  return require("snacks.picker.source.proc").proc(
    ctx:opts({
      cmd = fd,
      args = args,
      cwd = cwd,
      transform = function(item)
        item.cwd = cwd
        if item.text:sub(-1) == "/" then
          item.dir = true
          item.text = item.text:sub(1, -2)
        end
        item.file = item.text
      end,
    }),
    ctx
  )
end

-- `opts.cwd`: pasta da busca; por padrao, a raiz do projeto do arquivo atual.
function M.find(opts)
  opts = opts or {}
  Snacks.picker.pick({
    title = "Arquivos e pastas",
    finder = find_files_and_dirs,
    cwd = opts.cwd or M.root(current_file()),
    format = "file",
    -- Nome em destaque e a pasta ao lado, apagada: "Calc.java  src/main/...".
    formatters = { file = { filename_first = true, truncate = "left" } },
    layout = { preset = "vscode" },
    confirm = function(picker, item, action)
      if not item then
        return
      end
      if item.dir then
        local path = Snacks.picker.util.path(item)
        picker:close()
        vim.schedule(function()
          M.reveal(path)
        end)
      else
        Snacks.picker.actions.jump(picker, item, action)
      end
    end,
  })
end

return M
