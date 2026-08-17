local M = {}

local generators = {
  constructor = {
    kind = "source.generate.constructors",
    title = "Generate Constructors",
    label = "construtor",
  },
  accessors = {
    kind = "source.generate.accessors",
    title = "Generate Getters and Setters",
    label = "getters e setters",
  },
  equals_hashcode = {
    kind = "source.generate.hashCodeEquals",
    title = "Generate hashCode() and equals()",
    label = "equals e hashCode",
  },
}

local function notify(message, level)
  vim.notify(message, level or vim.log.levels.INFO, { title = "Java" })
end

local function configure_field_picker()
  local ok, ui = pcall(require, "jdtls.ui")
  if not ok or ui.java_codegen_picker_configured then
    return
  end

  local original_pick_many = ui.pick_many
  ui.pick_many = function(items, prompt, label_fn, opts)
    local is_constructor_fields = prompt:find("field to initialize", 1, true) ~= nil
    local is_equals_hashcode_fields = prompt:find("equals/hashCode", 1, true) ~= nil

    if not is_constructor_fields and not is_equals_hashcode_fields then
      return original_pick_many(items, prompt, label_fn, opts)
    end

    if not items or #items == 0 then
      return {}
    end

    label_fn = label_fn or tostring
    local choices = {}
    for index, item in ipairs(items) do
      choices[index] = string.format("%d. %s", index, label_fn(item))
    end

    local title = is_constructor_fields and "Campos do construtor" or "Campos de equals/hashCode"
    local input_prompt = string.format(
      "\n%s\n%s\nSelecione uma vez (ex.: 1, 1,3 ou 1-3; Enter vazio = todos): ",
      title,
      table.concat(choices, "\n")
    )

    while true do
      local answer = vim.trim(vim.fn.input(input_prompt) or "")
      if answer == "" then
        return items
      end

      local selected = {}
      local included = {}
      local valid = true

      for token in answer:gmatch("[^,%s]+") do
        local first, last = token:match("^(%d+)%-(%d+)$")
        if first then
          first, last = tonumber(first), tonumber(last)
          if first > last then
            first, last = last, first
          end
          if first < 1 or last > #items then
            valid = false
            break
          end
          for index = first, last do
            if not included[index] then
              table.insert(selected, items[index])
              included[index] = true
            end
          end
        else
          local index = token:match("^%d+$") and tonumber(token) or nil
          if not index or index < 1 or index > #items then
            valid = false
            break
          end
          if not included[index] then
            table.insert(selected, items[index])
            included[index] = true
          end
        end
      end

      if valid and #selected > 0 then
        return selected
      end
      notify("Selecao invalida. Use 1, 1,3 ou um intervalo como 1-3.", vim.log.levels.WARN)
    end
  end

  ui.java_codegen_picker_configured = true
end

local function has_java_client(bufnr)
  return #vim.lsp.get_clients({
    bufnr = bufnr,
    name = "jdtls",
    method = "textDocument/codeAction",
  }) > 0
end

local function run(generator)
  local bufnr = vim.api.nvim_get_current_buf()
  if vim.bo[bufnr].filetype ~= "java" then
    notify("Este gerador so pode ser usado em arquivos Java", vim.log.levels.WARN)
    return
  end
  if not has_java_client(bufnr) then
    notify("O servidor Java ainda nao esta conectado a este arquivo", vim.log.levels.WARN)
    return
  end

  vim.lsp.buf.code_action({
    apply = true,
    context = {
      diagnostics = {},
      only = { generator.kind },
      triggerKind = vim.lsp.protocol.CodeActionTriggerKind.Invoked,
    },
    filter = function(action)
      return action.kind == generator.kind and action.title:find(generator.title, 1, true) == 1
    end,
  })
end

function M.constructor()
  run(generators.constructor)
end

function M.accessors()
  run(generators.accessors)
end

function M.equals_hashcode()
  run(generators.equals_hashcode)
end

local function set_java_keymaps(bufnr)
  local options = { buffer = bufnr, silent = true }
  vim.keymap.set("n", "<C-A-c>", M.constructor, vim.tbl_extend("force", options, {
    desc = "Java: gerar construtor",
  }))
  vim.keymap.set("n", "<C-A-g>", M.accessors, vim.tbl_extend("force", options, {
    desc = "Java: gerar getters e setters",
  }))
  vim.keymap.set("n", "<C-A-e>", M.equals_hashcode, vim.tbl_extend("force", options, {
    desc = "Java: gerar equals e hashCode",
  }))
end

function M.setup()
  vim.api.nvim_create_user_command("JavaGenerateConstructor", M.constructor, {
    desc = "Gerar construtor para os campos selecionados",
  })
  vim.api.nvim_create_user_command("JavaGenerateAccessors", M.accessors, {
    desc = "Gerar getters e setters",
  })
  vim.api.nvim_create_user_command("JavaGenerateEqualsHashCode", M.equals_hashcode, {
    desc = "Gerar equals e hashCode",
  })

  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("JavaCodeGenerationKeymaps", { clear = true }),
    pattern = "java",
    callback = function(event)
      configure_field_picker()
      set_java_keymaps(event.buf)
    end,
  })
end

return M
