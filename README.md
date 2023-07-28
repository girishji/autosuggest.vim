#### Autocomplete Plugin for Vim's Cmdline Mode

Wouldn't it be nice to have autocomplete during search and command execution?
This unobtrusive plugin simply opens a popup menu and shows 
autocompletion options when you search (`/`, `?`) or enter commands (`:`) in
commandline-mode.

__How it helps?__

- Preview searchable words and commands (and their arguments).
- Search multiple words, even across line boundary; Fuzzy search.
- All Vim idioms work as before. No surprises.
- Fast, does not hang up when searching large files or expanding wildcards.

__How to use it?__

- Search using `/` or `?` or enter commands using `:` as usual.
- `<Tab>` and `<Shift-tab>` will select menu items.
- `<Ctrl-E>` dismisses popup menu.
- `<Enter>` accepts selection, and `<Esc>` dismisses search.
- `<Ctrl-C>` will force popup menu to close.

__Multiword Search__

- Type the character between words (like `<Space>`) after the first word to include the second word in search.
- Type `\n` at the end of the last word in a line to continue to next line.
- Available only when fuzzy option is not selected.

If you like this plugin, checkout insert-mode tab completion plugin
([Vimcomplete](https://github.com/girishji/vimcomplete)).

### Search

[![asciicast](https://asciinema.org/a/dGNdbLbsTMSdaL8E4PonxQDKL.svg)](https://asciinema.org/a/dGNdbLbsTMSdaL8E4PonxQDKL)

[![asciicast](https://asciinema.org/a/vLqdbH0ITj6v6toDTWqyXP0si.svg)](https://asciinema.org/a/vLqdbH0ITj6v6toDTWqyXP0si)

### Command

[![asciicast](https://asciinema.org/a/eGWd650BZa7uiRi6lv76qYMRG.svg)](https://asciinema.org/a/eGWd650BZa7uiRi6lv76qYMRG)

### Popup Menu over Statusline

[![asciicast](https://asciinema.org/a/DrvlJnoumCA9jWuMH8WGBCVJz.svg)](https://asciinema.org/a/DrvlJnoumCA9jWuMH8WGBCVJz)

[![asciicast](https://asciinema.org/a/HLRW3J95pcQFbuC4Kwttk6Ofo.svg)](https://asciinema.org/a/HLRW3J95pcQFbuC4Kwttk6Ofo)


# Features

- Does not interfere with `[c|d|y]/{pattern}` commands (copy/delete/yank).
- Respects forward (`/`) and reverse (`?`) search when displaying menu items.
- Does not interfere with search-highlighting and incremental-search.
- Does not interfere with search-history recall (arrow keys, `<Ctrl-N/P>` are not mapped).
- Fuzzy search option.
- Will not hang under any circumstance (including `**` wildcards)
- Command names, arguments, Vimscript functions, variables, etc., are autocompleted.
- Switch between normal popup menu and flat menu.
- Command completion works independent of `wildmenu` (you could enable both).
- Written in Vim9script for readability and ease of maintenance (and speed).

# Requirements

- Vim >= 9.0

# Installation

Install using [vim-plug](https://github.com/junegunn/vim-plug)

```
vim9script
plug#begin()
Plug 'girishji/autosuggest.vim'
plug#end()
```

Legacy script:

```
call plug#begin()
Plug 'girishji/autosuggest.vim'
call plug#end()
```

Or use Vim's builtin package manager.

# Configuration

*Case Sensitive Search*

Set `ignorecase` and `smartcase` using `set` command. See `:h 'ignorecase'` and
`h 'smartcase'`.

### Options

Default options are as follows.

```
vim9script
var options = {
    search: {
        enable: true,   # 'false' will disable search completion
        maxheight: 12,	# line count of stacked menu
        pum: true,	    # 'false' for flat menu, 'true' for stacked menu
        fuzzy: false,   # fuzzy completion
    },
    cmd: {
        enable: true,   # 'false' will disable command completion
        pum: true,      # 'false' for flat menu, 'true' for stacked menu
    }
}
```

Options can be modified using g:AutoSuggestSetup().

```
augroup AutoSuggestGrp | autocmd!
    autocmd WinEnter,BufEnter * g:AutoSuggestSetup(options)
augroup END
```

### Commands

 _Enable and disable this plugin_

- `:AutoSuggestEnable`
- `:AutoSuggestDisable`


### Highlight Groups

Highlight group `AS_SearchCompletePrefix` affects style of the fragment of menu item
that matches text being searched. By default it is linked to highlight group `Special`.
Popup menu appearance is determined by Vim's highlight groups `Pmenu`,
`PmenuSel`, `PmenuSbar` and `PmenuThumb`. For command completion `WildMenu`
group (`:h hl-WildMenu`) can be used.

# Performance

Care is taken to ensure that responsiveness does not deteriorate when
searching large files or expanding wildcards. Large files are searched in
batches. Between each search attempt input keystrokes are allowed to be queued
into Vim's main loop. Wildcard expansions are first executed in a separate job
and aborted after a timeout.

# Contributing

Pull requests are welcome.

# Similar Plugins

- [cmp-cmdline](https://github.com/hrsh7th/cmp-cmdline)
- [wilder.nvim](https://github.com/gelguy/wilder.nvim)
- [sherlock](https://github.com/vim-scripts/sherlock.vim)
