return {
    {
        "MeanderingProgrammer/render-markdown.nvim",
        ft = { "markdown" },
        dependencies = {
            "nvim-treesitter/nvim-treesitter",
            "nvim-mini/mini.nvim",
        },
        opts = {
            enabled = true,
            -- Edicao fica crua e previsivel; somente o buffer de preview recebe a
            -- renderizacao visual, em linha com o fluxo do VS Code.
            render_modes = false,
            overrides = {
                preview = {
                    render_modes = true,
                },
            },
            anti_conceal = {
                enabled = false,
            },
            completions = {
                lsp = { enabled = true },
            },
            heading = {
                sign = false,
                icons = { "", "", "", "", "", "" },
                position = "inline",
                width = "block",
                border = true,
                border_virtual = true,
                above = "─",
                below = "─",
            },
            paragraph = {
                left_margin = 2,
            },
            bullet = {
                icons = { "•", "◦", "▪", "▫" },
                left_pad = 2,
                right_pad = 1,
            },
            dash = {
                icon = "─",
                width = "full",
                left_margin = 2,
            },
            code = {
                sign = false,
                width = "block",
                border = "thin",
            },
        },
    },
    {
        "iamcco/markdown-preview.nvim",
        ft = { "markdown" },
        cmd = {
            "MarkdownPreview",
            "MarkdownPreviewStop",
            "MarkdownPreviewToggle",
        },
        build = function()
            vim.fn["mkdp#util#install"]()
        end,
        init = function()
            vim.g.mkdp_filetypes = { "markdown" }
            vim.g.mkdp_theme = "dark"
            vim.g.mkdp_auto_close = 1
            vim.g.mkdp_combine_preview = 0
            vim.g.mkdp_preview_options = {
                disable_sync_scroll = 0,
                sync_scroll_type = "middle",
                hide_yaml_meta = 1,
                content_editable = false,
            }
            vim.g.mkdp_markdown_css = vim.fs.joinpath(vim.fn.stdpath("config"), "assets", "markdown-preview-vscode.css")
        end,
    },
}
