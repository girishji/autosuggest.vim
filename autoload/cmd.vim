vim9script

import autoload './options.vim' as opt

var options = opt.options.cmd

var popup_winid: number

def CmdlineEnable()
    autocmd! CmdCompleteAutocmds CmdlineChanged : Complete()
enddef

def CmdlineDisable()
    autocmd! CmdCompleteAutocmds CmdlineChanged :
enddef

def PopupCreate()
    var attr = {
	cursorline: false, # Do not automatically select the first item
	pos: 'botleft',
	line: &lines - &cmdheight,
	col: 1,
	drag: false,
	border: [0, 0, 0, 0],
	filtermode: 'c',
	hidden: true,
	filter: (_, _) => {
	    popup_winid->popup_hide()
	    :redraw
	    CmdlineEnable()
	    return false
	},
	callback: (_, result) => {
	    if result == -1 # popup force closed due to <c-c>
		feedkeys("\<c-c>", 'n')
		CmdlineEnable()
	    endif
	},
    }
    if options.pum
	attr->extend({ minwidth: 14 }) 
    else
	attr->extend({ scrollbar: 0, padding: [0, 0, 0, 0], highlight: 'statusline' }) 
    endif
    popup_winid = popup_menu([], attr)
enddef

def PopupShow(position: number, completions: list<any>)
    if options.pum
	popup_winid->popup_move({ col: position })
	popup_winid->popup_settext(completions)
    else
	var hmenu = completions->join('  ')
	if hmenu->len() > winwidth(0)
	    hmenu = hmenu->slice(0, winwidth(0) - 2)
	    var spacechar = hmenu->match('.*\zs\s')
	    hmenu = (spacechar == -1 ? hmenu : hmenu->slice(0, spacechar)) .. ' >'
	endif
	hmenu->setbufline(popup_winid->winbufnr(), 1)
    endif
    popup_winid->popup_show()
    :redraw
    CmdlineDisable()
enddef

def Overlap(context: string, completion: string): list<number>
    var contextt = context->matchstr('\v.*/\ze[^/]*') # remove anything after last '/'
    var matchcol = contextt->stridx(completion[0])
    while matchcol != -1
	var matchlen = contextt->len() - matchcol
	if contextt->slice(matchcol) == completion->slice(0, matchlen)
	    return [matchcol, matchlen]
	endif
	matchcol = contextt->stridx(completion[0], matchcol + 1)
    endwhile
    return [-1, -1]
enddef

# Completion candidates for file are obtained as full path. Extract relevant
# portion of path for display.
# Retrun the column nr where popup menu should be displayed. Relevant only for
# stacked popup menu (not flat menu).
def ExtractShowable(context: string, completions: list<any>): number
    var compl = completions[0]
    if isdirectory(expand(compl)) || filereadable(expand(compl))
	if context =~ '\\ '
	    completions->map((_, v) => v->escape(' '))
	endif
	var [matchcol, matchlen] = Overlap(context, completions[0])
	if matchcol == -1
	    return max([1, context->stridx(' ') + 2])
	endif
	completions->map((_, val) => val->slice(matchlen))
	return matchcol + matchlen + 1
    endif
    if !options.pum || context !~ '\s'
	return 1
    endif
    var pos = max([context->strridx('$'), context->strridx('&'), context->strridx(' ')])
    return max([1, pos + 2])
enddef

# Verify that this completion does not take a long time (does not hang)
def Verify(context: string): bool
    if context !~ '\*\*'
	return true
    endif
    const Timeout = 500 # millisec
    var start = reltime()
    var cmd = ['vim', '-es', $'+:silent! call getcompletion("{context}", "cmdline") | q!']
    var vjob: job = job_start(cmd)
    while start->reltime()->reltimefloat() * 1000 < Timeout
	if vjob->job_status() == 'run'
	    :sleep 5m
	else 
	    break
	endif
    endwhile
    if vjob->job_status() ==? 'run'
	vjob->job_stop('kill')
	# echom 'Aborted job, taking too long: ' .. context
	return false
    endif
    return true
enddef

def DoComplete(oldcontext: string, timer: number)
    var context = getcmdline()->strpart(0, getcmdpos() - 1)
    if context !=# oldcontext
	# Likely pasted text or coming from keymap
	return
    endif
    var completions: list<any> = []
    if Verify(context)
	completions = context->getcompletion('cmdline')
    endif
    if completions->empty()
	return
    endif
    var pos = ExtractShowable(context, completions)
    if completions->len() == 1 && context->strridx(completions[0]) != -1
	# This completion is already inserted
	return
    endif
    PopupShow(pos, completions)
enddef

def Completable(context: string)
    var delay = max([10, options.delay])
    timer_start(delay, function(DoComplete, [context]))
enddef

var statusline: string
var showmode: bool
var ruler: bool

def Init()
    PopupCreate()
    CmdlineEnable()
    statusline = &statusline
    showmode = &showmode
    ruler = &ruler
    :set noshowmode noruler
    :set statusline=%<
enddef

def Teardown()
    ## fix for Vim bug #12634
    popup_winid->popup_move({ pos: 'center' })
    :redraw
    ##
    popup_winid->popup_close()
    if showmode
	:set showmode
    endif
    if ruler
	:set ruler
    endif
    exec $'set statusline={statusline}'
enddef

def Complete()
    if wildmenumode()
	return
    endif
    var context = getcmdline()->strpart(0, getcmdpos() - 1)
    if context == '' || context =~ '^\s\+$' || context[-1] =~ '\s'
	return
    endif
    Completable(context)
enddef

export def Setup()
    if options.enable
	:set wildchar=<Tab>
	:set wildmenu
	:set wildmode=full
	if options.pum
	    :set wildoptions+=pum
	else
	    :set wildoptions-=pum
	endif
	augroup CmdCompleteAutocmds | autocmd!
	    autocmd CmdlineEnter   : Init()
	    autocmd CmdlineChanged : Complete()
	    autocmd CmdlineLeave   : Teardown()
	augroup END
    endif
enddef