local graph = require("vimseq.graph")

local M = {}

local function asset_from_line(line)
  local patterns = {
    "%.%./assets/[^%)%]%s]+",
    "assets/[^%)%]%s]+",
  }

  for _, pattern in ipairs(patterns) do
    local match = line:match(pattern)
    if match ~= nil then
      return match
    end
  end

  return nil
end

local function opener_command(path)
  if vim.fn.has("macunix") == 1 then
    return { "open", path }
  end

  if vim.fn.executable("xdg-open") == 1 then
    return { "xdg-open", path }
  end

  return nil
end

function M.open_under_cursor()
  local dir = graph.require_dir()
  if dir == nil then
    return
  end

  local asset = asset_from_line(vim.api.nvim_get_current_line())
  if asset == nil then
    vim.notify("vimseq: no asset path found on current line", vim.log.levels.WARN)
    return
  end

  asset = asset:gsub("^%.%./", "")
  local full_path = dir .. "/" .. asset

  if vim.fn.filereadable(full_path) == 0 then
    vim.notify("vimseq: asset not found: " .. full_path, vim.log.levels.ERROR)
    return
  end

  local cmd = opener_command(full_path)
  if cmd == nil then
    vim.notify("vimseq: no asset opener found for " .. full_path, vim.log.levels.ERROR)
    return
  end

  vim.fn.jobstart(cmd, { detach = true })
end

return M
