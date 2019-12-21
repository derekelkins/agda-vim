import vim
import re
import subprocess
from functools import wraps


def vim_func(vim_fname_or_func=None, conv=None):
    '''Expose a python function to vim, optionally overriding its name.'''

    def wrap_func(func, vim_fname, conv):
        fname = func.func_name
        vim_fname = vim_fname or fname

        arg_names = func.func_code.co_varnames[:func.func_code.co_argcount]
        arg_defaults = dict(zip(arg_names[:-len(func.func_defaults or ()):], func.func_defaults or []))

        @wraps(func)
        def from_vim(vim_arg_dict):
            args = {}
            for k in arg_names:
                try:
                    val = vim_arg_dict[k]
                except KeyError:
                    val = arg_defaults[k]

                if k in conv:
                    val = conv[k](val)

                args[k] = val
            return func(**args)

        setattr(func, 'from_vim', from_vim)

        vim.command('''
            function! {vim_fname}({vim_params})
                py {fname}.from_vim(vim.eval(\'a:\'))
            endfunction
        '''.format(
            vim_fname=vim_fname,
            vim_params=', '.join(arg_names),
            fname=fname,
        ))
        return func

    if callable(vim_fname_or_func):
        return wrap_func(func=vim_fname_or_func, vim_fname=None, conv={})

    def wrapper(func):
        return wrap_func(func=func, vim_fname=vim_fname_or_func, conv=conv or {})
    return wrapper


def vim_bool(s):
    if not s:
        return False
    elif s == 'False':
        return False
    elif s == 'True':
        return True
    return bool(int(s))

goals = {}
annotations = []

agdaVersion = [0,0,0,0]

rewriteMode = "Normalised"

# This technically needs to turn a string into a Haskell escaped string, buuuut just gonna cheat.
def escape(s):
    return s.replace('\\', '\\\\').replace('"', '\\"').replace('\n','\\n') # keep '\\' case first

# This technically needs to turn a Haskell escaped string into a string, buuuut just gonna cheat.
def unescape(s):
    return s.replace('\\\\','\x00').replace('\\"', '"').replace('\\n','\n').replace('\x00', '\\') # hacktastic

def setRewriteMode(mode):
    global rewriteMode
    mode = mode.strip()
    if mode not in ["AsIs", "Normalised", "Simplified", "HeadNormal", "Instantiated"]:
        rewriteMode = "Normalised"
    else:
        rewriteMode = mode

def promptUser(msg):
    vim.command('call inputsave()')
    result = vim.eval('input("%s")' % msg)
    vim.command('call inputrestore()')
    return result

def findGoals(goalList):
    global goals

    vim.command('syn sync fromstart') # TODO: This should become obsolete given good sync rules in the syntax file.

    goals = {}
    lines = vim.current.buffer
    row = 1
    agdaHolehlID = vim.eval('hlID("agdaHole")')
    for line in lines:

        start = 0
        while start != -1:
            qstart = line.find("?", start)
            hstart = line.find("{!", start)
            if qstart == -1:
                start = hstart
            elif hstart == -1:
                start = qstart
            else:
                start = min(hstart, qstart)
            if start != -1:
                start = start + 1

                if vim.eval('synID("%d", "%d", 0)' % (row, start)) == agdaHolehlID:
                    goals[goalList.pop(0)] = (row, start)
            if len(goalList) == 0: break
        if len(goalList) == 0: break
        row = row + 1

    vim.command('syn sync clear') # TODO: This wipes out any sync rules and should be removed if good sync rules are added to the syntax file.

def findGoal(row, col):
    global goals
    for item in goals.items():
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

def parseVersion(versionString):
    global agdaVersion
    agdaVersion = [int(c) for c in versionString[12:].split("-")[0].split('.')]
    agdaVersion = agdaVersion + [0]*max(0, 4-len(agdaVersion))

# This is not very efficient presumably.
def c2b(n):
    return int(vim.eval('byteidx(join(getline(1, "$"), "\n"),%d)' % n))

