return {
  "nvim-lualine/lualine.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  event = "VeryLazy",
  config = function()
    local background = "#202329"
    local foreground = "#abb2bf"
    local muted = "#7e8491"

    local flat_theme = {
      normal = {
        a = { fg = "#98c379", bg = background, gui = "bold" },
        b = { fg = foreground, bg = background },
        c = { fg = muted, bg = background },
      },
      insert = {
        a = { fg = "#56b6c2", bg = background, gui = "bold" },
      },
      visual = {
        a = { fg = "#c678dd", bg = background, gui = "bold" },
      },
      replace = {
        a = { fg = "#e06c75", bg = background, gui = "bold" },
      },
      command = {
        a = { fg = "#e5c07b", bg = background, gui = "bold" },
      },
      inactive = {
        a = { fg = muted, bg = background },
        b = { fg = muted, bg = background },
        c = { fg = muted, bg = background },
      },
    }

    require("lualine").setup({
      options = {
        theme = flat_theme,
        icons_enabled = true,
        component_separators = { left = "", right = "" },
        section_separators = { left = "", right = "" },
        disabled_filetypes = {
          statusline = { "neo-tree", "lazy", "TelescopePrompt" },
          winbar = {},
        },
        globalstatus = true,
      },
      sections = {
        lualine_a = { "mode" },
        lualine_b = { "branch" },
        lualine_c = {
          {
            "filename",
            file_status = true,
            path = 1, -- Caminho relativo do arquivo
          },
        },
        lualine_x = { "diagnostics", "filetype" },
        lualine_y = {},
        lualine_z = { "location" },
      },
    })
  end,
}
