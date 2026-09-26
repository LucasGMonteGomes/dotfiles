-- Testes JUnit 5 pelo neotest: ✓/✗ ao lado de cada teste, painel com a
-- arvore do projeto e a mensagem da falha na linha que falhou. Os atalhos do
-- jdtls (<leader>tc, tm, tp, tt, tn em features/java/tests.lua) continuam
-- valendo e sao os que funcionam com JUnit 4.
local function neotest_call(fn)
  return function()
    fn(require("neotest"))
  end
end

-- Num projeto so com JUnit 4, o neotest-java marca todos os testes como
-- falhos sem explicar; os atalhos de execucao avisam e apontam os do jdtls.
local function neotest_run(fn)
  return function()
    local project = require("features.java.project")
    if project.junit4_only(project.build_file_content(project.current_path())) then
      vim.notify(
        "O neotest-java roda apenas JUnit 5. Neste projeto (JUnit 4), use <leader>tc ou <leader>tm.",
        vim.log.levels.WARN,
        { title = "Testes" }
      )
      return
    end
    fn(require("neotest"))
  end
end

return {
  "nvim-neotest/neotest",
  dependencies = {
    "nvim-neotest/nvim-nio",
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
    "mfussenegger/nvim-jdtls",
    -- O neotest-java compila pelo jdtls e depura pelo nvim-dap.
    "mfussenegger/nvim-dap",
    "rcasia/neotest-java",
  },
  cmd = { "Neotest", "NeotestJava" },
  keys = {
    {
      "<leader>ts",
      neotest_call(function(neotest)
        neotest.summary.toggle()
      end),
      desc = "Testes: abrir/fechar o painel",
    },
    {
      "<leader>tr",
      neotest_run(function(neotest)
        neotest.run.run()
      end),
      desc = "Testes: rodar o teste sob o cursor (neotest)",
    },
    {
      "<leader>tf",
      neotest_run(function(neotest)
        neotest.run.run(vim.fn.expand("%"))
      end),
      desc = "Testes: rodar o arquivo (neotest)",
    },
    {
      "<leader>ta",
      neotest_run(function(neotest)
        neotest.run.run(require("features.java.project").root(require("features.java.project").current_path()))
      end),
      desc = "Testes: rodar todos do projeto (neotest)",
    },
    {
      "<leader>tl",
      neotest_run(function(neotest)
        neotest.run.run_last()
      end),
      desc = "Testes: repetir a ultima execucao (neotest)",
    },
    {
      "<leader>td",
      neotest_run(function(neotest)
        neotest.run.run({ strategy = "dap" })
      end),
      desc = "Testes: depurar o teste sob o cursor (neotest)",
    },
    {
      "<leader>to",
      neotest_call(function(neotest)
        neotest.output.open({ enter = true, auto_close = true })
      end),
      desc = "Testes: ver a saida do teste sob o cursor",
    },
    {
      "<leader>tx",
      neotest_call(function(neotest)
        neotest.run.stop()
      end),
      desc = "Testes: interromper a execucao",
    },
  },
  config = function()
    require("neotest").setup({
      adapters = { require("neotest-java")({}) },
      -- A falha ja aparece na linha (diagnostico) e na quickfix; a saida
      -- completa fica em <leader>to, sem janela flutuante a cada execucao.
      output = { open_on_run = false },
      quickfix = {
        open = function()
          if pcall(require, "trouble") then
            vim.cmd("Trouble qflist open focus=false")
          else
            vim.cmd("copen")
          end
        end,
      },
    })
  end,
}
