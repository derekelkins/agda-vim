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

    command! -nargs=0 Load call Load(0)
    command! -nargs=0 AgdaVersion call AgdaVersion(0)
    command! -nargs=0 Reload silent! make!|redraw!
    command! -nargs=0 RestartAgda exec s:python_cmd 'RestartAgda()'
    command! -nargs=0 ShowImplicitArguments exec s:python_cmd "sendCommand('ShowImplicitArgs True')"
    command! -nargs=0 HideImplicitArguments exec s:python_cmd "sendCommand('ShowImplicitArgs False')"
    command! -nargs=0 ToggleImplicitArguments exec s:python_cmd "sendCommand('ToggleImplicitArgs')"
    command! -nargs=0 Constraints exec s:python_cmd "sendCommand('Cmd_constraints')"
    command! -nargs=0 Metas exec s:python_cmd "sendCommand('Cmd_metas')"
    command! -nargs=0 SolveAll exec s:python_cmd "sendCommand('Cmd_solveAll')"
    command! -nargs=1 ShowModule call ShowModule(<args>)
    command! -nargs=1 WhyInScope call WhyInScope(<args>)
    command! -nargs=1 SetRewriteMode exec s:python_cmd "setRewriteMode('<args>')"
    command! -nargs=0 SetRewriteModeAsIs exec s:python_cmd "setRewriteMode('AsIs')"
    command! -nargs=0 SetRewriteModeNormalised exec s:python_cmd "setRewriteMode('Normalised')"
    command! -nargs=0 SetRewriteModeSimplified exec s:python_cmd "setRewriteMode('Simplified')"
    command! -nargs=0 SetRewriteModeHeadNormal exec s:python_cmd "setRewriteMode('HeadNormal')"
    command! -nargs=0 SetRewriteModeInstantiated exec s:python_cmd "setRewriteMode('Instantiated')"

    " C-c C-l -> \l
    nnoremap <buffer> <LocalLeader>l :Reload<CR>
    " C-c C-d -> \t
    nnoremap <buffer> <LocalLeader>t :call Infer()<CR>
    " C-c C-r -> \r
    nnoremap <buffer> <LocalLeader>r :call Refine("False")<CR>
    nnoremap <buffer> <LocalLeader>R :call Refine("True")<CR>
    " C-c C-space -> \g
    nnoremap <buffer> <LocalLeader>g :call Give()<CR>
    " C-c C-g -> \c
    nnoremap <buffer> <LocalLeader>c :call MakeCase()<CR>
    " C-c C-a -> \a
    nnoremap <buffer> <LocalLeader>a :call Auto()<CR>
    " C-c C-, -> \e
    nnoremap <buffer> <LocalLeader>e :call Context()<CR>
    " C-u C-c C-n -> \n
    nnoremap <buffer> <LocalLeader>n :call Normalize("False")<CR>
    " C-c C-n -> \N
    nnoremap <buffer> <LocalLeader>N :call Normalize("True")<CR>
    nnoremap <buffer> <LocalLeader>M :call ShowModule('')<CR>
    " C-c C-w -> \y
    nnoremap <buffer> <LocalLeader>y :call WhyInScope('')<CR>
    nnoremap <buffer> <LocalLeader>h :call HelperFunction()<CR>
    " M-. -> \d
    nnoremap <buffer> <LocalLeader>d :call GotoAnnotation()<CR>
    " C-c C-? -> \m
    nnoremap <buffer> <LocalLeader>m :Metas<CR>

    " Show/reload metas
    " C-c C-? -> C-e
    nnoremap <buffer> <C-e> :Metas<CR>
    inoremap <buffer> <C-e> <C-o>:Metas<CR>

    " Go to next/previous meta
    " C-c C-f -> C-g
    nnoremap <buffer> <silent> <C-g>  :let _s=@/<CR>/ {!\\| ?<CR>:let @/=_s<CR>2l
    inoremap <buffer> <silent> <C-g>  <C-o>:let _s=@/<CR><C-o>/ {!\\| ?<CR><C-o>:let @/=_s<CR><C-o>2l

    " C-c C-b -> C-y
    nnoremap <buffer> <silent> <C-y>  2h:let _s=@/<CR>? {!\\| \?<CR>:let @/=_s<CR>2l
    inoremap <buffer> <silent> <C-y>  <C-o>2h<C-o>:let _s=@/<CR><C-o>? {!\\| \?<CR><C-o>:let @/=_s<CR><C-o>2l


Some commonly used utf8 bindings are listed below, together with their emacs counterparts. For an exhaustive list,
look in `agda-utf8.vim`.

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
