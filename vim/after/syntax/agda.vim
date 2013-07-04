" The ReloadSyntax function is reproduced from
" http://wiki.portal.chalmers.se/agda/pmwiki.php?n=Main.VIMEditing
" the remainder is covered by the license described in LICENSE.
function! ReloadSyntax()
    syntax clear
    let f = expand('%:h') . "/." . expand('%:t') . ".vim"
    if filereadable(f)
        exec "source " . escape(f, '*')
    endif
    runtime syntax/agda.vim
endfunction

call ReloadSyntax()

function! Load(quiet)
    " Do nothing.  Overidden below with a Python function if python plugins
    " are supported.
endfunction

" map ,rs :call ReloadSyntax()<CR> " Just do :make instead
au QuickfixCmdPost make call ReloadSyntax()|call Load(1)
set autowrite

runtime agda-utf8.vim

set makeprg=agda\ --vim\ %
set efm=\ \ /%\\&%f:%l\\,%c-%.%#,%E/%\\&%f:%l\\,%c-%.%#,%Z,%C%m,%-G%.%#

if has('python') 

function! s:LogAgda(name, text, append)
    let agdawinnr = bufwinnr('__Agda__')
    let prevwinnr = winnr()
    if agdawinnr == -1
        let eventignore_save = &eventignore
        set eventignore=all

        silent keepalt botright 8split __Agda__

        let &eventignore = eventignore_save
        setlocal noreadonly
        setlocal buftype=nofile
        setlocal bufhidden=hide
        setlocal noswapfile
        setlocal nobuflisted
        setlocal nolist
        setlocal nonumber
        setlocal nowrap
        setlocal textwidth=0
        setlocal nocursorline
        setlocal nocursorcolumn

        if exists('+relativenumber')
            setlocal norelativenumber
        endif
    else
        let eventignore_save = &eventignore
        set eventignore=BufEnter

        execute agdawinnr . 'wincmd w'
        let &eventignore = eventignore_save
    endif
    
    let lazyredraw_save = &lazyredraw
    set lazyredraw
    let eventignore_save = &eventignore
    set eventignore=all

    if a:append == 'True'
        exec 'setlocal statusline=' . substitute(a:name, ' ', '\\ ', 'g')
        silent put =a:text
    else
        exec 'setlocal statusline=' . substitute(a:name, ' ', '\\ ', 'g')
        silent %delete _
        silent 0put =a:text
    endif

    0

    let &lazyredraw = lazyredraw_save
    let &eventignore = eventignore_save

    let eventignore_save = &eventignore
    set eventignore=BufEnter

    execute prevwinnr . 'wincmd w'
    let &eventignore = eventignore_save
endfunction    

python << EOF
import vim
import re
import subprocess

# start Agda
# I'm pretty sure this will start an agda process per buffer which is less than desirable...
agda = subprocess.Popen(["agda", "--interaction"], bufsize = 1, stdin = subprocess.PIPE, stdout = subprocess.PIPE)

goals = {}

rewriteMode = "Normalised"

# synID, synIDattr, synID = 85 corresponds to agdaHole
# This should be calculated rather than hard-coded.

def setRewriteMode(mode):
    global rewriteMode
    mode = mode.strip()
    if mode not in ["AsIs", "Normalised", "HeadNormal", "Instantiated"]:
        rewriteMode = "Normalised"
    else:
        rewriteMode = mode

def promptUser(msg):
    vim.command('call inputsave()')
    result = vim.eval('input("%s")' % msg) 
    vim.command('call inputrestore()')
    return result

def RestartAgda():
    global agda
    agda = subprocess.Popen(["agda", "--interaction"], bufsize = 1, stdin = subprocess.PIPE, stdout = subprocess.PIPE)

