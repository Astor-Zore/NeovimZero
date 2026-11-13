local hooks = require("ibl.hooks")

-- 在 colorscheme 切换后重新设置高亮，保证始终生效
hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
    -- 很暗的灰色，只是隐约可见
    vim.api.nvim_set_hl(0, "IndentDim", { fg = "#3b3b4f", nocombine = true })
    -- 当前行所在代码块作用域稍微亮一点，方便定位
    vim.api.nvim_set_hl(0, "IndentScope", { fg = "#6b6b80", nocombine = true })
end)

require("ibl").setup({
    indent = {
        -- "▏" 是最细的竖线（1/8 块宽）；也可换 "│" 或 "┆"
        char = "▏",
        highlight = "IndentDim",
    },
    scope = {
        -- 当前行所在的代码块作用域稍微亮一点，方便定位
        highlight = "IndentScope",
    },
    exclude = {
        filetypes = { "startify", "dashboard", "NvimTree", "packer" },
        buftypes = { "terminal", "nofile", "quickfix", "prompt" },
    },
})
