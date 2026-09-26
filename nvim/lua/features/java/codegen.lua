-- Geradores de codigo Java oferecidos pelo JDTLS.
local M = {}

local generators = {
  constructor = {
    kind = "source.generate.constructors",
    label = "construtor",
  },
  -- As tres acoes de acessores tem o mesmo kind; o argumento `kind` do
  -- comando as diferencia (0 = getters, 1 = setters, 2 = ambos).
  accessors = {
    kind = "source.generate.accessors",
    accessor_kind = 2,
    label = "getters e setters",
  },
  getters = {
    kind = "source.generate.accessors",
    accessor_kind = 0,
    label = "getters",
  },
  setters = {
    kind = "source.generate.accessors",
    accessor_kind = 1,
    label = "setters",
  },
  equals_hashcode = {
    kind = "source.generate.hashCodeEquals",
    label = "equals e hashCode",
  },
  to_string = {
    kind = "source.generate.toString",
    label = "toString",
  },
  override_methods = {
    kind = "source.overrideMethods",
    label = "metodos sobrescritos",
  },
  delegate_methods = {
    kind = "source.generate.delegateMethods",
    label = "metodos delegados",
  },
}

local function notify(message, level)
  vim.notify(message, level or vim.log.levels.INFO, { title = "Java" })
end

-- Prompts do nvim-jdtls (e o de getters/setters, implementado abaixo) que
-- passam pelo seletor de campos. `preselect` define o que ja vem marcado:
-- "suggested" usa a sugestao do jdtls (no toString, so os campos, sem
-- getClass/hashCode) e marca todos quando nao ha sugestao; "none" nao marca
-- nada. `empty` define o Enter sem nenhum item marcado: "none" gera sem itens
-- (construtor sem parametros) e "cancel" nao gera nada.
local field_prompts = {
  { pattern = "field to initialize", title = "Campos do construtor", preselect = "suggested", empty = "none" },
  { pattern = "super class constructor", title = "Construtores da superclasse", preselect = "suggested", empty = "cancel" },
  { pattern = "equals/hashCode", title = "Campos do equals e hashCode", preselect = "suggested", empty = "cancel" },
  { pattern = "toString", title = "Campos do toString", preselect = "suggested", empty = "cancel" },
  { pattern = "accessors", title = "Campos dos getters e setters", preselect = "suggested", empty = "cancel" },
  { pattern = "delegate for method", title = "Metodos a delegar", preselect = "none", empty = "cancel" },
  { pattern = "Method to override", title = "Metodos a sobrescrever/implementar", preselect = "none", empty = "cancel" },
}

local function prompt_config(prompt)
  for _, candidate in ipairs(field_prompts) do
    if prompt:find(candidate.pattern, 1, true) then
      return candidate
    end
  end
end

