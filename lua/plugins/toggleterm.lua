return {
  "akinsho/toggleterm.nvim",
  cmd = { "ToggleTerm", "TermExec", "ToggleTermToggleAll" },
  keys = {
    { "<C-l>", "<cmd>ToggleTerm<cr>", desc = "Abrir Terminal Flutuante", mode = "n" },
    { "<leader>tt", "<cmd>ToggleTerm<cr>", desc = "Alternar Terminal Flutuante" },
    { "<leader>th", "<cmd>ToggleTerm size=15 direction=horizontal<cr>", desc = "Terminal Horizontal (Inferior)" },
    { "<leader>tv", "<cmd>ToggleTerm size=65 direction=vertical<cr>", desc = "Terminal Vertical (Lateral)" },
    { "<leader>tf", "<cmd>ToggleTerm direction=float<cr>", desc = "Terminal Flutuante" },
  },
  config = function()
    local shell = vim.fn.executable("pwsh") == 1 and "pwsh"
      or (vim.fn.executable("powershell") == 1 and "powershell" or vim.o.shell)

    require("toggleterm").setup({
      size = function(term)
        if term.direction == "horizontal" then
          return 15
        elseif term.direction == "vertical" then
          return math.floor(vim.o.columns * 0.4)
        end
      end,
      hide_numbers = true,
      shade_filetypes = {},
      shade_terminals = true,
      shading_factor = 2,
      start_in_insert = true,
      insert_mappings = true,
      terminal_mappings = true,
      persist_size = true,
      persist_mode = true,
      direction = "float", -- Abre por padrão como janela flutuante centralizada
      close_on_exit = true,
      shell = shell,
      auto_scroll = true,
      float_opts = {
        border = "curved",
        width = function()
          return math.floor(vim.o.columns * 0.90)
        end,
        height = function()
          return math.floor(vim.o.lines * 0.85)
        end,
        winblend = 0,
      },
      winbar = {
        enabled = false,
      },
    })

    -- Atalhos de navegação dentro do modo Terminal (:terminal)
    function _G.set_terminal_keymaps()
      local opts = { buffer = 0, silent = true }
      vim.keymap.set("t", "<Esc>", [[<C-\><C-n><Cmd>ToggleTerm<CR>]], opts)
      vim.keymap.set("t", "<C-h>", [[<Cmd>wincmd h<CR>]], opts)
      vim.keymap.set("t", "<C-j>", [[<Cmd>wincmd j<CR>]], opts)
      vim.keymap.set("t", "<C-k>", [[<Cmd>wincmd k<CR>]], opts)
      vim.keymap.set("t", "<C-w>", [[<C-\><C-n><C-w>]], opts)
    end

    vim.api.nvim_create_autocmd("TermOpen", {
      pattern = "term://*",
      callback = function()
        set_terminal_keymaps()
      end,
    })
  end,
}
