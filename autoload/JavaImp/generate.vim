function! JavaImp#generate#BuildCache() abort
    if (JavaImp#CheckEnvironment() != 0)
        return
    endif
    " We would like to save the current buffer first:
    if expand('%') !=# ''
        update
    endif
    cclose
    if (bufexists(g:JavaImpClassList))
        silent exe 'bwipeout! ' . g:JavaImpClassList
    endif
    "Recursivly go through the directory and write to the temporary file.
    let l:impfile = tempname()
    " Save the current buffer number
    let l:currBuff = bufnr('%')
    silent exe 'split ' . l:impfile
    let l:currPaths = g:JavaImpPaths
    " See if currPaths has a separator at the end, if not, we add it.
    if (match(l:currPaths, g:JavaImpPathSep . '$') == -1)
        let l:currPaths = l:currPaths . g:JavaImpPathSep
    endif

    while (l:currPaths !=# '' && l:currPaths !~ '^ *' . g:JavaImpPathSep . '$')
        " Cut off the first path from the delimited list of paths to examine.
        let l:sepIndex = stridx(l:currPaths, g:JavaImpPathSep)
        let l:currPath = strpart(l:currPaths, 0, l:sepIndex)
        let l:currPaths = strpart(l:currPaths, l:sepIndex + 1, strlen(l:currPaths) - l:sepIndex - 1)

        echo 'Searching in path: ' . l:currPath
        call s:buildCacheFromPath(l:currPath)
    endwhile

    let l:classCount = line('$')

    1,$call s:formatLineForDict()

    " Sorting the file
    %sort u

    silent exe 'write! ' . g:JavaImpClassList
    silent exe 'bwipeout! ' . l:impfile
    call delete(l:impfile)
    echo 'Done.  Found ' . l:classCount . ' classes'
endfunction

" The helper function to append a class entry in the class list
function! s:buildCacheFromPath(cpath, relativeTo) abort
    echo 'Loading file/directory ' . a:cpath
    if strlen(a:cpath) < 1
        echo 'Alert! Bug in JavaApppendClass (JavaImp.vim)'
        echo '(beats me... hack the source and figure it out)'
        " Base case... infinite loop protection
        return 0
    elseif (!isdirectory(a:cpath) && match(a:cpath, '\(\.class$\|\.java$\)') > -1)
        " oh good, we see a single entry like org/apache/xerces/bubba.java
        " just slap it on our tmp buffer
        call append(0, a:relativeTo)
    elseif (isdirectory(a:cpath))
        " Recursively fetch all Java files from the provided directory path.
        let l:list = glob(a:cpath . '/*', 1, 1)
        for l:filename in l:list
            if isdirectory(l:filename) || match(l:filename, '\v(\.class|.java|.jar)$') > -1
                call s:buildCacheFromPath(l:filename, a:relativeTo)
            endif
        endfor

    elseif (match(a:cpath, '\(\.jar$\)') > -1)
        " Check if the jar file exists, if not, we return immediately.
        if (!filereadable(a:cpath))
            echo 'Skipping ' . a:cpath . '. File does not exist.'
            return 0
        endif
        " If we get a jar file, we first tries to match the timestamp of the
        " cache defined in g:JavaImpJarCache directory.  If the jar is newer,
        " then we would execute the jar command.  Otherwise, we just slap the
        " cached file to the buffer.
        "
        " The cached entries are organized in terms of the relativeTo path
        " with the '/' characters replaced with '_'.  For example, if you have
        " your jar in the directory /blah/lib/foo.jar, you'll have a cached
        " file called _blah_lib_foo.jmplst in your cache directory.

        let l:jarcache = expand(g:JavaImpJarCache)
        let l:jarcmd = 'jar -tf "'.a:cpath . '"'
        if (l:jarcache !=# '')
            let l:cachefile = substitute(a:cpath, '[ :\\/]',  '_', 'g')
            let l:cachefile = substitute(l:cachefile, 'jar$',  'jmplst', '')
            let l:jarcache = JavaImp#Path(l:jarcache, l:cachefile)
            " Note that if l:jarcache does not exist, it'll return -1
            if (getftime(l:jarcache) < getftime(a:cpath))
                " jar file is newer
                " if we get a jar, just slap the jar -tf contents to the cache
                echo '  - Updating jar: ' . fnamemodify(a:cpath, ':t') . "\n"
                let l:jarcmd = '!' . l:jarcmd . ' > "' . escape(l:jarcache, '\\') . '"'
                silent execute l:jarcmd
                if (v:shell_error != 0)
                    echo '  - Error running the jar command: ' . l:jarcmd
                endif
            else
                "echo "  - jar (cached): " . fnamemodify(a:cpath, ":t") . "\n"
            endif
            " Slap the cached content to the buffer
            silent execute 'read ' . l:jarcache
        else
            echo '  - Updating jar: ' . fnamemodify(a:cpath, ':t') . "\n"
            " Always slap the output for the jar command to the file if cache
            " is turned off.
            silent execute 'read !'.l:jarcmd
        endif
    endif
endfunction

" Converts the current line in the buffer from a java|class file pathname
"  into a space delimited class package
" For example:
"  /javax/swing/JPanel.java
"  becomes:
"  JPanel javax.swing.Jpanel
" If the current line does not appear to contain a java|class file,
" we blank it out (this is useful for non-bytecode entries in the
" jar files, like gif files or META-INF)
function! s:formatLineForDict() abort
    let l:currentLine = getline('.')

    " -- get the package name
    let l:subdirectory = fnamemodify(l:currentLine, ':h')
    let l:packageName = substitute(l:subdirectory, '/', '.', 'g')

    " -- get the class name
    " this match string extracts the classname from a class path name
    " in other words, if you hand /javax/swing/JPanel.java, it would
    " return in JPanel (as regexp var \1)
    let l:classExtensions = '\(\.class\|\.java\)'
    let l:matchClassName = match(l:currentLine, '[\\/]\([\$A-Za-z_]*\)' . l:classExtensions . '$')
    if l:matchClassName > -1
        let l:matchClassName = l:matchClassName + 1
        let l:className = strpart(l:currentLine, l:matchClassName)
        let l:className = substitute(l:className,  l:classExtensions, '', '')

        " Inner classes are separated by a dollar sign from their containing class.
        " Anonymous inner class names are numbers. For example, Stream.Builder is
        " java.util.stream.Stream$Builder, but if there were any anonymous inner classes
        " used in that declaration they would appear as java.util.stream.Stream$1, etc.
        " You cannot import an anonymous inner class as such, so we skip those lines by
        " not including [0-9] in the l:matchClassName regex above.

        let l:className = substitute(l:className, '\$', '.', 'g')
        call setline('.', l:className . ' ' . l:packageName . '.' . l:className)
    else
        " if we didn't find something which looks like a class, we
        " blank out this line (sorting will pick this up later)
        call setline('.', '')
    endif
endfunction

