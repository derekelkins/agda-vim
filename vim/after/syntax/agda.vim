" The ReloadSyntax function is reproduced from
" http://wiki.portal.chalmers.se/agda/pmwiki.php?n=Main.VIMEditing
" the remainder is covered by the license described in LICENSE.
function! ReloadSyntax()
    syntax clear
    runtime syntax/agda.vim
    let f = expand('%:h') . "/." . expand('%:t') . ".vim"
    if filereadable(f)
        exec "source " . escape(f, '*')
    endif
endfunction

call ReloadSyntax()

function! Load()
    " Do nothing.  Overidden below with a Python function if python plugins
    " are supported.
endfunction

" map ,rs :call ReloadSyntax()<CR> " Just do :make instead
au QuickfixCmdPost make call ReloadSyntax()|call Load()

runtime agda-utf8.vim

set makeprg=agda\ --vim\ %
" Unsolved metas, parse errors, error header, error footer, error footer, error body, ignore everything else
" set efm=\ \ /%\\&%f:%l\\,%c-%.%#,%+C/%\\&%f:%l\\,%c:\ expected\ sequence\ of\ bound,%+Zidentifiers\ %m,%Z/%\\&%f:%l\\,%c:\ %m,%E/%\\&%f:%l\\,%c-%.%#,%+Zwhen\ %m,%C%m,%-G%.%#
set efm=\ \ /%\\&%f:%l\\,%c-%.%#,%E/%\\&%f:%l\\,%c-%.%#,%Z,%C%m,%-G%.%#

if has('python') 

python << EOF
# define AgdaRange class
# define asHaskellList function to print a Python list as an Haskell list
import vim
import re
import subprocess

# start Agda
agda = subprocess.Popen(["agda", "--interaction"], bufsize = 1, stdin = subprocess.PIPE, stdout = subprocess.PIPE)

goals = {}

# synID, synIDattr, synID = 85 corresponds to agdaHole
# This should be calculated rather than hard-coded.

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

def interpretResponse(responses):
    for response in responses:
        if response.startswith('(agda2-info-action '):
            for match in re.finditer(r'"((?:[^"\\]|\\.)*)"', response[19:]):
                print match.group(1).decode('string_escape')
        elif "(agda2-goals-action '" in response:
            findGoals([int(s) for s in re.findall(r'(\d+)', response[response.index("agda2-goals-action '")+21:])])
        elif "(agda2-make-case-action '" in response:
            response = response.replace("?", "{!   !}")
            cases = re.findall(r'"((?:[^"\\]|\\.)*)"', response[response.index("agda2-make-case-action '")+24:])
            row = vim.current.window.cursor[0]
            vim.current.buffer[row-1:row] = cases
            sendCommand('Cmd_load "%s" []' % f)
            break
        elif response.startswith('(agda2-give-action '):
            response = response.replace("?", "{!   !}")
            match = re.search(r'(\d+)\s+"((?:[^"\\]|\\.)*)"', response[19:])
            replaceHole(match.group(2).decode('string_escape'))
        else:
            print response

def sendCommand(arg, interpret=True):
    vim.command(':write')
    f = vim.current.buffer.name;
    # The x is a really hacky way of getting a consistent final response.  Namely, "cannot read"
    agda.stdin.write('IOTCM "%s" None Indirect (%s)\nx\n' % (f, arg))
    if interpret:
        interpretResponse(getOutput())
    else:
        print getOutput()

def getIdentifierAtCursor():
    (r, c) = vim.current.window.cursor
    line = vim.current.line
    try:
        start = re.search(r"[^\s@(){};]+$", line[:c+1]).start()
        end = re.search(r"^[^\s@(){};]+", line[c:]).end() + c
    except AttributeError as e:
        return None
    return line[start:end]

def replaceHole(replacement):
    (r, c) = vim.current.window.cursor
    line = vim.current.line
    if line[c] == "?":
        start = c
        end = c+1
    else:
        try:
            start = re.search(r"{!", line[:c+1]).start()
            end = re.search(r"!}", line[c:]).end() + c
        except AttributeError as e:
            return
    vim.current.line = line[:start] + replacement + line[end:]

def getHoleBodyAtCursor():
    (r, c) = vim.current.window.cursor
    line = vim.current.line
    if line[c] == "?":
        return ("?", findGoal(r, c+1))
    try:
        start = re.search(r"{!", line[:c+1]).start()
        end = re.search(r"!}", line[c:]).end() + c
    except AttributeError as e:
        return None
    result = line[start+2:end-2].strip()
    if result == "":
        result = "?"
    return (result, findGoal(r, start+1))
EOF

function! Load()
python << EOF
import vim
f = vim.current.buffer.name;
sendCommand('Cmd_load "%s" []' % f)
EOF
endfunction

function! Give()
python << EOF
import vim
result = getHoleBodyAtCursor()
if result is None:
    print "No hole under the cursor"
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
else:
    sendCommand('Cmd_make_case %d noRange "%s"' % (result[1], result[0]))
EOF
endfunction

function! Refine()
python << EOF
import vim
result = getHoleBodyAtCursor()
if result is None:
    print "No hole under the cursor"
else:
    sendCommand('Cmd_refine %d noRange "%s"' % (result[1], result[0]))
EOF
endfunction

function! Auto()
python << EOF
import vim
result = getHoleBodyAtCursor()
if result is None:
    print "No hole under the cursor"
else:
    sendCommand('Cmd_auto %d noRange "%s"' % (result[1], result[0]))
EOF
endfunction

function! Context()
python << EOF
import vim
result = getHoleBodyAtCursor()
if result is None:
    print "No hole under the cursor"
else:
    sendCommand('Cmd_goal_type_context_infer AsIs %d noRange "%s"' % (result[1], result[0]))
EOF
endfunction

function! Infer()
python << EOF
import vim
identifier = getIdentifierAtCursor()
if identifier is None:
    print "No identifier under the cursor"
else:
    sendCommand('Cmd_infer_toplevel AsIs "%s"' % identifier)
EOF
endfunction

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

endif
