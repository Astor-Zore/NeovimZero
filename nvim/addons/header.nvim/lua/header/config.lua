local M = {}

M.defaults = {
    allow_autocmds = true,
    file_name = true,
    author = nil,
    project = nil,
    date_created = true,
    date_created_fmt = "%Y-%m-%d %H:%M:%S",
    date_modified = true,
    date_modified_fmt = "%Y-%m-%d %H:%M:%S",
    line_separator = "------",
    use_block_header = true,
    copyright_text = nil,
    license_from_file = false,
    author_from_git = false,
}

M.constants = {
    -- Doxygen 文件头标签；max_tag_len 用于表格对齐（值列起始列）
    file_name = "@file",
    date_created = "@date",
    author = "@author",
    project = "@project",
    date_modified = "@modified",
    max_tag_len = 12, -- "@date_modified" 之类最长标签 + 对齐空格
}

function M.read_config_file()
    local f = io.open(".header.nvim", "r")
    if not f then
        return nil
    end
    local content = f:read("*a")
    f:close()
    if not content or content == "" then
        return nil
    end
    return vim.fn.json_decode(content)
end

return M
