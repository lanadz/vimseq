local config = require("vimseq.config")

local M = {}

local function normalize(path)
  if path == nil or path == "" then
    return ""
  end

  path = vim.fn.expand(path)
  path = vim.fn.fnamemodify(path, ":p")
  path = path:gsub("/+$", "")
  return path
end

local function exists_dir(path)
  return path ~= "" and vim.fn.isdirectory(path) == 1
end

local function exists_file(path)
  return path ~= "" and vim.fn.filereadable(path) == 1
end

function M.looks_like_graph(dir)
  dir = normalize(dir)

  return exists_file(dir .. "/logseq/config.edn")
    and exists_dir(dir .. "/pages")
    and exists_dir(dir .. "/journals")
end

function M.find_upwards(start_dir)
  local dir = normalize(start_dir)

  if dir == "" then
    dir = normalize(vim.fn.getcwd())
  end

  while dir ~= "" and dir ~= "/" do
    if M.looks_like_graph(dir) then
      return dir
    end

    local parent = normalize(vim.fn.fnamemodify(dir, ":h"))
    if parent == dir then
      break
    end
    dir = parent
  end

  return ""
end

function M.dir()
  local opts = config.get()

  if opts.graph_dir ~= nil and opts.graph_dir ~= "" then
    return normalize(opts.graph_dir)
  end

  local current = vim.api.nvim_buf_get_name(0)
  if current ~= "" then
    return M.find_upwards(vim.fn.fnamemodify(current, ":p:h"))
  end

  return M.find_upwards(vim.fn.getcwd())
end

function M.require_dir()
  local dir = M.dir()

  if dir == "" then
    vim.notify("vimseq: graph directory not found. Set vim.g.vimseq_graph_dir or require('vimseq').setup({ graph_dir = ... })", vim.log.levels.ERROR)
    return nil
  end

  return dir
end

function M.path(...)
  local dir = M.require_dir()
  if dir == nil then
    return nil
  end

  local parts = { ... }
  local path = dir
  for _, part in ipairs(parts) do
    path = path .. "/" .. part
  end

  return path
end

function M.pages_dir()
  return M.path(config.get().pages_dir)
end

function M.journals_dir()
  return M.path(config.get().journals_dir)
end

function M.assets_dir()
  return M.path(config.get().assets_dir)
end

function M.is_graph_file(path)
  local dir = M.dir()
  if dir == "" then
    return false
  end

  path = normalize(path)
  dir = normalize(dir)

  return path == dir or path:sub(1, #dir + 1) == dir .. "/"
end

function M.today()
  local opts = config.get()
  local journals = M.journals_dir()
  if journals == nil then
    return
  end

  vim.fn.mkdir(journals, "p")

  local filename = os.date(opts.journal_date_format) .. ".md"
  local file = journals .. "/" .. filename

  vim.cmd.edit(vim.fn.fnameescape(file))
end

return M
