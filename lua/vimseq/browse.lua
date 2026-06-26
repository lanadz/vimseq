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

  local qf = {}
  for _, item in ipairs(items) do
    table.insert(qf, {
      filename = item.path,
      lnum = 1,
      col = 1,
      text = string.format("%-8s %s", item.kind, item.display),
    })
  end

  vim.fn.setqflist({}, " ", {
    title = "VimseqBrowse",
    items = qf,
  })

  vim.cmd("botright copen")
end

local TAG_TITLE = "VimseqBrowseTags"

local function markdown_files()
  local files = {}

  for _, dir in ipairs({ graph.journals_dir(), graph.pages_dir() }) do
    if dir ~= nil and vim.fn.isdirectory(dir) == 1 then
      vim.list_extend(files, vim.fn.globpath(dir, "**/*.md", false, true))
    end
  end

  return files
end

-- Extract the Logseq tags present on a single line, in the forms
-- #tag, #tag/sub, #[[multi word]] and the `tags:: a, b` property.
local function line_tags(line)
  local out = {}

  for col, name in line:gmatch("()#%[%[([^%]]+)%]%]") do
    table.insert(out, { name = vim.trim(name), col = col })
  end

  for col, name in line:gmatch("()#([%w][%w%-_/]*)") do
    table.insert(out, { name = vim.trim(name), col = col })
  end

  local value = line:match("^%s*tags::%s*(.+)$")
  if value ~= nil then
    for raw in value:gmatch("[^,]+") do
      local name = vim.trim(raw):gsub("^%[%[", ""):gsub("%]%]$", ""):gsub("^#", "")
      if name ~= "" then
        table.insert(out, { name = name, col = 1 })
      end
    end
  end

  return out
end

-- Replace all occurrences of a tag in the quickfix list (drill-down).
function M.drill(name)
  local items = {}

  for _, file in ipairs(markdown_files()) do
    local ok, lines = pcall(vim.fn.readfile, file)
    if ok then
      for lnum, line in ipairs(lines) do
        for _, tag in ipairs(line_tags(line)) do
          if tag.name == name then
            table.insert(items, {
              filename = file,
              lnum = lnum,
              col = tag.col,
              text = line,
            })
            break
          end
        end
      end
    end
  end

  vim.fn.setqflist({}, "r", {
    title = "vimseq tag: #" .. name,
    items = items,
  })

  if #items == 0 then
    vim.notify("vimseq: no matches for #" .. name)
  end
end

-- Quickfix <CR> handler: drill into a tag when viewing the tag index,
-- otherwise fall back to the built-in jump-to-entry behaviour.
function M.qf_enter()
  local title = vim.fn.getqflist({ title = 1 }).title
  if title == TAG_TITLE then
    local row = vim.api.nvim_win_get_cursor(0)[1]
    local name = (M._tag_list or {})[row]
    if name ~= nil then
      M.drill(name)
    end
    return
  end

  local cr = vim.api.nvim_replace_termcodes("<CR>", true, false, true)
  vim.api.nvim_feedkeys(cr, "n", false)
end

function M.tags()
  if graph.require_dir() == nil then
    return
  end

  local tags = {}
  local order = {}

  for _, file in ipairs(markdown_files()) do
    local ok, lines = pcall(vim.fn.readfile, file)
    if ok then
      for lnum, line in ipairs(lines) do
        for _, tag in ipairs(line_tags(line)) do
          local entry = tags[tag.name]
          if entry == nil then
            entry = { count = 0, file = file, lnum = lnum, col = tag.col }
            tags[tag.name] = entry
            table.insert(order, tag.name)
          end
          entry.count = entry.count + 1
        end
      end
    end
  end

  if #order == 0 then
    vim.notify("vimseq: no tags found")
    return
  end

  -- Most-used tags first, ties broken alphabetically.
  table.sort(order, function(a, b)
    if tags[a].count ~= tags[b].count then
      return tags[a].count > tags[b].count
    end
    return a < b
  end)

  local qf = {}
  for _, name in ipairs(order) do
    local entry = tags[name]
    table.insert(qf, {
      filename = entry.file,
      lnum = entry.lnum,
      col = entry.col,
      text = string.format("%4d  #%s", entry.count, name),
    })
  end

  -- Parallel list so the <CR> handler can map a quickfix row to its tag.
  M._tag_list = order

  vim.fn.setqflist({}, " ", {
    title = TAG_TITLE,
    items = qf,
  })

  vim.cmd("botright copen")

  vim.keymap.set("n", "<CR>", function()
    require("vimseq.browse").qf_enter()
  end, { buffer = vim.api.nvim_get_current_buf(), silent = true })
end

return M
