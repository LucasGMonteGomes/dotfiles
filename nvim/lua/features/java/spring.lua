-- Integracao com Spring Initializr.
local M = {}

local endpoint = "https://start.spring.io/starter.zip"

local function notify(message, level)
  vim.notify(message, level or vim.log.levels.INFO, { title = "Spring Initializr" })
end

local function prompt(label, default, callback)
  vim.ui.input({ prompt = label .. ": ", default = default }, function(value)
    if value == nil then
      notify("Criacao cancelada", vim.log.levels.WARN)
      return
    end

    value = vim.trim(value)
    callback(value ~= "" and value or default)
  end)
end

local function directory_has_files(path)
  local stat = vim.uv.fs_stat(path)
  if not stat then
    return false
  end
  if stat.type ~= "directory" then
    return true
  end

  local scan = vim.uv.fs_scandir(path)
  return scan ~= nil and vim.uv.fs_scandir_next(scan) ~= nil
end

local function open_project(path, project_type)
  vim.ui.select({ "Sim", "Nao" }, { prompt = "Abrir o novo projeto agora?" }, function(choice)
    if choice ~= "Sim" then
      return
    end

    vim.cmd.cd(vim.fn.fnameescape(path))
    local candidates = project_type == "maven-project"
        and { "pom.xml" }
      or { "build.gradle.kts", "build.gradle" }

    for _, file in ipairs(candidates) do
      local full_path = vim.fs.joinpath(path, file)
      if vim.uv.fs_stat(full_path) then
        vim.cmd.edit(vim.fn.fnameescape(full_path))
        return
      end
    end
  end)
end

function M.generate(options)
  local destination = vim.fs.normalize(vim.fn.fnamemodify(options.destination, ":p"))
  if directory_has_files(destination) then
    notify("O destino ja existe e nao esta vazio: " .. destination, vim.log.levels.ERROR)
    return
  end

  local curl = vim.fn.exepath("curl")
  if curl == "" then
    curl = vim.fn.exepath("curl.exe")
  end
  local tar = vim.fn.exepath("tar")
  if tar == "" then
    tar = vim.fn.exepath("tar.exe")
  end
  if curl == "" or tar == "" then
    notify("curl e tar precisam estar disponiveis no PATH", vim.log.levels.ERROR)
    return
  end

  local archive = vim.fn.tempname() .. ".zip"
  local package_name = (options.group_id .. "." .. options.artifact_id:gsub("[^%w_]", "")):lower()
  local arguments = {
    curl,
    "--fail",
    "--location",
    "--silent",
    "--show-error",
    "--get",
    endpoint,
    "--output",
    archive,
    "--data-urlencode",
    "type=" .. options.project_type,
    "--data-urlencode",
    "language=" .. options.language,
    "--data-urlencode",
    "javaVersion=" .. options.java_version,
    "--data-urlencode",
    "groupId=" .. options.group_id,
    "--data-urlencode",
    "artifactId=" .. options.artifact_id,
    "--data-urlencode",
    "name=" .. options.artifact_id,
    "--data-urlencode",
    "packageName=" .. package_name,
    "--data-urlencode",
    "dependencies=" .. options.dependencies,
    "--data-urlencode",
    "baseDir=",
  }

  notify("Baixando o projeto...")
  vim.system(arguments, { text = true }, function(download)
    vim.schedule(function()
      if download.code ~= 0 then
        vim.fn.delete(archive)
        notify("Falha ao gerar o projeto: " .. vim.trim(download.stderr or "erro desconhecido"), vim.log.levels.ERROR)
        return
      end

      vim.fn.mkdir(destination, "p")
      vim.system({ tar, "-xf", archive, "-C", destination }, { text = true }, function(extract)
        vim.schedule(function()
          vim.fn.delete(archive)
          if extract.code ~= 0 then
            notify("Falha ao extrair o projeto: " .. vim.trim(extract.stderr or "erro desconhecido"), vim.log.levels.ERROR)
            return
          end

          notify("Projeto criado em " .. destination)
          if options.open_after ~= false then
            open_project(destination, options.project_type)
          end
        end)
      end)
    end)
  end)
end

function M.open()
  local build_options = {
    { label = "Maven", value = "maven-project" },
    { label = "Gradle (Groovy)", value = "gradle-project" },
    { label = "Gradle (Kotlin)", value = "gradle-project-kotlin" },
  }

  vim.ui.select(build_options, {
    prompt = "Spring Initializr - build:",
    format_item = function(item)
      return item.label
    end,
  }, function(build)
    if not build then
      return
    end

    vim.ui.select({ "java", "kotlin", "groovy" }, { prompt = "Linguagem:" }, function(language)
      if not language then
        return
      end

      vim.ui.select({ "21", "17", "25" }, { prompt = "Versao do Java:" }, function(java_version)
        if not java_version then
          return
        end

        prompt("Group ID", "com.example", function(group_id)
          prompt("Artifact ID", "demo", function(artifact_id)
            prompt("Dependencias (IDs separados por virgula)", "web", function(dependencies)
              local default_destination = vim.fs.joinpath(vim.fn.getcwd(), artifact_id)
              prompt("Pasta de destino", default_destination, function(destination)
                M.generate({
                  project_type = build.value,
                  language = language,
                  java_version = java_version,
                  group_id = group_id,
                  artifact_id = artifact_id,
                  dependencies = dependencies,
                  destination = destination,
                })
              end)
            end)
          end)
        end)
      end)
    end)
  end)
