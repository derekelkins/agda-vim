Version 0.12.0

A vim mode for interactively editing Agda code with the features of the emacs mode.

For a demonstration see:

[![agda-vim Introduction on YouTube](http://img.youtube.com/vi/i7Btts-duZw/0.jpg)](https://www.youtube.com/watch?v=i7Btts-duZw)

It incorporates the syntax and Unicode input files from <http://wiki.portal.chalmers.se/agda/pmwiki.php?n=Main.VIMEditing>
but extends them with support for interacting with the Agda process in the same manner as the emacs mode.  In addition,
it sets Agda as the make program to automatically generate and load the local vim highlighting files and to jump
to errors.  The make program is currently just `agda --vim`, i.e. it does not compile the program.

This requires syntax highlighting to be turned on and, for the interactivity, Python plugins to be supported.  This
interacts via the same interface emacs uses, though a lot of the logic is in the emacs mode.  This is not an officially
supported mode, so there's no guarantee it will work with different versions of Agda.  I've currently used it with
Agda 2.3.2.1 through 2.5.3.0.  I have not tested Literate Agda files at all and would be a bit surprised if they worked.

It should work as a Pathogen bundle and allegedly as a Vundle or NeoBundle and possibly others.  (I can vouch for Pathogen.)
With Pathogen (and presumably the others) you should be able to simply `git clone` this whole repository into `.vim/bundle/`.

It should also work by just copying the file structure into your `.vim` folder and adding the following line to
`.vim/filetypes.vim`:

    au BufNewFile,BufRead *.agda setf agda

You can add paths to the paths Agda searches by setting `g:agda_extraincpaths` as demonstrated by the command below
which could be added to your .vimrc.

    let g:agda_extraincpaths = ["/home/derek/haskell/agda-stdlib-0.8.1/src"]

Support for go-to definition can be disabled which may speed up loads by putting the following in your `.vimrc`:

    let g:agdavim_enable_goto_definition = 0

In the commands below, the `<LocalLeader>` is set by setting `maplocalleader` which needs to occur before the mappings
are made, e.g. in your `.vimrc`:

    let maplocalleader = ","

The commands and mappings as defined currently are below, as well as their Emacs counterparts:

    command! -buffer -nargs=0 AgdaLoad call AgdaLoad(v:false)
    command! -buffer -nargs=0 AgdaVersion call AgdaVersion(v:false)
    command! -buffer -nargs=0 AgdaReload silent! make!|redraw!
    command! -buffer -nargs=0 AgdaRestartAgda exec s:python_cmd 'AgdaRestart()'
    command! -buffer -nargs=0 AgdaShowImplicitArguments exec s:python_cmd "sendCommand('ShowImplicitArgs True')"
    command! -buffer -nargs=0 AgdaHideImplicitArguments exec s:python_cmd "sendCommand('ShowImplicitArgs False')"
    command! -buffer -nargs=0 AgdaToggleImplicitArguments exec s:python_cmd "sendCommand('ToggleImplicitArgs')"
    command! -buffer -nargs=0 AgdaConstraints exec s:python_cmd "sendCommand('Cmd_constraints')"
    command! -buffer -nargs=0 AgdaMetas exec s:python_cmd "sendCommand('Cmd_metas')"
    command! -buffer -nargs=0 AgdaSolveAll exec s:python_cmd "sendCommand('Cmd_solveAll')"
    command! -buffer -nargs=1 AgdaShowModule call AgdaShowModule(<args>)
    command! -buffer -nargs=1 AgdaWhyInScope call AgdaWhyInScope(<args>)
    command! -buffer -nargs=1 AgdaSetRewriteMode exec s:python_cmd "setRewriteMode('<args>')"
    command! -buffer -nargs=0 AgdaSetRewriteModeAsIs exec s:python_cmd "setRewriteMode('AsIs')"
    command! -buffer -nargs=0 AgdaSetRewriteModeNormalised exec s:python_cmd "setRewriteMode('Normalised')"
    command! -buffer -nargs=0 AgdaSetRewriteModeSimplified exec s:python_cmd "setRewriteMode('Simplified')"
    command! -buffer -nargs=0 AgdaSetRewriteModeHeadNormal exec s:python_cmd "setRewriteMode('HeadNormal')"
    command! -buffer -nargs=0 AgdaSetRewriteModeInstantiated exec s:python_cmd "setRewriteMode('Instantiated')"

    " C-c C-l -> \l
    nnoremap <buffer> <LocalLeader>l :AgdaReload<CR>

    " C-c C-d -> \t
    nnoremap <buffer> <LocalLeader>t :call AgdaInfer()<CR>

    " C-c C-r -> \r
    nnoremap <buffer> <LocalLeader>r :call AgdaRefine("False")<CR>
    nnoremap <buffer> <LocalLeader>R :call AgdaRefine("True")<CR>

    " C-c C-space -> \g
    nnoremap <buffer> <LocalLeader>g :call AgdaGive()<CR>

    " C-c C-g -> \c
    nnoremap <buffer> <LocalLeader>c :call AgdaMakeCase()<CR>

    " C-c C-a -> \a
    nnoremap <buffer> <LocalLeader>a :call AgdaAuto()<CR>

    " C-c C-, -> \e
    nnoremap <buffer> <LocalLeader>e :call AgdaContext()<CR>

    " C-u C-c C-n -> \n
    nnoremap <buffer> <LocalLeader>n :call AgdaNormalize("IgnoreAbstract")<CR>

    " C-c C-n -> \N
    nnoremap <buffer> <LocalLeader>N :call AgdaNormalize("DefaultCompute")<CR>
    nnoremap <buffer> <LocalLeader>M :call AgdaShowModule('')<CR>

    " C-c C-w -> \y
    nnoremap <buffer> <LocalLeader>y :call AgdaWhyInScope('')<CR>
    nnoremap <buffer> <LocalLeader>h :call AgdaHelperFunction()<CR>

    " M-. -> \d
    nnoremap <buffer> <LocalLeader>d :call AgdaGotoAnnotation()<CR>

    " C-c C-? -> \m
    nnoremap <buffer> <LocalLeader>m :AgdaMetas<CR>

    " Show/reload metas
    " C-c C-? -> C-e
    nnoremap <buffer> <C-e> :AgdaMetas<CR>
    inoremap <buffer> <C-e> <C-o>:AgdaMetas<CR>

    " Go to next/previous meta
    " C-c C-f -> C-g
    nnoremap <buffer> <silent> <C-g>  :let _s=@/<CR>/ {!\\| ?<CR>:let @/=_s<CR>2l
    inoremap <buffer> <silent> <C-g>  <C-o>:let _s=@/<CR><C-o>/ {!\\| ?<CR><C-o>:let @/=_s<CR><C-o>2l

    " C-c C-b -> C-y
    nnoremap <buffer> <silent> <C-y>  2h:let _s=@/<CR>? {!\\| \?<CR>:let @/=_s<CR>2l
    inoremap <buffer> <silent> <C-y>  <C-o>2h<C-o>:let _s=@/<CR><C-o>? {!\\| \?<CR><C-o>:let @/=_s<CR><C-o>2l

Some commonly used utf8 bindings are listed below, together with their emacs counterparts. For an exhaustive list,
look in `autoload/agda.vim`.

| utf-8 | agda-vim       | emacs             |
|:-----:| -------------- | ----------------- |
| →     | \to            | \to               |
| ¬     | \neg           | \lnot             |
| ∨     | \lor           | \or or vee        |
| ∧     | \land          | \and or \wedge    |
| ₁, ₂  | \1, \2         | \\\_1, \\\_2      |
| ≡     | \equiv         | \equiv or \\==    |
| ⊤     | \top           | \top              |
| ⊥     | \bot           | \bot              |
| ×     | \times         | \times            |
| ⊎     | \dunion        | \uplus            |
| λ     | \l or lambda   | \Gl or \lambda    |
