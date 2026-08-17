return {
  "akinsho/toggleterm.nvim",
  cmd = { "ToggleTerm", "TermExec", "ToggleTermToggleAll", "LazyDocker" },
  keys = {
    { "<C-m>", "<cmd>ToggleTerm direction=horizontal<cr>", desc = "Abrir Terminal Inferior", mode = "n" },
  },
  config = function()
    local shell = vim.fn.executable("pwsh") == 1 and "pwsh"
      or (vim.fn.executable("powershell") == 1 and "powershell" or vim.o.shell)

    require("toggleterm").setup({
      size = function(term)
        if term.direction == "horizontal" then
          return 12
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
      persist_size = false,
      persist_mode = true,
      direction = "horizontal", -- Abre por padrão em um split no canto inferior
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

    local LazyDocker = require("toggleterm.terminal").Terminal:new({
      cmd = "lazydocker",
      direction = "horizontal",
      size = 20,
      hidden = true,
    })

    vim.api.nvim_create_user_command("LazyDocker", function()
      if vim.fn.executable("lazydocker") == 0 then
        vim.notify("lazydocker não está instalado ou não foi encontrado no PATH", vim.log.levels.ERROR)
        return
      end
      LazyDocker:toggle()
    end, { desc = "Abrir gerenciador visual do Docker" })

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
