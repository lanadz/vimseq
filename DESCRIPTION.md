# vimseq description

`vimseq` is a Lua Neovim plugin for editing Logseq graphs directly in the terminal.

The project starts from one idea: Logseq's file format is useful, but its Electron editor can get in the way. `vimseq` keeps the graph on disk as normal Logseq-compatible Markdown and provides a stable Neovim editing layer over it.

## Core concept

Use Neovim as the primary writing/editing interface for a Logseq graph.

Logseq remains useful for:

- graph visualization
- advanced queries
- backlinks UI
- plugin ecosystem
- mobile/desktop review

Neovim becomes the interface for:

- fast daily capture
- stable Markdown editing
- modal navigation
- bulk pasting
- grep/search workflows
- terminal-native note management

## First feature set

### Settings

Configure the Logseq graph directory:

```lua
require('vimseq').setup({
  graph_dir = '~/notes/logseq',
})
```

Classic globals are also supported:

```lua
vim.g.vimseq_graph_dir = '~/notes/logseq'
```

The plugin should read/write files under that graph without inventing a separate storage layer.

### Commands

#### `:VimseqToday`

Open or create today's Logseq journal file.

#### `:VimseqSearchByTag {tag}`

Find files/entries related to a Logseq tag.

#### `:VimseqSearch {query}`

Plain text search over pages and journals. Implementation should use quickfix and avoid requiring Telescope/Spectre/fzf.

#### `:VimseqBrowse`

Browse graph files from Neovim and open selected pages/journals.

## Design principles

1. **Compatibility first**

   Files edited by `vimseq` should remain readable by Logseq.

2. **Stable source view**

   Do not hide/reveal Markdown syntax on cursor focus in a way that shifts layout.

3. **No mandatory plugin dependencies**

   Core browsing/search should work with standard Neovim primitives: buffers, quickfix, autocmds, and mappings.

4. **Optional niceties later**

   Fuzzy pickers, inline images, advanced indexing, and Neovim-only UI can be optional integrations.

5. **Bulk text must be easy**

   There should be an obvious way to paste hundreds of lines without turning every line into a Logseq block.

## Image/screenshot stance

Inline image rendering in terminal Neovim is not universally supported. The portable first version opens image assets externally. Inline previews can be added later for terminals that support Kitty graphics, iTerm2 inline images, SIXEL, or helper tools like `ueberzugpp`, `viu`, or `chafa`.

## Success criteria for MVP

The MVP is successful if you can:

- open today's Logseq journal from Neovim
- search notes by text
- search notes by tag
- browse pages/journals
- edit files without Logseq-style focus/layout jumps
- paste large raw snippets without fighting automatic bulletization
- reopen the same graph in Logseq without broken files
