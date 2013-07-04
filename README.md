Version 0.0.1

A simple vim mode for interactively editing Agda code.  This is very alpha.

It incorporates the syntax and unicode input files from <http://wiki.portal.chalmers.se/agda/pmwiki.php?n=Main.VIMEditing>
but extends them with support for interacting with the Agda process in the same manner as the emacs mode.  In addition,
it sets Agda as the make program to automatically generate and load the local vim highlighting files and to jump
to errors.  The make program is currently just "agda --vim", i.e. it does not compile the program.

This requires syntax highlighting to be turned on and, for the interactivity, python plugins to be supported.  This
interacts via the same interface emacs uses, though a lot of the logic is in the emacs mode.  This is not an officially
supported mode, so there's no guarantee it will work with different versions of Agda.  I've currently used it with
Agda 2.3.2.1.  I have not tested Literate Agda files at all and would be a bit surprised if they worked.

This currently does not use any of the vim "package" formats.  Copying the vim subfolder into your .vim file
should and adding the following line to filetypes.vim should be adequate:

    au BufNewFile,BufRead *.agda setf agda

The commands and mappings as defined currently are below:

    command! -nargs=0 Load call Load(0)
    command! -nargs=0 Reload silent! make!|redraw!
    command! -nargs=0 RestartAgda python RestartAgda()
    command! -nargs=0 ShowImplicitArguments python sendCommand('ShowImplicitArgs True')
    command! -nargs=0 HideImplicitArguments python sendCommand('ShowImplicitArgs False')
    command! -nargs=0 ToggleImplicitArguments python sendCommand('ToggleImplicitArgs')
    command! -nargs=0 Constraints python sendCommand('Cmd_constraints')
    command! -nargs=0 Metas python sendCommand('Cmd_metas')
    command! -nargs=0 SolveAll python sendCommand('Cmd_solveAll')
    command! -nargs=1 ShowModule python sendCommand('Cmd_show_module_contents_toplevel "%s"' % "<args>")
    command! -nargs=1 SetRewriteMode python setRewriteMode("<args>")
    nmap <buffer> ,l :Reload<CR>
    nmap <buffer> ,t :call Infer()<CR>
    nmap <buffer> ,r :call Refine("False")<CR>
    nmap <buffer> ,R :call Refine("True")<CR>
    nmap <buffer> ,g :call Give()<CR>
    nmap <buffer> ,c :call MakeCase()<CR>
    nmap <buffer> ,a :call Auto()<CR>
    nmap <buffer> ,e :call Context()<CR>
    nmap <buffer> ,n :call Normalize("False")<CR>
    nmap <buffer> ,N :call Normalize("True")<CR>
    nmap <buffer> ,m :call ShowModule()<CR>
