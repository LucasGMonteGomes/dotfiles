return {
  "mistweaverco/kulala.nvim",
  event = { "SessionLoadPost", "VimLeavePre" },
  ft = { "http", "rest" },
  keys = {
    { "<leader>Rs", desc = "HTTP: enviar requisicao" },
    { "<leader>Ra", desc = "HTTP: enviar todas as requisicoes" },
    { "<leader>Rr", desc = "HTTP: repetir ultima requisicao" },
    { "<leader>Rb", desc = "HTTP: abrir scratchpad" },
  },
  opts = {
    global_keymaps = {
      ["Send request"] = {
        "<leader>Rs",
        function()
          require("kulala").run()
        end,
        mode = { "n", "v" },
        ft = { "http", "rest" },
        desc = "HTTP: enviar requisicao",
      },
      ["Send all requests"] = {
        "<leader>Ra",
        function()
          require("kulala").run_all()
        end,
        mode = { "n", "v" },
        ft = { "http", "rest" },
        desc = "HTTP: enviar todas as requisicoes",
      },
      ["Replay the last request"] = {
        "<leader>Rr",
        function()
          require("kulala").replay()
        end,
        desc = "HTTP: repetir ultima requisicao",
      },
      ["Open scratchpad"] = {
        "<leader>Rb",
        function()
          require("kulala").scratchpad()
        end,
        desc = "HTTP: abrir scratchpad",
      },
    },
    global_keymaps_prefix = "<leader>R",
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
