return {
  {
    "williamboman/mason.nvim",
    build = ":MasonUpdate",
    cmd = "Mason",
    config = function()
      require("mason").setup()
    end,
  },
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "hrsh7th/cmp-nvim-lsp",
    },
    config = function()
      require("mason").setup()

      local mason_lspconfig = require("mason-lspconfig")
      mason_lspconfig.setup({
        ensure_installed = { "jdtls", "rust_analyzer", "ts_ls" },
        automatic_installation = true,
      })

      local capabilities = vim.lsp.protocol.make_client_capabilities()
      local has_cmp, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
      if has_cmp then
        capabilities = cmp_nvim_lsp.default_capabilities(capabilities)
      end

      local data_dir = vim.fn.stdpath("cache") .. "/jdtls/workspace"

      -- Java (jdtls)
      vim.lsp.config("jdtls", {
        cmd = { "jdtls", "-data", data_dir },
        capabilities = capabilities,
        root_markers = { "pom.xml", "build.gradle", "settings.gradle", ".git", "mvnw", "gradlew" },
        root_dir = function(bufnr, on_dir)
          local root = vim.fs.root(bufnr, { "pom.xml", "build.gradle", "settings.gradle", ".git", "mvnw", "gradlew" })
            or vim.fs.dirname(vim.api.nvim_buf_get_name(bufnr))
            or vim.fn.getcwd()
          on_dir(root)
        end,
      })

      -- Rust (rust_analyzer)
      vim.lsp.config("rust_analyzer", {
        capabilities = capabilities,
        root_markers = { "Cargo.toml", "rust-project.json", ".git" },
      })

      -- TypeScript / JavaScript (ts_ls)
      vim.lsp.config("ts_ls", {
        capabilities = capabilities,
        root_markers = { "tsconfig.json", "package.json", "jsconfig.json", ".git" },
      })

      -- Ativa os servidores LSP
      vim.lsp.enable("jdtls")
      vim.lsp.enable("rust_analyzer")
      vim.lsp.enable("ts_ls")

      -- Atalhos de teclado quando qualquer LSP conectar ao buffer
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
        callback = function(ev)
          local opts = { buffer = ev.buf, silent = true }
          vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
          vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
          vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
          vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
          vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
          vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
          vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
          vim.keymap.set("n", "<leader>f", function() vim.lsp.buf.format({ async = true }) end, opts)
          vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
          vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
        end,
      })
    end,
  },
}