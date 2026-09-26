-- Build do projeto (Maven/Gradle) em segundo plano. Erros de compilacao e
-- testes que falharam vao para a quickfix, aberta no Trouble; a saida
-- completa fica disponivel em <leader>bo.
local M = {}

local project = require("features.java.project")

local builds = {}
local last = nil
local output = {}

local function notify(message, level, opts)
  vim.notify(message, level or vim.log.levels.INFO, vim.tbl_extend("force", { title = "Build" }, opts or {}))
end

-- Tarefas do menu: o nome mostrado e os argumentos no Maven e no Gradle.
local tasks = {
  { label = "Compilar", maven = { "compile" }, gradle = { "classes" } },
  { label = "Compilar com os testes", maven = { "test-compile" }, gradle = { "testClasses" } },
  { label = "Rodar os testes", maven = { "test" }, gradle = { "test" } },
  { label = "Empacotar (sem testes)", maven = { "package", "-DskipTests" }, gradle = { "assemble" } },
  { label = "Verificar (testes e checagens)", maven = { "verify" }, gradle = { "check" } },
  { label = "Instalar no repositorio local", maven = { "install" }, gradle = { "publishToMavenLocal" } },
  { label = "Limpar e instalar", maven = { "clean", "install" }, gradle = { "clean", "build" } },
  { label = "Limpar", maven = { "clean" }, gradle = { "clean" } },
}

-- Classe de teste (`AppTest`) do relatorio para o arquivo, procurando no
-- projeto; os testes ficam em src/test na maioria dos casos.
local function find_class_file(root, class)
  local name = class:match("([^.$]+)[^.]*$") .. ".java"
  local files = vim.fs.find(name, { path = root, type = "file", limit = math.huge })
  table.sort(files, function(a, b)
    return (a:find("/src/test/", 1, true) and 1 or 0) > (b:find("/src/test/", 1, true) and 1 or 0)
  end)
  return files[1]
end

-- Transforma a saida em itens da quickfix. `maven` escolhe o formato.
local function parse(lines, root, maven)
  local items, seen = {}, {}
  local previous = nil
  local in_failures = false
  local gradle_failed_test = nil

  -- O Maven repete cada erro no resumo final, e so ali com o detalhe; a
  -- repeticao devolve o item ja registrado para o detalhe ir para ele.
  local function add(item)
    local key = table.concat({ item.filename or "", item.lnum or 0, item.col or 0, item.text }, ":")
    if seen[key] then
      return seen[key]
    end
    seen[key] = item
    table.insert(items, item)
    return item
  end

  for _, line in ipairs(lines) do
    local current = nil
    if maven then
      -- [ERROR] /caminho/App.java:[11,29] cannot find symbol
      local level, file, lnum, col, text = line:match("^%[(%u+)%] (/.-%.%a+):%[(%d+),(%d+)%] (.*)$")
      if file then
        current = add({
          filename = file,
          lnum = tonumber(lnum),
          col = tonumber(col),
          text = text,
          type = level == "ERROR" and "E" or "W",
        })
      elseif line:match("^%[ERROR%] Failures:") or line:match("^%[ERROR%] Errors:") then
        in_failures = true
      elseif in_failures and line:match("^%[ERROR%]   %S") then
        -- [ERROR]   AppTest.shouldAnswerWithTrue:18 deveria ser verdadeiro
        local class, method, test_line, message = line:match("^%[ERROR%]%s+([%w_$.]+)%.([%w_$]+)[^:%s]*:(%d+)%s*(.*)$")
        if class then
          add({
            filename = find_class_file(root, class),
            lnum = tonumber(test_line),
            text = method .. ": " .. (message ~= "" and message or "falhou"),
            type = "E",
          })
        end
      elseif in_failures then
        in_failures = false
      elseif previous and line:match("^%[ERROR%]   %S") then
        -- Detalhe do erro anterior: `symbol: variable naoExiste`.
        local detail = " (" .. vim.trim((line:gsub("^%[ERROR%]", ""))) .. ")"
        if not previous.text:find(detail, 1, true) then
          previous.text = previous.text .. detail
        end
        current = previous
      end
    else
      -- /caminho/App.java:11: error: cannot find symbol
      local file, lnum, level, text = line:match("^(/.-%.java):(%d+): (%a+): (.*)$")
      -- e: file:///caminho/App.kt:11:29 Unresolved reference
      local kind, kt_file, kt_lnum, kt_col, kt_text = line:match("^([ew]): file://(/.-):(%d+):(%d+) (.*)$")
      -- AppTest > deveSomar() FAILED
      local failed_class, failed_test = line:match("^(%S+) > (.-) FAILED$")
      if file then
        current = add({ filename = file, lnum = tonumber(lnum), text = text, type = level == "error" and "E" or "W" })
      elseif kt_file then
        current = add({
          filename = kt_file,
          lnum = tonumber(kt_lnum),
          col = tonumber(kt_col),
          text = kt_text,
          type = kind == "e" and "E" or "W",
        })
      elseif failed_class then
        gradle_failed_test = { class = failed_class, test = failed_test }
      elseif gradle_failed_test then
        --     org.opentest4j.AssertionFailedError at AppTest.java:18
        local exception, test_line = line:match("^%s+(%S+) at [%w_$]+%.java:(%d+)")
        if exception then
          add({
            filename = find_class_file(root, gradle_failed_test.class),
            lnum = tonumber(test_line),
            text = gradle_failed_test.test .. ": " .. exception,
            type = "E",
          })
          gradle_failed_test = nil
        end
      end
    end
    previous = current
  end

  return items
