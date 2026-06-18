local config = require("vimseq.config")
local graph = require("vimseq.graph")

local M = {}

local function existing_roots()
  local roots = {}
  local pages = graph.pages_dir()
  local journals = graph.journals_dir()

  if pages ~= nil and vim.fn.isdirectory(pages) == 1 then
    table.insert(roots, pages)
  end
  if journals ~= nil and vim.fn.isdirectory(journals) == 1 then
    table.insert(roots, journals)
  end

  return roots
end

local function open_quickfix()
  if config.get().open_quickfix_on_search then
    vim.cmd.copen()
  end
end

local function set_quickfix(title, items)
  vim.fn.setqflist({}, "r", {
    title = title,
    items = items,
  })
  open_quickfix()
end

local function parse_rg_line(line)
  local file, lnum, col, text = line:match("^(.-):(%d+):(%d+):(.*)$")
  if file == nil then
    return nil
  end

  return {
    filename = file,
    lnum = tonumber(lnum),
    col = tonumber(col),
    text = text,
  }
end

local function search_with_rg(query, roots)
  local cmd = { "rg", "--vimgrep", "--fixed-strings", query }

  for _, root in ipairs(roots) do
    table.insert(cmd, root)
  end

  local lines = vim.fn.systemlist(cmd)
  local status = vim.v.shell_error

  if status ~= 0 and status ~= 1 then
    vim.notify("vimseq: rg failed", vim.log.levels.ERROR)
    return
  end

  local items = {}
  for _, line in ipairs(lines) do
    local item = parse_rg_line(line)
    if item ~= nil then
      table.insert(items, item)
    end
  end

  set_quickfix("vimseq search: " .. query, items)

  if #items == 0 then
    vim.notify("vimseq: no matches")
  end
end

local function all_markdown_files(roots)
  local files = {}

  for _, root in ipairs(roots) do
    local found = vim.fn.globpath(root, "**/*.md", false, true)
    for _, file in ipairs(found) do
      table.insert(files, file)
    end
  end

  return files
end

local function search_with_lua(query, roots)
  local items = {}

  for _, file in ipairs(all_markdown_files(roots)) do
    local ok, lines = pcall(vim.fn.readfile, file)
    if ok then
      for lnum, line in ipairs(lines) do
        local start_col = line:find(query, 1, true)
        if start_col ~= nil then
          table.insert(items, {
            filename = file,
            lnum = lnum,
            col = start_col,
            text = line,
          })
        end
      end
    end
  end

  set_quickfix("vimseq search: " .. query, items)

  if #items == 0 then
    vim.notify("vimseq: no matches")
  end
end

function M.text(query)
  if query == nil or vim.trim(query) == "" then
    vim.notify("vimseq: search query is required", vim.log.levels.ERROR)
    return
  end

  if graph.require_dir() == nil then
    return
  end

  local roots = existing_roots()
  if #roots == 0 then
    vim.notify("vimseq: no pages/ or journals/ directories found", vim.log.levels.ERROR)
    return
  end

  local backend = config.get().search_backend
  if backend == "rg" or (backend == "auto" and vim.fn.executable("rg") == 1) then
    search_with_rg(query, roots)
  else
    search_with_lua(query, roots)
  end
end

function M.tag(tag)
  if tag == nil or vim.trim(tag) == "" then
    vim.notify("vimseq: tag is required", vim.log.levels.ERROR)
    return
  end

  tag = vim.trim(tag)
  if tag:sub(1, 1) ~= "#" then
    tag = "#" .. tag
  end

  M.text(tag)
end

return M
