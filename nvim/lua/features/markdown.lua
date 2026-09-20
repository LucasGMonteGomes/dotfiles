local M = {}

local preview_by_source = {}
local source_by_preview = {}
local configure_spell

local function valid_buffer(buffer)
  return buffer and vim.api.nvim_buf_is_valid(buffer)
end

local function set_spell_in_windows(buffer, enabled)
  for _, window in ipairs(vim.fn.win_findbuf(buffer)) do
    if vim.api.nvim_win_is_valid(window) then
      vim.wo[window].spell = enabled
    end
  end
end

local function configure_preview_windows(buffer)
  for _, window in ipairs(vim.fn.win_findbuf(buffer)) do
    if vim.api.nvim_win_is_valid(window) then
      vim.wo[window].number = false
      vim.wo[window].relativenumber = false
      vim.wo[window].cursorline = false
      vim.wo[window].signcolumn = "no"
      vim.wo[window].foldcolumn = "0"
      vim.wo[window].wrap = true
      vim.wo[window].linebreak = true
      vim.wo[window].breakindent = true
      vim.wo[window].colorcolumn = ""
      vim.wo[window].spell = false
      vim.wo[window].winbar = "  Markdown Preview"
    end
  end
end

local function window_for_buffer(buffer)
  if not valid_buffer(buffer) then
    return nil
  end

  for _, window in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_get_buf(window) == buffer then
      return window
    end
  end
end

local function source_for_buffer(buffer)
  return source_by_preview[buffer] or buffer
end

local function set_source_raw(source)
  if not valid_buffer(source) then
    return
  end

  vim.api.nvim_buf_call(source, function()
    local ok, renderer = pcall(require, "render-markdown")
    if ok then
      renderer.buf_disable()
    end
  end)
end

local function forget_preview(source, preview)
  if preview_by_source[source] == preview then
    preview_by_source[source] = nil
  end
  if source_by_preview[preview] == source then
    source_by_preview[preview] = nil
  end
end

local function register_preview(source, preview)
  preview_by_source[source] = preview
  source_by_preview[preview] = source
  -- O preview e apenas leitura/visualizacao, como no VS Code. Nao exibe
  -- palavras marcadas nem recebe o corretor ortografico.
  configure_preview_windows(preview)

  vim.keymap.set("n", "<C-m>i", M.cycle_preview, {
    buffer = preview,
    silent = true,
    desc = "Markdown: alternar preview interno",
  })
  vim.keymap.set("n", "<C-m>e", M.edit_only, {
    buffer = preview,
    silent = true,
    desc = "Markdown: voltar para edicao",
  })

  vim.api.nvim_create_autocmd("BufWipeout", {
    buffer = preview,
    once = true,
    callback = function()
      forget_preview(source, preview)
      vim.schedule(function()
        set_source_raw(source)
      end)
    end,
  })
end

local function open_preview(source)
  local buffers_before = {}
  for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
    buffers_before[buffer] = true
  end

  set_source_raw(source)
  require("render-markdown").preview()

  local preview
  for _, window in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local buffer = vim.api.nvim_win_get_buf(window)
    if not buffers_before[buffer]
      and vim.bo[buffer].filetype == "markdown"
      and vim.bo[buffer].buftype == "nofile"
    then
      preview = buffer
      break
    end
  end

  if not preview then
    vim.notify("Nao foi possivel abrir o preview de Markdown", vim.log.levels.ERROR)
    return
  end

  register_preview(source, preview)
  configure_preview_windows(preview)
  vim.notify("Markdown: edicao a esquerda e preview a direita")
end

local function show_source_only(source, preview)
  local source_window = window_for_buffer(source)
  local preview_window = window_for_buffer(preview)

  if not source_window and preview_window then
    vim.api.nvim_win_set_buf(preview_window, source)
    source_window = preview_window
  end

  forget_preview(source, preview)
  if valid_buffer(preview) then
    vim.api.nvim_buf_delete(preview, { force = true })
  end

  if source_window and vim.api.nvim_win_is_valid(source_window) then
    vim.api.nvim_set_current_win(source_window)
  end
  set_source_raw(source)
  configure_spell(source)
  vim.notify("Markdown: somente edicao")
