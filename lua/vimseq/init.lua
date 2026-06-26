local config = require("vimseq.config")

local M = {}

local function create_commands()
  vim.api.nvim_create_user_command("VimseqToday", function()
    require("vimseq.graph").today()
  end, { desc = "Open or create today's Logseq journal" })

  vim.api.nvim_create_user_command("VimseqSearch", function(args)
    require("vimseq.search").text(args.args)
  end, { nargs = "+", desc = "Search Logseq pages and journals" })

  vim.api.nvim_create_user_command("VimseqSearchByTag", function(args)
    require("vimseq.search").tag(args.args)
  end, { nargs = "+", desc = "Search Logseq pages and journals by tag" })

  vim.api.nvim_create_user_command("VimseqBrowse", function()
    require("vimseq.browse").open()
  end, { desc = "Browse Logseq pages and journals" })

  vim.api.nvim_create_user_command("VimseqBrowseTags", function()
    require("vimseq.browse").tags()
  end, { desc = "Browse Logseq tags; <CR> drills into a tag" })

  vim.api.nvim_create_user_command("VimseqOpenAsset", function()
    require("vimseq.asset").open_under_cursor()
  end, { desc = "Open Logseq asset on current line" })
end

local function enable_current_buffer(buf)
  local opts = config.get()
  if not opts.enable_mappings then
    return
  end

  local graph = require("vimseq.graph")
  local edit = require("vimseq.edit")
  local name = vim.api.nvim_buf_get_name(buf)

  if name == "" then
    return
  end

  vim.api.nvim_buf_call(buf, function()
    if graph.is_graph_file(name) then
      edit.enable_buffer(buf)
    end
  end)
end

local function create_autocmds()
  local group = vim.api.nvim_create_augroup("vimseq", { clear = true })

  vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
    group = group,
    pattern = "*.md",
    callback = function(args)
      enable_current_buffer(args.buf)
    end,
  })
end

function M.setup(opts)
  config.setup(opts or {})
  create_commands()
  create_autocmds()
end

return M
