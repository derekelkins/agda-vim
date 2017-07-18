Version 0.10.0

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
Agda 2.3.2.1 through 2.5.2.0.  I have not tested Literate Agda files at all and would be a bit surprised if they worked.

It should work as a Pathogen bundle and allegedly as a Vundle or NeoBundle and possibly others.  (I can vouch for Pathogen.)
With Pathogen (and presumably the others) you should be able to simply `git clone` this whole repository into `.vim/bundle/`.

It should also work by just copying the file structure into your `.vim` folder and adding the following line to
`.vim/filetypes.vim`:

    au BufNewFile,BufRead *.agda setf agda

You can add paths to the paths Agda searches by setting `g:agda_extraincpaths` as demonstrated by the command below
which could be added to your .vimrc.

    let g:agda_extraincpaths = ["/home/derek/haskell/agda-stdlib-0.8.1/src"]

In the commands below, the `<LocalLeader>` is set by setting `maplocalleader` which needs to occur before the mappings
are made, e.g. in your `.vimrc`:

    let maplocalleader = ","

The commands and mappings as defined currently are below:

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

    nnoremap <buffer> <LocalLeader>l :Reload<CR>
    nnoremap <buffer> <LocalLeader>t :call Infer()<CR>
    nnoremap <buffer> <LocalLeader>r :call Refine("False")<CR>
    nnoremap <buffer> <LocalLeader>R :call Refine("True")<CR>
    nnoremap <buffer> <LocalLeader>g :call Give()<CR>
    nnoremap <buffer> <LocalLeader>c :call MakeCase()<CR>
    nnoremap <buffer> <LocalLeader>a :call Auto()<CR>
    nnoremap <buffer> <LocalLeader>e :call Context()<CR>
    nnoremap <buffer> <LocalLeader>n :call Normalize("False")<CR>
    nnoremap <buffer> <LocalLeader>N :call Normalize("True")<CR>
    nnoremap <buffer> <LocalLeader>M :call ShowModule('')<CR>
    nnoremap <buffer> <LocalLeader>y :call WhyInScope('')<CR>
    nnoremap <buffer> <LocalLeader>m :Metas<CR>

    " Show/reload metas
    nnoremap <buffer> <C-e> :Metas<CR>
    inoremap <buffer> <C-e> <C-o>:Metas<CR>

    " Go to next/previous meta
    nnoremap <buffer> <silent> <C-g>  :let _s=@/<CR>/ {!\\| ?<CR>:let @/=_s<CR>2l
    inoremap <buffer> <silent> <C-g>  <C-o>:let _s=@/<CR><C-o>/ {!\\| ?<CR><C-o>:let @/=_s<CR><C-o>2l

    nnoremap <buffer> <silent> <C-y>  2h:let _s=@/<CR>? {!\\| \?<CR>:let @/=_s<CR>2l
    inoremap <buffer> <silent> <C-y>  <C-o>2h<C-o>:let _s=@/<CR><C-o>? {!\\| \?<CR><C-o>:let @/=_s<CR><C-o>2l
