vim9script

import autoload './options.vim' as opt

var options = opt.options.search

# Encapsulate the state and operations of search menu completion.
def NewPopup(isfwd: bool): dict<any>
    var popup = {
        winid: -1,             #  id of popup window
        keywords: [],          #  keywords shown in popup menu
        candidates: [],        #  candidates for completion (could be phrases)
        index: 0,              #  index to keywords and candidates array
        context: '',           #  cached cmdline contents
        isfwd: isfwd,          #  true for '/' and false for '?'
        starttime: [],         #  timestamp at which search started
        firstmatch: [],        #  workaround for vim issue 12538
        cursorpos: [],         #  cached cursor position when command is first invoked
    }
    popup->extend({
        completeWord: function(CompleteWord, [popup]),
        selectItem: function(SelectItem, [popup]),
        updateMenu: function(UpdateMenu, [popup]),
        bufMatches: function(BufMatches, [popup]),
        bufFuzzyMatches: function(BufFuzzyMatches, [popup]),
        showPopupMenu: function(ShowPopupMenu, [popup]),
    })
    # XXX:
    # Issue #1: Due to vim issue 12538 highlighting has to be provoked explicitly during
    # async search. The redraw command causes some flickering of highlighted
    # text. So do async search only when file is large.
    # Issue #2: Currently there is a unfixable problem during highlighting
    # where searching does not remove previous highlights until <cr> is typed.
    # Cannot remove highlighting manually either since clearmatches() does
    # nothing and getmatches() returns an empty list (when there is
    # highlighting visible on the screen). This is another Vim bug. Async
    # 'works' except for this annoyance. Enable async only on large buffers.
    if options.async
        popup->extend({async: (line('$') < 1500 ? false : true)})
        options.timeout = 2000
    else
        popup->extend({async: false})
    endif
    return popup
enddef

var completor = {}

var bgPopupWinId: number

def Init()
    completor = getcmdtype() == '/' ? NewPopup(true) : NewPopup(false)
    EnableCmdline()
    if &incsearch
        completor.cursorpos = [line('.'), col('.')] # Cache the cursor position
    endif
    if !options.pum
        bgPopupWinId = popup_create(' ', {line: &lines - &cmdheight, col: 1, minwidth: winwidth(0)})
    endif
enddef

def Clear()
    ## Problem seems to have gone away in new release.
    ## To fix Vim bug #12634
    # completor.winid->popup_move({ pos: 'center' })
    # :redraw
    ##
    completor.winid->popup_close()
    completor = {}
    if !options.pum
        bgPopupWinId->popup_close()
    endif
enddef

def Complete()
    completor.completeWord()
enddef

def TabComplete()
    var lastcharpos = getcmdpos() - 2
    if getcmdline()[lastcharpos] ==? "\<tab>"
        setcmdline(getcmdline()->slice(0, lastcharpos))
        completor.completeWord()
    endif
enddef

export def Setup()
    if options.enable
        augroup SearchCompleteAutocmds | autocmd!
            autocmd CmdlineEnter    /,\?  Init()
            autocmd CmdlineChanged  /,\?  options.alwayson ? Complete() : TabComplete()
            autocmd CmdlineLeave    /,\?  Clear()
        augroup END
    endif
enddef

export def Teardown()
    augroup SearchCompleteAutocmds | autocmd!
    augroup END
enddef

def EnableCmdline()
    autocmd! SearchCompleteAutocmds CmdlineChanged /,\? options.alwayson ? Complete() : TabComplete()
enddef

def DisableCmdline()
    autocmd! SearchCompleteAutocmds CmdlineChanged /,\?
enddef

