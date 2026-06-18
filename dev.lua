vim.opt.runtimepath:prepend(vim.fn.getcwd())

require("vimseq").setup({
  graph_dir = vim.fn.getcwd() .. "/test-graph",
})

vim.cmd("VimseqToday")
