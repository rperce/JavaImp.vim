" -------------------------------------------------------------------
" Choosing and caching imports
" -------------------------------------------------------------------

" Check with the choice cache and determine the final order of the import
" list.
" The choice cache is a file with the following format:
" [className1] [most recently used class] [2nd most recently used class] ...
" [className2] [most recently used class] [2nd most recently used class] ...
" ...
"
" imports and the return list consists of fully-qualified classes separated by
" \n.  This function will list the imports list in the order specified by the
" choice cache file
"
" IMPORTANT: if the choice is not available in the cache, this returns
" empty string, not the imports

" Choose the import if there's multiple of them.  Returns the selected import
" class.
function! JavaImp#choose#ChooseImport(imctr, className, imports) abort
    let l:imps = s:makeChoice(a:imctr, a:className, a:imports)
    let l:uncached = l:imps ==# ''
    if l:uncached
        let l:imps = a:imports
        let l:simps = a:imports
        if (a:imctr > 1)
            let l:imps = "[No previous choice.  Please pick one from below...]\n" . l:imps
        endif
    else
        let l:simps = l:imps
    endif

    let l:choice = 0
    if (a:imctr > 1)
      " if the item had not been cached, we force the user to make
      " a choice, rather than letting her choose the default
      let l:choice = s:displayChoices(l:imps, a:className)
      " if the choice is not cached, we don't want the user to
      " simply pick anything because he is hitting enter all the
      " time so we loop around he picks something which isn't the
      " default (earlier on, we set the default to some nonsense
      " string)
      while (l:uncached && l:choice == 0)
        let l:choice = s:displayChoices(l:imps, a:className)
      endwhile
    endif

    " If cached, since we inserted the banner, we need to subtract the choice
    " by one:
    if (l:uncached && l:choice > 0)
        let l:choice = l:choice - 1
    endif

    " We run through the string again to pick the choice from the list
    " First reset the counter
    let l:ctr = 0
    let l:imps = l:simps
    while (l:imps !=# '' && l:imps !~# '^ *\n$')
        let l:sepIdx = stridx(l:imps, "\n")
        let l:imp = strpart(l:imps, 0, l:sepIdx)
        if (l:ctr ==# l:choice)
            " We found it, we should update the choices
            "echo "save choice simps:" . simps . " imp: " . imp
            call s:saveChoice(a:className, l:simps, l:imp)
            return l:imp
        endif
        let l:ctr = l:ctr + 1
        let l:imps = strpart(l:imps, l:sepIdx + 1, strlen(l:imps) - l:sepIdx - 1)
    endwhile
    " should not get here...
    echo 'warning: should-not-get here reached in ChooseImport'
    return
endfunction

function! s:makeChoice(imctr, className, imports) abort
    let l:jicc = JavaImp#Path(expand(g:JavaImpDataDir), 'choices.txt')
    if !filereadable(l:jicc)
        return ''
    endif
    silent exe 'split ' . l:jicc
    let l:flags = 'w'
    let l:pattern = '^' . a:className . ' '
    if (search(l:pattern, l:flags) > 0)
        let l:line = substitute(getline('.'), '^\S* \(.*\)', '\1', '')
        close
        return s:orderChoice(a:imctr, l:line, a:imports)
    else
        close
        return ''
    endif
endfunction

" Order the imports with the cacheLine and returns the list.
function! s:orderChoice(imctr, cacheLine, imports) abort
    " we construct the imports so we can test for <space>classname<space>
    let l:il = ' ' . substitute(a:imports, "\n", ' ', 'g') . ' '
    let l:rtn = ' '
    " We first construct check each entry in the cacheLine to see if it's in
    " the imports list, if so, we add it to the final list.
    let l:cl = a:cacheLine . ' '
    while (l:cl !~# '^ *$')
        let l:sepIdx = stridx(l:cl, ' ')
        let l:cls = strpart(l:cl, 0, l:sepIdx)
        let l:pat = ' ' . l:cls . ' '
        if (match(l:il, l:pat) >= 0)
            let l:rtn = l:rtn . l:cls . ' '
        endif
        let l:cl = strpart(l:cl, l:sepIdx + 1)
    endwhile
    "echo "cache: " . rtn
    " at this point we need to add the remaining imports in the rtn list.
    " get rid of the beginning space
    let l:mil = strpart(l:il, 1)
    while (l:mil !~# '^ *$')
        let l:sepIdx = stridx(l:mil, ' ')
        let l:cls = strpart(l:mil, 0, l:sepIdx)
        let l:pat = ' ' . escape(l:cls, '.') . ' '
        " we add to the list if only it's not in there.
        if (match(l:rtn, l:pat) < 0)
            let l:rtn = l:rtn . l:cls . ' '
        endif
        let l:mil = strpart(l:mil, l:sepIdx + 1)
    endwhile
    " rid the head space
    let l:rtn = strpart(l:rtn, 1)
    let l:rtn = substitute(l:rtn, ' ', "\n", 'g')
    return l:rtn
endfunction

" Save the import to the cache file.
function! s:saveChoice(className, imports, selected) abort
    let l:im = substitute(a:imports, "\n", ' ', 'g')
    " Note that we remove the selected first
    let l:spat = a:selected . ' '
    let l:spat = escape(l:spat, '.')
    let l:im = substitute(l:im, l:spat, '', 'g')

    let l:jicc = JavaImp#Path(expand(g:JavaImpDataDir), 'choices.txt')
    silent exe 'split ' . l:jicc
    let l:flags = 'w'
    let l:pattern = '^' . a:className . ' '
    let l:sel = a:className . ' ' . a:selected . ' ' . l:im
    if (search(l:pattern, l:flags) > 0)
        " we found it, replace the line.
        call setline('.', l:sel)
    else
        " we couldn't found it, so we just add the choices
        call append(0, l:sel)
    endif

    silent update
    close
endfunction

function! s:displayChoices(imps, className) abort
    let l:imps = a:imps
    let l:simps = l:imps
    let l:ctr = 0
    let l:choice = 0
    let l:cfmstr = ''
    let l:questStr =  'Multiple matches for ' . a:className . ". Your choice?\n"
    while (l:imps !=# '' && l:imps !~# '^ *\n$')
        let l:sepIdx = stridx(l:imps, "\n")
        " Gets the substring exluding the newline
        let l:imp = strpart(l:imps, 0, l:sepIdx)
        let l:questStr = l:questStr . '(' . l:ctr . ') ' . l:imp . "\n"
        let l:cfmstr = l:cfmstr . '&' . l:ctr . "\n"
        let l:ctr = l:ctr + 1
        let l:imps = strpart(l:imps, l:sepIdx + 1, strlen(l:imps) - l:sepIdx - 1)
    endwhile

    if (l:ctr <= 10)
        " Note that we need to get rid of the ending "\n" for it'll give
        " an extra choice in the GUI
        let l:cfmstr = strpart(l:cfmstr, 0, strlen(l:cfmstr) - 1)
        let l:choice = confirm(l:questStr, l:cfmstr, 0)
        " Note that confirms goes from 1 to 10, so if the result is not 0,
        " we need to subtract one
        if (l:choice != 0)
            let l:choice = l:choice - 1
        endif
    else
        let l:choice = input(l:questStr)
    endif

    return l:choice
endfunction