# Return a list containing range of lines to search in each worker iteration.
def SearchIntervals(fwd: bool, range: number): list<any>
    var intervals = []
    var firstsearch = true
    var stopline = 0
    #  Note: startl <- start line, startc <- start column, etc.
    while firstsearch || stopline != (fwd ? line('$') : 1)
        var startline = firstsearch ? line('.') : stopline
        stopline = fwd ? min([startline + range, line('$')]) : max([startline - range, 1])
        intervals->add({startl: startline + (firstsearch ? 0 : fwd ? -5 : 5),
            startc: firstsearch ? col('.') : 1, stopl: stopline})
        firstsearch = false
    endwhile
    firstsearch = true
    while firstsearch || stopline != line('.')
        var startline = firstsearch ? fwd ? 1 : line('$') : stopline
        stopline = fwd ? min([startline + range, line('.')]) : max([startline - range, line('.')])
        intervals->add({startl: startline + (firstsearch ? 0 : fwd ? -5 : 5), startc: 1, stopl: stopline})
        firstsearch = false
    endwhile
    return intervals
enddef


# Return a list of strings (can have spaces and newlines) that match the pattern
def BufMatches(popup: dict<any>, interval: dict<any>): list<any>
    var p = popup
    var flags = p.async ? (p.isfwd ? '' : 'b') : (p.isfwd ? 'w' : 'wb')
    if p.async && &incsearch && p.firstmatch == [] # find first match to highlight (vim issue 12538)
        try
            var [lnum, cnum] = p.context->searchpos(flags, interval.stopl)
            if [lnum, cnum] != [0, 0]
                p.firstmatch = [lnum, cnum, p.context->len()]
            endif
        catch # E33 is thrown when ~ is the first character of search
            return []
        endtry
    endif
    # XXX: \k includes '~'. it causes E33 and E383 after <cr> if '~' is in a menu item. use \w instead.
    # var pattern = p.context =~ '\s' ? $'{p.context}\k*' : $'\k*{p.context}\k*'
    var pattern = p.context =~ '\s' ? $'{p.context}\w*' : $'\w*{p.context}\w*'
    var [lnum, cnum] = [0, 0]
    var [startl, startc] = [0, 0]
    try
        if p.async
            [lnum, cnum] = pattern->searchpos(flags, interval.stopl)
        else
            [lnum, cnum] = pattern->searchpos(flags, 0, options.timeout)
            [startl, startc] = [lnum, cnum]
        endif
    catch # '*' with magic can throw E871
        # echom v:exception
        return []
    endtry

    var matches = []
    var found = {}
    for item in p.candidates
        found[item] = 1
    endfor
    var starttime = p.starttime
    var timeout = options.timeout
    while [lnum, cnum] != [0, 0] && matches->len() < 50
        var [endl, endc] = pattern->searchpos('ceW') # end of matching string
        var lines = getline(lnum, endl)
        var mstr = '' # fragment that matches pattern (can be multiline)
        if lines->len() == 1
            mstr = lines[0]->strpart(cnum - 1, endc - cnum + 1)
        else
            var mlist = [lines[0]->strpart(cnum - 1)] + lines[1 : -2] + [lines[-1]->strpart(0, endc)]
            mstr = mlist->join('\n')
        endif
        if !found->has_key(mstr)
            found[mstr] = 1
            matches->add(mstr)
        endif
        cursor(lnum, cnum) # restore cursor to beginning of pattern, otherwise '?' does not work
        [lnum, cnum] = p.async ? pattern->searchpos(flags, interval.stopl) :
            pattern->searchpos(flags, 0, timeout)

        if !p.async && ([startl, startc] == [lnum, cnum] ||
                (starttime->reltime()->reltimefloat() * 1000) > timeout)
            break
        endif
    endwhile
    return matches
enddef

