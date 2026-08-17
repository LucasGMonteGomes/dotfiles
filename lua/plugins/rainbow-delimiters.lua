return {
  "HiPhish/rainbow-delimiters.nvim",
  event = { "BufReadPost", "BufNewFile" },
  submodules = false,
  config = function()
    require("rainbow-delimiters.setup").setup({
      strategy = {
        [""] = "rainbow-delimiters.strategy.global",
      },
      query = {
        [""] = "rainbow-delimiters",
      },
      priority = {
        [""] = 110,
      },
      highlight = {
        "RainbowDelimiterViolet",
        "RainbowDelimiterCyan",
        "RainbowDelimiterYellow",
        "RainbowDelimiterBlue",
        "RainbowDelimiterOrange",
        "RainbowDelimiterGreen",
        "RainbowDelimiterRed",
      },
    })
  end,
}
