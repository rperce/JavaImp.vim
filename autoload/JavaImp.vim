function! s:os_var(opts) abort
    if has('unix') && has_key(a:opts, 'unix')
        return a:opts.unix
    elseif (has('win16') || has('win32') || has('win95') ||
            \has('dos16') || has('dos32') || has('os2')) && has_key(a:opts, 'win')
        return a:opts.win
    endif
    return a:opts.default
endfunction

let s:SL = s:os_var({'unix': '/', 'win': '\', 'default': '/'})
function! JavaImp#Path(...) abort
    let l:out = ''
    for l:arg in a:000
        let l:out = l:out . s:SL . l:arg
    endfor
    return l:out
endfunction


function! JavaImp#Setup() abort
    if !exists('g:JavaImpDataDir')
        if has('nvim')
            let g:JavaImpDataDir = JavaImp#path(expand('$HOME'), '.config', 'nvim', 'JavaImp')
        else
            let g:JavaImpDataDir = JavaImp#path(expand('$HOME'), 'vim', 'JavaImp')
        endif
    endif

    if !exists('g:JavaImpClassList')
        let g:JavaImpClassList = g:JavaImpDataDir . s:SL . 'JavaImp.txt'
    endif

    " Order import statements which match these regular expressions in the order
    " of the expression.  The default setting sorts import statements with java.*
    " first, then javax.*, then org.*, then com.*, and finally everything else
    " alphabetically after that.  These settings emulate Eclipse's settings.
    if !exists('g:JavaImpTopImports')
        let g:JavaImpTopImports = [
            \ 'java\..*',
            \ 'javax\..*',
            \ 'org\..*',
            \ 'com\..*'
            \ ]
    endif

    " Bottom Imports.
    " Place these import statements after the middle import statements, and before
    " static import statements (if they're configured to come last).
    if !exists('g:JavaImpBottomImports')
        let g:JavaImpBottomImports = []
    endif

    " Put the Static Imports First if 1, otherwise put the Static Imports last.
    " Defaults to 1.
    if !exists('g:JavaImpStaticImportsFirst')
        let g:JavaImpStaticImportsFirst = 1
    endif


    " Deprecated
    if !exists('g:JavaImpJarCache')
        let g:JavaImpJarCache = g:JavaImpDataDir . s:SL . 'cache'
    endif

    if !exists('g:JavaImpSortRemoveEmpty')
        let g:JavaImpSortRemoveEmpty = 1
    endif

    " Note if the SortPkgSep is set, then you need to remove the empty lines.
    if !exists('g:JavaImpSortPkgSep')
        let g:JavaImpSortPkgSep = 0
    endif

    if !exists('g:JavaImpPathSep')
        let g:JavaImpPathSep = ','
    endif

    if !exists('g:JavaImpDocViewer')
        let g:JavaImpDocViewer = 'w3m'
    endif
endfunction

" Check and make sure the directories are set up correctly.  Otherwise, create
" the dir or complain.
function! JavaImp#CheckEnvironment() abort
    " Check if the g:JavaImpPaths is set:
    if (!exists('g:JavaImpPaths'))
        echo 'You have not set the g:JavaImpPaths variable.  Pleae see documentation for details.'
        return 1
    endif
    let l:rc = s:confirmMakeDir(g:JavaImpDataDir)
    if (l:rc != 0)
        echo 'Error creating directory: ' . g:JavaImpDataDir
        return l:rc
    endif

    let l:rc = s:confirmMakeDir(g:JavaImpJarCache)
    if (l:rc != 0)
        echo 'Error creating directory: ' . g:JavaImpJarCache
        return l:rc
    endif
    return 0
endfunction

" Returns 0 if the directory is created successfully.  Returns non-zero
" otherwise.
function! s:confirmMakeDir(dir) abort
    if !isdirectory(a:dir)
        let l:input = confirm('Do you want to create the directory ' . a:dir . '?', '&Create\n&No', 1)
        if (l:input == 1)
            return s:mkdir(a:dir)
        else
            echo 'Operation aborted.'
            return 1
        endif
    endif
endfunction

function! s:mkdir(dir) abort
    let l:cmd = os_var({
        \ 'unix': 'mkdir -p "' . a:dir,
        \ 'win':  'mkdir "' . a:dir . '"',
        \ 'default': 'fail' })
    if l:cmd ==# 'fail'
        return 1
    endif

    call system(l:cmd)
    return v:shell_error
endfunction


" Returns the full path of the Java source file or JavaDoc.
"
" Set 'ext' to:
"  .html - for JavaDoc.
"  .java - for Java files.
"
" @param basePath - the base path to search for the class.
" @param fullClassName - fully qualified class name
" @param ext - extension to search for.
function! JavaImp#GetFile(basePath, fullClassName, ext) abort
    " Convert the '.' to '/'.
    let l:df = substitute(a:fullClassName, '\.', '/', 'g')

    " Construct the full path to the possible file.
    let l:h = l:df . a:ext
    let l:rtn = expand(a:basePath . '/' . l:h)

    " If the file is not readable, return an empty string.
    if filereadable(l:rtn) == 0
        let l:rtn = ''
    endif
    return l:rtn
endfunction

