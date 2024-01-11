# autosuggest.vim

Autocompletion for Vim's Cmdline Mode. This unobtrusive plugin opens a popup menu of candidate items during search (`/`, `?`) and command (`:`) execution.

## Key Features

- Preview searchable words and commands (and their arguments).
- Search multiple words, even across line boundary; Fuzzy search.
- All Vim idioms work as before. No surprises.
- Fast, does not hang up when searching large files or expanding wildcards.
  
## Usage

Vim's default keybindings are not altered in any way.

- `/` or `?` to search forward/backward.
- `:` to enter commands.
- `<Tab>` and `<Shift-tab>` (or `<Ctrl-N>` and `<Ctrl-P>`) to select menu items.
- `<Ctrl-E>` to dismiss popup menu.
- `<Enter>` to accept selection, and `<Esc>` to dismiss search.
- `<Ctrl-C>` to force close popup menu.

> [!NOTE]
> For multi-word search, type the separator character (like `<Space>`) after the first word to trigger autocompletion for second word. Type `\n` at the end of the last word in a line to continue to next line. Setting fuzzy search option disables this feature.

> [!NOTE]
> For insert-mode autocompletion see [Vimcomplete](https://github.com/girishji/vimcomplete).

### Search

[![asciicast](https://asciinema.org/a/dGNdbLbsTMSdaL8E4PonxQDKL.svg)](https://asciinema.org/a/dGNdbLbsTMSdaL8E4PonxQDKL)

### Command

[![asciicast](https://asciinema.org/a/eGWd650BZa7uiRi6lv76qYMRG.svg)](https://asciinema.org/a/eGWd650BZa7uiRi6lv76qYMRG)

### Popup Menu over Statusline

[![asciicast](https://asciinema.org/a/DrvlJnoumCA9jWuMH8WGBCVJz.svg)](https://asciinema.org/a/DrvlJnoumCA9jWuMH8WGBCVJz)

## Features

- Will not hang under any circumstance (including `**` wildcards)
- Autocomplete command names, arguments, Vimscript functions, and variables.
- Switch between normal popup menu and flat menu.
- `[c|d|y]/{pattern}` commands (copy/delete/yank) work as expected.
- Search-highlighting, incremental-search, and history recall work as expected.
- Distinguishes between forward (`/`) and reverse (`?`) search.
- Fuzzy search option.
- Written in Vim9script for ease of maintenance.

## Requirements

- Vim >= 9.0

## Installation

Install using [vim-plug](https://github.com/junegunn/vim-plug):

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

## Configuration

### Options

Default options are as follows.

```
vim9script
var options = {
    search: {
        enable: true,   # 'false' will disable search completion
        maxheight: 12,  # line count of stacked menu
        pum: true,      # 'false' for flat menu, 'true' for stacked menu
        fuzzy: false,   # fuzzy completion
        alwayson: true, # when 'false' press <tab> to open popup menu
    },
    cmd: {
        enable: true,   # 'false' will disable command completion
        pum: true,      # 'false' for flat menu, 'true' for stacked menu
        fuzzy: false,   # fuzzy completion
        exclude: [],    # keywords excluded from completion (use \c for ignorecase)
        onspace: [],    # show popup menu after keyword+space (ex. :buffer<space>, etc.)
    }
}
```

Options can be modified using `g:AutoSuggestSetup()`. If you are using
[vim-plug](https://github.com/junegunn/vim-plug) use the `VimEnter` event as
follows.

```
autocmd VimEnter * g:AutoSuggestSetup(options)
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

### Case Sensitive Search

Set `ignorecase` and `smartcase` using `set` command. See `:h 'ignorecase'` and
`h 'smartcase'`.

## Key Mapping

If you defined a keymap that puts text on the command line or waits for input,
you may find that the command line may get cleared by the popup. This
undesirable outcome can be prevented by one of two methods: specify keywords
that should be ignored by the autocompletion mechanism, or disable and enable
the plugin within the keymap.

For instance, let's say you have a keymap as follows. First command lists
buffers and second one chooses.

```
nnoremap <leader>b :buffers<cr>:buffer<space>
```

This will not work because the second `buffer` command is just text on the
command line. It causes the popup to open and clear the output of previous
`buffers` command.

First solution is to simply exclude the word `buffer` from autocompletion.
Include this in your options.

```
var options = {
    cmd: {
        exclude: ['buffer']
    }
}
```

Another solution is to disable and enable.

```
:nnoremap <leader>b :AutoSuggestDisable<cr>:buffers<cr>:let nr = input("Which one: ")<Bar>exe $'buffer {nr}'<bar>AutoSuggestEnable<cr>
```

### Find Files and Switch Buffers Quickly

You can define some interesting keymappings with the help of this plugin. Here
are two examples. First one will help you open file under current working
directory. Second mapping switches buffers. Type a few letters to narrow the
search and use `<tab>` to choose from menu.

```
nnoremap <leader>f :e<space>**/*<left>
nnoremap <leader>b :buffer<space>

# Set the following option
autocmd VimEnter * g:AutoSuggestSetup({ cmd: { onspace: ['buffer'] }})
```

[![asciicast](https://asciinema.org/a/XeuHijghtC9XmbNVu5EKzdmeH.svg)](https://asciinema.org/a/XeuHijghtC9XmbNVu5EKzdmeH)

## Performance

Care is taken to ensure that responsiveness does not deteriorate when
searching large files or expanding wildcards. Large files are searched in
batches. Between each search attempt input keystrokes are allowed to be queued
into Vim's main loop. Wildcard expansions are first executed in a separate job
and aborted after a timeout.

## Contributing

Pull requests are welcome.

# Similar Plugins

- [cmp-cmdline](https://github.com/hrsh7th/cmp-cmdline)
- [wilder.nvim](https://github.com/gelguy/wilder.nvim)
- [sherlock](https://github.com/vim-scripts/sherlock.vim)