end

-- Execucao da aplicacao (spring-boot:run / bootRun) num terminal proprio por
-- projeto, para que os logs continuem visiveis depois de esconde-lo.
local build_files = { "pom.xml", "build.gradle", "build.gradle.kts" }
local applications = {}

-- Modulo do arquivo atual; fora de um arquivo (Explorer, terminal), usa a
-- pasta de trabalho.
local function project_root()
  local path = vim.bo.buftype == "" and vim.api.nvim_buf_get_name(0) or ""
  return vim.fs.root(path ~= "" and path or vim.fn.getcwd(), build_files)
end

-- O wrapper (mvnw/gradlew) pode estar num diretorio pai, em projetos
-- multi-modulo; ele encontra a raiz do build sozinho.
local function run_command(root)
  local maven = vim.uv.fs_stat(vim.fs.joinpath(root, "pom.xml")) ~= nil
  local wrapper = maven and "mvnw" or "gradlew"
  local wrapper_dir = vim.fs.root(root, wrapper)
  local executable = wrapper_dir and vim.fs.joinpath(wrapper_dir, wrapper) or (maven and "mvn" or "gradle")
  if not wrapper_dir and vim.fn.executable(executable) == 0 then
    return nil, executable .. " nao foi encontrado no PATH e o projeto nao tem " .. wrapper
  end
  local task = maven and "spring-boot:run" or "bootRun"
  return vim.fn.shellescape(executable) .. " " .. task
end

function M.run()
  local root = project_root()
  if not root then
    notify("Nenhum pom.xml ou build.gradle encontrado a partir deste arquivo", vim.log.levels.WARN)
    return
  end

  -- Ja esta rodando (on_exit remove da tabela): apenas mostra ou esconde os logs.
  if applications[root] then
    applications[root]:toggle()
    return
  end

  local command, err = run_command(root)
  if not command then
    notify(err, vim.log.levels.ERROR)
    return
  end

  application = require("toggleterm.terminal").Terminal:new({
    cmd = command,
    dir = root,
    direction = "horizontal",
    display_name = "Spring Boot: " .. vim.fs.basename(root),
    hidden = true,
    -- Mantem os logs na tela quando a aplicacao termina ou falha.
    close_on_exit = false,
    on_exit = function()
      applications[root] = nil
    end,
  })
  applications[root] = application
  application:open()
end

function M.stop()
  local root = project_root()
  local application = root and applications[root]
  if not application then
    notify("Nenhuma aplicacao deste projeto esta rodando", vim.log.levels.WARN)
    return
  end
  application:shutdown()
  applications[root] = nil
  notify("Aplicacao encerrada: " .. vim.fs.basename(root))
end

-- Busca de simbolos do Spring Boot Language Server (`@/` endpoints, `@+`
-- beans). A consulta vai somente para ele: o jdtls tambem responderia com
-- simbolos Java sem relacao.
local function spring_symbols(query, title)
  local client = vim.lsp.get_clients({ name = "spring-boot" })[1]
  if not client then
    notify("O Spring Boot Language Server nao esta ativo neste projeto", vim.log.levels.WARN)
    return
  end

  client:request("workspace/symbol", { query = query }, function(err, result)
    if err then
      notify("Falha ao buscar " .. title:lower() .. ": " .. err.message, vim.log.levels.ERROR)
      return
    end

    local items = {}
    for _, symbol in ipairs(result or {}) do
      local location = symbol.location
      if location and location.range then
        table.insert(items, {
          text = symbol.name,
          file = vim.uri_to_fname(location.uri),
          pos = { location.range.start.line + 1, location.range.start.character },
        })
      end
    end
    if #items == 0 then
      notify("Nenhum resultado em " .. title:lower(), vim.log.levels.WARN)
      return
    end

    Snacks.picker({
      title = title,
      items = items,
      format = function(item)
        return {
          { item.text },
          { "  " },
          { vim.fn.fnamemodify(item.file, ":t"), "Comment" },
        }
      end,
    })
  end)
end

function M.endpoints()
  spring_symbols("@/", "Endpoints")
end

function M.beans()
  spring_symbols("@+", "Beans")
end

function M.setup()
  vim.keymap.set("n", "<leader>se", M.endpoints, { desc = "Spring: buscar endpoints" })
  vim.keymap.set("n", "<leader>sb", M.beans, { desc = "Spring: buscar beans" })

  vim.api.nvim_create_user_command("SpringInitializr", M.open, {
    desc = "Criar um projeto pela API do Spring Initializr",
  })
  vim.keymap.set("n", "<C-A-i>", M.open, { desc = "Spring: criar projeto (Initializr)" })

  vim.api.nvim_create_user_command("SpringBootRun", M.run, {
    desc = "Rodar a aplicacao Spring Boot do projeto atual",
  })
  vim.api.nvim_create_user_command("SpringBootStop", M.stop, {
    desc = "Encerrar a aplicacao Spring Boot do projeto atual",
  })
  vim.keymap.set("n", "<leader>sr", M.run, { desc = "Spring: rodar aplicacao / mostrar logs" })
  vim.keymap.set("n", "<leader>ss", M.stop, { desc = "Spring: encerrar aplicacao" })
end

return M