# Return a list of strings that fuzzy match the pattern
def BufFuzzyMatches(popup: dict<any>): list<any>
    var p = popup
    var found = {}
    var words = []
    var starttime = reltime()
    var timeout = options.timeout
    var batches = []
    const MaxLines = 5000 # on M1 it takes 100ms to process 9k lines
    if line('$') > MaxLines
        var lineend = min([line('.') + MaxLines, line('$')])
        batches->add({start: line('.'), end: lineend})
        var linestart = max([line('.') - MaxLines, 0])
        var remaining = line('.') + MaxLines - line('$')
        if linestart != 0 && remaining > 0
            linestart = max([linestart - remaining, 0])
        endif
        batches->add({start: linestart, end: line('.')})
    else
        batches->add({start: 1, end: line('$')})
    endif
    for batch in batches
        var linenr = batch.start 
        for line in getline(batch.start, batch.end)
            for word in line->split('\W\+')
                if !found->has_key(word) && word->len() > 1
                    found[word] = 1
                    words->add(word)
                endif
            endfor
            # Check every 200 lines if timeout is exceeded
            if timeout > 0 && linenr % 200 == 0 &&
                    starttime->reltime()->reltimefloat() * 1000 > timeout
                break
            endif
            linenr += 1
        endfor
    endfor
    return words->matchfuzzy(p.context, { matchseq: 1, limit: 100 }) # max 100 matches
enddef

# Menu width for flat menu is obtained as needed since user can resize window.
def HMenuWidth(): number
    return winwidth(0) - 4
enddef

def MatchedPattern(popup: dict<any>): string
    var p = popup
    return options.fuzzy ? $'\c[{p.context->split("\zs")}]' : (&ignorecase ? $'\c{p.context}' : p.context)
enddef

# Display popup menu.
def ShowPopupMenu(popup: dict<any>)
    var p = popup
    if options.pum
        var lastword = p.context->matchstr('\s*\S\+$')
        p.winid->popup_move({col: p.context->strridx(lastword) + 2})
        p.winid->popup_settext(p.keywords)
        win_execute(p.winid, "normal! gg")
    else
        var hmenu = p.keywords->join('  ')
        if hmenu->len() > HMenuWidth()
            var lastSpaceChar = match(hmenu[0 : HMenuWidth() - 4], '.*\zs\s')
            hmenu = hmenu->slice(0, lastSpaceChar == -1 ? 0 : lastSpaceChar) .. ' >'
        endif
        hmenu->setbufline(p.winid->winbufnr(), 1)
    endif
    p.index = -1
    p.winid->popup_setoptions({cursorline: false})
    clearmatches(p.winid)
    selMatchId = 0
    matchadd('AutoSuggestSearchMatch', MatchedPattern(p), 10, -1, {window: p.winid})
    p.winid->popup_show()
    if !&incsearch # redraw only when noincsearch, otherwise highlight flickers
        :redraw
    endif
    DisableCmdline()
enddef

