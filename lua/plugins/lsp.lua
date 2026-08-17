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
      "mfussenegger/nvim-jdtls",
    },
    config = function()
      require("mason").setup()

      local mason_lspconfig = require("mason-lspconfig")
      mason_lspconfig.setup({
        ensure_installed = {
          "jdtls",
          "rust_analyzer",
          "lua_ls",
          "docker_language_server",
        },
        automatic_installation = true,
      })

      local capabilities = vim.lsp.protocol.make_client_capabilities()

      local java_home = [[C:\Program Files\Java\jdk-21]]
      local java_bin = java_home .. [[\bin]]
      local jdtls = require("jdtls")
      local java_extended_capabilities = vim.deepcopy(jdtls.extendedClientCapabilities)
      java_extended_capabilities.resolveAdditionalTextEditsSupport = true

      -- Java (jdtls)
      vim.lsp.config("jdtls", {
        cmd_env = {
          JAVA_HOME = java_home,
          PATH = java_bin .. ";" .. vim.env.PATH,
        },
        capabilities = capabilities,
        commands = jdtls.commands,
        init_options = {
          extendedClientCapabilities = java_extended_capabilities,
        },
        root_markers = { "pom.xml", "build.gradle", "settings.gradle", ".git", "mvnw", "gradlew" },
        settings = {
          java = {
            configuration = {
              updateBuildConfiguration = "automatic",
              runtimes = {
                {
                  name = "JavaSE-21",
                  path = java_home,
                  default = true,
                },
              },
            },
          },
        },
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

      -- Lua
      vim.lsp.config("lua_ls", {
        capabilities = capabilities,
        root_markers = { ".luarc.json", ".luarc.jsonc", ".git" },
        settings = {
          Lua = {
            diagnostics = { globals = { "vim" } },
          },
        },
      })

      -- Dockerfile e Docker Compose
      vim.lsp.config("docker_language_server", {
        capabilities = capabilities,
        init_options = {
          telemetry = "off",
        },
      })

      -- Ativa os servidores LSP
      vim.lsp.enable("jdtls")
      vim.lsp.enable("rust_analyzer")
      vim.lsp.enable("lua_ls")
      vim.lsp.enable("docker_language_server")

      vim.diagnostic.config({
        virtual_text = false,
        severity_sort = true,
        signs = true,
        underline = true,
        update_in_insert = false,
        float = {
          border = "rounded",
          source = "if_many",
        },
      })

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

      local function enable_java_completion_while_typing(client)
        local completion = client.server_capabilities.completionProvider
        if not completion then
          return
        end

        completion.triggerCharacters = completion.triggerCharacters or {}

        local registered = {}
        for _, character in ipairs(completion.triggerCharacters) do
          registered[character] = true
        end

        local identifier_characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_"
        for index = 1, #identifier_characters do
          local character = identifier_characters:sub(index, index)
          if not registered[character] then
            table.insert(completion.triggerCharacters, character)
            registered[character] = true
          end
        end
      end

      -- Atalhos de teclado quando qualquer LSP conectar ao buffer
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
        callback = function(ev)
          local opts = { buffer = ev.buf, silent = true }
          local client = vim.lsp.get_client_by_id(ev.data.client_id)

          if client and client:supports_method("textDocument/completion") then
            if client.name == "jdtls" then
              enable_java_completion_while_typing(client)
            end

            vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })

            vim.keymap.set("i", "<C-Space>", vim.lsp.completion.get, {
              buffer = ev.buf,
              silent = true,
              desc = "LSP: abrir autocomplete",
            })
            vim.keymap.set("i", "<CR>", function()
              if vim.fn.pumvisible() == 1 then
                return "<C-y>"
              end
              return _G.MiniPairs and MiniPairs.cr() or "<CR>"
            end, {
              buffer = ev.buf,
              expr = true,
              desc = "Aceitar autocomplete ou criar nova linha",
            })
          end

          vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
          vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
          vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
          vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
          vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
          vim.keymap.set("n", "<C-l>", vim.lsp.buf.code_action, {
            buffer = ev.buf,
            silent = true,
            desc = "LSP: acoes de codigo",
          })
          vim.keymap.set("n", "<C-A-r>", vim.lsp.buf.rename, {
            buffer = ev.buf,
            silent = true,
            desc = "LSP: renomear simbolo",
          })
          vim.keymap.set("n", "<C-A-l>", organize_imports_and_format, {
            buffer = ev.buf,
            silent = true,
            desc = "Organizar imports e formatar",
          })
          vim.keymap.set("n", "[d", function()
            vim.diagnostic.jump({ count = -1, float = true })
          end, opts)
          vim.keymap.set("n", "]d", function()
            vim.diagnostic.jump({ count = 1, float = true })
          end, opts)
          vim.keymap.set("n", "df", vim.diagnostic.open_float, opts)
        end,
      })
    end,
  },
}