end

-- Sem nada reconhecido, a falha ainda aparece: as linhas [ERROR] do Maven ou
-- o bloco "What went wrong" do Gradle viram texto.
local function fallback_items(lines, maven)
  local items = {}
  local in_gradle_error = false
  for _, line in ipairs(lines) do
    local text
    if maven then
      text = line:match("^%[ERROR%] (.+)$")
    elseif line:match("^%* What went wrong:") then
      in_gradle_error = true
    elseif in_gradle_error then
      in_gradle_error = line ~= "" and not line:match("^%* ")
      text = in_gradle_error and line or nil
    end
    if text and not text:match("^%-> %[Help") and not text:match("^Re%-run Maven") then
      table.insert(items, { text = text, type = "E" })
    end
  end
  return items
end

local function show_quickfix()
  if pcall(require, "trouble") then
    vim.cmd("Trouble qflist open focus=false")
  else
    vim.cmd("copen")
  end
end

-- `args`: argumentos do Maven/Gradle; `label` aparece nas notificacoes.
function M.run(args, label)
  local root = project.root(project.current_path())
  local has_build = project.module_root(root)
    or vim.uv.fs_stat(vim.fs.joinpath(root, "settings.gradle"))
    or vim.uv.fs_stat(vim.fs.joinpath(root, "settings.gradle.kts"))
  if not has_build then
    notify("Nenhum pom.xml ou build.gradle encontrado a partir deste arquivo", vim.log.levels.WARN)
    return
  end
  if builds[root] then
    notify("Ja existe um build rodando em " .. vim.fs.basename(root), vim.log.levels.WARN)
    return
  end

  local command, maven = project.build_tool(root)
  if not command then
    notify(maven, vim.log.levels.ERROR)
    return
  end
  -- Saida sem cores nem barras de progresso, que atrapalham a leitura.
  vim.list_extend(command, maven and { "-B", "--no-transfer-progress" } or { "--console=plain" })
  vim.list_extend(command, args)

  label = label or table.concat(args, " ")
  last = { args = args, label = label }
  local title = vim.fs.basename(root) .. ": " .. label
  local id = "java-build-" .. root
  local started = vim.uv.hrtime()
  notify(title .. "...", vim.log.levels.INFO, { id = id })

  -- stdout e stderr na ordem em que chegam, como no terminal.
  local chunks = {}
  local function collect(_, data)
    if data then
      table.insert(chunks, data)
    end
  end

  local ok, process = pcall(vim.system, command, { cwd = root, text = true, stdout = collect, stderr = collect }, function(result)
    vim.schedule(function()
      builds[root] = nil
      output = vim.split(table.concat(chunks), "\n", { trimempty = true })
      local seconds = string.format("%.1fs", (vim.uv.hrtime() - started) / 1e9)

      local items = parse(output, root, maven)
      local failed = result.code ~= 0
      if failed and #vim.tbl_filter(function(item)
        return item.type == "E"
      end, items) == 0 then
        vim.list_extend(items, fallback_items(output, maven))
      end
      vim.fn.setqflist({}, "r", { title = "Build: " .. title, items = items })

      if failed then
        notify(title .. " falhou em " .. seconds .. " (" .. #items .. " itens na quickfix)", vim.log.levels.ERROR, { id = id })
        show_quickfix()
      else
        local warnings = #items > 0 and (" com " .. #items .. " avisos na quickfix") or ""
        notify(title .. " concluido em " .. seconds .. warnings, vim.log.levels.INFO, { id = id })
      end
    end)
  end)
  -- O processo nem chega a iniciar: executavel ausente ou wrapper com
  -- quebras de linha do Windows (`#!/bin/sh\r`, comum em clones feitos no
  -- Windows), que o kernel procura como um interpretador inexistente.
  if not ok then
    local message = title .. ": nao foi possivel executar " .. command[1] .. " (" .. tostring(process) .. ")"
    local first_line = vim.fn.filereadable(command[1]) == 1 and vim.fn.readfile(command[1], "b", 1)[1] or ""
    if first_line:find("\r$") then
      message = command[1] .. " tem quebras de linha do Windows. Corrija com: sed -i 's/\\r$//' " .. command[1]
    end
    notify(message, vim.log.levels.ERROR, { id = id })
    return
  end
  builds[root] = process
