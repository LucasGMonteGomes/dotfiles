-- Estado do jdtls para a statusline: a importacao do projeto (que pode levar
-- minutos) com o percentual, tarefas longas depois disso e erros. Os dados
-- vem do `language/status` (features/java/jdtls.lua) e do `$/progress` do LSP.
local M = {}

-- Glifo Nerd Font do Java (nf-dev-java), gerado pelo codigo como em debug.lua.
local icon = vim.fn.nr2char(0xe738)

-- Tarefas mais curtas que isto nao aparecem: depois de pronto, o jdtls dispara
-- varias de milissegundos (Building, Validate documents...) a cada alteracao.
local long_task_ms = 1000

-- Por id de cliente: `state` (starting, ready, error), `message`,
-- `project_ok` e as tarefas do `$/progress` ativas, por token. Um jdtls
-- reiniciado ganha outro id e comeca do zero.
local clients = {}

local function refresh()
  local ok, lualine = pcall(require, "lualine")
  if ok then
    lualine.refresh({ place = { "statusline" } })
  end
end

local function client_state(client_id)
  clients[client_id] = clients[client_id] or { state = "starting", message = "Iniciando", project_ok = true, tasks = {} }
  return clients[client_id]
end

-- Handler do `language/status` do jdtls (chamado por features/java/jdtls.lua).
function M.on_language_status(result, client_id)
  if not result then
    return
  end
  local status = client_state(client_id)
  if result.type == "Starting" then
    -- "27% Starting Java Language Server - Refreshing projects"
    local message = vim.trim((result.message:gsub("Starting Java Language Server%s*%-?%s*", "")))
    -- O primeiro aviso e so "0%".
    status.message = message:match("^%d+%%$") and (message .. " Iniciando") or message
  elseif result.type == "ServiceReady" or result.type == "Started" then
    status.state = "ready"
  elseif result.type == "Error" then
    status.state = "error"
    status.message = result.message
  elseif result.type == "ProjectStatus" then
    -- WARNING: o pom.xml/build.gradle nao pode ser importado por completo.
    status.project_ok = result.message == "OK"
  end
  refresh()
end

local function on_progress(event)
  local client = vim.lsp.get_client_by_id(event.data.client_id)
  if not client or client.name ~= "jdtls" then
    return
  end
  local status = client_state(client.id)
  local token, value = event.data.params.token, event.data.params.value
  if value.kind == "end" then
    -- So redesenha se a tarefa chegou a aparecer.
    local task = status.tasks[token]
    status.tasks[token] = nil
    if task and vim.uv.now() - task.started >= long_task_ms then
      refresh()
    end
  else
    local task = status.tasks[token]
    if not task then
      task = { started = vim.uv.now() }
      -- Aparece assim que passa do limite, sem esperar o ciclo do lualine.
      vim.defer_fn(function()
        if status.tasks[token] == task then
          refresh()
        end
      end, long_task_ms + 10)
    end
    task.title = value.title or task.title
    task.message = value.message or task.message
    task.percentage = value.percentage or task.percentage
    status.tasks[token] = task
  end
end

-- Tarefa mais antiga que ja passou do limite (nil se nao houver).
local function long_task(status)
  local now, oldest = vim.uv.now(), nil
  for _, task in pairs(status.tasks) do
    if now - task.started >= long_task_ms and (not oldest or task.started < oldest.started) then
      oldest = task
    end
  end
  return oldest
end

-- Cliente do buffer atual; antes do primeiro `language/status` (a JVM leva
-- alguns segundos para subir), o estado inicial ja mostra "Iniciando".
local function current_status()
  local client = vim.lsp.get_clients({ name = "jdtls", bufnr = 0, _uninitialized = true })[1]
  return client and client_state(client.id)
end

local function shorten(text, max)
  return #text > max and (text:sub(1, max - 1) .. "…") or text
end

-- Texto do componente; vazio fora de buffers ligados ao jdtls.
function M.text()
  local status = current_status()
  if not status then
    return ""
  end
  if status.state == "error" then
    return icon .. " erro: " .. shorten(status.message, 40)
  end
  if status.state == "starting" then
    return icon .. " " .. shorten(status.message, 50)
  end
  local task = long_task(status)
  if task then
    local message = task.message and task.message ~= "" and task.message or task.title or ""
    local percentage = task.percentage and (" " .. task.percentage .. "%") or ""
    return icon .. " " .. shorten(message, 45) .. percentage
  end
  if not status.project_ok then
    return icon .. " build com problemas"
  end
  return icon
end

-- Cor do componente: verde pronto, amarelo trabalhando/aviso, vermelho erro.
function M.color()
  local status = current_status()
  if not status then
    return nil
  end
  if status.state == "error" then
    return { fg = "#f27481" }
  end
  if status.state == "starting" or long_task(status) or not status.project_ok then
    return { fg = "#d5b778" }
  end
  return { fg = "#73bd7a" }
end

function M.setup()
  local group = vim.api.nvim_create_augroup("JavaStatus", { clear = true })
  vim.api.nvim_create_autocmd("LspProgress", { group = group, callback = on_progress })
end

return M
