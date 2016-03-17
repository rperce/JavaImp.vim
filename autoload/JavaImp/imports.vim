" Inserts the import statement of the class specified under the cursor in the
" current .java file.
"
" If there is a duplicated entry for the classname, it won't insert it.
"
" If the entry already exists (specified in an import statement in the current
" file), this will do nothing.
"
" pass 0 for verboseMode if you want fewer updates of what this function is
"  doing, or 1 for normal verbosity
" (silence is interesting if you're scripting the use of JavaImpInsert...
"  for example, i have a script that runs JavaImpInsert on all the
"  class not found errors)
function! JavaImp#imports#Insert(verboseMode) abort
    if (JavaImp#CheckEnvironment() != 0)
        return
    endif

    let l:verbosity = 'silent'
    if a:verboseMode
        let l:verbosity = ''
    end

    " choose the current word for the class
    let l:className = expand('<cword>')
    let l:fullClassName = s:currFullName(l:className)

    if (l:fullClassName !=# '')
        if l:verbosity !=# 'silent'
            echo 'Import for ' . l:className . ' found in this file.'
        endif
    else
        let l:fullClassName = JavaImp#imports#FindFullName(l:className)
        if (l:fullClassName ==# '')
            if !a:verboseMode
                echo l:className . ' not found (either run :JIG or correct a typo)'
            else
                echo 'Can not find any class that matches ' . l:className . '.'
                let l:input = confirm('Do you want to update the class map file?', '&Yes\n&No', 2)
                if (l:input == 1)
                    call JavaImp#generate#BuildCache()
                    return
                endif
            endif
        else
            let l:importLine = 'import ' . l:fullClassName . ';'
            " Split before we jump
            split

            let l:hasImport = JavaImp#imports#LastImportLine()
            let l:importLoc = line('.')

            let l:hasPackage = JavaImp#imports#GotoPackage()
            if (l:hasPackage == 1)
                let l:pkgLoc = line('.')
                let l:pattern= '\v^\s*package\s+((\w\+\.)*\w+)\s*;.*$'
                let l:pkg = substitute(getline(l:pkgLoc), l:pattern, '\1', '')

                " Check to see if the class is in this package, we won't
                " need an import.
                if (l:fullClassName == (l:pkg . '.' . l:className))
                    let l:importLoc = -1
                else
                    if (l:hasImport == 0)
                        " Add an extra blank line after the package before
                        " the import
                        exec l:verbosity 'call append(l:pkgLoc, "")'
                        let l:importLoc = l:pkgLoc + 1
                    endif
                endif
            elseif (l:hasImport == 0)
                let l:importLoc = 0
            endif

            exec l:verbosity 'call append(l:importLoc, l:importLine)'

            if a:verboseMode
                if (l:importLoc >= 0)
                    echo 'Inserted ' . l:fullClassName . ' for ' . l:className
                else
                    echo 'Import unneeded (same package): ' . l:fullClassName
                endif
            endif

            " go back to the old location
            close

        endif
    endif
endfunction

" Given a classname, try to search the current file for the import statement.
" If found, it'll return the fully qualify classname.  Otherwise, it'll return
" an empty string.
function! s:currFullName(className) abort
    let l:pattern = '^\s*import\s\s*.*[.]' . a:className . '\s*;'
    " Split and jump
    split
    " First search for the className in an import statement
    " vint: -ProhibitCommandRelyOnUser
    normal G$
    " vint: +ProhibitCommandRelyOnUser
    if (search(l:pattern, 'w') != 0)
        " We are on that import line now, try fetching the full className:
        let l:imp = substitute(getline('.'), '^\s*import\s\s*\(.*[.]' . a:className . '\)\s*;', '\1', '')
        " close the window
        close
        return l:imp
    else
        close
        return ''
    endif
endfunction

" Given a classname, try to search the current file for the import statement.
" If found, it'll return the fully qualify classname.  If not found, it'll try
" to search the import list for the match.
function! JavaImp#imports#FindFullName(className) abort
    let l:fcn = s:currFullName(a:className)
    if (l:fcn !=# '')
        return l:fcn
    endif
    " We didn't find a preexisting import... that means
    " there is work to do

    " notice that we switch to the JavaImpClassList buffer
    " (or load the file if needed)
    let l:icl = expand(g:JavaImpClassList)
    if (filereadable(l:icl))
        silent exe 'split ' . l:icl
    else
        echo 'Can not load the class map file ' . l:icl . '.'
        return ''
    endif
    let l:importLine = ''
    " vint: -ProhibitCommandRelyOnUser
    normal G$
    " vint: +ProhibitCommandRelyOnUser

    let l:flags = 'w'
    let l:firstImport = 0
    let l:importCtr = 0
    let l:pattern = '^' . a:className . ' '
    let l:firstFullPackage = ''
    while (search(l:pattern, l:flags) > 0)
        let l:importCtr = l:importCtr + 1
        let l:fullPackage = substitute(getline('.'), '\S* \(.*\)$', '\1', '')
        let l:importLine = l:importLine . l:fullPackage . "\n"
        let l:flags = 'W'
    endwhile
    " Loading back the old file
    close
    if (l:importCtr == 0)
        return ''
    else
        return JavaImp#choose#ChooseImport(l:importCtr, a:className, l:importLine)
    endif
endfunction

" Go to the last import statement that it can find.  Returns 1 if an import is
" found, returns 0 if not.
function! JavaImp#imports#LastImportLine() abort
    return <SID>JavaImpGotoFirstMatchingImport('', 'b')
endfunction

function! Java#imports#GotoPackage() abort
    " First search for the className in an import statement
    " vint: -ProhibitCommandRelyOnUser
    normal G$
    " vint: +ProhibitCommandRelyOnUser
    let l:flags = 'w'
    let l:pattern = '^\s*package\s\s*.*;'
    if (search(l:pattern, l:flags) == 0)
        return 0
    else
        return 1
    endif
endfunction

