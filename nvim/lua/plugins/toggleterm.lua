return {
  "akinsho/toggleterm.nvim",
  cmd = { "ToggleTerm", "TermExec", "ToggleTermToggleAll", "LazyDocker" },
  keys = {
    { "<C-t>", "<cmd>ToggleTerm direction=horizontal<cr>", desc = "Abrir/fechar terminal inferior", mode = "n" },
  },
  config = function()
    -- No Debian usa o shell da sessão (normalmente Bash). Para forçar outro,
    -- defina NVIM_TERMINAL_SHELL, por exemplo: export NVIM_TERMINAL_SHELL=pwsh.
    local shell = vim.env.NVIM_TERMINAL_SHELL
    if not shell or shell == "" then
      if vim.fn.has("win32") == 1 and vim.fn.executable("pwsh") == 1 then
        shell = "pwsh -NoLogo"
      else
        shell = vim.env.SHELL or vim.o.shell
      end
    end

    require("toggleterm").setup({
      size = function(term)
        if term.direction == "horizontal" then
          return 10
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

    -- Atalhos dentro do modo Terminal. Esc, Ctrl+W, Ctrl+K, Ctrl+H e Ctrl+J
    -- ficam com o shell e com programas TUI (lazydocker, lazygit, less):
    -- apagar palavra, cortar ate o fim da linha, backspace etc. Para ir ao
    -- modo NORMAL do Neovim use o padrao Ctrl+\ Ctrl+N.
    local function set_terminal_keymaps(bufnr)
      local opts = { buffer = bufnr, silent = true }
      vim.keymap.set("t", "<C-t>", [[<C-\><C-n><Cmd>ToggleTerm<CR>]], opts)
      vim.keymap.set("t", "<C-Tab>", [[<C-\><C-n><C-w>w]], opts)
      vim.keymap.set("t", "\27[9;5u", [[<C-\><C-n><C-w>w]], opts)
    end

    vim.api.nvim_create_autocmd("TermOpen", {
      group = vim.api.nvim_create_augroup("TerminalKeymaps", { clear = true }),
      pattern = "term://*",
      callback = function(event)
        set_terminal_keymaps(event.buf)
      end,
    })
  end,
}