# See https://github.com/agda/agda/blob/323f58f9b8dad239142ed1dfa0c60338ea2cb157/src/data/emacs-mode/annotation.el#L112
def parseAnnotation(spans):
    global annotations
    anns = re.findall(r'\((\d+) (\d+) \([^\)]*\) \w+ \(\"([^"]*)\" \. (\d+)\)\)', spans)
    # TODO: This is assumed to be in sorted order.
    for ann in anns:
        annotations.append([c2b(int(ann[0])-1), c2b(int(ann[1])-1), ann[2], c2b(int(ann[3]))])

def searchAnnotation(lo, hi, idx):
    global annotations

    if hi == 0: return None

    while hi - lo > 1:
        mid = lo + (hi - lo) // 2
        midOffset = annotations[mid][0]
        if idx < midOffset:
            hi = mid
        else:
            lo = mid

    (loOffset, hiOffset) = annotations[lo][0:2]
    if idx > loOffset and idx <= hiOffset:
        return annotations[lo][2:4]
    else:
        return None

def gotoAnnotation():
    global annotations
    byteOffset = int(vim.eval('line2byte(line(".")) + col(".") - 1'))
    result = searchAnnotation(0, len(annotations), byteOffset)
    if result is None: return
    (file, pos) = result
    targetBuffer = None
    for buffer in vim.buffers:
        if buffer.name == file: targetBuffer = buffer.number

    if targetBuffer is None:
        vim.command('edit %s' % file)
    else:
        vim.command('buffer %s' % targetBuffer)
    vim.command('%dgo' % pos)

def interpretResponse(responses, quiet = False):
    for response in responses:
        if response.startswith('(agda2-info-action ') or response.startswith('(agda2-info-action-and-copy '):
            if quiet and '*Error*' in response: vim.command('cwindow')
            strings = re.findall(r'"((?:[^"\\]|\\.)*)"', response[19:])
            if strings[0] == '*Agda Version*':
                parseVersion(strings[1])
            if quiet: continue
            vim.command('call s:LogAgda("%s","%s","%s")'% (strings[0], strings[1], response.endswith('t)')))
        elif "(agda2-goals-action '" in response:
            findGoals([int(s) for s in re.findall(r'(\d+)', response[response.index("agda2-goals-action '")+21:])])
        elif "(agda2-make-case-action-extendlam '" in response:
            response = response.replace("?", "{!   !}") # this probably isn't safe
            cases = re.findall(r'"((?:[^"\\]|\\.)*)"', response[response.index("agda2-make-case-action-extendlam '")+34:])
            col = vim.current.window.cursor[1]
            line = vim.current.line

            # TODO: The following logic is far from perfect.
            # Look for a semicolon ending the previous case.
            correction = 0
            starts = [mo for mo in re.finditer(r';', line[:col])]
            if len(starts) == 0:
                # Look for the starting bracket of the extended lambda..
                correction = 1
                starts = [mo for mo in re.finditer(r'{[^!]', line[:col])]
                if len(starts) == 0:
                    # Assume the case is on a line by itself.
                    correction = 1
                    starts = [mo for mo in re.finditer(r'^[ \t]*', line[:col])]
            start = starts[-1].end() - correction

            # Look for a semicolon ending this case.
            correction = 0
            ends = re.search(r';', line[col:])
            if ends == None:
                # Look for the ending bracket of the extended lambda.
                correction = 1
                ends = re.search(r'[^!]}', line[col:])
                if ends == None:
                    # Assume the case is on a line by itself (or at least has nothing after it).
                    correction = 0
                    ends = re.search(r'[ \t]*$', line[col:])
            end = ends.start() + col + correction

            vim.current.line = line[:start] + " " + "; ".join(cases) + " " + line[end:]
            f = vim.current.buffer.name
            sendCommandLoad(f, quiet)
            break
        elif "(agda2-make-case-action '" in response:
            response = response.replace("?", "{!   !}") # this probably isn't safe
            cases = re.findall(r'"((?:[^"\\]|\\.)*)"', response[response.index("agda2-make-case-action '")+24:])
            row = vim.current.window.cursor[0]
            prefix = re.match(r'[ \t]*', vim.current.line).group()
            vim.current.buffer[row-1:row] = [prefix + case for case in cases]
            f = vim.current.buffer.name
            sendCommandLoad(f, quiet)
            break
        elif response.startswith('(agda2-give-action '):
            response = response.replace("?", "{!   !}")
            match = re.search(r'(\d+)\s+"((?:[^"\\]|\\.)*)"', response[19:])
            replaceHole(unescape(match.group(2)))
        # elif response.startswith('(agda2-highlight-clear)'):
            # pass # Maybe do something with this.
        elif response.startswith('(agda2-highlight-add-annotations '):
            parseAnnotation(response)
        else:
            pass # print(response)

