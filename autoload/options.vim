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
    },
    cmd: {
	enable: true,
	delay: 10,      # delay before showing popup
	pum: true,      # 'false' for flat menu, 'true' for stacked menu
    }
}

if options.search.range < 10
    options.search.range = 10
endif

if options.search.fuzzy
    options.search.async = false
endif
