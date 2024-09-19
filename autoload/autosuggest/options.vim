vim9script

export var options: dict<any> = {
    search: {
        enable: true,
        maxheight: 12,	# line count of stacked menu
        pum: true,	# 'false' for flat menu, 'true' for stacked menu (for / and ?)
        range: 100,	# line count per search attemp
        timeout: 100,	# millisec to search, when non-async is specified
        async: true,	# async search
        fuzzy: false,   # fuzzy completion
        hidestatusline: false, # hide statusline temporarily when pum=false
        removestatusline: false, # remove statusline temporarily when pum=false
        alwayson: true, # when 'false' press <tab> to open popup menu
    },
    cmd: {
        enable: true,
        delay: 10,      # delay in ms before showing popup
        pum: true,      # 'false' for flat menu, 'true' for stacked menu
        fuzzy: false,   # fuzzy completion
        hidestatusline: false, # hide statusline temporarily when pum=false
        removestatusline: false, # remove statusline temporarily when pum=false
        exclude: [],    # keywords excluded from completion (use \c for ignorecase)
        autoexclude: ["'>", '^\a/', '^\A'], # keywords automatically excluded from completion
        onspace: [],    # show menu for keyword+space (ex. :find , :buffer , etc.)
        timeout: 500,   # max time in ms to search when '**' is specified in path
        editcmdworkaround: false,  # make :edit respect wildignore (without using file_in_path in getcompletion() which is slow)
        alwayson: true, # when 'false' press <tab> to open popup menu
    }
}

# XXX: hidestatusline (saving statusline) interferes with Quickfix list traversal (:cnext)

if options.search.range < 10
    options.search.range = 10
endif

if options.search.fuzzy
    options.search.async = false
endif

var slsave = {
    saved: false,
    laststatus: 1,
    statusline: '',
    showmode: false,
    ruler: false,
}

export def SaveStatusLine(opt: dict<any>)
    if !opt.pum && (opt.hidestatusline || opt.removestatusline)
        slsave.saved = true
        slsave.statusline = &statusline
        slsave.laststatus = &laststatus
        slsave.showmode = &showmode
        slsave.ruler = &ruler
        :set noshowmode noruler
        if opt.removestatusline
            :set laststatus=0
        else
            :set statusline=%<
        endif
    endif
enddef

export def RestoreStatusLine(opt: dict<any>)
    if slsave.saved
        slsave.saved = false
        if slsave.showmode
            :set showmode
        endif
        if slsave.ruler
            :set ruler
        endif
        if opt.removestatusline
            exec $'set laststatus={slsave.laststatus}'
        else
            exec $'set statusline={slsave.statusline}'
        endif
    endif
enddef

# vim: tabstop=8 shiftwidth=4 softtabstop=4
