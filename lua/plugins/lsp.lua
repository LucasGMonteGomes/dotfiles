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

      local function organize_imports(bufnr)
        local win = vim.fn.bufwinid(bufnr)
        if win == -1 then
          return
        end

        local clients = vim.lsp.get_clients({ bufnr = bufnr, method = "textDocument/codeAction" })
        for _, client in ipairs(clients) do
          local params = vim.lsp.util.make_range_params(win, client.offset_encoding)
          params.context = {
            diagnostics = {},
            only = { "source.organizeImports" },
            triggerKind = vim.lsp.protocol.CodeActionTriggerKind.Invoked,
          }

          local response = client:request_sync("textDocument/codeAction", params, 2000, bufnr)
          for _, action in ipairs(response and response.result or {}) do
            local kind = action.kind or ""
            local is_organize_imports = kind == "source.organizeImports"
              or vim.startswith(kind, "source.organizeImports.")

            if is_organize_imports and not action.disabled then
              if not (action.edit and action.command) and client:supports_method("codeAction/resolve") then
                local resolved = client:request_sync("codeAction/resolve", action, 2000, bufnr)
                if resolved and resolved.result then
                  action = resolved.result
                end
              end

              if action.edit then
                vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding)
              end

              local command = type(action.command) == "table" and action.command
                or (type(action.command) == "string" and action or nil)
              if command then
                local handler = client.commands[command.command] or vim.lsp.commands[command.command]
                if handler then
                  handler(command, { bufnr = bufnr, client_id = client.id })
                else
                  client:request_sync("workspace/executeCommand", {
                    command = command.command,
                    arguments = command.arguments,
                  }, 2000, bufnr)
                end
              end

              return
            end
          end
        end
      end

      local function organize_imports_and_format()
        local bufnr = vim.api.nvim_get_current_buf()
        organize_imports(bufnr)
        vim.lsp.buf.format({ bufnr = bufnr, async = false })
      end

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
          vim.keymap.set("n", "<C-A-l>", organize_imports_and_format, {
            buffer = ev.buf,
            silent = true,
            desc = "Organizar imports e formatar",
          })
          vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
          vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
        end,
      })
    end,
  },
}