def findGoals(goalList):
    global goals
    goals = {}
    lines = vim.current.buffer
    row = 1
    for line in lines:
        start = 0
        while start != -1:
            qstart = line.find('?', start)
            hstart = line.find('{!', start)
            if qstart == -1:
                start = hstart
            elif hstart == -1:
                start = qstart
            else:
                start = min(hstart, qstart)
            if start != -1:
                start = start + 1
                if vim.eval('synID("%d", "%d", 0)' % (row, start)) == '85': # Magic: synID of agdaHole
                    goals[goalList.pop(0)] = (row, start)
            if len(goalList) == 0: break
        if len(goalList) == 0: break
        row = row + 1

def findGoal(row, col):
    global goals
    for item in goals.iteritems():
        if item[1][0] == row and item[1][1] == col:
            return item[0]
    return None

def getOutput():
    line = agda.stdout.readline()[7:] # get rid of the "Agda2> " prompt
    lines = []
    while not line.startswith('Agda2> cannot read') and line != "":
        lines.append(line)
        line = agda.stdout.readline()
    return lines

def interpretResponse(responses, quiet = False):
    for response in responses:
        # print response
        if response.startswith('(agda2-info-action '):
            if quiet and '*Error*' in response: vim.command('cwindow')
            if quiet: continue
            strings = re.findall(r'"((?:[^"\\]|\\.)*)"', response[19:])
            vim.command('call s:LogAgda("%s","%s","%s")'% (strings[0],strings[1], response.endswith('t)')))
        elif "(agda2-goals-action '" in response:
            findGoals([int(s) for s in re.findall(r'(\d+)', response[response.index("agda2-goals-action '")+21:])])
        elif "(agda2-make-case-action-extendlam '" in response:
            response = response.replace("?", "{!   !}") # this probably isn't safe
            cases = re.findall(r'"((?:[^"\\]|\\.)*)"', response[response.index("agda2-make-case-action-extendlam '")+34:])
            col = vim.current.window.cursor[1]
            line = vim.current.line
            start = line.rindex('{', 0, col) + 1
            end = line.index('}', col)
            vim.current.line = line[:start] + " " + "; ".join(cases) + " " + line[end:]
            sendCommand('Cmd_load "%s" []' % f, quiet = quiet)
            break
        elif "(agda2-make-case-action '" in response:
            response = response.replace("?", "{!   !}") # this probably isn't safe
            cases = re.findall(r'"((?:[^"\\]|\\.)*)"', response[response.index("agda2-make-case-action '")+24:])
            row = vim.current.window.cursor[0]
            vim.current.buffer[row-1:row] = cases
            sendCommand('Cmd_load "%s" []' % f, quiet = quiet)
            break
        elif response.startswith('(agda2-give-action '):
            response = response.replace("?", "{!   !}")
            match = re.search(r'(\d+)\s+"((?:[^"\\]|\\.)*)"', response[19:])
            replaceHole(match.group(2).decode('string_escape'))
        else:
            pass # print response

def sendCommand(arg, quiet=False):
    vim.command(':silent! write')
    f = vim.current.buffer.name;
    # The x is a really hacky way of getting a consistent final response.  Namely, "cannot read"
    agda.stdin.write('IOTCM "%s" None Indirect (%s)\nx\n' % (f, arg))
    interpretResponse(getOutput(), quiet)

#def getIdentifierAtCursor():
#    (r, c) = vim.current.window.cursor
#    line = vim.current.line
#    try:
#        start = re.search(r"[^\s@(){};]+$", line[:c+1]).start()
#        end = re.search(r"^[^\s@(){};]+", line[c:]).end() + c
#    except AttributeError as e:
#        return None
#    return line[start:end]

def replaceHole(replacement):
    (r, c) = vim.current.window.cursor
    line = vim.current.line
    if line[c] == "?":
        start = c
        end = c+1
    else:
        try:
            mo = None
            for mo in re.finditer(r"{!", line[:min(len(line),c+2)]): pass
            start = mo.start()
            end = re.search(r"!}", line[max(0,c-1):]).end() + max(0,c-1)
        except AttributeError:
            return
    vim.current.line = line[:start] + replacement + line[end:]

