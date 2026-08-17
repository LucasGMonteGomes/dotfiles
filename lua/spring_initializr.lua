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

  local curl = vim.fn.exepath("curl.exe")
  if curl == "" then
    curl = vim.fn.exepath("curl")
  end
  local tar = vim.fn.exepath("tar.exe")
  if tar == "" then
    tar = vim.fn.exepath("tar")
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

function M.setup()
  vim.api.nvim_create_user_command("SpringInitializr", M.open, {
    desc = "Criar um projeto pela API do Spring Initializr",
  })
  vim.keymap.set("n", "<C-A-i>", M.open, { desc = "Spring: criar projeto (Initializr)" })
end

return M
