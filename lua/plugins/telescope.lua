local function unified_files()
  local finders = require("telescope.finders")
  local make_entry = require("telescope.make_entry")
  local pickers = require("telescope.pickers")
  local conf = require("telescope.config").values
  local themes = require("telescope.themes")

  local cwd = vim.fs.normalize(vim.fn.getcwd())
  local is_windows = vim.fn.has("win32") == 1
  local cwd_key = is_windows and cwd:lower() or cwd
  local files = {}
  local seen = {}

  local function add_file(path)
    if not path or path == "" then
      return
    end

    local absolute = vim.fs.normalize(vim.fn.fnamemodify(path, ":p")):gsub("/$", "")
    local key = is_windows and absolute:lower() or absolute
    local is_inside_project = key == cwd_key or vim.startswith(key, cwd_key .. "/")

    if not is_inside_project or seen[key] or vim.fn.filereadable(absolute) ~= 1 then
      return
    end

    seen[key] = true
    table.insert(files, absolute)
  end

  -- A ordem e intencional: buffers abertos, arquivos recentes e, por fim, o projeto.
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) and vim.bo[bufnr].buflisted and vim.bo[bufnr].buftype == "" then
      add_file(vim.api.nvim_buf_get_name(bufnr))
    end
  end

  for _, path in ipairs(vim.v.oldfiles or {}) do
    add_file(path)
  end

  local result = vim.system({
    "rg",
    "--files",
    "--hidden",
    "--glob", "!**/.git/**",
    "--glob", "!**/target/**",
    "--glob", "!**/.gradle/**",
    "--glob", "!**/build/**",
    "--glob", "!**/node_modules/**",
  }, { cwd = cwd, text = true }):wait()

  if result.code == 0 then
    for _, path in ipairs(vim.split(result.stdout or "", "\n", { plain = true, trimempty = true })) do
      add_file(path:gsub("\r$", ""))
    end
  end

  local opts = themes.get_ivy({
    cwd = cwd,
    prompt_title = "Arquivos: abertos, recentes e projeto",
  })

  pickers.new(opts, {
    finder = finders.new_table({
      results = files,
      entry_maker = make_entry.gen_from_file(opts),
    }),
    previewer = conf.file_previewer(opts),
    sorter = conf.file_sorter(opts),
  }):find()
end

return {
  "nvim-telescope/telescope.nvim",
  tag = "0.1.8",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
  },
  cmd = "Telescope",
  keys = {
    -- Atalho solicitado
    { "<C-p>", unified_files, desc = "Buscar buffers, recentes e arquivos do projeto" },
    { "<C-f>", "<cmd>Telescope live_grep<cr>", desc = "Buscar Texto no Projeto (Live Grep)" },

    { "<C-a>", "<cmd>Telescope find_files hidden=true no_ignore=true<cr>", desc = "Buscar Todos Arquivos (inc. ocultos)" },
    { "<C-A-w>", "<cmd>Telescope grep_string<cr>", desc = "Buscar Palavra sob o Cursor" },
    { "<C-A-b>", "<cmd>Telescope buffers<cr>", desc = "Buscar Buffers Abertos" },
    { "<C-e>", "<cmd>Telescope oldfiles<cr>", desc = "Arquivos Recentes" },
    { "<C-A-x>", "<cmd>Telescope diagnostics<cr>", desc = "Listar Erros e Avisos (LSP)" },
    { "<C-A-s>", "<cmd>Telescope lsp_document_symbols<cr>", desc = "Buscar Símbolos no Arquivo (Classes, Métodos)" },
    { "<C-A-y>", "<cmd>Telescope lsp_dynamic_workspace_symbols<cr>", desc = "Buscar Símbolos no Projeto Inteiro" },
  },
  config = function()
    local telescope = require("telescope")
    local actions = require("telescope.actions")
    local themes = require("telescope.themes")

    telescope.setup({
      defaults = vim.tbl_deep_extend("force", themes.get_ivy(), {
        prompt_prefix = "   ",
        selection_caret = " ❯ ",
        entry_prefix = "   ",
        initial_mode = "insert",
        selection_strategy = "reset",
        sorting_strategy = "ascending",
        layout_config = {
          height = 0.42,
          prompt_position = "top",
          preview_width = 0.55,
        },
        path_display = { "filename_first" }, -- Coloca o nome do arquivo primeiro (ideal para pacotes Java longos)
        file_ignore_patterns = {
          "%.git[/\\]",
          "node_modules[/\\]",
          "target[/\\]",
          "%.gradle[/\\]",
          "build[/\\]",
          "dist[/\\]",
          "%.angular[/\\]",
          "%.idea[/\\]",
          "%.vscode[/\\]",
          "%.class$",
        },
        mappings = {
          i = {
            ["<C-n>"] = actions.move_selection_next,
            ["<C-p>"] = actions.move_selection_previous,
            ["<C-j>"] = actions.move_selection_next,
            ["<C-k>"] = actions.move_selection_previous,
            ["<C-c>"] = actions.close,
            ["<Down>"] = actions.move_selection_next,
            ["<Up>"] = actions.move_selection_previous,
            ["<CR>"] = actions.select_default,
            ["<C-v>"] = actions.select_vertical,
            ["<C-s>"] = actions.select_horizontal,
            ["<C-t>"] = actions.select_tab,
            ["<C-u>"] = actions.preview_scrolling_up,
            ["<C-d>"] = actions.preview_scrolling_down,
            ["<C-q>"] = actions.send_to_qflist + actions.open_qflist,
            ["<Esc>"] = actions.close,
          },
          n = {
            ["<Esc>"] = actions.close,
            ["q"] = actions.close,
            ["<CR>"] = actions.select_default,
            ["v"] = actions.select_vertical,
            ["s"] = actions.select_horizontal,
            ["t"] = actions.select_tab,
            ["j"] = actions.move_selection_next,
            ["k"] = actions.move_selection_previous,
            ["<C-u>"] = actions.preview_scrolling_up,
            ["<C-d>"] = actions.preview_scrolling_down,
            ["<C-q>"] = actions.send_to_qflist + actions.open_qflist,
          },
        },
      }),
      pickers = {
        find_files = {
          hidden = true,
          find_command = { "rg", "--files", "--hidden", "--glob", "!**/.git/*" },
        },
        live_grep = {
          additional_args = function()
            return { "--hidden", "--glob", "!**/.git/*" }
          end,
        },
      },
    })
  end,
}
