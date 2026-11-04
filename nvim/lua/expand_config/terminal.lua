-- Terminal management using Neovim's built-in :terminal
-- The terminal is a normal, full-window buffer. <C-t> (TermToggle):
--   - terminal focused (fills current window) -> switch back to the previous buffer
--   - terminal visible in another window      -> jump to it
--   - terminal hidden                          -> show it in the current window
--   - no live terminal                         -> create a fresh one
-- The shell job keeps running while the buffer is hidden ('hidden' is set).
local M = {}

local term_bufnr = nil
local prev_bufnr = nil

local function term_alive()
	if not term_bufnr or not vim.api.nvim_buf_is_valid(term_bufnr) then
		return false
	end
	if vim.bo[term_bufnr].buftype ~= "terminal" then
		return false
	end
	local job = vim.b[term_bufnr].terminal_job_id
	if not job then
		return false
	end
	local running = false
	pcall(function()
		local r = vim.fn.jobwait({ job }, 0)
		-- vim.fn.jobwait may return a list-wrapped number ({-1}) from Lua
		if type(r) == "table" then
			r = r[1]
		end
		running = (r == -1)
	end)
	return running
end

local function term_win()
	if not term_alive() then
		return nil
	end
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		if vim.api.nvim_win_get_buf(win) == term_bufnr then
			return win
		end
	end
	return nil
end

function M.toggle()
	local win = term_win()

	if win then
		if win == vim.api.nvim_get_current_win() then
			-- Focused: switch the window back to the previous buffer
			if prev_bufnr and vim.api.nvim_buf_is_valid(prev_bufnr) then
				vim.api.nvim_set_current_buf(prev_bufnr)
			else
				vim.cmd("enew")
			end
		else
			-- Visible in another window: jump to it
			vim.api.nvim_set_current_win(win)
			vim.cmd("startinsert")
		end
		return
	end

	if term_alive() then
		-- Hidden: show it in the current window
		prev_bufnr = vim.api.nvim_get_current_buf()
		vim.api.nvim_set_current_buf(term_bufnr)
		vim.cmd("startinsert")
		return
	end

	-- Dead or none: wipe the old buffer and start a fresh terminal
	if term_bufnr and vim.api.nvim_buf_is_valid(term_bufnr) then
		pcall(vim.api.nvim_buf_delete, term_bufnr, { force = true })
	end
	prev_bufnr = vim.api.nvim_get_current_buf()
	vim.cmd("terminal")
	term_bufnr = vim.api.nvim_get_current_buf()
	vim.cmd("startinsert")
end

vim.api.nvim_create_user_command("TermToggle", M.toggle, {
	nargs = 0,
	desc = "Toggle built-in terminal",
})

return M
