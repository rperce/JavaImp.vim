JavaImp.vim
-----------
Short and sweet:  JavaImp generates and sorts your import statements so that
you don't have to.  It is also able to display JavaDoc HTML in a web browser of
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
- The 'jar' binary must be your path.
- A web browser such as Chrome or Firefox or a pager such as w3m or lynx.

Installation
------------
You can use any standard vim package manager (vim-plug, Vundle, Pathogen, etc.) in the
usual way

You need to set two global variables in your .vimrc in order for this to work:

1. Paths to Java Project Source files.

        let g:JavaImpPaths =
           \ $HOME . "/project/src/java," .
           \ $HOME . "/project2/javasrc," .
           \ $HOME . "/project3/javasrc"

   The g:JavaImpPaths is a comma separated list of paths that point to the
   roots of the 'com' or 'org' etc.  You can list your Java projects, external
   projects or even Java's source classes.  It is recommended that you do this
   so that you can take full advantage of automatic import statement
   generation.

   If ',' is not convenient for you, set g:JavaImpPathSep to the
   (single-character) separator you would like to use:

        let g:JavaImpPathSep = ':'

2. Path to JavaImp's temporary storage.  The default is:

        let g:JavaImpDataDir = $HOME . "/vim/JavaImp"

Commands
========
Generate a cache of classes for import:

    :JavaImpGenerate or :JIG

If you have not created the directory for g:JavaImpDataDir yet, this will
create the appropriate paths.  JIG will go through your JavaImpPaths and search
for anything that ends with .java, .class, or .jar.  It'll then write the
mappings to the JavaImp.txt and/or the cache files.

After you've generated your JavaImp.txt file, move your cursor to a class name
in a Java file and do a:

    :JavaImp or :JavaImpSilent or :JI

And the magic happens!  You'll realize that you have an extra import statement
inserted after the last import statement in the file.  It'll also prompts you
with duplicate class names and insert what you have selected.  If the class
name is already imported, it'll do nothing.

You can also sort the import statements in the file by doing:

    :JavaImpSort or :JIS

Source Viewing
--------------

JavaImp will try to find the source file of the class under your cursor by:

    :JavaImpFile or :JIF

Doing a :JavaImpFileSplit or :JIFS will open a split window on the file.

JavaDoc Viewing
---------------
If you want to use the JavaDoc viewing feature for JavaImp, you should set
g:JavaImpDocPaths.  Similar to how you set the g:JavaImpPaths,
g:JavaImpDocPaths contains a list of root level directories that contains your
java docs.  This, together with a HTML pager (like w3m or lynx on Unix), let
you view the JavaDocs very quickly by just hitting :JID on a class name.  For
example, you can set:

    let g:JavaImpDocPaths = "/usr/java/docs/api," .
       \ "/project/docs/api"

The default pager is set to:

    let g:JavaImpDocViewer = "w3m"

On windows, you can put iexplore.exe or mozilla.exe in your path and set the
g:JavaImpDocViewer to "iexplore.exe" or "mozilla.exe".

Once your paths are set correctly, with your cursor on a classname execute

    :JavaImpDoc or :JID

JavaImp will open the viewer to the class based on the import list that you've generated
by `:JIG`.

Import Statement Order
----------------------
JavaImp will order your import statements into groups:
* Statics Imports (if configured to come first)
* Top Imports
* Middle Imports
* Bottom Imports
* Statics Imports (if configured to come last)

Static import statements may come first or last.  The default is to place them
above the regular imports.  You can override this by setting:

    let g:JavaImpStaticImportsFirst = 0

Top import statements come next.  These are normal import statements which
match a prioritized list of regular expressions.  JavaImp uses similar setting
to Eclipse Mars by default:

    let g:JavaImpTopImports = [
        \ 'java\..*',
        \ 'javax\..*',
        \ 'org\..*',
        \ 'com\..*'
        \ ]

Next come the Middle Imports Statements.  These are any import statements which
are not static and do not match the top nor bottom import statement regular
expressions.

Bottom Import Statements appear below the Middle Import Statements.  These
statements will match a configured list of regular expressions.  By default,
this list is empty:

    let g:JavaImpBottomImports = []

JavaImp has the option to insert a blank line between package groups whose roots differ by
a specified amount via `g:JavaImpSortPkgSep`. For example, if `g:JavaImpSortPkgSep = 2`,

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

Note that adjacent imports have identical roots to two levels. The default depth is `0`.

Extras
------
After you have generated the `JavaImp.txt` file by using `:JIG`, you can use it as
your dictionary for autocompletion.  For example, you can put the following in
your `java.vim` ftplugin (note here `g:JavaImpDataDir` is set before running this):

    exec "setlocal dict=" . g:JavaImpDataDir . "/JavaImp.txt"
    setlocal complete-=k
    setlocal complete+=k

After you have done so, you can open a `.java` file and use `^P` and `^N` to
autocomplete your Java class names.

Importing your JDK Classes
--------------------------
Simply include `$JAVA_HOME/lib` in your `g:JavaImpPaths`.

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
