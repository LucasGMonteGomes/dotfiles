return {
  "saghen/blink.cmp",
  -- Tags de versao trazem o binario pre-compilado do filtro fuzzy em Rust.
  version = "1.*",
  event = "InsertEnter",
  ---@module "blink.cmp"
  ---@type blink.cmp.Config
  opts = {
    -- Mantem o fluxo anterior: nada vem selecionado, Enter so aceita quando
    -- um item foi escolhido e, caso contrario, cria a nova linha normalmente.
    keymap = {
      preset = "none",
      ["<C-Space>"] = { "show", "show_documentation", "hide_documentation" },
      ["<CR>"] = { "accept", "fallback" },
      -- Fecha o menu; sem menu, cai no <Esc> global, que nao sai do INSERT.
      ["<Esc>"] = { "hide", "fallback" },
      ["<Up>"] = { "select_prev", "fallback" },
      ["<Down>"] = { "select_next", "fallback" },
      ["<C-p>"] = { "select_prev", "fallback" },
      ["<C-n>"] = { "select_next", "fallback" },
      ["<Tab>"] = { "snippet_forward", "fallback" },
      ["<S-Tab>"] = { "snippet_backward", "fallback" },
    },
    completion = {
      list = {
        selection = {
          preselect = false,
          auto_insert = true,
        },
      },
      menu = {
        border = "rounded",
      },
      documentation = {
        auto_show = true,
        auto_show_delay_ms = 200,
        window = { border = "rounded" },
      },
    },
    -- Mostra a assinatura do metodo enquanto os argumentos sao digitados.
    signature = {
      enabled = true,
      window = { border = "rounded" },
    },
    sources = {
      default = { "lsp", "path", "snippets", "buffer" },
    },
    -- A linha de comando ja e completada pelo mini.cmdline.
    cmdline = { enabled = false },
    fuzzy = { implementation = "prefer_rust_with_warning" },
  },
}