-- Seletor com caixas de marcacao para escolher os campos/metodos de cada
-- geracao: Tab marca ou desmarca, Ctrl+A marca/desmarca todos, digitar filtra,
-- Enter gera com os marcados e Esc cancela. Roda dentro de uma corrotina (os
-- prompts do nvim-jdtls ja rodam numa) e a suspende ate a escolha. Cancelar
-- simplesmente nao a retoma: devolver uma lista vazia nao bastaria, porque o
-- nvim-jdtls ainda geraria codigo (o construtor sairia sem parametros).
local function choose(items, label_fn, config)
  local co = coroutine.running()
  if not co then
    error("choose() precisa rodar dentro de uma corrotina")
  end

  local entries = {}
  local suggested = {}
  for index, item in ipairs(items) do
    local entry = { text = label_fn(item), value = item, order = index }
    entries[index] = entry
    if type(item) == "table" and item.isSelected == true then
      table.insert(suggested, entry)
    end
  end

  local preselected = {}
  if config.preselect == "suggested" then
    preselected = #suggested > 0 and suggested or entries
  end

  local done = false
  local function finish(result)
    done = true
    vim.schedule(function()
      coroutine.resume(co, result)
    end)
  end

  Snacks.picker({
    title = config.title,
    -- As instrucoes ficam na linha de busca: no titulo, seriam cortadas.
    prompt = "Tab marca · Ctrl+A todos · Enter gera · Esc cancela ❯ ",
    items = entries,
    format = "text",
    layout = { preset = "select" },
    icons = { ui = { selected = "[x] ", unselected = "[ ] " } },
    formatters = { selected = { show_always = true, unselected = true } },
    on_show = function(picker)
      picker.list:set_selected(vim.list_slice(preselected))
    end,
    confirm = function(picker)
      local marked = picker:selected()
      if #marked == 0 and config.empty == "cancel" then
        notify("Nenhum item marcado; nada foi gerado. Marque com Tab.", vim.log.levels.WARN)
        return
      end
      -- Mantem a ordem da classe (a ordem dos parametros do construtor, por
      -- exemplo), nao a ordem em que os itens foram marcados.
      table.sort(marked, function(left, right)
        return left.order < right.order
      end)
      local result = vim.tbl_map(function(entry)
        return entry.value
      end, marked)
      -- Entrega antes de fechar: close() dispara on_close.
      finish(result)
      picker:close()
    end,
    on_close = function()
      done = true
    end,
  })
  return coroutine.yield()
end

local function configure_field_picker()
  local ok, ui = pcall(require, "jdtls.ui")
  if not ok or ui.java_codegen_picker_configured then
    return
  end

  local original_pick_many = ui.pick_many
  ui.pick_many = function(items, prompt, label_fn, opts)
    local config = prompt_config(prompt)
    if not config or not coroutine.running() then
      return original_pick_many(items, prompt, label_fn, opts)
    end
    if not items or #items == 0 then
      return {}
    end
    return choose(items, label_fn or tostring, config)
  end

  -- Escolhas unicas (o campo que recebe a delegacao quando ha varios, ou
  -- substituir um toString existente) tambem usam o seletor visual em vez da
  -- lista numerada do inputlist().
  local single_prompts = {
    ["Select target to generate delegates for."] = "Campo que recebera os metodos delegados",
  }
  local original_pick_one = ui.pick_one
  ui.pick_one = function(items, prompt, label_fn)
    local co = coroutine.running()
    if not co then
      return original_pick_one(items, prompt, label_fn)
    end
    local title = single_prompts[prompt] or prompt
    if prompt:find("already exists", 1, true) then
      title = "O metodo ja existe. Substituir?"
    end
    vim.ui.select(items, {
      prompt = title,
      format_item = label_fn or tostring,
    }, function(choice)
      vim.schedule(function()
        coroutine.resume(co, choice)
      end)
    end)
    return coroutine.yield()
  end

  ui.java_codegen_picker_configured = true
end

-- Getters e setters com escolha de campos. O jdtls oferece o protocolo
-- (java/resolveUnimplementedAccessors e java/generateAccessors) aos clientes
-- que anunciam advancedGenerateAccessorsSupport (plugins/lsp.lua), como o VS
-- Code; o nvim-jdtls nao implementa o comando, entao ele e registrado aqui.
local function generate_accessors_prompt(command, ctx)
  local client = vim.lsp.get_client_by_id(ctx.client_id)
  local params = command.arguments and command.arguments[1]
  if not client or not params then
    return
  end

  coroutine.wrap(function()
    local co = coroutine.running()
    local function request(method, request_params)
      client:request(method, request_params, function(err, result)
        coroutine.resume(co, err, result)
      end, ctx.bufnr)
      return coroutine.yield()
    end

    local err, accessors = request("java/resolveUnimplementedAccessors", params)
    if err then
      notify("Nao foi possivel listar os campos: " .. err.message, vim.log.levels.ERROR)
      return
    end
    if not accessors or #accessors == 0 then
      notify("Todos os campos ja tem os metodos pedidos", vim.log.levels.INFO)
      return
    end

    local selected = choose(accessors, function(accessor)
      local methods = {}
      if accessor.generateGetter then
        table.insert(methods, "get")
      end
      if accessor.generateSetter then
        table.insert(methods, "set")
      end
      return string.format("%s: %s  (%s)", accessor.fieldName, accessor.typeName, table.concat(methods, "/"))
    end, prompt_config("accessors"))

    local generate_err, edit = request("java/generateAccessors", { context = params, accessors = selected })
    if generate_err then
      notify("Nao foi possivel gerar os getters/setters: " .. generate_err.message, vim.log.levels.ERROR)
    elseif edit then
      vim.lsp.util.apply_workspace_edit(edit, client.offset_encoding)
    end
  end)()
