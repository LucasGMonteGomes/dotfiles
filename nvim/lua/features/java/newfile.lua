-- Esqueleto de arquivos Java novos, como o "New Java Class" do IntelliJ: o
-- `package` vem do caminho e o tipo (classe, interface, record, teste,
-- controller...) e escolhido num seletor. O Explorer cria o arquivo vazio no
-- disco, por isso tambem vale para arquivos .java vazios abertos depois.
local M = {}

-- Raizes de codigo; o que vem depois delas e o pacote. `src/` sozinho cobre
-- projetos sem Maven/Gradle.
local source_roots = {
  "/src/main/java/",
  "/src/test/java/",
  "/src/[^/]+/java/",
  "/src/",
}

local function package_name(path)
  for _, root in ipairs(source_roots) do
    local _, finish = path:find(root)
    if finish then
      local directory = vim.fs.dirname(path:sub(finish + 1))
      return directory ~= "." and directory:gsub("/", ".") or nil
    end
  end
  return nil
end

-- Conteudo do pom.xml/build.gradle, usado para decidir se os modelos do
-- Spring aparecem e qual versao do JUnit usar.
local function build_file_content(path)
  local root = vim.fs.root(path, { "pom.xml", "build.gradle", "build.gradle.kts" })
  if not root then
    return ""
  end
  for _, name in ipairs({ "pom.xml", "build.gradle", "build.gradle.kts" }) do
    local file = io.open(vim.fs.joinpath(root, name), "r")
    if file then
      local content = file:read("*a")
      file:close()
      return content
    end
  end
  return ""
end

-- "UserController" -> "users": ponto de partida para o @RequestMapping.
local function resource_path(name)
  local resource = name:gsub("Controller$", "")
  resource = resource:sub(1, 1):lower() .. resource:sub(2)
  return resource:gsub("(%u)", function(letter)
    return "-" .. letter:lower()
  end) .. "s"
end

-- Cada modelo devolve o corpo em sintaxe de snippet do LSP: $1, $2 sao
-- campos (Tab avanca) e $0 e onde o cursor termina. `imports` vai depois do
-- package.
local templates = {
  {
    label = "Classe",
    body = function(name)
      return {}, "public class " .. name .. " {\n\n    $0\n}"
    end,
  },
  {
    label = "Interface",
    body = function(name)
      return {}, "public interface " .. name .. " {\n\n    $0\n}"
    end,
  },
  {
    label = "Record",
    body = function(name)
      return {}, "public record " .. name .. "(${1}) {\n\n    $0\n}"
    end,
  },
  {
    label = "Enum",
    body = function(name)
      return {}, "public enum " .. name .. " {\n\n    ${1:VALOR}$0\n}"
    end,
  },
  {
    label = "Classe abstrata",
    body = function(name)
      return {}, "public abstract class " .. name .. " {\n\n    $0\n}"
    end,
  },
  {
    label = "Excecao (RuntimeException)",
    match = "Exception$",
    body = function(name)
      return {}, "public class " .. name .. " extends RuntimeException {\n\n"
        .. "    public " .. name .. "(String message) {\n        super(message);\n    }\n$0}"
    end,
  },
  {
    label = "Teste (JUnit)",
    match = "Tests?$",
    test = true,
    body = function(name, build)
      local method = "    @Test\n    void ${1:deveFazerAlgo}() {\n        $0\n    }"
      -- JUnit 4 so quando o projeto declara o `junit` antigo sem o Jupiter.
      if build:find("<artifactId>junit</artifactId>", 1, true) and not build:find("junit-jupiter", 1, true)
        and not build:find("spring-boot-starter-test", 1, true)
      then
        return { "org.junit.Test" }, "public class " .. name .. " {\n\n" .. method:gsub("    void", "    public void") .. "\n}"
      end
      return { "org.junit.jupiter.api.Test" }, "class " .. name .. " {\n\n" .. method .. "\n}"
    end,
  },
  {
    label = "Spring: @RestController",
    match = "Controller$",
    spring = true,
    body = function(name)
      return {
        "org.springframework.web.bind.annotation.RequestMapping",
        "org.springframework.web.bind.annotation.RestController",
      }, '@RestController\n@RequestMapping("/${1:' .. resource_path(name) .. '}")\npublic class ' .. name .. " {\n\n    $0\n}"
    end,
  },
  {
    label = "Spring: @Service",
    match = "Service$",
    spring = true,
    body = function(name)
      return { "org.springframework.stereotype.Service" }, "@Service\npublic class " .. name .. " {\n\n    $0\n}"
    end,
  },
  {
    label = "Spring: JpaRepository",
    match = "Repository$",
    spring = true,
    body = function(name)
      local entity = name:gsub("Repository$", "")
      return { "org.springframework.data.jpa.repository.JpaRepository" },
        "public interface " .. name .. " extends JpaRepository<${1:" .. entity .. "}, ${2:Long}> {\n\n    $0\n}"
    end,
  },
  {
    label = "Spring: @Configuration",
    match = "Config%a*$",
    spring = true,
    body = function(name)
      return { "org.springframework.context.annotation.Configuration" },
        "@Configuration\npublic class " .. name .. " {\n\n    $0\n}"
    end,
  },
  {
    label = "Spring: @Component",
    spring = true,
    body = function(name)
      return { "org.springframework.stereotype.Component" }, "@Component\npublic class " .. name .. " {\n\n    $0\n}"
    end,
  },
}