@vim_func
def AgdaInterpretResponse(responses, quiet = False):
    interpretResponse(responses, False)

def sendCommand(arg, quiet=False):
    cmd = 'call agda#job#send(\'%s\',%s)' % (arg, '1' if quiet else '0')
    vim.command(cmd)

def sendCommandLoadHighlightInfo(file, quiet):
    sendCommand('Cmd_load_highlighting_info "%s"' % escape(file), quiet = quiet)

def sendCommandLoad(file, quiet):
    global agdaVersion
    if agdaVersion < [2,5,0,0]: # in 2.5 they changed it so Cmd_load takes commandline arguments
        incpaths_str = ",".join(vim.vars['agdavim_agda_includepathlist'])
    else:
        incpaths_str = "\"-i\"," + ",\"-i\",".join(vim.vars['agdavim_agda_includepathlist'])
    sendCommand('Cmd_load "%s" [%s]' % (escape(file), incpaths_str), quiet = quiet)

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
    rep = replacement.replace('\n', ' ').replace('    ', ';') # TODO: This probably needs to be handled better
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
    vim.current.line = line[:start] + rep + line[end:]

def getHoleBodyAtCursor():
    (r, c) = vim.current.window.cursor
    line = vim.current.line
    try:
        if line[c] == "?":
            return ("?", findGoal(r, c+1))
    except IndexError:
        return None
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

def getWordAtCursor():
    return vim.eval("expand('<cWORD>')").strip()


## Directly exposed functions: {

@vim_func(conv={'quiet': vim_bool})
def AgdaVersion(quiet):
    sendCommand('Cmd_show_version', quiet=quiet)


@vim_func(conv={'quiet': vim_bool})
def AgdaLoadHighlightInfo(quiet):
    f = vim.current.buffer.name
    sendCommandLoadHighlightInfo(f, quiet)


@vim_func
def AgdaGotoAnnotation():
    gotoAnnotation()


@vim_func
def AgdaGive():
    result = getHoleBodyAtCursor()

    if agdaVersion < [2,5,3,0]:
        useForce = ""
    else:
        useForce = "WithoutForce" # or WithForce

    if result is None:
        print("No hole under the cursor")
    elif result[1] is None:
        print("Goal not loaded")
    elif result[0] == "?":
        sendCommand('Cmd_give %s %d noRange "%s"' % (useForce, result[1], escape(promptUser("Enter expression: "))))
    else:
        sendCommand('Cmd_give %s %d noRange "%s"' % (useForce, result[1], escape(result[0])))


@vim_func
def AgdaMakeCase():
    result = getHoleBodyAtCursor()
    if result is None:
        print("No hole under the cursor")
    elif result[1] is None:
        print("Goal not loaded")
    elif result[0] == "?":
        sendCommand('Cmd_make_case %d noRange "%s"' % (result[1], escape(promptUser("Make case on: "))))
    else:
        sendCommand('Cmd_make_case %d noRange "%s"' % (result[1], escape(result[0])))


@vim_func
def AgdaRefine(unfoldAbstract):
    result = getHoleBodyAtCursor()
    if result is None:
        print("No hole under the cursor")
    elif result[1] is None:
        print("Goal not loaded")
    else:
        sendCommand('Cmd_refine_or_intro %s %d noRange "%s"' % (unfoldAbstract, result[1], escape(result[0])))


