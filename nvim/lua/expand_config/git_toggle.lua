-- File: lua/expand_config/git_toggle.lua
-- :GitToggle —— 开关 neo-tree 的 git 状态显示（持久化到 nvim-settings.json）
--
-- 背景：WSL 无网络时用的是 Windows git（走 WSL interop），每次 git 调用
-- 跨系统往返（status ~2s, ls-files ~9s）。neo-tree 对每个文件做
-- git status / check-ignore，导致打开目录卡顿数秒。
-- 关闭本开关后 neo-tree 完全不碰 git。
-- neo-tree 的 setup 选项不可热更新，切换后重启 nvim 生效。

local settings = require("basic_setting.settings")

local function current()
	local v = settings.get_config("git_status", "custom")
	if v == nil then
		v = true -- 默认开启
	end
	return v
end

vim.api.nvim_create_user_command("GitToggle", function()
	local enabled = not current()
	settings.set_config("git_status", enabled, "custom")
	print(
		"neo-tree git status: "
			.. (enabled and "enabled" or "disabled")
			.. " (restart nvim to apply)"
	)
end, { desc = "Toggle git status in neo-tree (persisted)" })

vim.api.nvim_create_user_command("GitStatusInfo", function()
	print("neo-tree git status: " .. (current() and "enabled" or "disabled"))
end, { desc = "Show git status setting for neo-tree" })