end

local function get_java_client(bufnr)
  return vim.lsp.get_clients({
    bufnr = bufnr,
    name = "jdtls",
  })[1]
end

-- Erros de configuracao que impedem o jdtls de resolver os tipos do projeto.
-- Sem os tipos resolvidos, ele deixa de oferecer as acoes que dependem deles
-- (construtor, equals/hashCode), e o gerador so veria "nenhuma opcao".
local build_problems = {
  "is no longer supported",
  "There are no JREs installed in the workspace",
}

local function find_build_problem(client)
  local namespace = vim.lsp.diagnostic.get_namespace(client.id)
  for _, diagnostic in ipairs(vim.diagnostic.get(nil, { namespace = namespace })) do
    for _, pattern in ipairs(build_problems) do
      if diagnostic.message:find(pattern, 1, true) then
        return diagnostic.message
      end
    end
  end
end

local function notify_missing_action(generator, client)
  local problem = find_build_problem(client)
  if problem then
    notify(
      "Nenhuma opcao para gerar " .. generator.label .. ": o projeto nao compila no JDTLS.\n"
        .. problem .. "\n"
        .. "Atualize a versao do Java no pom.xml/build.gradle (ex.: maven.compiler.release 21).",
      vim.log.levels.WARN
    )
    return
  end
  notify("Nenhuma opcao para gerar " .. generator.label .. " neste ponto da classe", vim.log.levels.WARN)
end

local function apply_action(action, client, bufnr, params)
  if not action then
    notify("O JDTLS nao retornou uma acao valida", vim.log.levels.ERROR)
    return
  end

  if action.edit then
    vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding)
  end

  if action.command then
    local command = type(action.command) == "table" and action.command or action
    client:exec_cmd(command, {
      bufnr = bufnr,
      client_id = client.id,
      method = "textDocument/codeAction",
      params = params,
    })
  end
end

local function run(generator)
  local bufnr = vim.api.nvim_get_current_buf()
  if vim.bo[bufnr].filetype ~= "java" then
    notify("Este gerador so pode ser usado em arquivos Java", vim.log.levels.WARN)
    return
  end
  local client = get_java_client(bufnr)
  if not client then
    notify("O servidor Java ainda nao esta conectado a este arquivo", vim.log.levels.WARN)
    return
  end

  local winid = vim.fn.bufwinid(bufnr)
  local params = vim.lsp.util.make_range_params(winid, client.offset_encoding)
  params.context = {
    diagnostics = {},
    only = { generator.kind },
    triggerKind = vim.lsp.protocol.CodeActionTriggerKind.Invoked,
  }

  -- O JDTLS responde a estas requisicoes, mas em algumas versoes nao anuncia
  -- codeActionProvider. Por isso fazemos a requisicao diretamente em vez de
  -- usar vim.lsp.buf.code_action(), que recusaria chamar o servidor.
  client:request("textDocument/codeAction", params, function(err, actions)
    if err then
      notify("Nao foi possivel gerar " .. generator.label .. ": " .. err.message, vim.log.levels.ERROR)
      return
    end

    -- Filtra so pelo kind: o titulo varia com a classe (com @Getter do
    -- Lombok, por exemplo, a acao de acessores vira "Generate Setters").
    local selected
    for _, action in ipairs(actions or {}) do
      local arguments = type(action.command) == "table" and action.command.arguments
      local accessor_kind = arguments and type(arguments[1]) == "table" and arguments[1].kind
      if action.kind == generator.kind
        and (generator.accessor_kind == nil or accessor_kind == generator.accessor_kind)
      then
        selected = action
        break
      end
    end

    if not selected then
      notify_missing_action(generator, client)
      return
    end

    if selected.edit or selected.command then
      apply_action(selected, client, bufnr, params)
      return
    end

    -- A acao do JDTLS normalmente vem apenas com `data`; resolvemos a acao
    -- mesmo quando o servidor nao declarou codeAction/resolve nas capacidades.
    client:request("codeAction/resolve", selected, function(resolve_err, resolved)
      if resolve_err then
        notify("Nao foi possivel preparar " .. generator.label .. ": " .. resolve_err.message, vim.log.levels.ERROR)
        return
      end
      apply_action(resolved, client, bufnr, params)
    end, bufnr)
  end, bufnr)
