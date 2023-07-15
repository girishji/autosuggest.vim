" CmdLine completion plugin for Vim >= v9.0

if !has('vim9script') || v:version < 900
  " Needs Vim version 9.0 and above
  finish
endif

vim9script

g:loaded_live_cmdline = true

import autoload '../autoload/options.vim' as opt
import autoload '../autoload/search.vim' as ser
import autoload '../autoload/cmd.vim'

ser.Setup()
cmd.Setup()

def! g:LiveCmdlineSetup(opts: dict<any>)
    var update = (key) => {
	if opts->has_key(key)
	    opt.options[key]->extend(opts[key])
	endif
    }
    update('search')
    update('cmd')
enddef

def LiveCmdlineEnable(flag: bool)
    opt.options.search.enable = flag
    opt.options.cmd.enable = flag
enddef
command! LiveCmdlineEnable  CmdCompleteEnable(true)
command! LiveCmdlineDisable CmdCompleteEnable(false)

highlight default link SearchCompletePrefix    Special
