if vim.g.loaded_vimseq == 1 then
  return
end

vim.g.loaded_vimseq = 1

require("vimseq").setup()
