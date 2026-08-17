return {
  "mistweaverco/kulala.nvim",
  event = { "SessionLoadPost", "VimLeavePre" },
  ft = { "http", "rest" },
  keys = {
    { "<C-A-r>", desc = "HTTP: executar requisicao atual" },
    { "<C-A-a>", desc = "HTTP: executar todas as requisicoes" },
    { "<C-A-p>", desc = "HTTP: repetir ultima requisicao" },
    { "<C-A-n>", desc = "HTTP: abrir nova requisicao" },
  },
  opts = {
    global_keymaps = {
      ["Send request"] = {
        "<C-A-r>",
        function()
          require("kulala").run()
        end,
        mode = { "n", "v" },
        ft = { "http", "rest" },
        desc = "HTTP: executar requisicao atual",
      },
      ["Send all requests"] = {
        "<C-A-a>",
        function()
          require("kulala").run_all()
        end,
        mode = { "n", "v" },
        ft = { "http", "rest" },
        desc = "HTTP: executar todas as requisicoes",
      },
      ["Replay the last request"] = {
        "<C-A-p>",
        function()
          require("kulala").replay()
        end,
        desc = "HTTP: repetir ultima requisicao",
      },
      ["Open scratchpad"] = {
        "<C-A-n>",
        function()
          require("kulala").scratchpad()
        end,
        desc = "HTTP: abrir nova requisicao",
      },
    },
    kulala_keymaps_prefix = "",
    default_env = "default",
    treesitter = {
      enable = true,
      cli_path = "tree-sitter",
    },
    ui = {
      display_mode = "split",
      split_direction = "right",
      default_view = "body",
      winbar = true,
    },
  },
}
