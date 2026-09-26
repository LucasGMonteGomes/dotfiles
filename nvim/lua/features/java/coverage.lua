-- Cobertura de testes com JaCoCo, sem alterar o pom.xml/build.gradle: o
-- Maven roda o plugin do JaCoCo pela linha de comando e o Gradle recebe o
-- init script gradle/jacoco-init.gradle. O relatorio do modulo do arquivo
-- atual e mostrado na margem pelo nvim-coverage (plugins/coverage.lua).
local M = {}

local project = require("features.java.project")
local build = require("features.java.build")

local jacoco = "org.jacoco:jacoco-maven-plugin:0.8.15"
local shown = false

local function notify(message, level)
  vim.notify(message, level or vim.log.levels.INFO, { title = "Cobertura" })
end

-- Relatorio XML do JaCoCo do modulo do arquivo (nil fora de um projeto).
local function report_path(path)
  local module = project.module_root(path)
  if not module then
    return nil
  end
  local maven = vim.uv.fs_stat(vim.fs.joinpath(module, "pom.xml")) ~= nil
  return vim.fs.joinpath(
    module,
    maven and "target/site/jacoco/jacoco.xml" or "build/reports/jacoco/test/jacocoTestReport.xml"
  ),
    module
end

-- Converte o XML do JaCoCo para LCOV. O leitor de JaCoCo do nvim-coverage
-- ignora pacotes com uma unica classe (o XML dele devolve o elemento sozinho,
-- nao uma lista), enquanto o de LCOV le qualquer relatorio. Por linha:
-- instrucoes executadas e nenhuma perdida = coberta; alguma instrucao ou
-- ramificacao perdida numa linha executada = parcial; nada executado = sem
-- cobertura.
local function jacoco_to_lcov(xml_path, module)
  local file = io.open(xml_path, "r")
  if not file then
    return nil
  end
  local xml = file:read("*a")
  file:close()

  local records = {}
  for package, package_body in xml:gmatch('<package name="([^"]*)">(.-)</package>') do
    for source, body in package_body:gmatch('<sourcefile name="([^"]*)">(.-)</sourcefile>') do
      local language = source:match("%.kt$") and "kotlin" or "java"
      local path = vim.fs.joinpath(module, "src", "main", language, package, source)
      -- Relativo a pasta de trabalho quando possivel: o resumo abrevia
      -- caminhos longos a ponto de ficarem ilegiveis (/m/d/p/.../Calc.java).
      local record = { "SF:" .. (vim.fs.relpath(vim.fn.getcwd(), path) or path) }
      local found, hit, branches, branches_hit = 0, 0, 0, 0
      for nr, mi, ci, mb, cb in body:gmatch('<line nr="(%d+)" mi="(%d+)" ci="(%d+)" mb="(%d+)" cb="(%d+)"') do
        mi, ci, mb, cb = tonumber(mi), tonumber(ci), tonumber(mb), tonumber(cb)
        found = found + 1
        table.insert(record, "DA:" .. nr .. "," .. (ci > 0 and 1 or 0))
        if ci > 0 then
          hit = hit + 1
          if mi > 0 or mb > 0 then
            table.insert(record, "BRDA:" .. nr .. ",0,0,0")
          end
        end
        branches, branches_hit = branches + mb + cb, branches_hit + cb
      end
      vim.list_extend(record, {
        "LF:" .. found,
        "LH:" .. hit,
        "BRF:" .. branches,
        "BRH:" .. branches_hit,
        "end_of_record",
      })
      table.insert(records, table.concat(record, "\n"))
    end
  end

  local lcov_path = xml_path:gsub("%.xml$", ".lcov")
  vim.fn.writefile(vim.split(table.concat(records, "\n"), "\n"), lcov_path)
  return lcov_path
end

-- Com a cobertura visivel, a margem ganha uma segunda coluna: sem ela, a
-- barra da cobertura esconderia a do gitsigns na mesma linha.
local function set_shown(value)
  shown = value
  local signcolumn = value and "yes:2" or "yes"
  vim.go.signcolumn = signcolumn
  for _, window in ipairs(vim.api.nvim_list_wins()) do
    if vim.wo[window].signcolumn:match("^yes") then
      vim.wo[window].signcolumn = signcolumn
    end
  end
