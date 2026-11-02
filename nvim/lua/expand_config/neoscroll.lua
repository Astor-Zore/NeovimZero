local neoscroll = require('neoscroll')

-- Remember original window-local options so we can restore them after scrolling.
local cursorline_orig = true
local cursorcolumn_orig = true

neoscroll.setup({
  mappings = {}, -- disable default keymaps
  hide_cursor = true,
  stop_eof = true,
  respect_scrolloff = false,
  cursor_scrolls_alone = true,
  duration_multiplier = 1.0,
  easing = 'sine',
  pre_hook = function()
    -- Disable expensive highlight recomputation during the animation.
    cursorline_orig = vim.wo.cursorline
    cursorcolumn_orig = vim.wo.cursorcolumn
    vim.wo.cursorline = false
    vim.wo.cursorcolumn = false
  end,
  post_hook = function()
    vim.wo.cursorline = cursorline_orig
    vim.wo.cursorcolumn = cursorcolumn_orig
  end,
  performance_mode = false,
  ignored_events = { 'WinScrolled', 'CursorMoved' },
})

-- Create new command
vim.api.nvim_create_user_command(
    'Scroll',
    function(opts)
        local lines = tonumber(opts.args)
        neoscroll.scroll(lines, { move_cursor = true, duration = 200 })
    end,
    { nargs = 1 }
)

-- Half-page scroll for fast file navigation (distinct from line-by-line j/k).
vim.api.nvim_create_user_command(
    'ScrollHalfDown',
    function()
        neoscroll.ctrl_d({ duration = 200, easing = 'sine' })
    end,
    { nargs = 0, desc = 'Scroll half page down' }
)

vim.api.nvim_create_user_command(
    'ScrollHalfUp',
    function()
        neoscroll.ctrl_u({ duration = 200, easing = 'sine' })
    end,
    { nargs = 0, desc = 'Scroll half page up' }
)

-- Ensure keybinding is for normal mode
-- vim.keymap.set('n', '<C-k>', '<cmd>Scroll -10<CR>', { noremap = true, silent = true, desc = "scroll up" })
-- vim.keymap.set('n', '<C-j>', '<cmd>Scroll 10<CR>', { noremap = true, silent = true, desc = "scroll down" })