end

function M.menu()
  vim.ui.select(vim.list_extend(vim.deepcopy(tasks), { { label = "Outro comando..." } }), {
    prompt = "Build:",
    format_item = function(task)
      return task.label
    end,
  }, function(task)
    if not task then
      return
    end
    if task.maven then
      local root = project.root(project.current_path())
      local maven = vim.uv.fs_stat(vim.fs.joinpath(root, "pom.xml")) ~= nil
      M.run(maven and task.maven or task.gradle, task.label)
      return
    end
    vim.ui.input({ prompt = "Argumentos do Maven/Gradle: " }, function(input)
      if input and input:match("%S") then
        M.run(vim.split(input, "%s+", { trimempty = true }))
      end
    end)
  end)
end

function M.run_task(index)
  return function()
    local root = project.root(project.current_path())
    local maven = vim.uv.fs_stat(vim.fs.joinpath(root, "pom.xml")) ~= nil
    M.run(maven and tasks[index].maven or tasks[index].gradle, tasks[index].label)
  end
end

function M.rerun()
  if not last then
    notify("Nenhum build foi executado nesta sessao", vim.log.levels.WARN)
    return
  end
  M.run(last.args, last.label)
end

function M.show_output()
  if #output == 0 then
    notify("Nenhum build terminou nesta sessao", vim.log.levels.WARN)
    return
  end
  vim.cmd("botright new")
  local bufnr = vim.api.nvim_get_current_buf()
  vim.bo[bufnr].buftype = "nofile"
  vim.bo[bufnr].bufhidden = "wipe"
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, output)
  vim.bo[bufnr].modifiable = false
  vim.api.nvim_buf_set_name(bufnr, "build://" .. (last and last.label or "saida"))
  vim.cmd("normal! G")
end

function M.setup()
  vim.keymap.set("n", "<leader>bb", M.menu, { desc = "Build: escolher tarefa" })
  vim.keymap.set("n", "<leader>bc", M.run_task(1), { desc = "Build: compilar" })
  vim.keymap.set("n", "<leader>bt", M.run_task(3), { desc = "Build: rodar todos os testes" })
  vim.keymap.set("n", "<leader>bl", M.rerun, { desc = "Build: repetir o ultimo" })
  vim.keymap.set("n", "<leader>bo", M.show_output, { desc = "Build: ver a saida do ultimo" })

  vim.api.nvim_create_user_command("JavaBuild", function(opts)
    if #opts.fargs == 0 then
      M.menu()
    else
      M.run(opts.fargs)
    end
  end, { nargs = "*", desc = "Rodar o Maven/Gradle do projeto (sem argumentos, abre o menu)" })
end

return M