end

-- Converte e carrega o relatorio do modulo do arquivo e mostra os sinais.
local function load(bufnr, quiet)
  local report, module = report_path(vim.api.nvim_buf_get_name(bufnr))
  local lcov = report and vim.uv.fs_stat(report) and jacoco_to_lcov(report, module)
  if not lcov then
    if not quiet then
      notify("Nenhum relatorio do JaCoCo neste modulo. Gere com <leader>cr.", vim.log.levels.WARN)
    end
    return false
  end
  require("coverage").load_lcov(lcov, true)
  set_shown(true)
  return true
end

local function java_buffer()
  if vim.bo.filetype ~= "java" then
    notify("Abra um arquivo Java do projeto", vim.log.levels.WARN)
    return nil
  end
  return vim.api.nvim_get_current_buf()
end

-- Roda os testes do projeto com o JaCoCo e mostra a cobertura em seguida.
-- Testes que falham nao impedem o relatorio; as falhas vao para a quickfix.
function M.run()
  local bufnr = java_buffer()
  if not bufnr then
    return
  end
  local root = project.root(project.current_path())
  local maven = vim.uv.fs_stat(vim.fs.joinpath(root, "pom.xml")) ~= nil
  local args = maven
      and { "-Dmaven.test.failure.ignore=true", jacoco .. ":prepare-agent", "test", jacoco .. ":report" }
    or { "test", "--init-script", vim.fs.joinpath(vim.fn.stdpath("config"), "gradle", "jacoco-init.gradle") }

  build.run(args, "Testes com cobertura", function(ok)
    if ok and vim.api.nvim_buf_is_valid(bufnr) then
      load(bufnr)
    end
  end)
end

-- Relatorio ja gerado (por um `mvn verify` do projeto, por exemplo).
function M.load()
  local bufnr = java_buffer()
  if bufnr then
    load(bufnr)
  end
end

function M.toggle()
  local coverage = require("coverage")
  if shown then
    coverage.hide()
    set_shown(false)
  else
    local bufnr = java_buffer()
    if bufnr then
      load(bufnr)
    end
  end
end

function M.summary()
  if not shown then
    notify("Carregue a cobertura antes (<leader>cr ou <leader>cl)", vim.log.levels.WARN)
    return
  end
  require("coverage").summary()
end

function M.jump(direction)
  return function()
    if shown then
      local coverage = require("coverage")
      if direction > 0 then
        coverage.jump_next("uncovered")
      else
        coverage.jump_prev("uncovered")
      end
    end
  end
end

function M.setup()
  vim.keymap.set("n", "<leader>cr", M.run, { desc = "Cobertura: rodar os testes com JaCoCo" })
  vim.keymap.set("n", "<leader>cl", M.load, { desc = "Cobertura: carregar o relatorio existente" })
  vim.keymap.set("n", "<leader>ct", M.toggle, { desc = "Cobertura: mostrar/esconder" })
  vim.keymap.set("n", "<leader>cs", M.summary, { desc = "Cobertura: resumo por arquivo" })
  vim.keymap.set("n", "]u", M.jump(1), { desc = "Cobertura: proxima linha sem cobertura" })
  vim.keymap.set("n", "[u", M.jump(-1), { desc = "Cobertura: linha sem cobertura anterior" })

  -- O nvim-coverage so marca os buffers abertos quando o relatorio carrega;
  -- arquivos abertos depois recarregam o relatorio.
  vim.api.nvim_create_autocmd("BufReadPost", {
    group = vim.api.nvim_create_augroup("JavaCoverage", { clear = true }),
    pattern = "*.java",
    callback = function(event)
      if shown then
        vim.schedule(function()
          if vim.api.nvim_buf_is_valid(event.buf) and vim.bo[event.buf].filetype == "java" then
            load(event.buf, true)
          end
        end)
      end
    end,
  })
end

return M
