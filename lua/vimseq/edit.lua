local M = {}

local function bullet_prefix(line)
  return line:match("^(%s*[-*+]%s+)")
end

local function line_indent(line)
  return line:match("^(%s*)") or ""
end

local function continuation_indent(line)
  local prefix = bullet_prefix(line)
  if prefix ~= nil then
    return prefix:gsub("[-*+]%s+$", "  ")
  end
  return line_indent(line)
end

function M.insert_new_sibling_bullet()
  local line = vim.api.nvim_get_current_line()
  return "\n" .. (bullet_prefix(line) or "- ")
end

function M.insert_literal_newline()
  local line = vim.api.nvim_get_current_line()
  return "\n" .. continuation_indent(line)
end

function M.new_sibling_bullet()
  local line = vim.api.nvim_get_current_line()
  local prefix = bullet_prefix(line) or "- "
  local row = vim.api.nvim_win_get_cursor(0)[1]

  vim.api.nvim_buf_set_lines(0, row, row, false, { prefix })
  vim.api.nvim_win_set_cursor(0, { row + 1, #prefix })
  vim.cmd("startinsert!")
end

function M.literal_newline()
  local line = vim.api.nvim_get_current_line()
  local indent = continuation_indent(line)
  local row = vim.api.nvim_win_get_cursor(0)[1]

  vim.api.nvim_buf_set_lines(0, row, row, false, { indent })
  vim.api.nvim_win_set_cursor(0, { row + 1, #indent })
  vim.cmd("startinsert!")
end

local function default_register_lines()
  local text = vim.fn.getreg('"')
  return vim.split(text, "\n", { plain = true })
end

function M.paste_plain()
  local line = vim.api.nvim_get_current_line()
  local indent = continuation_indent(line)
  local out = {}

  for _, pasted in ipairs(default_register_lines()) do
    table.insert(out, indent .. pasted)
  end

  vim.api.nvim_buf_set_lines(0, vim.api.nvim_win_get_cursor(0)[1], vim.api.nvim_win_get_cursor(0)[1], false, out)
end

function M.paste_code_block()
  local line = vim.api.nvim_get_current_line()
  local indent = continuation_indent(line)
  local out = { indent .. "```text" }

  for _, pasted in ipairs(default_register_lines()) do
    table.insert(out, indent .. pasted)
  end

  table.insert(out, indent .. "```")
  vim.api.nvim_buf_set_lines(0, vim.api.nvim_win_get_cursor(0)[1], vim.api.nvim_win_get_cursor(0)[1], false, out)
end

function M.paste_bullets()
  local line = vim.api.nvim_get_current_line()
  local prefix = bullet_prefix(line) or "- "
  local out = {}

  for _, pasted in ipairs(default_register_lines()) do
    table.insert(out, prefix .. pasted)
  end

  vim.api.nvim_buf_set_lines(0, vim.api.nvim_win_get_cursor(0)[1], vim.api.nvim_win_get_cursor(0)[1], false, out)
end

function M.enable_buffer(buf)
  buf = buf or 0

  vim.b[buf].vimseq_enabled = true
  vim.wo.conceallevel = 0

  -- Avoid Neovim's automatic comment/list continuation fighting Logseq block edits.
  local formatoptions = vim.bo[buf].formatoptions
  formatoptions = formatoptions:gsub("o", ""):gsub("r", "")
  vim.bo[buf].formatoptions = formatoptions

  vim.keymap.set("i", "<CR>", function()
    return require("vimseq.edit").insert_new_sibling_bullet()
  end, { buffer = buf, expr = true, silent = true })

  -- Terminal support for Alt-Enter varies, but this is useful where supported.
  vim.keymap.set("i", "<M-CR>", function()
    return require("vimseq.edit").insert_literal_newline()
  end, { buffer = buf, expr = true, silent = true })

  vim.keymap.set("n", "<CR>", function()
    require("vimseq.edit").new_sibling_bullet()
  end, { buffer = buf, silent = true })
end

return M
