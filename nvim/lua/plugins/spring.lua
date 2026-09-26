return {
  -- Spring Boot Language Server (o mesmo do VS Code/STS): completion e
  -- validacao em application.yml/properties, navegacao entre propriedades e
  -- codigo, e simbolos de beans e endpoints. Carregado como dependencia do
  -- nvim-lspconfig porque o setup precisa acontecer antes de o jdtls subir:
  -- o handshake de classpath parte do jdtls.
  "JavaHello/spring-boot.nvim",
  lazy = true,
  config = function()
    -- O pacote e instalado pelo Mason em segundo plano (plugins/lsp.lua).
    -- Sem ele, o setup avisaria a cada abertura; o servidor fica desligado
    -- ate o proximo reinicio.
    local ok, registry = pcall(require, "mason-registry")
    if not ok or not registry.is_installed("vscode-spring-boot-tools") then
      return
    end

    require("spring_boot").setup({
      -- So inicia em projetos que realmente usam Spring Boot.
      project_filter = function(root_dir)
        return require("spring_boot.util").has_spring_boot_dependency(root_dir)
      end,
      -- O servidor e uma aplicacao Spring Boot que, sem esta opcao, sobe um
      -- servidor web local para o MCP (agentes de IA) a cada sessao. A
      -- extensao do VS Code usa a mesma opcao quando o MCP esta desligado,
      -- que e o padrao dela.
      jvm_args = { "-Dspring.main.web-application-type=NONE" },
    })
  end,
}
