" -------------------------------------------------------------------
" Sorting
" -------------------------------------------------------------------

" Sort the import statements in the current file.
function! JavaImp#sorting#SortImports() abort
    execute 'pyfile ' . g:JavaImpPluginHome . '/pythonx/javaimportsort.py'
endfunction

