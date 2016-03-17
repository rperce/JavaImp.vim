command! -nargs=? JIX              call JavaImp#quickfix#AutoImport()
command! -nargs=? JI               call JavaImp#imports#Insert(1)
command! -nargs=? JavaImp          call JavaImp#imports#Insert(1)
command! -nargs=? JavaImpSilent    call JavaImp#imports#Insert(0)

command! -nargs=? JIG              call JavaImp#generate#BuildCache()
command! -nargs=? JavaImpGenerate  call JavaImp#generate#BuildCache()

command! -nargs=? JIS              call JavaImp#sorting#SortImports()
command! -nargs=? JavaImpSort      call JavaImp#sorting#SortImports()

command! -nargs=? JID              call JavaImp#javadoc#ViewJavaDoc()
command! -nargs=? JavaImpDoc       call JavaImp#javadoc#ViewJavaDoc()

command! -nargs=? JIF              call JavaImp#source#ViewSource(0)
command! -nargs=? JavaImpFile      call JavaImp#source#ViewSource(0)

command! -nargs=? JIFS             call JavaImp#source#ViewSource(0)
command! -nargs=? JavaImpFileSplit call JavaImp#source#ViewSource(0)

call JavaImp#Setup()