end

function M.constructor()
  run(generators.constructor)
end

function M.accessors()
  run(generators.accessors)
end

function M.getters()
  run(generators.getters)
end

function M.setters()
  run(generators.setters)
end

function M.equals_hashcode()
  run(generators.equals_hashcode)
end

function M.to_string()
  run(generators.to_string)
end

function M.override_methods()
  run(generators.override_methods)
end

function M.delegate_methods()
  run(generators.delegate_methods)
end

function M.generate_menu()
  local choices = {
    { label = "Construtor", run = M.constructor },
    { label = "Getters e setters", run = M.accessors },
    { label = "Somente getters", run = M.getters },
    { label = "Somente setters", run = M.setters },
    { label = "equals e hashCode", run = M.equals_hashcode },
    { label = "toString", run = M.to_string },
    { label = "Sobrescrever/implementar metodos", run = M.override_methods },
    { label = "Metodos delegados de um campo", run = M.delegate_methods },
  }

  vim.ui.select(choices, {
    prompt = "Gerar codigo Java:",
    format_item = function(choice)
      return choice.label
    end,
  }, function(choice)
    if choice then
      vim.schedule(choice.run)
    end
  end)
end

local function set_java_keymaps(bufnr)
  local options = { buffer = bufnr, silent = true }
  vim.keymap.set("n", "<C-g>", M.generate_menu, vim.tbl_extend("force", options, {
    desc = "Java: abrir menu para gerar codigo",
  }))
end

function M.setup()
  vim.api.nvim_create_user_command("JavaGenerateConstructor", M.constructor, {
    desc = "Gerar construtor para os campos selecionados",
  })
  vim.api.nvim_create_user_command("JavaGenerateAccessors", M.accessors, {
    desc = "Gerar getters e setters",
  })
  vim.api.nvim_create_user_command("JavaGenerateGetters", M.getters, {
    desc = "Gerar somente getters",
  })
  vim.api.nvim_create_user_command("JavaGenerateSetters", M.setters, {
    desc = "Gerar somente setters",
  })
  vim.api.nvim_create_user_command("JavaGetSet", M.accessors, {
    desc = "Gerar getters e setters",
  })
  vim.api.nvim_create_user_command("JavaGenerateEqualsHashCode", M.equals_hashcode, {
    desc = "Gerar equals e hashCode",
  })
  vim.api.nvim_create_user_command("JavaGenerateToString", M.to_string, {
    desc = "Gerar toString",
  })
  vim.api.nvim_create_user_command("JavaOverrideMethods", M.override_methods, {
    desc = "Sobrescrever ou implementar metodos da superclasse/interfaces",
  })
  vim.api.nvim_create_user_command("JavaGenerateDelegateMethods", M.delegate_methods, {
    desc = "Gerar metodos que delegam para um campo",
  })
  vim.api.nvim_create_user_command("JavaGenerate", M.generate_menu, {
    desc = "Abrir menu de geracao de codigo Java",
  })

  vim.lsp.commands["java.action.generateAccessorsPrompt"] = generate_accessors_prompt

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
