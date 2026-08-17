local M = {}

local severity_type = {
  error = "E",
  warning = "W",
  info = "I",
  style = "I",
}

function M.setup()
  vim.api.nvim_create_user_command("DockerLint", function()
    if vim.fn.executable("hadolint") == 0 then
      vim.notify("hadolint não está instalado ou não foi encontrado no PATH", vim.log.levels.ERROR)
      return
    end

    local file = vim.api.nvim_buf_get_name(0)
    if file == "" then
      vim.notify("Salve o Dockerfile antes de executar o Hadolint", vim.log.levels.WARN)
      return
    end

    local result = vim.system({ "hadolint", "--format", "json", file }, { text = true }):wait()
    local ok, diagnostics = pcall(vim.json.decode, result.stdout ~= "" and result.stdout or "[]")
    if not ok then
      vim.notify("Não foi possível interpretar a saída do Hadolint", vim.log.levels.ERROR)
      return
    end

    local items = {}
    for _, diagnostic in ipairs(diagnostics) do
      table.insert(items, {
        filename = diagnostic.file or file,
        lnum = diagnostic.line or 1,
        col = diagnostic.column or 1,
        type = severity_type[diagnostic.level] or "W",
        text = string.format("%s: %s", diagnostic.code or "Hadolint", diagnostic.message or ""),
      })
    end

    vim.fn.setqflist({}, " ", {
      title = "Hadolint: " .. vim.fn.fnamemodify(file, ":t"),
      items = items,
    })

    if #items == 0 then
      vim.cmd("cclose")
      vim.notify("Hadolint: nenhum problema encontrado")
    else
      vim.cmd("copen")
    end
  end, { desc = "Analisar o Dockerfile atual com Hadolint" })
end

return M
