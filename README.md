# Live Cmdline

This plugin provides async-autocompletion for search and commands in cmdline-mode.
Sometimes it helps to know what words (starting with a letter) are available in the buffer for search even before searching.
If you liked Vim's `wildmenu`, you'd want popup autocompletion for completing commands and arguments.

__How it helps?__

- Unobtrusive and does not interfere with Vim's idioms.
- Preview searchable words and commands in a popup menu.
- Search multiple words even across line boundary; Fuzzy search.
- Fast; Does not hang up on large files or while searching wildcard paths.

__How to use it?__

- Search using `/` or `?`. Enter commands using `:` as usual.
- `<Tab>` and `<Shift-tab>` will select menu items.
- `<Ctrl-E>` dismisses popup menu.
- `<Enter>` accepts selection, and `<Esc>` dismisses search.
- `<Ctrl-C>` will force popup menu to close.

__Multiline Search__

- Type the character between words (like `<Space>`) after the first word to include the second word in search.
- Type `\n` at the end of the last word in a line to continue to next line.
- Available only when fuzzy option is not selected.

### Normal Popup Menu

[![asciicast](https://asciinema.org/a/dGNdbLbsTMSdaL8E4PonxQDKL.svg)](https://asciinema.org/a/dGNdbLbsTMSdaL8E4PonxQDKL)


### Popup Menu over Statusline

Main window remains fully visible since popup is positioned on the statusline.
This is the default option.

[![asciicast](https://asciinema.org/a/DrvlJnoumCA9jWuMH8WGBCVJz.svg)](https://asciinema.org/a/DrvlJnoumCA9jWuMH8WGBCVJz)

# Features

- Does not interfere with `c|d|y /pattern` commands (copy/delete/yank).
- Search command does not get bogged down when searching large files.
- Respects forward (`/`) and reverse (`?`) search when displaying menu items.
- Does not interfere with search-history recall (arrow keys, <Ctrl-N/P> are not mapped).
- Does not interfere with search-highlighting and incremental-search.
- Switch between normal popup menu and flat menu.
- Fully customizable colors and popup menu options.
- Can search across space and newline characters (multi-line search).
- Written in Vim9script for speed.

# Requirements

- Vim >= 9.0

# Installation

Install using [vim-plug](https://github.com/junegunn/vim-plug)

```
vim9script
plug#begin()
Plug 'girishji/search-complete.vim'
plug#end()
```

Legacy script:

```
call plug#begin()
Plug 'girishji/search-complete.vim'
call plug#end()
```

Or use Vim's builtin package manager.

# Configuration

### Case Sensitive Search

`ignorecase` and `smartcase` Vim variables are used to decide menu items. Set
them appropriately using `set` command.

### Options

There are two types of options that can be configured: 1) options passed directly to Vim's
[popup_create()](https://vimhelp.org/popup.txt.html#popup_create-arguments)
function, and 2) options used internally by this plugin. Any option accepted by
popup_create() is allowed. This includes `borderchars`, `border`, `maxheight`,
etc. See `:h popup_create-arguments`.

`g:SearchCompleteSetup()` function is used to set options. It takes a dictionary argument.
If you are using
[vim-plug](https://github.com/junegunn/vim-plug), use `autocmd` to set options
(after calling `Plug`).

```
vim9script
augroup MySearchComplete | autocmd!
    autocmd WinEnter,BufEnter * g:SearchCompleteSetup({
                \   borderchars: ['─', '│', '─', '│', '┌', '┐', '┘', '└'],
                \   flatMenu: false,
                \ })
augroup END
```

Legacy script:

```
augroup MySearchComplete | autocmd!
    autocmd WinEnter,BufEnter * call SearchCompleteSetup(#{
                \   borderchars: ['─', '│', '─', '│', '┌', '┐', '┘', '└'],
                \   flatMenu: v:false,
                \ })
augroup END
```

Options of interest:

- `maxheight`: Line count of vertical menu, defaults to 12 lines.
- `border`: To disable border set this to `[0, 0, 0, 0]`.
- `searchRange`: Lines per search iteration, defaults to 1000 lines.
- `flatMenu` : 'true' for flat menu, 'false' for normal popup menu. Defaults to true.

### Commands to Enable and Disable Search Completion

- `:SearchCompleteEnable`
- `:SearchCompleteDisable`


### Highlight Groups

Customize the colors to your liking using highlight groups.

- `SearchCompleteMenu`: Menu items in popup menu, linked to `Pmenu`.
- `SearchCompleteSelect`: Selected item, linked to `PmenuSel`.
- `SearchCompletePrefix`: Fragment of menu item that matches text being searched, linked to `Statement`.
- `SearchCompleteSbar`: Vertical menu scroll bar, linked to `PmenuSbar`.
- `SearchCompleteThumb`: Vertical menu scroll bar thumb, linked to `PmenuThumb`.


# Performance

Great care is taken to ensure that responsiveness does not deteriorate when
searching large files. Large files are searched in batches. Each search
attempt is limited to 1000 lines (configurable). Reduce this number if you prefer
faster response. Between each search attempt input keystrokes are allowed to be
queued into Vim's main loop.

# Contributing

Pull requests are welcome.

# Similar Plugins

- [cmp-cmdline](https://github.com/hrsh7th/cmp-cmdline)
- [wilder.nvim](https://github.com/gelguy/wilder.nvim)
- [sherlock](https://github.com/vim-scripts/sherlock.vim)
