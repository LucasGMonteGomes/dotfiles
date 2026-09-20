-- Comandos globais do editor.
vim.api.nvim_create_user_command("PackAdd", function(opts)
  vim.pack.add(opts.fargs)
end, { nargs = "+", desc = "Adicionar plugins nativos (:PackAdd user/repo)" })

vim.api.nvim_create_user_command("PackDel", function(opts)
  vim.pack.del(opts.fargs)
end, { nargs = "+", desc = "Remover plugins nativos (:PackDel plugin)" })

vim.api.nvim_create_user_command("PackUpdate", function(opts)
  if opts.args:match("%S") then
    local plugins = vim.split(opts.args, "%s+", { trimempty = true })
    vim.pack.update(plugins)
  else
    vim.pack.update()
  end
end, { nargs = "*", desc = "Atualizar todos os plugins nativos ou uma seleção" })

vim.api.nvim_create_user_command("Atalhos", function()
  local guide = vim.fs.joinpath(vim.fn.stdpath("config"), "ATALHOS.md")
  vim.cmd.edit(vim.fn.fnameescape(guide))
end, { desc = "Abrir guia dos atalhos configurados" })
