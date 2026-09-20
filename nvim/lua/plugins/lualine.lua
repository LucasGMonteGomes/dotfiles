return {
  "nvim-lualine/lualine.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  event = "VeryLazy",
  config = function()
    local background = "#26282c"
    local foreground = "#dfe1e5"
    local muted = "#b0b1b3"

    local flat_theme = {
      normal = {
        a = { fg = "#73bd7a", bg = background, gui = "bold" },
        b = { fg = foreground, bg = background },
        c = { fg = muted, bg = background },
      },
      insert = {
        a = { fg = "#56a8f5", bg = background, gui = "bold" },
      },
      visual = {
        a = { fg = "#c77dbb", bg = background, gui = "bold" },
      },
      replace = {
        a = { fg = "#f27481", bg = background, gui = "bold" },
      },
      command = {
        a = { fg = "#d5b778", bg = background, gui = "bold" },
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
          statusline = {
            "snacks_layout_box",
            "snacks_picker_input",
            "snacks_picker_list",
            "oil",
            "trouble",
            "lazy",
          },
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
