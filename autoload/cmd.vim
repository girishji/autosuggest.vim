vim9script

# Autocomplete Vimscript commands, functions, variables, etc.

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

# Retrun the column nr where popup menu should be displayed. Relevant only for
# stacked popup menu (not flat menu).
# Completion candidates for file are obtained as full path. Extract relevant
# portion of path for display.
def ExtractShowable(context: string, completions: list<any>): number
    var fpath: string = ''
    try
        # <spath> throws error E1245
        fpath = expand(completions[0])
    catch /^Vim\%((\a\+)\)\=:E/	 # catch all Vim errors
    endtry
    if !fpath->empty() && (isdirectory(fpath) || filereadable(fpath))
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

def ShowFiles(timer: number)
    if wildmenumode()
        for _ in range(pum_getpos().size)
            feedkeys("\<tab>", 'tn')
        endfor
    endif
enddef

# Verify that this completion does not take a long time (does not hang)
def Verify(context: string): bool
    if context !~ '\*\*'
        return true
    elseif options.editcmdworkaround && context =~ '\v^(e|ed|edi|edit) '
        # getcompletion('edit **', 'cmdline') does not respect wildignore just
        # like 'file' instead of 'cmdline'. However 'file_in_path' respects
        # wildignore but takes too long (5x longer compared to <tab>
        # completion which also respects wildignore).
        feedkeys("\<tab>", 'tn')
        timer_start(1, function(ShowFiles))
        return false
    else
        var start = reltime()
        var cmd = ['vim', '-es', $'+:silent! call getcompletion("{context}", "cmdline") | q!']
        var vjob: job = job_start(cmd)
        while start->reltime()->reltimefloat() * 1000 < options.timeout
            if vjob->job_status() ==? 'run'
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
    endif
enddef

def DoComplete(oldcontext: string, timer: number)
    var context = getcmdline()->strpart(0, getcmdpos() - 1)
    if context !=# oldcontext
        # Likely pasted text or coming from keymap
        return
    endif
    for pat in (options.exclude + options.autoexclude)
        if context =~ pat
            return
        endif
    endfor
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

def Init()
    PopupCreate()
    CmdlineEnable()
    if !options.pum && options.hidestatusline
        opt.SaveStatusLine()
    endif
enddef

def Clear()
    ## fix for Vim bug #12634
    popup_winid->popup_move({ pos: 'center' })
    :redraw
    ##
    popup_winid->popup_close()
    opt.RestoreStatusLine()
enddef

def Complete()
    if wildmenumode()
        return
    endif
    var context = getcmdline()->strpart(0, getcmdpos() - 1)
    if context == '' || context =~ '^\s\+$' ||
            (options.onspace->index(context->trim()) == -1 && context[-1] =~ '\s')
        return
    endif
    var delay = max([10, options.delay])
    timer_start(delay, function(DoComplete, [context]))
enddef

var wildsave = {
    saved: false,
    wildmode: '',
    wildoptions: '',
}

export def Setup()
    if options.enable
        if !wildsave.saved
            wildsave.saved = true
            wildsave.wildmode = &wildmode
            wildsave.wildoptions = &wildoptions
        endif
        :set wildchar=<Tab>
        :set wildmenu
        :set wildmode=full
        if  options.fuzzy
            :set wildoptions+=fuzzy
        else
            :set wildoptions-=fuzzy
        endif
        if options.pum
            :set wildoptions+=pum
        else
            :set wildoptions-=pum
        endif
        augroup CmdCompleteAutocmds | autocmd!
            autocmd CmdlineEnter   : Init()
            autocmd CmdlineChanged : Complete()
            autocmd CmdlineLeave   : Clear()
        augroup END
    endif
enddef

export def Teardown()
    if wildsave.saved
        exec $'set wildmode={wildsave.wildmode}'
        exec $'set wildoptions={wildsave.wildoptions}'
        wildsave.saved = false
    endif
    augroup CmdCompleteAutocmds | autocmd!
    augroup END
enddef

# vim: tabstop=8 shiftwidth=4 softtabstop=4
