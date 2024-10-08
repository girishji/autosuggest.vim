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
        alwayson: true, # when 'false' press <tab> to open popup menu
        popupattrs: {}, # dictionary of attributes passed to popup window
    },
    cmd: {
        enable: true,
        delay: 10,      # delay in ms before showing popup
        pum: true,      # 'false' for flat menu, 'true' for stacked menu
        fuzzy: false,   # fuzzy completion
        exclude: [],    # keywords excluded from completion (use \c for ignorecase)
        autoexclude: ["'>", '^\a/', '^\A'], # keywords automatically excluded from completion
        onspace: [],    # show menu for keyword+space (ex. :find , :buffer , etc.)
        timeout: 500,   # max time in ms to search when '**' is specified in path
        editcmdworkaround: false,  # make :edit respect wildignore (without using file_in_path in getcompletion() which is slow)
        alwayson: true, # when 'false' press <tab> to open popup menu
    }
}

if options.search.range < 10
    options.search.range = 10
endif

if options.search.fuzzy
    options.search.async = false
endif

# vim: tabstop=8 shiftwidth=4 softtabstop=4
