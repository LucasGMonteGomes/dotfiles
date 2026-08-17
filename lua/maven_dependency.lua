local M = {}

local search_endpoint = "https://search.maven.org/solrsearch/select"
local add_goal = "org.apache.maven.plugins:maven-dependency-plugin:3.11.0:add"

local function notify(message, level)
  vim.notify(message, level or vim.log.levels.INFO, { title = "Maven" })
end

local function current_pom()
  local path = vim.api.nvim_buf_get_name(0)
  if vim.fs.basename(path) ~= "pom.xml" then
    notify("Abra um arquivo pom.xml antes de adicionar uma dependencia", vim.log.levels.WARN)
    return nil
  end
  return vim.fs.normalize(path)
end

local function executable(name)
  local path = vim.fn.exepath(name)
  return path ~= "" and path or nil
end

local function maven_executable()
  if vim.fn.has("win32") == 1 then
    return executable("mvn.cmd") or executable("mvn")
  end
  return executable("mvn")
end

local function output_text(result)
  return vim.trim((result.stdout or "") .. "\n" .. (result.stderr or ""))
end

local function short_error(result)
  local lines = vim.split(output_text(result), "\n", { trimempty = true })
  local selected = {}

  for _, line in ipairs(lines) do
    if line:find("%[ERROR%]") then
      line = line:gsub("^.*%[ERROR%]%s*", "")
      if line ~= "" and not line:match("^%[Help %d+%]") then
        table.insert(selected, line)
      end
    end
  end

  if #selected == 0 then
    for index = math.max(1, #lines - 3), #lines do
      table.insert(selected, lines[index])
    end
  end

  return table.concat(selected, "\n")
end

local function search_score(item, query)
  local score = 0
  local group = (item.g or ""):lower()
  local artifact = (item.a or ""):lower()
  local normalized_query = query:lower():gsub("[^%w]+", "-")

  if artifact == normalized_query then
    score = score + 200
  elseif artifact:find(normalized_query, 1, true) then
    score = score + 80
  end

  if query:lower():find("spring", 1, true) then
    if group == "org.springframework.boot" then
      score = score + (artifact:find("starter", 1, true) and 400 or 150)
    elseif group:find("org.springframework", 1, true) == 1 then
      score = score + 100
    end
  end

  return score
end

function M.search(query, callback)
  local curl = executable(vim.fn.has("win32") == 1 and "curl.exe" or "curl")
  if not curl then
    callback(nil, "curl nao foi encontrado no PATH")
    return
  end

  local group, artifact = query:match("^([^:]+):([^:]+)$")
  local search_query = group and artifact
      and ('g:"%s" AND a:"%s"'):format(group, artifact)
    or query

  vim.system({
    curl,
    "--fail",
    "--silent",
    "--show-error",
    "--get",
    search_endpoint,
    "--data-urlencode",
    "q=" .. search_query,
    "--data-urlencode",
    "rows=30",
    "--data-urlencode",
    "wt=json",
  }, { text = true }, function(result)
    vim.schedule(function()
      if result.code ~= 0 then
        callback(nil, vim.trim(result.stderr or "Falha ao consultar o Maven Central"))
        return
      end

      local ok, decoded = pcall(vim.json.decode, result.stdout or "")
      if not ok then
        callback(nil, "O Maven Central retornou uma resposta invalida")
        return
      end

      local dependencies = decoded.response and decoded.response.docs or {}
      for index, dependency in ipairs(dependencies) do
        dependency._search_order = index
        dependency._search_score = search_score(dependency, query)
      end
      table.sort(dependencies, function(left, right)
        if left._search_score == right._search_score then
          return left._search_order < right._search_order
        end
        return left._search_score > right._search_score
      end)

      callback(dependencies)
    end)
  end)
end

local function reload_pom(bufnr, changedtick)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  vim.api.nvim_buf_call(bufnr, function()
    if vim.api.nvim_buf_get_changedtick(bufnr) == changedtick and not vim.bo.modified then
      local view = vim.fn.winsaveview()
      vim.cmd.edit({ bang = true })
      pcall(vim.fn.winrestview, view)
    else
      notify("O pom.xml mudou durante a operacao; execute :edit! para recarrega-lo", vim.log.levels.WARN)
    end
  end)
end

local function run_add(pom, dependency, scope, include_version, callback)
  local maven = maven_executable()
  if not maven then
    callback(false, "Maven nao foi encontrado no PATH")
    return
  end

  local gav = dependency.g .. ":" .. dependency.a
  if include_version then
    gav = gav .. ":" .. dependency.latestVersion
  end

  local command = {
    maven,
    "-q",
    add_goal,
    "-Dgav=" .. gav,
    "-Dalign=false",
  }
  if scope ~= "compile" then
    table.insert(command, "-Dscope=" .. scope)
  end

  vim.system(command, {
    cwd = vim.fs.dirname(pom),
    text = true,
  }, function(result)
    vim.schedule(function()
      callback(result.code == 0, output_text(result), result)
    end)
  end)
end

function M.add(pom, dependency, scope, callback)
  local bufnr = vim.fn.bufnr(pom)
  if bufnr > 0 and vim.bo[bufnr].modified then
    local saved, save_error = pcall(vim.api.nvim_buf_call, bufnr, function()
      vim.cmd.write()
    end)
    if not saved then
      callback(false, "Nao foi possivel salvar o pom.xml: " .. tostring(save_error))
      return
    end
  end
  local changedtick = bufnr > 0 and vim.api.nvim_buf_get_changedtick(bufnr) or nil

  notify(("Adicionando %s:%s..."):format(dependency.g, dependency.a))
  run_add(pom, dependency, scope, dependency.force_version == true, function(success, message, result)
    if not success and message:find("No version specified and no managed version found", 1, true) then
      if not dependency.latestVersion then
        callback(false, "Nenhuma versao foi encontrada para essa dependencia")
        return
      end
      run_add(pom, dependency, scope, true, function(retry_success, _, retry_result)
        if retry_success then
          if bufnr > 0 then
            reload_pom(bufnr, changedtick)
          end
          callback(true)
        else
          callback(false, short_error(retry_result))
        end
      end)
      return
    end

    if success then
      if bufnr > 0 then
        reload_pom(bufnr, changedtick)
      end
      callback(true)
    else
      callback(false, short_error(result))
    end
  end)
end

local function select_scope(pom, dependency)
  local scopes = {
    { label = "compile (padrao)", value = "compile" },
    { label = "runtime", value = "runtime" },
    { label = "provided", value = "provided" },
    { label = "test", value = "test" },
  }

  vim.ui.select(scopes, {
    prompt = "Escopo da dependencia:",
    format_item = function(item)
      return item.label
    end,
  }, function(scope)
    if not scope then
      return
    end

    M.add(pom, dependency, scope.value, function(success, err)
      if success then
        notify(("Dependencia adicionada: %s:%s"):format(dependency.g, dependency.a))
      else
        notify("Nao foi possivel adicionar a dependencia:\n" .. (err or "erro desconhecido"), vim.log.levels.ERROR)
      end
    end)
  end)
end

function M.open()
  local pom = current_pom()
  if not pom then
    return
  end

  vim.ui.input({ prompt = "Buscar dependencia Maven: " }, function(query)
    query = query and vim.trim(query) or ""
    if query == "" then
      return
    end

    local direct_group, direct_artifact, direct_version = query:match("^([^:]+):([^:]+):([^:]+)$")
    if direct_group then
      select_scope(pom, {
        g = direct_group,
        a = direct_artifact,
        latestVersion = direct_version,
        force_version = true,
      })
      return
    end

    notify("Buscando no Maven Central...")
    M.search(query, function(dependencies, err)
      if not dependencies then
        notify(err, vim.log.levels.ERROR)
        return
      end
      if #dependencies == 0 then
        notify("Nenhuma dependencia encontrada para: " .. query, vim.log.levels.WARN)
        return
      end

      vim.ui.select(dependencies, {
        prompt = "Selecione a dependencia:",
        format_item = function(item)
          local official = item.g:find("org.springframework", 1, true) == 1 and "★ " or "  "
          return ("%s%s:%s  [%s]"):format(official, item.g, item.a, item.latestVersion or "versao gerenciada")
        end,
      }, function(dependency)
        if dependency then
          select_scope(pom, dependency)
        end
      end)
    end)
  end)
end

function M.setup()
  vim.api.nvim_create_user_command("MavenAddDependency", M.open, {
    desc = "Buscar e adicionar uma dependencia ao pom.xml",
  })

  vim.api.nvim_create_autocmd({ "BufEnter", "BufNewFile" }, {
    group = vim.api.nvim_create_augroup("MavenDependencyKeymap", { clear = true }),
    pattern = "pom.xml",
    callback = function(event)
      vim.keymap.set("n", "<C-A-d>", M.open, {
        buffer = event.buf,
        silent = true,
        desc = "Maven: adicionar dependencia",
      })
    end,
  })
end

return M
