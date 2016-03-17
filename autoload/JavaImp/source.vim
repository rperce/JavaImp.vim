" -------------------------------------------------------------------
" Java Source Viewing
" -------------------------------------------------------------------
function! JavaImp#source#ViewSource(doSplit) abort
    " We would like to save the current buffer first:
    if expand('%') !=# ''
        update
    endif

    " Class Name to search for is the Current Word.
    let l:className = expand('<cword>')

    " Find the fully qualified classname for this class.
    let l:fullClassName = JavaImp#imports#FindFullName(l:className)
    if (l:fullClassName ==# '')
        echo "Can't find class " . l:className
        return

    " Otherwise, search for the class.
    else
        let l:currPaths = g:JavaImpPaths

        " See if currPaths has a separator at the end, if not, we add it.
        if (match(l:currPaths, g:JavaImpPathSep . '$') == -1)
            let l:currPaths = l:currPaths . g:JavaImpPathSep
        endif

        while (l:currPaths !=# '' && l:currPaths !~# '^ *' . g:JavaImpPathSep . '$')
            " Find First Separator (this marks the end of the Next Path).
            let l:sepIdx = stridx(l:currPaths, g:JavaImpPathSep)

            " Retrieve the Next Path.
            let l:currPath = strpart(l:currPaths, 0, l:sepIdx)

            " Chop off the Next Path--this leaves only the remaining paths to
            " search.
            let l:currPaths = strpart(l:currPaths, l:sepIdx + 1, strlen(l:currPaths) - l:sepIdx - 1)

            if (isdirectory(l:currPath))
                let l:f = JavaImp#GetFile(l:currPath, l:fullClassName, '.java')
                if (l:f !=# '')
                    if (a:doSplit == 1)
                        split
                    endif
                    exec 'edit ' . l:f
                    return
                endif
            endif
        endwhile
        echo 'Can not find ' . l:fullClassName . ' in g:JavaImpPaths'
    endif
endfunction