# A worker task for async search.
def SearchWorker(popup: dict<any>, attr: dict<any>, timer: number)
    var p = popup
    var timediff = p.starttime->reltime(attr.starttime)->reltimefloat()
    var context = getcmdline()->strpart(0, getcmdpos() - 1)
    if context !=# p.context || timediff < 0 || attr.index >= attr.intervals->len()
        return
    endif

    var cursorpos = [line('.'), col('.')]
    var interval = attr.intervals[attr.index]
    cursor(interval.startl, interval.startc)
    var matches = p.bufMatches(interval)
    cursor(cursorpos)

    # Add matched fragments to list of candidates and segregate
    var candidates = timediff > 0 ? matches : p.candidates + matches
    p.candidates = candidates->copy()->filter((_, v) => v =~# $'^{p.context}') +
        candidates->copy()->filter((_, v) => v !~# $'^{p.context}')
    p.keywords = p.candidates->copy()->map((_, val) => val->matchstr('\s*\zs\S\+$'))

    if len(p.keywords) > 0
        p.showPopupMenu()
        # Workaround for vim bug 12538: Explicitly call matchadd and matchaddpos
        # https://github.com/vim/vim/issues/12538
        if p.async && &hlsearch
            matchadd('Search', &ignorecase ? $'\c{p.context}' : p.context, 11)
            :redraw
        endif
        if p.async && &incsearch && !p.firstmatch->empty()
            matchaddpos('IncSearch', [p.firstmatch], 12)
            :redraw
        endif
    endif

    attr.index += 1
    timer_start(0, function(SearchWorker, [popup, attr]))
enddef

# Populate popup menu and display it.
def UpdateMenu(popup: dict<any>, key: string)
    var p = popup
    if !p.cursorpos->empty()
        cursor(p.cursorpos)
    endif
    p.firstmatch = []
    var context = getcmdline()->strpart(0, getcmdpos() - 1) .. key
    # https://github.com/girishji/autosuggest.vim/issues/2: `\` causes errors in searchpos()
    if context == '' || context =~ '^\s\+$' || context =~ '\'
        return
    endif
    p.context = context->escape('~\')
    p.starttime = reltime()
    p.candidates = []
    p.keywords = []
    if p.async
        var attr = {
            starttime: p.starttime,
            intervals: p.isfwd->SearchIntervals(options.range),
            index: 0,
        }
        p->SearchWorker(attr, 0)
    else
        var cursorpos = [line('.'), col('.')]
        var matches = options.fuzzy ? p.bufFuzzyMatches() : p.bufMatches({})
        cursor(cursorpos)  # restore cursor position changed by BufMatches() (searchpos())
        p.candidates = matches->copy()->filter((_, v) => v =~# $'^{p.context}') +
            matches->copy()->filter((_, v) => v !~# $'^{p.context}')
        p.keywords = p.candidates->mapnew((_, val) => val->matchstr('\s*\zs\S\+$'))
        if len(p.keywords) > 0
            p.showPopupMenu()
        endif
    endif
enddef

var selMatchId: number = 0

# Select next/prev item in popup menu; wrap around at end of list.
def SelectItem(popup: dict<any>, direction: string)
    var p = popup
    var count = p.keywords->len()

    def MatchPosSel(lnum: number, offset: number = 0): list<any>
        var mpat = MatchedPattern(p)
        var sline = p.keywords[p.index]
        var pos = []
        var startidx = 0
        while true
            var m = matchstrpos(sline, mpat, startidx)
            if m == ["", -1, -1]
                break
            endif
            pos->add([lnum, m[1] + 1 + offset, m[2] - m[1]])
            startidx = m[2] + 1
        endwhile
        return pos
    enddef

    def SelectVert()
        if p.winid->popup_getoptions().cursorline
            p.winid->popup_filter_menu(direction)
            p.index += (direction ==# 'j' ? 1 : -1)
            p.index %= count
        else
            p.winid->popup_setoptions({cursorline: true})
            p.index = 0
        endif
    enddef

    def SelectHoriz(): string
        var hmenu = ''
        var rotate = false
        if p.index == -1
            p.index = direction ==# 'j' ? 0 : count - 1
            rotate = true
        else
            if p.index == (direction ==# 'j' ? count - 1 : 0)
                p.index = (direction ==# 'j' ? 0 : count - 1)
                rotate = true
            else
                p.index += (direction ==# 'j' ? 1 : -1)
            endif
        endif
        var hmenustr = getbufline(p.winid->winbufnr(), 1)[0]
        var kwordpat = $'\<{p.keywords[p.index]}\>'
        if hmenustr !~# kwordpat
            def HMenuStr(kwidx: number, position: string): string
                var selected = [p.keywords[kwidx]]
                var atleft = position ==# 'left'
                var overflowl = kwidx > 0
                var overflowr = kwidx < p.keywords->len() - 1
                var idx = kwidx
                while (atleft && idx < p.keywords->len() - 1) ||
                        (!atleft && idx > 0)
                    idx += (atleft ? 1 : -1)
                    var last = (atleft ? idx == p.keywords->len() - 1 : idx == 0)
                    if selected->join('  ')->len() + p.keywords[idx]->len() + 1 <
                            HMenuWidth() - (last ? 0 : 4)
                        if atleft
                            selected->add(p.keywords[idx])
                        else
                            selected->insert(p.keywords[idx])
                        endif
                    else
                        idx -= (atleft ? 1 : -1)
                        break
                    endif
                endwhile
                if atleft
                    overflowr = idx < p.keywords->len() - 1
                else
                    overflowl = idx > 0
                endif
                return (overflowl ? '< ' : '') .. selected->join('  ') .. (overflowr ? ' >' : '')
            enddef
            if direction ==# 'j'
                hmenu = rotate ? HMenuStr(0, 'left') : HMenuStr(p.index, 'right')
            else
                hmenu = rotate ? HMenuStr(p.keywords->len() - 1, 'right') : HMenuStr(p.index, 'left')
            endif
            hmenu->setbufline(p.winid->winbufnr(), 1)
        else
            hmenu = hmenustr
        endif
        clearmatches(p.winid)
        selMatchId = 0
        matchadd('AutoSuggestSearchMatch', MatchedPattern(p), 10, -1, {window: p.winid})
        if hlexists('PopupSelected')
            matchadd('PopupSelected', kwordpat, 11, -1, {window: p.winid})
        else
            matchadd('PmenuSel', kwordpat, 11, -1, {window: p.winid})
        endif
        return hmenu
    enddef

    var menustr = null_string
    if options.pum
        SelectVert()
    else
        menustr = SelectHoriz()
    endif
    if p.index >= 0 && p.index < p.keywords->len()
        if selMatchId > 0
            matchdelete(selMatchId, p.winid)
            selMatchId = 0
        endif
        var lnum = options.pum ? getcurpos(p.winid)[1] : 1
        var offset = 0
        if !options.pum && menustr != null_string
            offset = menustr->match($'\v\C<{p.keywords[p.index]}>')
        endif
        var pos = MatchPosSel(lnum, offset)
        if !pos->empty()
            selMatchId = matchaddpos('AutoSuggestSearchMatchSel', pos, 12, -1, {window: p.winid})
        endif
    endif
    clearmatches()
    setcmdline(p.candidates[p.index])
    if &hlsearch
        matchadd('Search', &ignorecase ? $'\c{p.context}' : p.context, 11)
    endif
    :redraw  # needed for <tab> selected menu item highlighting to work
enddef


# Filter function receives keys when popup is shown. It handles special
# keys for scrolling/dismissing popup menu. Other keys are fed back to Vim's
# main loop (through feedkeys).
def Filter(winid: number, key: string): bool
    var p = completor
    # Note: do not include arrow keys since they are used for history lookup
    if key ==? "\<tab>" || key ==? "\<c-n>"
        p.selectItem('j') # next item
    elseif key ==? "\<s-tab>" || key ==? "\<c-p>"
        p.selectItem('k') # prev item
    elseif key ==? "\<c-e>"
        clearmatches()
        p.winid->popup_hide()
        setcmdline('')
        feedkeys(p.context, 'n')
        :redraw!
        timer_start(0, (_) => EnableCmdline()) # timer will que this after feedkeys
    elseif key ==? "\<cr>" || key ==? "\<esc>"
        EnableCmdline()
        return false
    else
        clearmatches()
        p.winid->popup_hide()
        p.updateMenu(key)
        EnableCmdline()
        return false # Let vim's usual mechanism (ex. search highlighting) handle this
    endif
    return true
enddef

# Create a popup if necessary. When popup is not hidden the filter function
# consumes the keys. When popup is not yet created or if it is hidden
# input keys come through autocommand (tied to CmdlineChanged).
def CompleteWord(popup: dict<any>)
    var p = popup
    if p.winid->popup_getoptions() == {} # popup does not exist, create it
        var attr = {
            cursorline: false, # Do not automatically select the first item
            pos: 'botleft',
            line: &lines - &cmdheight,
            col: 1,
            drag: false,
            border: [0, 0, 0, 0],
            filtermode: 'c',
            filter: Filter,
            hidden: true,
            maxheight: options.maxheight,
            callback: (winid, result) => {
                clearmatches()
                if result == -1 # popup force closed due to <c-c> or cursor mvmt
                    EnableCmdline()
                    feedkeys("\<c-c>", 'n')
                endif
            },
        }
        if options.pum
            attr->extend({ minwidth: 14 })
        else
            attr->extend({ scrollbar: 0, padding: [0, 0, 0, 0] })
        endif
        p.winid = popup_menu([], attr->extend(options.popupattrs))
    endif

    p.updateMenu('')
enddef

# vim: tabstop=8 shiftwidth=4 softtabstop=4