-- Modelos disponiveis, com os que combinam com o nome (UserController,
-- UserServiceTest...) primeiro. Em src/test, o teste vem antes de tudo.
local function available_templates(name, path, build)
  local spring = build:find("org.springframework", 1, true) ~= nil
  local in_tests = path:find("/src/test/", 1, true) ~= nil
  local matched, others = {}, {}
  for _, template in ipairs(templates) do
    if spring or not template.spring then
      local is_match = (template.match and name:find(template.match)) or (template.test and in_tests)
      table.insert(is_match and matched or others, template)
    end
  end
  -- "UserServiceTest" combina com o teste e com o @Service; o teste ganha.
  table.sort(matched, function(a, b)
    return (a.test and 1 or 0) > (b.test and 1 or 0)
  end)
  return vim.list_extend(matched, others)
end

local function is_empty(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  return #lines == 1 and lines[1] == ""
end

local function fill(bufnr)
  local path = vim.api.nvim_buf_get_name(bufnr)
  -- Somente arquivos reais: nada de jdt://, diffview:// ou buffers especiais.
  if vim.bo[bufnr].buftype ~= "" or not vim.bo[bufnr].modifiable or not vim.startswith(path, "/") then
    return
  end

  local name = vim.fn.fnamemodify(path, ":t:r")
  if not name:match("^[%a_$][%w_$]*$") or name == "package-info" or name == "module-info" then
    return
  end

  local build = build_file_content(path)
  vim.ui.select(available_templates(name, path, build), {
    prompt = "Novo arquivo Java (" .. name .. "):",
    format_item = function(template)
      return template.label
    end,
  }, function(template)
    -- Esc deixa o arquivo vazio. O seletor pode ter levado o foco a outra
    -- janela; o snippet so e expandido no buffer que o pediu, ainda vazio.
    if not template or vim.api.nvim_get_current_buf() ~= bufnr or not is_empty(bufnr) then
      return
    end

    local imports, body = template.body(name, build)
    local header = {}
    local package = package_name(path)
    if package then
      table.insert(header, "package " .. package .. ";\n")
    end
    if #imports > 0 then
      table.sort(imports)
      for _, import in ipairs(imports) do
        table.insert(header, "import " .. import .. ";")
      end
      table.insert(header, "")
    end

    vim.api.nvim_win_set_cursor(0, { 1, 0 })
    vim.snippet.expand(table.concat(header, "\n") .. (#header > 0 and "\n" or "") .. body)
  end)
end

function M.setup()
  vim.api.nvim_create_autocmd({ "BufNewFile", "BufReadPost" }, {
    group = vim.api.nvim_create_augroup("JavaNewFile", { clear = true }),
    pattern = "*.java",
    callback = function(event)
      if is_empty(event.buf) then
        -- Espera o buffer aparecer na janela antes de abrir o seletor.
        vim.schedule(function()
          if vim.api.nvim_buf_is_valid(event.buf) and is_empty(event.buf) then
            fill(event.buf)
          end
        end)
      end
    end,
  })
end

return M
