# vimseq

A Neovim/Lua terminal editing layer for [Logseq](https://logseq.com/) graphs.

`vimseq` is not a new notes database. It edits the Markdown files that Logseq already stores on disk, while giving you stable Neovim normal/insert-mode workflows for daily notes, outlines, search, and bulk text capture.

## Why

Logseq is great as an outliner and graph UI, but its editor can be frustrating when you mostly want to write:

- focusing a block reveals Markdown/source syntax and shifts the visual layout
- pressing `Enter` always creates a new block, which is great for outlines but bad for dumping large snippets
- modal editing is not first-class
- pasting logs, transcripts, stack traces, or long notes can become over-structured too quickly

`vimseq` keeps the Logseq-compatible file format and replaces the editing surface with Vim.

## Goals

- Edit an existing Logseq graph directly from Neovim.
- Stay compatible with Logseq's Markdown file layout.
- Provide stable, non-jumping source editing.
- Make common Logseq actions available as Vim commands.
- Avoid hard dependencies on large UI/search plugins.
- Use built-in Vim concepts first: buffers, quickfix, location lists, folds, filetype plugins, and mappings.
- Support optional integrations later, without requiring them.

## Non-goals, at least initially

- Reimplement all of Logseq.
- Reimplement Logseq queries in full.
- Build a graph database/indexer before the file-based workflow proves itself.
- Depend on Telescope, Spectre, fzf, or other large plugins for core functionality.
- Replace the Logseq Electron app completely. Logseq can still be used for graph view, advanced queries, and plugin ecosystem features.

## Logseq compatibility

A Logseq graph usually looks like:

```text
my-graph/
  logseq/
    config.edn
  pages/
    Some Page.md
  journals/
    2026_06_17.md
  assets/
    image_*.png
```

`vimseq` should preserve normal Logseq Markdown conventions:

```markdown
- normal bullet block
  - child block
- page links like [[Some Page]]
- tags like #project/foo
- block refs like ((block-id))
- properties
  id:: 664...
  collapsed:: true
- fenced code blocks
```

The plugin should avoid making changes that Logseq cannot read.

## Configuration

The first important setting is the graph directory:

```lua
require('vimseq').setup({
  graph_dir = '~/notes/logseq',
  journal_date_format = '%Y_%m_%d',
})
```

Classic globals also work:

```lua
vim.g.vimseq_graph_dir = '~/notes/logseq'
vim.g.vimseq_journal_date_format = '%Y_%m_%d'
vim.g.vimseq_pages_dir = 'pages'
vim.g.vimseq_journals_dir = 'journals'
vim.g.vimseq_assets_dir = 'assets'
vim.g.vimseq_search_backend = 'auto' -- auto | rg | lua
```

If no graph directory is configured, the plugin tries to detect a graph by walking upward from the current file and looking for:

```text
logseq/config.edn
pages/
journals/
```

## Commands

### `:VimseqToday`

Open or create today's journal entry using Logseq's journal naming format.

Example:

```vim
:VimseqToday
```

Expected behavior:

- resolve the graph directory
- find/create `journals/YYYY_MM_DD.md`
- open it in the current window
- initialize it only if the file is missing
- never add content that breaks Logseq compatibility

### `:VimseqBrowse`

Browse graph files from inside Vim.

Implementation:

- collect files from `journals/` and `pages/`
- populate the quickfix list (journals first, most recent at the top)
- open the quickfix window; pressing `<CR>` opens the selected file

Later improvements:

- fuzzy-ish filtering without external plugins
- show page title instead of raw filename
- include assets optionally

### `:VimseqBrowseTags`

Browse the graph's tags as an index.

Implementation:

- scan `journals/` and `pages/` for `#tag`, `#tag/sub`, `#[[multi word]]`, and
  `tags::` property values
- populate the quickfix list with each tag and its occurrence count, most-used
  first
- pressing `<CR>` on a tag drills in: the quickfix list is replaced with every
  block that uses that tag

### `:VimseqSearch {query}`

Search the graph for plain text.

Example:

```vim
:VimseqSearch deploy pipeline
```

Expected behavior:

- search `pages/` and `journals/`
- prefer `rg` when available
- fallback to a dependency-free Lua scanner
- show matches in quickfix
- open quickfix window automatically

This should be intentionally boring at first. Quickfix is enough.

### `:VimseqSearchByTag {tag}`

Search for notes related to a Logseq tag.

Examples:

```vim
:VimseqSearchByTag project/foo
:VimseqSearchByTag #project/foo
```

Expected behavior:

- normalize the tag input
- search for `#project/foo`
- probably also search page-tag syntax later, e.g. `tags:: project/foo`
- show matches in quickfix

Tag search should understand at least these forms over time:

```markdown
- something #foo
- something #[[foo bar]]
tags:: foo, bar
```

### Implemented asset commands

```vim
:VimseqOpenAsset
```

### Future commands

```vim
:VimseqOpenPage {page}
:VimseqRenamePage {old} {new}
:VimseqBacklinks [page]
:VimseqFollowLink
```

## Editing behavior

The core editing model should feel like Logseq where that helps, and like Vim where Logseq gets in the way.

Suggested mappings:

```text
<CR>       create next sibling bullet
<Tab>      indent block
<S-Tab>    outdent block
<M-CR>     insert literal newline inside current block
```

Since you edit the raw Markdown directly, Logseq's auto-bulletizing of pasted
text no longer applies. Bulk dumps (logs, transcripts, code) can be pasted and
shaped with normal Vim motions and visual-block edits.

## Images and screenshots

Vim itself does not have a universal image display API. Terminal image support depends on the terminal emulator and protocol.

Possible strategies:

1. **Open externally**
   - simplest and most portable
   - `:VimseqOpenAsset` can call `open` on macOS, `xdg-open` on Linux, etc.

2. **Terminal inline image protocols**
   - Kitty graphics protocol
   - iTerm2 inline images
   - SIXEL terminals
   - WezTerm image protocol support varies by mode/protocol

3. **Helper tools**
   - `ueberzugpp`
   - `viu`
   - `chafa`
   - `imgcat`

4. **ASCII/block previews**
   - portable-ish
   - useful for quick identification, not real screenshot inspection

Initial `vimseq` should probably support external asset opening first, then optional inline preview later behind feature detection/settings.

## Implementation direction

Start dependency-free and Neovim-native:

- Lua plugin layout
- graph detection and path helpers
- quickfix-based search
- quickfix-based browse UI
- buffer-local mappings for Logseq Markdown files
- no mandatory external plugins

Current structure:

```text
plugin/vimseq.lua       -- plugin entrypoint
lua/vimseq/init.lua     -- setup, commands, autocmds
lua/vimseq/config.lua   -- configuration
lua/vimseq/graph.lua    -- graph/path helpers and :VimseqToday
lua/vimseq/search.lua   -- :VimseqSearch and :VimseqSearchByTag
lua/vimseq/browse.lua   -- :VimseqBrowse
lua/vimseq/edit.lua     -- bullet mappings
lua/vimseq/asset.lua    -- :VimseqOpenAsset
doc/vimseq.txt          -- help docs
```

## Development

Run locally with the included fake graph:

```bash
nvim -u NONE -S dev.lua
```

Then try:

```vim
:VimseqToday
:VimseqBrowse
:VimseqSearch vimseq
:VimseqSearchByTag vimseq
```

## Status

Lua scaffold exists. See [TODO.md](TODO.md).
