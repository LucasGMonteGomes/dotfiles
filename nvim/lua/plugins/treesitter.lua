return {
  {
    -- O branch `main` substitui o `master`, congelado pelo projeto. Ele nao
    -- tem mais os modulos de highlight/indent/selecao: o highlight e o
    -- `vim.treesitter.start()` do Neovim e a selecao incremental e nativa do
    -- 0.12 (`an`/`in` no modo visual).
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    -- O plugin nao suporta lazy-loading.
    lazy = false,
    build = ":TSUpdate",
    config = function()
      local treesitter = require("nvim-treesitter")
      local parsers = {
        "java",
        "rust",
        "json",
        "yaml",
        "toml",
        "xml",
        "properties",
        "markdown",
        "markdown_inline",
        "bash",
        "http",
        "dockerfile",
        "lua",
        "vim",
        "vimdoc",
        "query",
        "regex",
      }

      -- Os parsers sao compilados pelo tree-sitter CLI, instalado pelo Mason.
      -- O Mason so entra no PATH quando carrega (ao abrir um arquivo), por
      -- isso o diretorio e adicionado aqui tambem.
      local mason_bin = vim.fs.joinpath(vim.fn.stdpath("data"), "mason", "bin")
      if not vim.env.PATH:find(mason_bin, 1, true) then
        vim.env.PATH = mason_bin .. ":" .. vim.env.PATH
      end
      local can_install = vim.fn.executable("tree-sitter") == 1
      if can_install then
        treesitter.install(parsers)
      end

      local function start(buf, lang)
        if vim.api.nvim_buf_is_valid(buf) and pcall(vim.treesitter.start, buf, lang) then
          vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
      end

      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("TreesitterStart", { clear = true }),
        callback = function(event)
          local lang = vim.treesitter.language.get_lang(event.match)
          if not lang then
            return
          end
          -- Equivale ao antigo auto_install: linguagens fora da lista tem o
          -- parser instalado na primeira vez que um arquivo delas e aberto.
          if not vim.list_contains(treesitter.get_installed(), lang) then
            if can_install and vim.list_contains(treesitter.get_available(), lang) then
              treesitter.install(lang):await(vim.schedule_wrap(function()
                start(event.buf, lang)
              end))
            end
            return
          end
          start(event.buf, lang)
        end,
      })

      -- Mantem o fluxo anterior: Ctrl+Espaco inicia a selecao do no sob o
      -- cursor e a expande; Backspace volta um nivel.
      vim.keymap.set("n", "<C-Space>", "van", { remap = true, desc = "Selecionar no do codigo" })
      vim.keymap.set("x", "<C-Space>", "an", { remap = true, desc = "Expandir selecao" })
      vim.keymap.set("x", "<BS>", "in", { remap = true, desc = "Reduzir selecao" })
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter-context",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    keys = {
      { "<C-A-h>", "<cmd>TSContext toggle<cr>", desc = "Ativar/desativar cabecalho de contexto" },
    },
    opts = {
      enable = true,
      max_lines = 2,
      min_window_height = 20,
      line_numbers = true,
      multiline_threshold = 3,
      trim_scope = "outer",
      mode = "cursor",
    },
  },
}
