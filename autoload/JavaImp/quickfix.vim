function! JavaImp#quickfix#AutoImport() abort
    if (JavaImp#CheckEnvironment() != 0)
        return
    endif
    " FIXME... we should figure out if there are no errors and
    " quit gracefully, rather than let vim do its error thing and
    " figure out where to stop
    crewind
    cn
    cn
    copen
    let l:nextStr = getline('.')
    echo l:nextStr
    let l:currentStr = ''

    crewind
    " we use the cn command to advance down the quickfix list until
    " we've hit the last error
    while match(l:nextStr,'|[0-9]\+ col [0-9]\+|') > -1
        " jump to the quickfix error window
        cnext
        copen
        let l:currentLine = line('.')
        let l:currentStr=getline(l:currentLine)
        let l:nextStr=getline(l:currentLine + 1)

        if (match(l:currentStr, 'cannot resolve symbol$') > -1 ||
                    \ match(l:currentStr, 'Class .* not found.$') > -1 ||
                    \ match(l:currentStr, 'Undefined variable or class name: ') > -1)

            " get the filename (we don't use this for the sort,
            " but later on when we want to sort a file's after
            " imports after inserting all the ones we know of
            let l:nextFilename = substitute(l:nextStr,  '|.*$','','g')
            let l:oldFilename = substitute(l:currentStr,'|.*$','','g')

            " jump to where the error occurred, and fix it
            cc
            call JavaImp#imports#Insert(0)

            " since we're still in the buffer, if the next line looks
            " like a different file (or maybe the end-of-errors), sort
            " this file's import statements
            if l:nextFilename != l:oldFilename
                call JavaImp#sorting#SortImports()
            endif
        endif
    endwhile
endfunction

