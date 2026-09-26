return {
    {
        "mason-org/mason.nvim",
        build = ":MasonUpdate",
        cmd = {
            "Mason",
            "MasonInstall",
            "MasonUninstall",
            "MasonUpdate",
            "MasonLog",
        },
        config = function()
            require("mason").setup()

            -- Pacotes que o mason-lspconfig nao gerencia: depurador e testes
            -- Java, SonarLint, Spring Boot Tools (iniciado pelo spring-boot.nvim)
            -- e o tree-sitter CLI, que compila os parsers do nvim-treesitter.
            -- Sao instalados em segundo plano na primeira vez.
            local tools = {
                "java-debug-adapter",
                "java-test",
                "sonarlint-language-server",
                "vscode-spring-boot-tools",
                "tree-sitter-cli",
            }
            local registry = require("mason-registry")
            registry.refresh(function()
                for _, name in ipairs(tools) do
                    local ok, package = pcall(registry.get_package, name)
                    if ok and not package:is_installed() and not package:is_installing() then
                        package:install({}, function(success)
                            vim.schedule(function()
                                vim.notify(
                                    success and (name .. " instalado. Reinicie o Neovim para usa-lo.")
                                        or ("Falha ao instalar " .. name .. ". Veja :MasonLog."),
                                    success and vim.log.levels.INFO or vim.log.levels.ERROR,
                                    { title = "Mason" }
                                )
                            end)
                        end)
                    end
                end
            end)
        end,
    },
    {
        "neovim/nvim-lspconfig",
        event = { "BufReadPre", "BufNewFile" },
        dependencies = {
            "mason-org/mason.nvim",
            "mason-org/mason-lspconfig.nvim",
            "mfussenegger/nvim-jdtls",
            "b0o/SchemaStore.nvim",
            "saghen/blink.cmp",
            -- Precisa ser configurado antes do jdtls (ver plugins/spring.lua).
            "JavaHello/spring-boot.nvim",
        },
        config = function()
            local mason_lspconfig = require("mason-lspconfig")
            mason_lspconfig.setup({
                ensure_installed = {
                    "jdtls",
                    "rust_analyzer",
                    "lua_ls",
                    "yamlls",
                    "docker_language_server",
                    "markdown_oxide",
                },
                -- Os servidores sao ativados explicitamente com vim.lsp.enable abaixo.
                automatic_enable = false,
            })

            -- O autocomplete e feito pelo blink.cmp (plugins/completion.lua).
            local capabilities = require("blink.cmp").get_lsp_capabilities()

            require("features.java.jdtls").setup(capabilities)

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

            -- YAML genérico
            vim.lsp.config("yamlls", {
                capabilities = capabilities,

                -- Docker Compose fica sob responsabilidade do Docker Language Server.
                filetypes = {
                    "yaml",
                    "yaml.gitlab",
                    "yaml.helm-values",
                },

                settings = {
                    redhat = {
                        telemetry = {
                            enabled = false,
                        },
                    },

                    yaml = {
                        validate = true,
                        hover = true,

                        format = {
                            enable = true,
                        },

                        schemaStore = {
                            enable = false,
                            url = "",
                        },

                        schemas = require("schemastore").yaml.schemas(),
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

            -- Markdown e Zettelkasten: links, backlinks, titulos e referencias.
            local markdown_capabilities = vim.deepcopy(capabilities)
            markdown_capabilities.workspace = markdown_capabilities.workspace or {}
            markdown_capabilities.workspace.didChangeWatchedFiles = {
                dynamicRegistration = true,
            }
            vim.lsp.config("markdown_oxide", {
                capabilities = markdown_capabilities,
                root_markers = { ".moxide.toml", ".obsidian", ".git" },
            })

            -- Ativa os servidores LSP
            vim.lsp.enable("jdtls")
            vim.lsp.enable("rust_analyzer")
            vim.lsp.enable("lua_ls")
            vim.lsp.enable("yamlls")
            vim.lsp.enable("docker_language_server")
            vim.lsp.enable("markdown_oxide")

            -- Dicas inline e lentes ficam ativas em todo servidor que as suporte.
            vim.lsp.inlay_hint.enable(true)
            vim.lsp.codelens.enable(true)
            vim.keymap.set("n", "<leader>ih", function()
                vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
            end, { desc = "LSP: mostrar/ocultar dicas inline" })

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

            -- Atalhos de teclado quando qualquer LSP conectar ao buffer
            vim.api.nvim_create_autocmd("LspAttach", {
                group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
                callback = function(ev)
                    local opts = { buffer = ev.buf, silent = true }

                    -- K (hover), grr (referencias), gri (implementacao), grt (tipo),
                    -- grn (rename), gra (acoes) e gO (simbolos) sao padroes do Neovim.
                    -- Mapear `gr` ou `gi` aqui atrasaria esses atalhos e apagaria o
                    -- `gi` nativo (voltar a inserir onde parou).
                    vim.keymap.set("n", "gd", vim.lsp.buf.definition, {
                        buffer = ev.buf,
                        silent = true,
                        desc = "LSP: ir para definicao",
                    })
                    vim.keymap.set("n", "gD", vim.lsp.buf.declaration, {
                        buffer = ev.buf,
                        silent = true,
                        desc = "LSP: ir para declaracao",
                    })
                    vim.keymap.set("n", "<C-l>", vim.lsp.buf.code_action, {
                        buffer = ev.buf,
                        silent = true,
                        desc = "LSP: acoes de codigo",
                    })
                    -- F2 como no VS Code/IntelliJ; Ctrl+Alt+R fica com o kulala (.http).
                    vim.keymap.set("n", "<F2>", vim.lsp.buf.rename, {
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
                    -- `df` colidia com `d` + `f{char}` (ex.: `df;`). `gl` nao tem uso nativo.
                    vim.keymap.set("n", "gl", vim.diagnostic.open_float, {
                        buffer = ev.buf,
                        silent = true,
                        desc = "LSP: mostrar diagnostico da linha",
                    })
                end,
            })
        end,
    },
}