def getHoleBodyAtCursor():
    (r, c) = vim.current.window.cursor
    line = vim.current.line
    if line[c] == "?":
        return ("?", findGoal(r, c+1))
    try: # handle virtual space better
        mo = None
        for mo in re.finditer(r"{!", line[:min(len(line),c+2)]): pass
        start = mo.start()
        end = re.search(r"!}", line[max(0,c-1):]).end() + max(0,c-1)
    except AttributeError:
        return None
    result = line[start+2:end-2].strip()
    if result == "":
        result = "?"
    return (result, findGoal(r, start+1))
EOF

function! Load(quiet)
python << EOF
import vim
f = vim.current.buffer.name;
sendCommand('Cmd_load "%s" []' % f, quiet = int(vim.eval('a:quiet')) == 1)
EOF
endfunction

function! Give()
python << EOF
import vim
result = getHoleBodyAtCursor()
if result is None:
    print "No hole under the cursor"
elif result[1] is None:
    print "Goal not loaded"
elif result[0] == "?":
    sendCommand('Cmd_give %d noRange "%s"' % (result[1], promptUser("Enter expression: ")))
else:
    sendCommand('Cmd_give %d noRange "%s"' % (result[1], result[0]))
EOF
endfunction

function! MakeCase()
python << EOF
import vim
result = getHoleBodyAtCursor()
if result is None:
    print "No hole under the cursor"
elif result[1] is None:
    print "Goal not loaded"
elif result[0] == "?":
    sendCommand('Cmd_make_case %d noRange "%s"' % (result[1], promptUser("Make case on: ")))
else:
    sendCommand('Cmd_make_case %d noRange "%s"' % (result[1], result[0]))
EOF
endfunction

function! Refine(unfoldAbstract)
python << EOF
import vim
result = getHoleBodyAtCursor()
if result is None:
    print "No hole under the cursor"
elif result[1] is None:
    print "Goal not loaded"
else:
    sendCommand('Cmd_refine_or_intro %s %d noRange "%s"' % (vim.eval('a:unfoldAbstract'), result[1], result[0]))
EOF
endfunction

function! Auto()
python << EOF
import vim
result = getHoleBodyAtCursor()
if result is None:
    print "No hole under the cursor"
elif result[1] is None:
    print "Goal not loaded"
else:
    sendCommand('Cmd_auto %d noRange "%s"' % (result[1], ""))
EOF
endfunction

function! Context()
python << EOF
import vim
result = getHoleBodyAtCursor()
if result is None:
    print "No hole under the cursor"
elif result[1] is None:
    print "Goal not loaded"
else:
    sendCommand('Cmd_goal_type_context_infer %s %d noRange "%s"' % (rewriteMode, result[1], result[0]))
EOF
endfunction

function! Infer()
python << EOF
import vim
result = getHoleBodyAtCursor()
if result is None:
    sendCommand('Cmd_infer_toplevel %s "%s"' % (rewriteMode, promptUser("Enter expression: ")))
elif result[1] is None:
    print "Goal not loaded"
else:
    sendCommand('Cmd_infer %s %d noRange "%s"' % (rewriteMode, result[1], result[0]))
EOF
endfunction

function! Normalize(unfoldAbstract)
python << EOF
import vim
result = getHoleBodyAtCursor()
if result is None:
    sendCommand('Cmd_compute_toplevel %s "%s"' % (vim.eval('a:unfoldAbstract'), promptUser("Enter expression: ")))
elif result[1] is None:
    print "Goal not loaded"
else:
    sendCommand('Cmd_compute %s %d noRange "%s"' % (vim.eval('a:unfoldAbstract'), result[1], result[0]))
EOF
endfunction

function! ShowModule()
python << EOF
result = getHoleBodyAtCursor()
if result is None:
    sendCommand('Cmd_show_module_contents_toplevel "%s"' % promptUser("Enter module name: "))
elif result[1] is None:
    print "Goal not loaded"
else:
    sendCommand('Cmd_show_module_contents %d noRange "%s"' % (result[1], result[0]))
EOF
endfunction

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

Reload

endif
