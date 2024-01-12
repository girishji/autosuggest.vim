# autosuggest.vim

Autocompletion for Vim's Cmdline Mode (`/`, `?` to search and `:` to enter a command).

<p>
  <a href="#key-features">Key Features</a> •
  <a href="#requirements">Requirements</a> •
  <a href="#installation">Installation</a> •
  <a href="#configuration">Configuration</a>
</p>


## Key Features

- Preview candidates for search pattern autocompletion and command autocompletion.
- Switch between normal popup menu and flat menu.
- Autocomplete multiple words during search.
- Fuzzy search.
- All Vim idioms work as expected (ex. 'c', 'y', 'd' with pattern).
- Does not hang or slow down when searching large files or expanding wildcards.
- Search-highlighting, incremental-search, and history recall work as expected.
- Written in Vim9script.
  
## Usage

Vim's default keybindings are not altered in any way.

- `/` or `?` to search forward or backward.
- `:` to enter commands.
- `<Tab>` and `<Shift-tab>` (or `<Ctrl-N>` and `<Ctrl-P>`) to select menu items.
- `<Ctrl-E>` to dismiss popup menu.
- `<Enter>` to accept selection.
- `<Esc>` to dismiss search.
- `<Ctrl-C>` to force close popup menu.

> [!NOTE]
> For multi-word search, type the separator character (like `<Space>`) after the first word to trigger autocompletion for second word. Type `\n` at the end of the last word in a line to continue to next line. Setting fuzzy search option disables multi-word search.

> [!NOTE]
> For insert-mode autocompletion see [Vimcomplete](https://github.com/girishji/vimcomplete).

### Search

[![asciicast](https://asciinema.org/a/dGNdbLbsTMSdaL8E4PonxQDKL.svg)](https://asciinema.org/a/dGNdbLbsTMSdaL8E4PonxQDKL)

### Command

[![asciicast](https://asciinema.org/a/eGWd650BZa7uiRi6lv76qYMRG.svg)](https://asciinema.org/a/eGWd650BZa7uiRi6lv76qYMRG)

### Popup Menu over Statusline

[![asciicast](https://asciinema.org/a/DrvlJnoumCA9jWuMH8WGBCVJz.svg)](https://asciinema.org/a/DrvlJnoumCA9jWuMH8WGBCVJz)


## Requirements

- Vim >= 9.0

## Installation

Install it via [vim-plug](https://github.com/junegunn/vim-plug).

<details><summary><b>Show instructions</b></summary>

<br>
Using vim9 script:

```vim
vim9script
plug#begin()
Plug 'girishji/autosuggest.vim'
plug#end()
```

Using legacy script:

```vim
call plug#begin()
Plug 'girishji/autosuggest.vim'
call plug#end()
```

</details>

Install using Vim's built-in package manager.

<details><summary><b>Show instructions</b></summary>
<br>
  
```bash
$ mkdir -p $HOME/.vim/pack/downloads/opt
$ cd $HOME/.vim/pack/downloads/opt
$ git clone https://github.com/girishji/autosuggest.vim
```

Add the following line to your $HOME/.vimrc file.

```vim
packadd autosuggest.vim
```

</details>


## Configuration

Default options are as follows:

```
vim9script
var options = {
    search: {
        enable: true,   # 'false' will disable search completion
        pum: true,      # 'false' for flat menu, 'true' for stacked menu
        maxheight: 12,  # max height of stacked menu in lines
        fuzzy: false,   # fuzzy completion
        alwayson: true, # when 'false' press <tab> to open popup menu
    },
    cmd: {
        enable: true,   # 'false' will disable command completion
        pum: true,      # 'false' for flat menu, 'true' for stacked menu
        fuzzy: false,   # fuzzy completion
        exclude: [],    # patterns to exclude from command completion (use \c for ignorecase)
        onspace: [],    # show popup menu when cursor is in front of space (ex. :buffer<space>)
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

 Enable or disable this plugin:

- `:AutoSuggestEnable`
- `:AutoSuggestDisable`


### Highlight Groups

The `AS_SearchCompletePrefix` highlight group influences the fragment of a menu item that matches the text being searched. By default, it is linked to the highlight group `Special`. The appearance of the popup menu is determined by Vim's highlight groups `Pmenu`, `PmenuSel`, `PmenuSbar`, and `PmenuThumb`. For command completion, the `WildMenu` group (refer to `:h hl-WildMenu`) can be utilized.


### Case Sensitive Search

Set `ignorecase` and `smartcase` using `set` command. See `:h 'ignorecase'` and
`h 'smartcase'`.

### Key Mapping

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
autocmd VimEnter * g:AutoSuggestSetup({ cmd: { onspace: ['buffer'] }})
```

<details><summary><b>Show demo</b></summary>
<br>
[![asciicast](https://asciinema.org/a/XeuHijghtC9XmbNVu5EKzdmeH.svg)](https://asciinema.org/a/XeuHijghtC9XmbNVu5EKzdmeH)

</details>

### Performance

Care is taken to ensure that responsiveness does not deteriorate when
searching large files or expanding wildcards. Large files are searched in
batches. Between each search attempt input keystrokes are allowed to be queued
into Vim's main loop. Wildcard expansions are first executed in a separate job
and aborted after a timeout.

## Contributing

Pull requests are welcome.

## Similar Plugins

- [cmp-cmdline](https://github.com/hrsh7th/cmp-cmdline)
- [wilder.nvim](https://github.com/gelguy/wilder.nvim)
- [sherlock](https://github.com/vim-scripts/sherlock.vim)
