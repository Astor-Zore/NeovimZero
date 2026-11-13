-- File: lua/expand_config/project_style.lua
-- 根据项目 .clang-format 文件自动设置当前 buffer 的缩进和列宽
-- 仅 buffer 局部生效，可随时手动 :set 覆盖

local M = {}

-- 缓存：配置文件路径 -> { mtime = {sec, nsec}, style = 解析结果 }
-- mtime 变了才重新读盘，同一项目打开多个文件时零 IO
local cache = {}

-- 默认风格（与 conform.lua 中 clang_format 的 fallback 保持一致）
local DEFAULT = {
	use_tab = true,
	indent_width = 8,
	tab_width = 8,
	column_limit = 80,
}

-- 简单解析 .clang-format 中的顶层标量键（YAML 子集足够覆盖）
-- 支持三种形式：KeyValue:、{Key: Value, ...}、--style={...} 不涉及（那是命令行）
local function parse_clang_format(path)
	local style = {}
	local content = io.open(path, "r")
	if not content then
		return style
	end

	local text = content:read("*a")
	content:close()

	-- 去掉注释行
	local cleaned = {}
	for line in text:gmatch("[^\r\n]+") do
		local l = line:gsub("#.*$", "")
		if l:match("%S") then
			table.insert(cleaned, l)
		end
	end
	text = table.concat(cleaned, " ")

	-- "Key: Value" 形式（包括在大括号 { Key: Value, ... } 内的）
	for key, value in text:gmatch("([%w]+):%s*([%w%.%-]+)") do
		style[key] = value
	end
	return style
end

-- 从文件所在目录向上查找 .clang-format / _clang-format
local function find_clang_format(bufnr)
	local fname = vim.api.nvim_buf_get_name(bufnr)
	if fname == "" then
		return nil
	end
	local dir = vim.fs.dirname(fname)
	local found = vim.fs.find(
		{ ".clang-format", "_clang-format" },
		{ upward = true, path = dir }
	)
	-- vim.fs.find 从当前目录开始向上，直到根；取第一个（最近的）
	if #found > 0 then
		return found[1]
	end
	return nil
end

-- 带缓存的读取 + 解析
local function get_style(path)
	local stat = vim.loop.fs_stat(path) -- 或 vim.uv.fs_stat，看 nvim 版本
	if not stat then
		return nil
	end
	local mtime = { stat.mtime.sec, stat.mtime.nsec }
	local entry = cache[path]
	if entry and entry.mtime[1] == mtime[1] and entry.mtime[2] == mtime[2] then
		return entry.style
	end
	local style = parse_clang_format(path)
	cache[path] = { mtime = mtime, style = style }
	return style
end

-- 对当前 buffer 应用风格
M.apply = function(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	local ft = vim.bo[bufnr].filetype
	if ft ~= "c" and ft ~= "cpp" and ft ~= "objc" and ft ~= "objcpp" then
		return
	end

	local style = {
		use_tab = DEFAULT.use_tab,
		indent_width = DEFAULT.indent_width,
		tab_width = DEFAULT.tab_width,
		column_limit = DEFAULT.column_limit,
	}
	local source = "default"

	local cfg = find_clang_format(bufnr)
	if cfg then
		local parsed = get_style(cfg) or {}
		local ut = parsed.UseTab or parsed["UseTab"]
		local iw = parsed.IndentWidth
		local tw = parsed.TabWidth
		local cl = parsed.ColumnLimit
		if ut then
			style.use_tab = (ut == "Always" or ut == "ForContinuationAndIndentation")
			source = vim.fs.basename(cfg)
		end
		if iw then
			style.indent_width = tonumber(iw) or style.indent_width
		end
		if tw then
			style.tab_width = tonumber(tw) or style.tab_width
		end
		if cl and cl ~= "0" then
			style.column_limit = tonumber(cl) or style.column_limit
		end
	end

	-- 全部设置 buffer-local，不影响其他文件，且可被手动 :set 覆盖
	local bo = vim.bo[bufnr]
	bo.expandtab = not style.use_tab
	bo.shiftwidth = style.indent_width
	bo.tabstop = style.tab_width
	bo.softtabstop = style.indent_width
	bo.textwidth = style.column_limit
	-- 列宽指示线跟随项目列宽（colorcolumn 是 window-local，
	-- 用当前窗口局部设置覆盖全局默认 81）
	vim.api.nvim_win_set_option(0, "colorcolumn", tostring(style.column_limit + 1))

	vim.b[bufnr].project_style_source = source
	vim.b[bufnr].project_style = style
end

-- 显示当前 buffer 的生效风格
M.show = function()
	local style = vim.b.project_style
	if not style then
		print("project-style: not applied yet (open a C/C++ file)")
		return
	end
	print(string.format(
		"project-style (%s): %s, indent=%d, tabstop=%d, textwidth=%d, colorcolumn=%s",
		vim.b.project_style_source,
		vim.bo.expandtab and "spaces" or "tabs",
		vim.bo.shiftwidth,
		vim.bo.tabstop,
		vim.bo.textwidth,
		vim.inspect(vim.opt_local.colorcolumn:get())
	))
end

vim.api.nvim_create_user_command("ProjectStyleInfo", function()
	M.show()
end, { desc = "Show effective project style for current buffer" })

vim.api.nvim_create_user_command("ProjectStyleReload", function()
	M.apply(0)
	M.show()
end, { desc = "Re-detect .clang-format and re-apply to current buffer" })

-- 打开 C/C++ 文件时自动应用
vim.api.nvim_create_autocmd({ "FileType" }, {
	pattern = { "c", "cpp", "objc", "objcpp" },
	callback = function(args)
		M.apply(args.buf)
	end,
})

return M
