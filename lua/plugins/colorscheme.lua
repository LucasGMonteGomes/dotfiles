return {
  "navarasu/onedark.nvim",
  name = "onedark",
  priority = 1000,
  lazy = false,
  config = function()
    require("onedark").setup({
      -- Paleta One Dark Islands (JetBrains Islands UI) adaptada ao Neovim.
      style = "darker",
      transparent = false,
      term_colors = true,
      colors = {
        black = "#181a1f",
        bg0 = "#202329",
        bg1 = "#282c34",
        bg2 = "#323844",
        bg3 = "#333841",
        bg_d = "#1b1e23",
        bg_blue = "#568AF2",
        fg = "#abb2bf",
        grey = "#7e8491",
        light_grey = "#9da5b4",
        red = "#e06c75",
        green = "#98c379",
        yellow = "#e5c07b",
        orange = "#d19a66",
        blue = "#61afef",
        purple = "#c678dd",
        cyan = "#56b6c2",
      },
      highlights = {
        NormalFloat = { fg = "$fg", bg = "$bg1" },
        FloatBorder = { fg = "$bg3", bg = "$bg1" },
        Pmenu = { fg = "$fg", bg = "$bg1" },
        PmenuSel = { fg = "$fg", bg = "$bg2", fmt = "bold" },
        Visual = { bg = "$bg2" },
        CursorLine = { bg = "$bg1" },
        WinSeparator = { fg = "$bg3" },
      },
      code_style = {
        comments = "italic",
        keywords = "none",
        functions = "none",
        strings = "none",
        variables = "none",
      },
    })
    require("onedark").load()
  end,
}