end

function M.cycle_preview()
  local current = vim.api.nvim_get_current_buf()
  local source = source_for_buffer(current)
  if not valid_buffer(source) or vim.bo[source].filetype ~= "markdown" then
    return
  end

  local preview = preview_by_source[source]
  if not valid_buffer(preview) then
    preview_by_source[source] = nil
    open_preview(source)
    return
  end

  local source_window = window_for_buffer(source)
  local preview_window = window_for_buffer(preview)

  -- Segundo estado: remove a janela de edicao e deixa apenas o renderizado.
  if source_window and preview_window then
    vim.api.nvim_set_current_win(preview_window)
    vim.api.nvim_win_close(source_window, false)
    vim.notify("Markdown: somente preview")
    return
  end

  -- Terceiro estado: fecha o preview e restaura o buffer editavel.
  show_source_only(source, preview)
end

function M.edit_only()
  local current = vim.api.nvim_get_current_buf()
  local source = source_for_buffer(current)
  local preview = preview_by_source[source]

  if valid_buffer(preview) then
    show_source_only(source, preview)
  else
    set_source_raw(source)
    local source_window = window_for_buffer(source)
    if source_window then
      vim.api.nvim_set_current_win(source_window)
    end
    configure_spell(source)
    vim.notify("Markdown: somente edicao")
  end
end

configure_spell = function(source)
  local spell_dir = vim.fs.joinpath(vim.fn.stdpath("data"), "site", "spell")
  vim.fn.mkdir(spell_dir, "p")

  require("nvim.spellfile").config({ confirm = false, timeout_ms = 30000 })
  if vim.fn.globpath(vim.o.runtimepath, "spell/pt.utf-8.spl") == "" then
    require("nvim.spellfile").get("pt")
  end

  vim.bo[source].spelllang = "pt_br"
  vim.bo[source].spellfile = vim.fs.joinpath(spell_dir, "pt.utf-8.add")
  set_spell_in_windows(source, true)
end

local function configure_buffer(source)
  if vim.bo[source].buftype ~= "" then
    return
  end

  -- Equivale ao `editor.wordWrap: off` do VS Code. O texto nao e quebrado ou
  -- alterado durante a digitacao.
  vim.bo[source].textwidth = 0
  vim.api.nvim_buf_call(source, function()
    vim.opt_local.formatoptions:remove("t")
  end)

  configure_spell(source)
  set_source_raw(source)

  -- O preview HTML e o padrao: ele corresponde ao modelo de documento do
  -- VS Code. O terminal nao consegue representar tamanhos de fonte distintos.
  vim.keymap.set("n", "<C-m>p", "<cmd>MarkdownPreviewToggle<cr>", {
    buffer = source,
    silent = true,
    desc = "Markdown: alternar preview HTML",
  })
  vim.keymap.set("n", "<C-m>i", M.cycle_preview, {
    buffer = source,
    silent = true,
    desc = "Markdown: alternar preview interno",
  })
  vim.keymap.set("n", "<C-m>e", M.edit_only, {
    buffer = source,
    silent = true,
    desc = "Markdown: voltar para edicao",
  })
  vim.keymap.set("n", "<C-m>b", "<cmd>MarkdownPreview<cr>", {
    buffer = source,
    silent = true,
    desc = "Markdown: abrir preview HTML no navegador",
  })
end

function M.setup()
  local group = vim.api.nvim_create_augroup("MarkdownWorkflow", { clear = true })

  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = "markdown",
    callback = function(args)
      vim.schedule(function()
        if valid_buffer(args.buf) then
          configure_buffer(args.buf)
        end
      end)
    end,
  })
end

return M
