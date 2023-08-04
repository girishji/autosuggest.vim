vim9script

export var options: dict<any> = {
    search: {
	enable: true,
	maxheight: 12,	# line count of stacked menu
	pum: true,	# 'false' for flat menu, 'true' for stacked menu (for / and ?)
	range: 1000,	# line count per search attemp
	timeout: 100,	# millisec to search, when non-async is specified
	async: true,	# async search
	fuzzy: false,   # fuzzy completion
	hidestatusline: false, # hide statusline (so it is not visible underneath when pum=false)
	alwayson: true, # when 'false' press <tab> to open popup menu
    },
    cmd: {
	enable: true,
	delay: 10,      # delay before showing popup
	pum: true,      # 'false' for flat menu, 'true' for stacked menu
	fuzzy: false,   # fuzzy completion
	hidestatusline: false, # hide statusline (so it is not visible underneath when pum=false)
    }
}

if options.search.range < 10
    options.search.range = 10
endif

if options.search.fuzzy
    options.search.async = false
endif

var slsave = {
    saved: false,
    statusline: '',
    showmode: false,
    ruler: false,
}

export def SaveStatusLine()
    slsave.saved = true
    slsave.statusline = &statusline
    slsave.showmode = &showmode
    slsave.ruler = &ruler
    :set noshowmode noruler
    :set statusline=%<
enddef

export def RestoreStatusLine()
    if slsave.saved
	slsave.saved = false
	if slsave.showmode
	    :set showmode
	endif
	if slsave.ruler
	    :set ruler
	endif
	exec $'set statusline={slsave.statusline}'
    endif
enddef

# vim: tabstop=8 shiftwidth=4 softtabstop=4
