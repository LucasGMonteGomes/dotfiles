-- Renomear e mover arquivos e pastas (explorador) com o refactor do LSP,
-- como no IntelliJ: renomear Calc.java para Calculadora.java muda a classe,
-- os construtores, as referencias e os imports do projeto; mover um .java
-- ou renomear uma pasta de pacote atualiza o `package` e os imports.
--
-- Substitui duas funcoes do Snacks.rename, usadas pelo explorador:
-- - on_rename_file consultava so servidores que anunciam
--   workspace/willRenameFiles, esperando 1 s. O jdtls responde sem anunciar
--   e leva ~2 s para uma classe usada em varios arquivos.
-- - _rename achava o buffer com bufnr(caminho), que aceita correspondencia
--   parcial: renomear a pasta calc/ podia trocar o buffer calc/Calc.java.
local M = {}

local timeout_ms = 10000

local function notify(message, level)
  vim.notify(message, level or vim.log.levels.INFO, { title = "Explorador" })
end

local function normalize(path)
  return (vim.fs.normalize(vim.fn.fnamemodify(path, ":p")):gsub("/$", ""))
end

-- Arquivo .java ou pasta com arquivos .java: o jdtls precisa refatorar.
local function has_java(path)
  if path:match("%.java$") then
    return true
  end
  return vim.fn.isdirectory(path) == 1
    and #vim.fs.find(function(name)
      return name:match("%.java$") ~= nil
    end, { path = path, type = "file", limit = 1 }) > 0
end

-- jdtls do projeto do caminho, se estiver rodando.
local function jdtls_for(path)
  for _, client in ipairs(vim.lsp.get_clients({ name = "jdtls" })) do
    if client.root_dir and vim.startswith(path, client.root_dir .. "/") then
      return client
    end
  end
  return nil
end

local function is_inside(path, dir)
  return path == dir or vim.startswith(path, dir .. "/")
end

-- Buffers cujo arquivo e `path` ou esta dentro da pasta `path`.
local function buffers_under(path)
  local ret = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    local name = vim.api.nvim_buf_get_name(buf)
    if name ~= "" and vim.bo[buf].buftype == "" and is_inside(vim.fs.normalize(name), path) then
      ret[#ret + 1] = buf
    end
  end
  return ret
end

local function save(buf)
  if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].modified then
    vim.api.nvim_buf_call(buf, function()
      vim.cmd("silent write")
    end)
  end
end

-- URIs dos documentos alterados por um WorkspaceEdit.
local function edited_uris(edit)
  local uris = {}
  for uri in pairs(edit.changes or {}) do
    uris[#uris + 1] = uri
  end
  for _, change in ipairs(edit.documentChanges or {}) do
    if change.textDocument then
      uris[#uris + 1] = change.textDocument.uri
    end
  end
  return uris
end

--- Move o arquivo ou a pasta no disco e reabre, no caminho novo, os buffers
--- que estavam abertos (mantendo o cursor de cada janela).
---@return boolean ok
function M.rename_path(from, to)
  from, to = normalize(from), normalize(to)
  vim.fn.mkdir(vim.fs.dirname(to), "p")
  if vim.fn.rename(from, to) ~= 0 then
    notify("Nao foi possivel mover " .. vim.fn.fnamemodify(from, ":~:.") .. " para " .. vim.fn.fnamemodify(to, ":~:."), vim.log.levels.ERROR)
    return false
  end

  for _, buf in ipairs(buffers_under(from)) do
    local new = to .. vim.fs.normalize(vim.api.nvim_buf_get_name(buf)):sub(#from + 1)
    local new_buf = vim.fn.bufadd(new)
    vim.bo[new_buf].buflisted = true
    for _, win in ipairs(vim.fn.win_findbuf(buf)) do
      local cursor = vim.api.nvim_win_get_cursor(win)
      vim.api.nvim_win_call(win, function()
        vim.cmd("buffer " .. new_buf)
      end)
      pcall(vim.api.nvim_win_set_cursor, win, cursor)
    end
    vim.api.nvim_buf_delete(buf, { force = true })
  end
  return true
end

--- Pede aos servidores as alteracoes do refactor, aplica, salva e so entao
--- executa `rename` (que move no disco) e avisa que o arquivo mudou.
function M.on_rename_file(from, to, rename)
  from, to = normalize(from), normalize(to)
  local changes = { files = { { oldUri = vim.uri_from_fname(from), newUri = vim.uri_from_fname(to) } } }

  local clients = {}
  for _, client in ipairs(vim.lsp.get_clients()) do
    if client.name ~= "jdtls" and client:supports_method("workspace/willRenameFiles") then
      clients[#clients + 1] = client
    end
  end

  if has_java(from) then
    local jdtls = jdtls_for(from)
    if jdtls and require("features.java.status").is_ready(jdtls.id) then
      clients[#clients + 1] = jdtls
    else
      local answer = vim.fn.confirm(
        "O servidor Java ainda nao esta pronto neste projeto: classes, package e imports nao serao atualizados.\n"
          .. "Para refatorar, abra um arquivo .java do projeto e espere o icone do Java ficar verde na statusline.\n\n"
          .. "Renomear so o arquivo mesmo assim?",
        "&Sim\n&Nao",
        2
      )
      if answer ~= 1 then
        return
      end
    end
  end

  local updated = 0
  for _, client in ipairs(clients) do
    notify("Atualizando referencias com " .. client.name .. "...")
    vim.cmd.redraw()
    local response = client:request_sync("workspace/willRenameFiles", changes, timeout_ms, 0)
    if response and response.err then
      notify(client.name .. ": " .. response.err.message, vim.log.levels.WARN)
    elseif not response then
      notify(client.name .. " nao respondeu em " .. (timeout_ms / 1000) .. " s; as referencias nao foram atualizadas.", vim.log.levels.WARN)
    elseif response.result then
      vim.lsp.util.apply_workspace_edit(response.result, client.offset_encoding)
      -- As alteracoes vao para o disco antes de mover: o buffer do proprio
      -- arquivo e fechado e reaberto do disco no caminho novo.
      for _, uri in ipairs(edited_uris(response.result)) do
        save(vim.uri_to_bufnr(uri))
        updated = updated + 1
      end
    end
  end

  -- Alteracoes nao salvas nos arquivos movidos iriam se perder ao reabri-los.
  for _, buf in ipairs(buffers_under(from)) do
    save(buf)
  end

  if rename then
    rename()
  end

  for _, client in ipairs(vim.lsp.get_clients()) do
    if client.name == "jdtls" or client:supports_method("workspace/didRenameFiles") then
      client:notify("workspace/didRenameFiles", changes)
    end
  end

  if updated > 0 then
    notify(("%s renomeado; %d arquivo(s) atualizado(s)."):format(vim.fs.basename(to), updated))
  end
end

function M.setup()
  local rename = require("snacks.rename")
  rename.on_rename_file = M.on_rename_file
  rename._rename = M.rename_path
end

return M
