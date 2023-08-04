" CmdLine completion plugin for Vim >= v9.0

if !has('vim9script') || v:version < 900
  " Needs Vim version 9.0 and above
  finish
endif

vim9script

g:loaded_autosuggest = true

import autoload '../autoload/options.vim' as opt
import autoload '../autoload/search.vim' as ser
import autoload '../autoload/cmd.vim'

def Reset()
    ser.Teardown()
    ser.Setup()
    cmd.Teardown()
    cmd.Setup()
enddef

autocmd VimEnter * Reset()

def! g:AutoSuggestSetup(opts: dict<any>)
    var Update = (key) => {
	if opts->has_key(key)
	    opt.options[key]->extend(opts[key])
	endif
    }
    Update('search')
    Update('cmd')
    Reset()
enddef

def AutoSuggestEnable(flag: bool)
    opt.options.search.enable = flag
    opt.options.cmd.enable = flag
    Reset()
enddef
command! AutoSuggestEnable  AutoSuggestEnable(true)
command! AutoSuggestDisable AutoSuggestEnable(false)

highlight default link AS_SearchCompletePrefix    Special

# vim: tabstop=8 shiftwidth=4 softtabstop=4
