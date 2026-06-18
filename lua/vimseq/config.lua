local M = {}

M.options = {
  graph_dir = nil,
  journal_date_format = "%Y_%m_%d",
  pages_dir = "pages",
  journals_dir = "journals",
  assets_dir = "assets",
  search_backend = "auto", -- auto | rg | lua
  open_quickfix_on_search = true,
  enable_mappings = true,
}

local function g(name)
  return vim.g["vimseq_" .. name]
end

function M.setup(opts)
  opts = opts or {}
  M.options = vim.tbl_deep_extend("force", M.options, opts)
end

function M.get()
  local opts = vim.deepcopy(M.options)

  -- Support classic Vim-style globals as a convenient config surface.
  if opts.graph_dir == nil and g("graph_dir") ~= nil then
    opts.graph_dir = g("graph_dir")
  end
  if g("journal_date_format") ~= nil then
    opts.journal_date_format = g("journal_date_format")
  end
  if g("pages_dir") ~= nil then
    opts.pages_dir = g("pages_dir")
  end
  if g("journals_dir") ~= nil then
    opts.journals_dir = g("journals_dir")
  end
  if g("assets_dir") ~= nil then
    opts.assets_dir = g("assets_dir")
  end
  if g("search_backend") ~= nil then
    opts.search_backend = g("search_backend")
  end

  return opts
end

return M
