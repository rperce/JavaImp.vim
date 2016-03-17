function! JavaImp#javadoc#ViewJavaDoc() abort
    if (!exists('g:JavaImpDocPaths'))
        echo 'Error: g:JavaImpDocPaths not set.  Please see the documentation for details.'
        return
    endif

    " choose the current word for the class
    let l:className = expand('<cword>')
    let l:fullClassName = JavaImp#imports#FindFullName(l:className)
    if (l:fullClassName ==# '')
        return
    endif

    let l:currPaths = g:JavaImpDocPaths
    " See if currPaths has a separator at the end, if not, we add it.
    if (match(l:currPaths, g:JavaImpPathSep . '$') == -1)
        let l:currPaths = l:currPaths . g:JavaImpPathSep
    endif
    while (l:currPaths !=# '' && l:currPaths !~# '^ *' . g:JavaImpPathSep . '$')
        let l:sepIdx = stridx(l:currPaths, g:JavaImpPathSep)
        " Gets the substring exluding the newline
        let l:currPath = strpart(l:currPaths, 0, l:sepIdx)
        "echo "Searching in path: " . currPath
        let l:currPaths = strpart(l:currPaths, l:sepIdx + 1, strlen(l:currPaths) - l:sepIdx - 1)
        let l:docFile = JavaImp#GetFile(l:currPath, l:fullClassName, '.html')
        if (filereadable(l:docFile))
            call JavaImp#javadoc#ViewJavaDoc(l:docFile)
            return
        endif
    endwhile
    echo 'JavaDoc not found in g:JavaImpDocPaths for class ' . l:fullClassName
    return
endfunction

function! JavaImp#javadoc#ViewJavaDoc(file) abort
    let l:cmd = '!' . g:JavaImpDocViewer . ' "' . a:file . '"'
    silent execute l:cmd
    redraw!
endfunction
