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

            local java_executable = vim.fn.exepath("java")
            local java_home = vim.env.JAVA_HOME
            if java_executable ~= "" and (not java_home or java_home == "") then
                local real_java = (vim.uv or vim.loop).fs_realpath(java_executable) or java_executable
                java_home = vim.fs.dirname(vim.fs.dirname(real_java))
            end

            -- Nome do ambiente de execucao (JavaSE-21, JavaSE-1.8...) lido do
            -- arquivo `release` do JDK; nil quando o diretorio nao e um JDK.
            local function java_runtime_name(home)
                local file = io.open(vim.fs.joinpath(home, "release"), "r")
                if not file then
                    return nil
                end
                local content = file:read("*a")
                file:close()

                local version = content:match('JAVA_VERSION="([^"]+)"')
                if not version then
                    return nil
                end
                local legacy = version:match("^1%.(%d+)")
                return legacy and ("JavaSE-1." .. legacy) or ("JavaSE-" .. version:match("^%d+"))
            end

            -- Registra todos os JDKs instalados para que cada projeto compile
            -- contra a versao declarada no pom.xml/build.gradle. O JDK de
            -- JAVA_HOME (ou do `java` no PATH) e o padrao.
            local function java_runtimes(default_home)
                local runtimes = {}
                local by_name = {}
                local homes = { default_home }
                for _, pattern in ipairs({ "/usr/lib/jvm/*", "~/.sdkman/candidates/java/*" }) do
                    vim.list_extend(homes, vim.fn.glob(pattern, false, true))
                end

                for _, home in ipairs(homes) do
                    local real = (vim.uv or vim.loop).fs_realpath(vim.fn.expand(home))
                    local name = real and java_runtime_name(real)
                    if name and not by_name[name] then
                        by_name[name] = true
                        table.insert(runtimes, { name = name, path = real, default = #runtimes == 0 })
                    end
                end
                return runtimes
            end

            local build_files = { "pom.xml", "build.gradle", "build.gradle.kts", "build.xml" }

            local function has_build_file(directory)
                for _, file in ipairs(build_files) do
                    if (vim.uv or vim.loop).fs_stat(vim.fs.joinpath(directory, file)) then
                        return true
                    end
                end
                return false
            end

            -- Um projeto multi-modulo deve ter um unico servidor na raiz. O
            -- wrapper/settings define essa raiz; sem eles, sobe enquanto os
            -- diretorios pais tambem tiverem arquivo de build (pom pai).
            local function java_root(path)
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

            -- Argumentos extras da JVM do jdtls, como no lspconfig:
            -- JDTLS_JVM_ARGS="-Xmx4g -Dfoo=bar". O Lombok distribuido pelo
            -- pacote jdtls do Mason e carregado como agente para que @Data,
            -- @Getter, @Builder etc. sejam entendidos pelo servidor.
            local function jdtls_jvm_args()
                local arguments = vim.split(vim.env.JDTLS_JVM_ARGS or "", "%s+", { trimempty = true })
                local lombok = vim.fs.joinpath(vim.fn.stdpath("data"), "mason", "packages", "jdtls", "lombok.jar")
                local has_agent = vim.iter(arguments):any(function(argument)
                    return argument:find("lombok", 1, true) ~= nil
                end)
                if not has_agent and (vim.uv or vim.loop).fs_stat(lombok) then
                    table.insert(arguments, "-javaagent:" .. lombok)
                end
                return arguments
            end

            -- Extensoes carregadas dentro do jdtls: java-debug (depurador) e
            -- java-test (JUnit/TestNG), ambas instaladas pelo Mason acima.
            local function java_bundles()
                local packages = vim.fs.joinpath(vim.fn.stdpath("data"), "mason", "packages")
                local bundles = vim.fn.glob(
                    packages .. "/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar",
                    true,
                    true
                )
                -- O runner e o agente do JaCoCo rodam na JVM do teste, nao no jdtls.
                local excluded = {
                    ["com.microsoft.java.test.runner-jar-with-dependencies.jar"] = true,
                    ["jacocoagent.jar"] = true,
                }
                for _, jar in ipairs(vim.fn.glob(packages .. "/java-test/extension/server/*.jar", true, true)) do
                    if not excluded[vim.fs.basename(jar)] then
                        table.insert(bundles, jar)
                    end
                end
                -- Extensoes do Spring Boot Tools: dao ao jdtls o classpath que o
                -- servidor do Spring consulta.
                local ok, spring_boot = pcall(require, "spring_boot")
                if ok then
                    vim.list_extend(bundles, spring_boot.java_extensions())
                end
                return bundles
            end

            local jdtls = require("jdtls")
            local java_extended_capabilities = vim.deepcopy(jdtls.extendedClientCapabilities)
            java_extended_capabilities.resolveAdditionalTextEditsSupport = true
            -- Getters/setters com escolha de campos (java/resolveUnimplementedAccessors),
            -- como no VS Code; o prompt e implementado em features/java/codegen.lua.
            java_extended_capabilities.advancedGenerateAccessorsSupport = true

            -- Java (jdtls)
            local jdtls_config = {
                capabilities = capabilities,
                commands = jdtls.commands,
                init_options = {
                    extendedClientCapabilities = java_extended_capabilities,
                    bundles = java_bundles(),
                },
                cmd = function(dispatchers, config)
                    -- O lspconfig nomeia o workspace so pelo nome da pasta; dois
                    -- projetos `demo` dividiriam o mesmo indice. O hash do caminho
                    -- completo separa os dois.
                    local root = config.root_dir or vim.fn.getcwd()
                    local data_dir = vim.fs.joinpath(
                        vim.fn.stdpath("cache"),
                        "jdtls",
                        "workspace",
                        vim.fs.basename(root) .. "-" .. vim.fn.sha256(root):sub(1, 8)
                    )

                    local command = { "jdtls", "-data", data_dir }
                    for _, argument in ipairs(jdtls_jvm_args()) do
                        table.insert(command, "--jvm-arg=" .. argument)
                    end

                    return vim.lsp.rpc.start(command, dispatchers, {
                        cwd = config.cmd_cwd,
                        env = config.cmd_env,
                        detached = config.detached,
                    })
                end,
                handlers = {
                    -- Dicas e lentes pedidas antes do fim da importacao do projeto
                    -- voltam vazias e nao sao refeitas. Quando o jdtls avisa que
                    -- esta pronto, os buffers anexados pedem de novo.
                    ["language/status"] = function(_, result, ctx)
                        if not result or result.type ~= "ServiceReady" then
                            return
                        end
                        for bufnr in pairs(vim.lsp.get_client_by_id(ctx.client_id).attached_buffers) do
                            for _, feature in ipairs({ vim.lsp.inlay_hint, vim.lsp.codelens }) do
                                if feature.is_enabled({ bufnr = bufnr }) then
                                    feature.enable(false, { bufnr = bufnr })
                                    feature.enable(true, { bufnr = bufnr })
                                end
                            end
                        end
                    end,
                },
                root_dir = function(bufnr, on_dir)
                    local name = vim.api.nvim_buf_get_name(bufnr)
                    if vim.startswith(name, "jdt://") then
                        -- Classes de bibliotecas abertas pelo `gd` sao anexadas pelo
                        -- nvim-jdtls ao servidor ja existente; nao inicia outro.
                        local client = vim.lsp.get_clients({ name = "jdtls", bufnr = vim.fn.bufnr("#") })[1]
                            or vim.lsp.get_clients({ name = "jdtls" })[1]
                        if client then
                            on_dir(client.root_dir)
                        end
                        return
                    end
                    on_dir(name ~= "" and java_root(name) or vim.fn.getcwd())
                end,
            }

            jdtls_config.settings = {
                java = {
                    configuration = {
                        updateBuildConfiguration = "automatic",
                    },
                    -- Nomes de parametros so em argumentos literais, como no
                    -- IntelliJ: `service.find(/* id: */ 42)`.
                    inlayHints = {
                        parameterNames = { enabled = "literals" },
                    },
                    -- Contagem de referencias/implementacoes acima de classes e
                    -- metodos; `grx` executa a lente sob o cursor.
                    referencesCodeLens = { enabled = true },
                    implementationsCodeLens = { enabled = true },
                    -- O perfil padrao do Eclipse indenta com TAB. Sem isto, o codigo
                    -- gerado (construtores, toString, code actions) entra com TAB
                    -- em arquivos indentados com 4 espacos (config/options.lua).
                    -- O perfil versionado ajusta o padrao do Eclipse ao estilo do
                    -- IntelliJ: comentarios nao quebram em 80 colunas nem ganham
                    -- linhas com espaco no fim, e quebras feitas a mao ficam.
                    format = {
                        insertSpaces = true,
                        tabSize = 4,
                        settings = {
                            url = vim.fs.joinpath(vim.fn.stdpath("config"), "formatter", "eclipse-java-style.xml"),
                            profile = "dotfiles",
                        },
                    },
                    -- equals/hashCode com Objects.equals/Objects.hash e instanceof
                    -- no lugar do estilo do Java 6 (`prime * result`), chaves em
                    -- todo if gerado e sem comentarios "TODO Auto-generated".
                    codeGeneration = {
                        hashCodeEquals = {
                            useJava7Objects = true,
                            useInstanceof = true,
                        },
                        useBlocks = true,
                        generateComments = false,
                    },
                    -- Metodos estaticos sugeridos no autocomplete com o import
                    -- estatico (`assertThat`, `when`, `get("/api")`). A lista
                    -- substitui a padrao do jdtls, por isso repete a do JUnit.
                    completion = {
                        favoriteStaticMembers = {
                            "org.junit.Assert.*",
                            "org.junit.Assume.*",
                            "org.junit.jupiter.api.Assertions.*",
                            "org.junit.jupiter.api.Assumptions.*",
                            "org.junit.jupiter.api.DynamicContainer.*",
                            "org.junit.jupiter.api.DynamicTest.*",
                            "org.mockito.Mockito.*",
                            "org.mockito.ArgumentMatchers.*",
                            "org.mockito.BDDMockito.*",
                            "org.assertj.core.api.Assertions.*",
                            "org.hamcrest.Matchers.*",
                            "org.hamcrest.MatcherAssert.*",
                            "org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*",
                            "org.springframework.test.web.servlet.result.MockMvcResultMatchers.*",
                        },
                    },
                },
            }

            if java_home and java_home ~= "" then
                jdtls_config.cmd_env = { JAVA_HOME = java_home }
                jdtls_config.settings.java.configuration.runtimes = java_runtimes(java_home)
            else
                vim.schedule(function()
                    vim.notify(
                        "Java não foi encontrado. Instale openjdk-21-jdk ou defina JAVA_HOME.",
                        vim.log.levels.WARN,
                        { title = "Neovim / JDTLS" }
                    )
                end)
            end

            vim.lsp.config("jdtls", jdtls_config)

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
