JavaImp.vim
-----------
Short and sweet:  JavaImp generates and sorts your import statements so that
you don't have to. It is also able to display JavaDoc HTML in a web browser of
your choice.

Features
--------
- Import Statement Management:
  - Semi-automatic insertion.
  - Sorting.
  - Styling/Organizing.
- Quick source lookup referenced classes.
- JavaDoc Display.

Requirements
------------
- Vim 7+ (with Python support) or Neovim 0.1.0+.
- `jar` must be in your `$PATH`.
- A web browser, either graphical (Chromium, Firefox, etc.) or console (w3m, lynx, etc.)
  if you want to view JavaDocs.

Installation
------------
You can use any standard vim package manager
([vim-plug](https://github.com/junegunn/vim-plug),
[Vundle](https://github.com/VundleVim/Vundle.vim),
[Pathogen](https://github.com/tpope/vim-pathogen), etc.) in the
usual way. I like vim-plug.

You need to set two global variables in your `.vimrc` or `init.vim` (neovim) in order for
this to work:

1. Paths to java classes to be loaded. For example,

        let g:JavaImpPaths =
           \ $HOME . "/project/src/java," .
           \ $HOME . "/project2/javasrc," .
           \ $HOME . "/project3/javasrc"

   Each entry can be a directory or any one of a `.java`, `.class`, or `.jar` file. If the
   entry is a directory, it will be recursed into and each sub-directory or appropriate
   file loaded as well. `.java` and `.class` files are loaded directly; `.jar` files have
   their contained classes listed with `jar ft <jarname>` and all such classes are added
   to the list of known paths. Note the terminal `','` character.

   If `','` is not convenient for you, set `g:JavaImpPathSep` to the single-character
   separator you would like to use, e.g.

        let g:JavaImpPathSep = ':'

2. Path to JavaImp's storage. The default is:

        let g:JavaImpDataDir = $HOME . "/.vim/JavaImp"

   (unless `has('nvim')` is true, in which case it's)

        let g:JavaImpDataDir = $HOME . "/.config/nvim/JavaImp"

   The `cache` subdirectory will contained cached `.jar` contents; the `JavaImp.txt` file
   in that directory contains a full dictionary list of every class `JavaImp` knows about.

Commands
========
Generate a cache of classes for import:

    :JavaImpGenerate or :JIG

If you have not created the directory for g:JavaImpDataDir yet, this will
create the appropriate paths. JIG will go through your JavaImpPaths and search
for anything that ends with .java, .class, or .jar. It'll then write the
mappings to the JavaImp.txt and/or the cache files.

Once your class-cache is ready, while your cursor is in or after a class name,

    :JavaImp or :JavaImpSilent or :JI

inserts the relevant import after the last import statement in the file.
If necessary, you'll be prompted with duplicate class names and insert what you have
selected. If the class is already imported, it'll do nothing.

You can also sort the import statements in the file by doing:

    :JavaImpSort or :JIS

Source Viewing
--------------

JavaImp will try to find the source file of the class under your cursor by:

    :JavaImpFile or :JIF

Doing a :JavaImpFileSplit or :JIFS will open a split window on the file.

JavaDoc Viewing
---------------
If you want to use the JavaDoc viewing feature for JavaImp, you need to set
`g:JavaImpDocPaths`. Similar to how you set the `g:JavaImpPaths`,
g:JavaImpDocPaths contains a list of root level directories that contains your
java docs.

    let g:JavaImpDocPaths =
       \ "/usr/java/docs/api," .
       \ "/project/docs/api"

The default pager is set to:

    let g:JavaImpDocViewer = "w3m"

On Windows, you can put, e.g., `iexplore.exe` or `chrome.exe` in your path and set
`g:JavaImpDocViewer` to that browser.

Once your paths are set correctly, with your cursor on a classname, execute

    :JavaImpDoc or :JID

Import Statement Order
----------------------
JavaImp will order your import statements into groups:
* Static Imports (if configured to come first)
* Top Imports
* Middle Imports
* Bottom Imports
* Static Imports (if configured to come last)

Static import statements may come first or last. The default is to place them
above the regular imports. You can override this by setting:

    let g:JavaImpStaticImportsFirst = 0

Top import statements come next. These are non-static imports that match a prioritized
list of regular expressions. JavaImp uses similar setting to Eclipse by default:

    let g:JavaImpTopImports = [
        \ 'java\..*',
        \ 'javax\..*',
        \ 'org\..*',
        \ 'com\..*'
        \ ]

Middle imports are those import statements which are not static and match neither the top
nor bottom regexp lists.

Bottom imports appear below the middle imports, unsurprisingly. These imports, like those
at the top, match a list of regexps. However, by default, this list is empty:

    let g:JavaImpBottomImports = []

If you wish, you may insert a blank line between package groups whose roots differ by a
specified amount via `g:JavaImpSortPkgSep`. For example, if `g:JavaImpSortPkgSep = 2`,

    import java.util.List;
    import org.apache.tools.zip.ZipEntry;
    import javax.mail.search.MessageNumberTerm;
    import java.util.Vector;
    import javax.mail.Message;
    import org.apache.tools.ant.types.ZipFileSet;
    import java.math.BigInteger;

will become:

    import java.math.BigInteger;

    import java.util.List;
    import java.util.Vector;

    import javax.mail.Message;
    import javax.mail.search.MessageNumberTerm;

    import org.apache.tools.ant.types.ZipFileSet;
    import org.apache.tools.zip.ZipEntry;

Note that adjacent imports have identical roots to two levels. The default depth is `0`,
i.e., no extra spacing.

Extras
------
After you have generated the `JavaImp.txt` file by using `:JIG`, you can use it as
your dictionary for autocompletion. For example, you can put the following in
your `ftplugin/java.vim`:

    exec "setlocal dict=" . g:JavaImpDataDir . "/JavaImp.txt"
    setlocal complete-=k " ensure only one 'k' entry ("autocomplete from dict")
    setlocal complete+=k

After you have done so, you can open a `.java` file and use your completion-cycling binds
(`<C-P>` and `<C-N>` by default) to autocomplete your Java class names.

To be able to insert import statements for classes as you type, add the following to your
`vimrc` or `ftplugin/java.com`:

    inoremap <C-I> <ESC>:JavaImpSilent<Enter>a

By default `<C-I>` acts identically to pressing the `<Tab>` key, which is less that
useful. It's much nicer for *i*mports.

Importing your JDK Classes
--------------------------
Simply include `$JAVA_HOME/jre/lib/rt.jar` in your `g:JavaImpPaths`.

History
-------
This script is descended from [Vim Script #325](http://www.vim.org/scripts/script.php?script_id=325) originally written by
William Lee by way of [rustushki's fork](https://github.com/rustushki/JavaImp.vim). It's
pretty nifty, but had a couple of important bugs -- e.g., repeated `:JIS` would slowly
delete your entire file. I'm fixin' stuff.

Credits
--------
William Lee &lt;wl1012@yahoo.com&gt;
(c) 2002-2004. All Rights Reserved

Russ Adams (rustushki)

Robert Perce (rperce)

Thanks
------
William Lee for an excellent and most useful Vim plugin.

rustushki for making progress
