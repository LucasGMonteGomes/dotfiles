-- Exibicao da cobertura na margem e resumo por arquivo. O relatorio do
-- JaCoCo e gerado, convertido para LCOV e carregado por
-- features/java/coverage.lua, que tambem define os atalhos.
return {
  "andythigpen/nvim-coverage",
  dependencies = { "nvim-lua/plenary.nvim" },
  lazy = true,
  config = function()
    require("coverage").setup({
      -- Os comandos :Coverage* do plugin sao substituidos pelos atalhos.
      commands = false,
      -- Mesmas cores da statusline (plugins/lualine.lua).
      highlights = {
        covered = { fg = "#73bd7a" },
        uncovered = { fg = "#f27481" },
        partial = { fg = "#d5b778" },
      },
      -- Largura para o caminho do arquivo caber sem ser abreviado.
      summary = {
        width_percentage = 0.9,
        min_coverage = 80.0,
      },
    })
  end,
}
