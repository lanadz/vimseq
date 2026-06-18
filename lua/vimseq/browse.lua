local graph = require("vimseq.graph")

local M = {}

local function relpath(path, root)
  if path:sub(1, #root) == root then
    return path:sub(#root + 2)
  end
  return path
end

local function collect(kind, dir)
  if dir == nil or vim.fn.isdirectory(dir) == 0 then
    return {}
  end

  local files = vim.fn.globpath(dir, "**/*.md", false, true)
  local items = {}

  for _, file in ipairs(files) do
    local display = relpath(file, dir):gsub("%.md$", "")
    table.insert(items, {
      kind = kind,
      path = file,
      display = display,
    })
  end

  table.sort(items, function(a, b)
    if kind == "journal" then
      return a.display > b.display
    end
    return a.display < b.display
  end)

  return items
end

local function render(items)
  local lines = {}

  for _, item in ipairs(items) do
    table.insert(lines, string.format("%-8s %s", item.kind, item.display))
  end

  return lines
end

function M.open()
  if graph.require_dir() == nil then
    return
  end

  local items = {}
  vim.list_extend(items, collect("journal", graph.journals_dir()))
  vim.list_extend(items, collect("page", graph.pages_dir()))

  if #items == 0 then
    vim.notify("vimseq: no pages or journals found")
    return
  end

  vim.cmd("botright new")
  local buf = vim.api.nvim_get_current_buf()

  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].buflisted = false
  vim.bo[buf].filetype = "vimseqbrowse"

  vim.b[buf].vimseq_browse_items = items

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, render(items))
  vim.bo[buf].modifiable = false

  vim.keymap.set("n", "<CR>", function()
    require("vimseq.browse").open_selected()
  end, { buffer = buf, silent = true })

  vim.keymap.set("n", "q", "<cmd>bd!<CR>", { buffer = buf, silent = true })

  vim.api.nvim_win_set_cursor(0, { 1, 0 })
end

function M.open_selected()
  local items = vim.b.vimseq_browse_items
  if items == nil then
    return
  end

  local row = vim.api.nvim_win_get_cursor(0)[1]
  local item = items[row]
  if item == nil then
    return
  end

  vim.cmd.edit(vim.fn.fnameescape(item.path))
end

return M