@vim_func
def AgdaAuto():
    result = getHoleBodyAtCursor()
    if result is None:
        print("No hole under the cursor")
    elif result[1] is None:
        print("Goal not loaded")
    else:
        if agdaVersion < [2,6,0,0]:
            sendCommand('Cmd_auto %d noRange "%s"' % (result[1], escape(result[0]) if result[0] != "?" else ""))
        else:
            sendCommand('Cmd_autoOne %d noRange "%s"' % (result[1], escape(result[0]) if result[0] != "?" else ""))


@vim_func
def AgdaContext():
    result = getHoleBodyAtCursor()
    if result is None:
        print("No hole under the cursor")
    elif result[1] is None:
        print("Goal not loaded")
    else:
        sendCommand('Cmd_goal_type_context_infer %s %d noRange "%s"' % (rewriteMode, result[1], escape(result[0])))


@vim_func
def AgdaInfer():
    result = getHoleBodyAtCursor()
    if result is None:
        sendCommand('Cmd_infer_toplevel %s "%s"' % (rewriteMode, escape(promptUser("Enter expression: "))))
    elif result[1] is None:
        print("Goal not loaded")
    else:
        sendCommand('Cmd_infer %s %d noRange "%s"' % (rewriteMode, result[1], escape(result[0])))


# As of 2.5.2, the options are "DefaultCompute", "IgnoreAbstract", "UseShowInstance"
@vim_func
def AgdaNormalize(unfoldAbstract):
    if agdaVersion < [2,5,2,0]:
        unfoldAbstract = str(unfoldAbstract == "DefaultCompute")

    result = getHoleBodyAtCursor()
    if result is None:
        sendCommand('Cmd_compute_toplevel %s "%s"' % (unfoldAbstract, escape(promptUser("Enter expression: "))))
    elif result[1] is None:
        print("Goal not loaded")
    else:
        sendCommand('Cmd_compute %s %d noRange "%s"' % (unfoldAbstract, result[1], escape(result[0])))


@vim_func
def AgdaWhyInScope(termName):
    result = getHoleBodyAtCursor() if termName == '' else None

    if result is None:
        termName = getWordAtCursor() if termName == '' else termName
        termName = promptUser("Enter name: ") if termName == '' else termName
        sendCommand('Cmd_why_in_scope_toplevel "%s"' % escape(termName))
    elif result[1] is None:
        print("Goal not loaded")
    else:
        sendCommand('Cmd_why_in_scope %d noRange "%s"' % (result[1], escape(result[0])))


@vim_func
def AgdaShowModule(moduleName):
    result = getHoleBodyAtCursor() if moduleName == '' else None

    if agdaVersion < [2,4,2,0]:
        if result is None:
            moduleName = promptUser("Enter module name: ") if moduleName == '' else moduleName
            sendCommand('Cmd_show_module_contents_toplevel "%s"' % escape(moduleName))
        elif result[1] is None:
            print("Goal not loaded")
        else:
            sendCommand('Cmd_show_module_contents %d noRange "%s"' % (result[1], escape(result[0])))
    else:
        if result is None:
            moduleName = promptUser("Enter module name: ") if moduleName == '' else moduleName
            sendCommand('Cmd_show_module_contents_toplevel %s "%s"' % (rewriteMode, escape(moduleName)))
        elif result[1] is None:
            print("Goal not loaded")
        else:
            sendCommand('Cmd_show_module_contents %s %d noRange "%s"' % (rewriteMode, result[1], escape(result[0])))


@vim_func
def AgdaHelperFunction():
    result = getHoleBodyAtCursor()

    if result is None:
        print("No hole under the cursor")
    elif result[1] is None:
        print("Goal not loaded")
    elif result[0] == "?":
        sendCommand('Cmd_helper_function %s %d noRange "%s"' % (rewriteMode, result[1], escape(promptUser("Enter name for helper function: "))))
    else:
        sendCommand('Cmd_helper_function %s %d noRange "%s"' % (rewriteMode, result[1], escape(result[0])))


## }
