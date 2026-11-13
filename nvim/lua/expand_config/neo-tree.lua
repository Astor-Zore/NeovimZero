-- neo-tree.lua
-- Configuration for neo-tree file explorer

-- Define custom commands for toggling neo-tree
local function neotree_toggle()
	-- Toggle neo-tree in left sidebar with width 30
	vim.cmd("Neotree position=left toggle")
end

local function neotree_toggle_float()
	-- Toggle neo-tree in floating window with width 40, aligned to left
	vim.cmd("Neotree position=float toggle")
end

local function neotree_toggle_current()
	-- Toggle neo-tree in current window/buffer (like netrw)
	vim.cmd("Neotree position=current toggle")
end

-- Register custom commands
vim.api.nvim_create_user_command("NeotreeToggle", function()
	neotree_toggle()
end, { nargs = 0 })

vim.api.nvim_create_user_command("NeotreeToggleFloat", function()
	neotree_toggle_float()
end, { nargs = 0 })

vim.api.nvim_create_user_command("NeotreeToggleCurrent", function()
	neotree_toggle_current()
end, { nargs = 0 })

-- Main neo-tree configuration

-- git 状态开关（持久化到 nvim-settings.json 的 custom.git_status）
-- 关闭原因：WSL 无网络时用的是 Windows git，每次 git 调用都要走
-- WSL interop 跨系统往返（status ~2s, ls-files ~9s），neo-tree 对每个
-- 文件做 git status / check-ignore 会导致打开目录卡顿数秒。
-- 用 :GitToggle 随时开关，关闭时 neo-tree 完全不碰 git。
local settings = require("basic_setting.settings")
local git_enabled = settings.get_config("git_status", "custom")
if git_enabled == nil then
	git_enabled = true -- 默认开启
end

require("neo-tree").setup({
	-- Basic settings
	sources = { "filesystem", "buffers", "git_status", "document_symbols" },
	close_if_last_window = false, -- Close neo-tree if it's the last window
	enable_diagnostics = true, -- Show diagnostics (works with COC)
	enable_git_status = git_enabled, -- Show git status indicators（:GitToggle 可关）
	default_source = "filesystem", -- Default to filesystem view

	-- Window configuration
	popup_border_style = "rounded", -- Rounded borders for floating windows
	window = {
		position = "left", -- Default position
		width = 30, -- Default width for sidebar
		auto_expand_width = false, -- Prevent auto-expand when only window
		mappings = {
			["e"] = function()
				local win = vim.api.nvim_get_current_win()
				local w = vim.api.nvim_win_get_width(win)
				vim.api.nvim_win_set_width(win, w == 30 and 80 or 30)
			end,
		},
		popup = {
			-- Floating window settings
			size = {
				height = "90%",
				width = "30%", -- Width for floating window
			},
			position = { row = "100%", col = "0%" }, -- Align to left side of screen
			row_offset = -1, -- Move up by 1 row to be fully visible
			col_offset = 0, -- No horizontal offset
		},
	},

	-- Filesystem settings
	filesystem = {
		follow_current_file = {
			enabled = true, -- Automatically reveal and focus current file
			leave_dirs_open = false, -- Close auto-expanded directories when leaving
		},
		hijack_netrw_behavior = "disabled", -- Disable netrw integration
		use_libuv_file_watcher = true, -- 增量刷新，避免全量重扫目录

		-- File filtering settings
		filtered_items = {
			visible = false, -- Hide filtered items by default
			hide_dotfiles = true,
			-- gitignore 过滤对每个文件跑一次 git check-ignore，
			-- Windows git 下同样是卡顿源，随总开关一起关闭
			hide_gitignored = git_enabled,
			never_show = { -- Always hide these items
				".git",
				"node_modules",
				".cache",
				"__pycache__",
				-- "target",
				-- "dist",
				-- "build",
			},
		},
	},

	-- Buffers settings
	buffers = {
		follow_current_file = {
			enabled = true, -- Follow the current buffer
			leave_dirs_open = false,
		},
		show_unloaded = true, -- Show unloaded buffers
	},

	-- Git status settings
	git_status = {
		window = {
			-- Git status will use the default window settings
		},
	},

	-- Document symbols settings (compatible with COC)
	document_symbols = {
		follow_cursor = true, -- Follow cursor movement in the symbols tree
		client_filters = false, -- Use the first available LSP client
	},

	-- Default component configurations
	default_component_configs = {
		indent = {
			indent_size = 2,
			padding = 1,
			with_markers = true,
			indent_marker = "│",
			last_indent_marker = "└",
		},
		icon = {
			folder_closed = "",
			folder_open = "",
			folder_empty = "",
			default = "*",
			highlight = "NeoTreeFileIcon",
		},
		name = {
			trailing_slash = false,
			use_git_status_colors = true,
			highlight = "NeoTreeFileName",
		},
		git_status = {
			symbols = {
				added = "✚",
				modified = "",
				deleted = "✖",
				renamed = "󰁕",
				untracked = "",
				ignored = "",
				unstaged = "󰄱",
				staged = "",
				conflict = "",
			},
		},
	},
})

-- :GitToggle / :GitStatusInfo 命令注册在 expand_config.git_toggle
-- （独立于 neo-tree 的懒加载，随时可用）
