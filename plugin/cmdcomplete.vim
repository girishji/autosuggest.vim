" CmdLine completion plugin for Vim >= v9.0

if !has('vim9script') || v:version < 900
  " Needs Vim version 9.0 and above
  finish
endif

vim9script

g:loaded_cmdcomplete = true

import autoload '../autoload/options.vim' as opt
import autoload '../autoload/search.vim' as ser
import autoload '../autoload/cmd.vim'

ser.Setup()
cmd.Setup()

def! g:CmdCompleteSetup(opts: dict<any>)
    var update = (key) => {
	if opts->has_key(key)
	    opt.options[key]->extend(opts[key])
	endif
    }
    update('search')
    update('cmdline')
enddef

def CmdCompleteEnable(flag: bool)
    opt.options.search.enable = flag
    opt.options.cmdline.enable = flag
enddef
command! CmdCompleteEnable  CmdCompleteEnable(true)
command! CmdCompleteDisable CmdCompleteEnable(false)

# highlight default link CmdCompleteMenu	    Pmenu
# highlight default link CmdCompleteSelect    PmenuSel
highlight default link SearchCompletePrefix    Special
# highlight default link CmdCompleteSbar	    PmenuSbar
# highlight default link CmdCompleteThumb	    PmenuThumb
