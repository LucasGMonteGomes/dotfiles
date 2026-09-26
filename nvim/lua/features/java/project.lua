-- Raiz e ferramenta de build (Maven/Gradle) de projetos Java, usadas pelo
-- jdtls, pelo Spring Boot e pelo build.
local M = {}

local build_files = { "pom.xml", "build.gradle", "build.gradle.kts", "build.xml" }

local function has_build_file(directory)
  for _, file in ipairs(build_files) do
    if vim.uv.fs_stat(vim.fs.joinpath(directory, file)) then
      return true
    end
  end
  return false
end

-- Arquivo do buffer atual; fora de um arquivo (Explorer, terminal), a pasta
-- de trabalho.
function M.current_path()
  local path = vim.bo.buftype == "" and vim.api.nvim_buf_get_name(0) or ""
  return path ~= "" and path or vim.fn.getcwd()
end

-- Um projeto multi-modulo deve ter um unico servidor na raiz. O
-- wrapper/settings define essa raiz; sem eles, sobe enquanto os
-- diretorios pais tambem tiverem arquivo de build (pom pai).
function M.root(path)
  local root = vim.fs.root(path, { "mvnw", "gradlew", "settings.gradle", "settings.gradle.kts" })
  if root then
    return root
  end

  root = vim.fs.root(path, build_files)
  if root then
    local parent = vim.fs.dirname(root)
    while parent ~= root and has_build_file(parent) do
      root = parent
      parent = vim.fs.dirname(root)
    end
    return root
  end

  return vim.fs.root(path, ".git") or vim.fs.dirname(path)
end

-- Modulo Maven/Gradle mais proximo do arquivo (nil fora de um projeto).
function M.module_root(path)
  return vim.fs.root(path, { "pom.xml", "build.gradle", "build.gradle.kts" })
end

-- Comando do build do diretorio: o wrapper (mvnw/gradlew) do projeto, que
-- pode estar num diretorio pai em projetos multi-modulo, ou o mvn/gradle do
-- PATH. Devolve a lista de argumentos e se e Maven, ou nil e o erro.
function M.build_tool(directory)
  local maven = vim.uv.fs_stat(vim.fs.joinpath(directory, "pom.xml")) ~= nil
  local wrapper = maven and "mvnw" or "gradlew"
  local wrapper_dir = vim.fs.root(directory, wrapper)
  if wrapper_dir then
    local path = vim.fs.joinpath(wrapper_dir, wrapper)
    -- Wrappers copiados sem permissao de execucao ainda rodam pelo sh.
    return vim.fn.executable(path) == 1 and { path } or { "sh", path }, maven
  end

  local executable = maven and "mvn" or "gradle"
  if vim.fn.executable(executable) == 0 then
    return nil, executable .. " nao foi encontrado no PATH e o projeto nao tem " .. wrapper
  end
  return { executable }, maven
end

return M
