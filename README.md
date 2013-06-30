Version 0.0.1

A simple vim mode for interactively editing Agda code.  This is very alpha.

It incorporates the syntax and unicode input files from <http://wiki.portal.chalmers.se/agda/pmwiki.php?n=Main.VIMEditing>
but extends them with support for interacting with the Agda process in the same manner as the emacs mode.  In addition,
it sets Agda as the make program to automatically generate and load the local vim highlighting files and to jump
to errors.  The make program is currently just "agda --vim", i.e. it does not compile the program.

This requires syntax highlighting to be turned on and, for the interactivity, python plugins to be supported.  This
interacts via the same interface emacs uses, though a lot of the logic is in the emacs mode.  This not an officially
supported mode, so there's no guarantee it will work with different versions of Agda.  I've currently used it with
Agda 2.3.2.1.

This currently does not use any of the vim "package" formats.  Copying the vim subfolder into your .vim file
should be adequate.

It is currently required to explicitly executed the Ex command "Load" to start the interactivity, but
there is really no reason it couldn't be automatically called.  It is necessary to call it to resync the
file, primarily when holes are manually created or deleted.  There should be no trouble hooking it to call
Load after every save, though that is a bit overkill.  :make calls Load.

The commands and mappings as defined currently are below:

    command! -nargs=0 Load call Load()
    command! -nargs=0 RestartAgda python RestartAgda()
    command! -nargs=0 ToggleImplicitArguments python sendCommand('ToggleImplicitArgs')
    command! -nargs=0 Constraints python sendCommand('Cmd_constraints')
    command! -nargs=0 Metas python sendCommand('Cmd_metas')
    command! -nargs=0 SolveAll python sendCommand('Cmd_solveAll')
    command! -nargs=1 ShowModule python sendCommand('Cmd_show_module_contents_toplevel "%s"' % "<args>")
    map ,t :call Infer()<CR>
    map ,r :call Refine()<CR>
    map ,g :call Give()<CR>
    map ,c :call MakeCase()<CR>
    map ,a :call Auto()<CR>
    map ,e :call Context()<CR>
