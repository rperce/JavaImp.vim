" -------------------------------------------------------------------
" Sorting
" -------------------------------------------------------------------

" Sort the import statements in the current file.
function! JavaImp#sorting#SortImports() abort
    let l:pluginHome = expand('<sfile>:p:h')
    echom l:pluginHome
    execute 'pyfile ' . l:pluginHome . '/pythonx/jis.py'
endfunction

" Place Sorted Static Imports either before or after the normal imports
" depending on g:JavaImpStaticImportsFirst.
function! s:placeSortedStaticImports() abort
    " Find the Range of Static Imports
    if (s:findFirstStaticImport() > 0)
        let l:firstStaticImp = line('.')
        call s:findLastStaticImport()
        let l:lastStaticImp = line('.')

        " Remove the block of Static Imports.
        exec l:firstStaticImp . ',' . l:lastStaticImp . 'delete'

        " Place the cursor before the Normal Imports.
        if g:JavaImpStaticImportsFirst == 1
            " Find the Line which should contain the first import.
            if (JavaImp#imports#GotoPackage() == 0)
                normal! ggP
            else
                normal! jp
            endif


        " Otherwise, place the cursor after the Normal Imports.
        else
            " Paste in the Static Imports after the last import or at the top
            " of the file if no other imports.
            if (JavaImp#imports#LastImportLine() <= 0)
                if (JavaImp#imports#GotoPackage() == 0)
                    normal! ggP
                else
                    normal! jp
                endif
            else
                normal! p
            endif
        endif

    endif
endfunction

" -------------------------------------------------------------------
" Inserting spaces between packages
" -------------------------------------------------------------------

" Given a sorted range, we would like to add a new line (do a 'O')
" to seperate sections of packages.  The depth argument controls
" what we treat as a seperate section.
"
" Consider the following:
" -----
"  import java.util.TreeSet;
"  import java.util.Vector;
"  import org.apache.log4j.Logger;
"  import org.apache.log4j.spi.LoggerFactory;
"  import org.exolab.castor.xml.Marshaller;
" -----
"
" With a depth of 1, this becomes
" -----
"  import java.util.TreeSet;
"  import java.util.Vector;

"  import org.apache.log4j.Logger;
"  import org.apache.log4j.spi.LoggerFactory;
"  import org.exolab.castor.xml.Marshaller;
" -----

" With a depth of 2, it becomes
" ----
"  import java.util.TreeSet;
"  import java.util.Vector;
"
"  import org.apache.log4j.Logger;
"  import org.apache.log4j.spi.LoggerFactory;
"
"  import org.exolab.castor.xml.Marshaller;
" ----
" The recommended depth setting is 0
function! s:javaImpAddPkgSep(fromLine, toLine, depth) abort
    if (a:depth <= 0)
      return
    endif

    let l:cline = a:fromLine
    let l:endline = a:toLine
    let l:lastPkg = s:javaImpGetSubPkg(getline(l:cline), a:depth)

    let l:cline = l:cline + 1
    while (l:cline <= l:endline)
        let l:thisPkg = s:javaImpGetSubPkg(getline(l:cline), a:depth)

        " If last package does not equals to this package, append a line
        if (l:lastPkg != l:thisPkg)
            call append(l:cline - 1, '')
            let l:endline = l:endline + 1
            let l:cline = l:cline + 1
        endif
        let l:lastPkg = l:thisPkg
        let l:cline = l:cline + 1
    endwhile
endfunction

" Go to the last static import statement that it can find.  Returns 1 if an
" import is found, returns 0 if not.
function! s:findLastStaticImport() abort
    return s:gotoFirstMatchingImport('static\s\s*', 'b')
endfunction
"
" Go to the first static import statement that it can find.  Returns 1 if an
" import is found, returns 0 if not.
function! s:findFirstStaticImport() abort
    return s:gotoFirstMatchingImport('static\s\s*', 'w')
endfunction

function! s:gotoFirstMatchingImport(pattern, flags) abort
    " vint: -ProhibitCommandRelyOnUser
    normal G$
    " vint: +ProhibitCommandRelyOnUser
    let l:pattern = '^\s*import\s\s*'
    if (a:pattern !=# '')
        let l:pattern = l:pattern . a:pattern
    endif
    let l:pattern = l:pattern . '.*;'
    return (search(l:pattern, a:flags) > 0)
endfunction

" Returns the (sub) package name of an import " statement.
"
" Consider the string "import foo.bar.Frobnicability;"
"
" If depth is 1, this returns "foo"
" If depth is 2, this returns "foo.bar"
" If depth >= 3, this returns "foo.bar.Frobnicability"
function! s:javaImpGetSubPkg(importStr,depth) abort
    " set up the match/grep command
    let l:subpkgStr = '[^.]\{-}\.'
    let l:pkgMatch = '\s*import\s*.*\.[^.]*;$'
    let l:pkgGrep = '\s*import\s*\('
    let l:curDepth = a:depth
    " we tack on a:depth extra subpackage to the end of the match
    " and grep expressions
    while (l:curDepth > 0)
      let l:pkgGrep = l:pkgGrep . l:subpkgStr
      let l:curDepth = l:curDepth - 1
    endwhile
    let l:pkgGrep = l:pkgGrep . '\)'.'.*;$'
    " echo pkgGrep

    if (match(a:importStr, l:pkgMatch) == -1)
        let l:lastPkg = ''
    else
        let l:lastPkg = substitute(a:importStr, l:pkgGrep, '\1', '')
    endif

    return l:lastPkg
endfunction
