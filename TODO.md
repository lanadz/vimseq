# vimseq TODO

## Phase 0 — Decisions

- [x] Choose baseline runtime: Neovim Lua-first.
- [x] Decide whether this plugin targets raw Vim, Neovim, or both: Neovim-only for now.
- [x] Confirm default Logseq journal filename format: `YYYY_MM_DD.md`.
- [x] Decide whether graph directory is mandatory or auto-detected: configured first, auto-detected as fallback.
- [ ] Decide minimum supported Neovim version.

Starting decision: **Lua-first, quickfix-first, scratch-buffer browse, no plugin dependencies.**

## Phase 1 — Graph configuration and detection

- [x] Add `g:vimseq_graph_dir` setting.
- [x] Add Lua `require('vimseq').setup({ graph_dir = ... })` setting.
- [x] Expand `~` and environment variables in graph paths.
- [ ] Validate graph directory exists.
- [x] Detect Logseq graph by checking for:
  - [x] `logseq/config.edn`
  - [x] `pages/`
  - [x] `journals/`
- [x] Add helper for graph-relative paths.
- [x] Add helper for pages directory.
- [x] Add helper for journals directory.
- [x] Add helper for assets directory.
- [x] Add useful error messages when graph is not configured.

## Phase 2 — Journal command

- [x] Implement `:VimseqToday`.
- [x] Create journal file if missing.
- [x] Open today's journal in current window.
- [x] Respect configurable date format.
- [x] Preserve Logseq-compatible empty file behavior.
- [ ] Add `:VimseqJournal {date}` later.

## Phase 3 — Search

- [x] Implement `:VimseqSearch {query}`.
- [x] Search only `pages/` and `journals/` by default.
- [x] Prefer `rg` if available.
- [x] Fallback to Lua scanner if `rg` is unavailable.
- [x] Populate quickfix list.
- [x] Open quickfix window.
- [x] Escape search input safely by using fixed-string search.
- [x] Handle multi-word queries.
- [ ] Add tests/manual fixtures for special characters.

## Phase 4 — Tag search

- [x] Implement `:VimseqSearchByTag {tag}`.
- [x] Accept `foo` and `#foo`.
- [x] Normalize to Logseq hashtag search.
- [x] Search for inline tags: `#foo`.
- [x] Search for nested tags: `#project/foo`.
- [ ] Later: support page-style tags: `#[[foo bar]]`.
- [ ] Later: support property tags: `tags:: foo, bar`.
- [ ] Later: show grouped results by page/journal.

## Phase 5 — Browse

- [x] Implement `:VimseqBrowse`.
- [x] List files from `pages/`.
- [x] List files from `journals/`.
- [x] Open browse results in scratch buffer.
- [x] Press `<CR>` to open selected file.
- [x] Mark journals/pages differently.
- [x] Sort journals descending.
- [x] Sort pages alphabetically.
- [ ] Later: add in-buffer filtering.

## Phase 6 — Editing ergonomics

- [x] Detect Logseq Markdown buffers.
- [x] Add buffer-local mappings only inside graph files.
- [x] Implement `<CR>` as next sibling bullet.
- [x] Preserve indentation level.
- [ ] Handle empty bullet behavior.
- [ ] Implement indent/outdent block helpers.
- [x] Implement literal newline inside block.
- [x] Implement paste helpers:
  - [x] `:VimseqPastePlain`
  - [x] `:VimseqPasteCodeBlock`
  - [x] `:VimseqPasteBullets`
- [x] Avoid changing normal Markdown files outside the Logseq graph.

## Phase 7 — Page links and navigation

- [ ] Implement page-name to filename conversion.
- [ ] Implement `:VimseqOpenPage {page}`.
- [ ] Implement `:VimseqFollowLink` for `[[Page]]` under cursor.
- [ ] Create missing page files on demand.
- [ ] Support spaces and escaped characters in page names.
- [ ] Later: support block refs `((uuid))`.
- [ ] Later: support backlinks `:VimseqBacklinks [page]`.

## Phase 8 — Assets and images

- [x] Implement `:VimseqOpenAsset` for asset under cursor.
- [x] Open asset externally using OS default app.
- [x] macOS: use `open`.
- [x] Linux: use `xdg-open`.
- [ ] Later: optional inline preview backends:
  - [ ] Kitty graphics protocol
  - [ ] iTerm2 inline image protocol
  - [ ] SIXEL
  - [ ] `ueberzugpp`
  - [ ] `chafa` / `viu` fallback previews
- [ ] Keep image support optional and feature-detected.

## Phase 9 — Documentation

- [ ] Document installation.
- [x] Document configuration.
- [x] Document commands.
- [x] Document mappings.
- [x] Document compatibility assumptions.
- [x] Add examples with a tiny fake Logseq graph.
- [ ] Add troubleshooting section.

## Open questions

- Should `vimseq` stay Neovim-only forever, or eventually support Vim?
- Search results use quickfix for now; do we need grouped/custom UI later?
- `:VimseqBrowse` uses a scratch buffer for now; do we need filtering/fuzzy matching?
- How aggressively should the plugin parse Logseq Markdown versus relying on grep/regex?
- How should multi-line Logseq blocks be represented during paste?
- Should inline image preview be attempted, or should assets simply open externally?
- Should the plugin ever modify Logseq properties like `id::`, or leave those entirely to Logseq?
