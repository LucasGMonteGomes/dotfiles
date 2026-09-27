-- Arquivos do projeto: a busca de arquivos e pastas (Ctrl+P), num retangulo
-- no alto da tela como o "Go to File" do VS Code, e o explorador (Ctrl+E),
-- uma janela flutuante com a arvore do projeto que abre ao iniciar o Neovim
-- sem arquivo. O explorador e o do Snacks (plugins/navigation.lua).
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

-- Abre o explorador na raiz do projeto do arquivo atual, com o arquivo
-- selecionado e as pastas ate ele expandidas; se ja estiver aberto, fecha.
function M.toggle_explorer()
  local explorer = Snacks.picker.get({ source = "explorer" })[1]
  if explorer then
    explorer:close()
    return
  end
  local file = current_file()
  if file and vim.uv.fs_stat(file) then
    M.reveal(file)
  else
    Snacks.explorer.open({ cwd = M.root(file) })
  end
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

function M.setup()
  -- `nvim` sem arquivo abre o explorador; `nvim .` e `nvim pasta/` ja abrem
  -- pelo Snacks, que substitui o netrw. UIEnter so acontece com interface:
  -- scripts com --headless nao abrem o explorador.
  vim.api.nvim_create_autocmd("UIEnter", {
    group = vim.api.nvim_create_augroup("FilesStartup", { clear = true }),
    once = true,
    callback = function()
      local empty = vim.api.nvim_buf_get_name(0) == ""
        and vim.api.nvim_buf_line_count(0) == 1
        and vim.api.nvim_buf_get_lines(0, 0, 1, false)[1] == ""
      if vim.fn.argc() == 0 and empty then
        vim.schedule(function()
          Snacks.explorer.open({ cwd = vim.fn.getcwd() })
        end)
      end
    end,
  })
end

return M
