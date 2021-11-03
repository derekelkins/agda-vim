" Only do this when not done yet for this buffer
if exists('b:did_ftplugin')
  finish
endif
let b:did_ftplugin = 1
let b:undo_ftplugin = ''

let s:cpo_save = &cpo
set cpo&vim

" The AgdaReloadSyntax function is reproduced from
" http://wiki.portal.chalmers.se/agda/pmwiki.php?n=Main.VIMEditing
" the remainder is covered by the license described in LICENSE.
function! AgdaReloadSyntax()
    syntax clear
    let f = expand('%:h') . "/." . expand('%:t') . ".vim"
    if filereadable(f)
        exec "source " . escape(f, '*')
    endif
    runtime syntax/agda.vim
endfunction
call AgdaReloadSyntax()

function! AgdaLoad(quiet)
    " Do nothing.  Overidden below with a Python function if python is supported.
endfunction

autocmd QuickfixCmdPost make call AgdaReloadSyntax()|call AgdaVersion(v:true)|call AgdaLoad(v:true)

setlocal autowrite
let b:undo_ftplugin .= ' | setlocal autowrite<'

let g:agdavim_agda_includepathlist = deepcopy(['.'] + get(g:, 'agda_extraincpaths', []))
call map(g:agdavim_agda_includepathlist, ' ''"'' . v:val . ''"'' ')
let &l:makeprg = 'agda --vim ' . '-i ' . join(g:agdavim_agda_includepathlist, ' -i ') . ' %'
let b:undo_ftplugin .= ' | setlocal makeprg<'

if get(g:, 'agdavim_includeutf8_mappings', v:true)
    runtime agda-utf8.vim
endif

let g:agdavim_enable_goto_definition = get(g:, 'agdavim_enable_goto_definition', v:true) ? v:true : v:false

setlocal errorformat=\ \ /%\\&%f:%l\\,%c-%.%#,%E/%\\&%f:%l\\,%c-%.%#,%Z,%C%m,%-G%.%#
let b:undo_ftplugin .= ' | setlocal errorformat<'

setlocal nolisp
let b:undo_ftplugin .= ' | setlocal nolisp<'

setlocal formatoptions-=t
setlocal formatoptions+=croql
let b:undo_ftplugin .= ' | setlocal formatoptions<'

setlocal autoindent
let b:undo_ftplugin .= ' | setlocal autoindent<'

" {-
" -- Foo
" -- bar
" -}
setlocal comments=sfl:{-,mb1:--,ex:-},:--
let b:undo_ftplugin .= ' | setlocal comments<'

setlocal commentstring=--\ %s
let b:undo_ftplugin .= ' | setlocal commentstring<'

setlocal iskeyword=@,!-~,^\,,^\(,^\),^\",^\',192-255
let b:undo_ftplugin .= ' | setlocal iskeyword<'

setlocal matchpairs&vim
setlocal matchpairs+=(:)
setlocal matchpairs+=<:>
setlocal matchpairs+=[:]
setlocal matchpairs+={:}
setlocal matchpairs+=«:»
setlocal matchpairs+=‹:›
setlocal matchpairs+=⁅:⁆
setlocal matchpairs+=⁽:⁾
setlocal matchpairs+=₍:₎
setlocal matchpairs+=⌈:⌉
setlocal matchpairs+=⌊:⌋
setlocal matchpairs+=〈:〉
setlocal matchpairs+=⎛:⎞
setlocal matchpairs+=⎝:⎠
setlocal matchpairs+=⎡:⎤
setlocal matchpairs+=⎣:⎦
setlocal matchpairs+=⎧:⎫
setlocal matchpairs+=⎨:⎬
setlocal matchpairs+=⎩:⎭
setlocal matchpairs+=⎴:⎵
setlocal matchpairs+=❨:❩
setlocal matchpairs+=❪:❫
setlocal matchpairs+=❬:❭
setlocal matchpairs+=❮:❯
setlocal matchpairs+=❰:❱
setlocal matchpairs+=❲:❳
setlocal matchpairs+=❴:❵
setlocal matchpairs+=⟅:⟆
setlocal matchpairs+=⟦:⟧
setlocal matchpairs+=⟨:⟩
setlocal matchpairs+=⟪:⟫
setlocal matchpairs+=⦃:⦄
setlocal matchpairs+=⦅:⦆
setlocal matchpairs+=⦇:⦈
setlocal matchpairs+=⦉:⦊
setlocal matchpairs+=⦋:⦌
setlocal matchpairs+=⦍:⦎
setlocal matchpairs+=⦏:⦐
setlocal matchpairs+=⦑:⦒
setlocal matchpairs+=⦓:⦔
setlocal matchpairs+=⦕:⦖
setlocal matchpairs+=⦗:⦘
setlocal matchpairs+=⸠:⸡
setlocal matchpairs+=⸢:⸣
setlocal matchpairs+=⸤:⸥
setlocal matchpairs+=⸦:⸧
setlocal matchpairs+=⸨:⸩
setlocal matchpairs+=〈:〉
setlocal matchpairs+=《:》
setlocal matchpairs+=「:」
setlocal matchpairs+=『:』
setlocal matchpairs+=【:】
setlocal matchpairs+=〔:〕
setlocal matchpairs+=〖:〗
setlocal matchpairs+=〘:〙
setlocal matchpairs+=〚:〛
setlocal matchpairs+=︗:︘
setlocal matchpairs+=︵:︶
setlocal matchpairs+=︷:︸
setlocal matchpairs+=︹:︺
setlocal matchpairs+=︻:︼
setlocal matchpairs+=︽:︾
setlocal matchpairs+=︿:﹀
setlocal matchpairs+=﹁:﹂
setlocal matchpairs+=﹃:﹄
setlocal matchpairs+=﹇:﹈
setlocal matchpairs+=﹙:﹚
setlocal matchpairs+=﹛:﹜
setlocal matchpairs+=﹝:﹞
setlocal matchpairs+=（:）
setlocal matchpairs+=＜:＞
setlocal matchpairs+=［:］
setlocal matchpairs+=｛:｝
setlocal matchpairs+=｟:｠
setlocal matchpairs+=｢:｣
let b:undo_ftplugin .= ' | setlocal matchpairs<'

function! s:UsingPython2()
  if has('python3')
    return 0
  endif
  return 1
endfunction

let s:using_python2 = s:UsingPython2()
let s:python_cmd = s:using_python2 ? 'py ' : 'py3 '
let s:python_loadfile = s:using_python2 ? 'pyfile ' : 'py3file '

if has('python') || has('python3')

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

    let &l:statusline = a:name
    if a:append == 'True'
        silent put =a:text
    else
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

execute s:python_loadfile . resolve(expand('<sfile>:p:h') . '/../agda.py')

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

nnoremap <buffer> <LocalLeader>l :AgdaReload<CR>
nnoremap <buffer> <LocalLeader>t :call AgdaInfer()<CR>
nnoremap <buffer> <LocalLeader>r :call AgdaRefine("False")<CR>
nnoremap <buffer> <LocalLeader>R :call AgdaRefine("True")<CR>
nnoremap <buffer> <LocalLeader>g :call AgdaGive()<CR>
nnoremap <buffer> <LocalLeader>c :call AgdaMakeCase()<CR>
nnoremap <buffer> <LocalLeader>a :call AgdaAuto()<CR>
nnoremap <buffer> <LocalLeader>e :call AgdaContext()<CR>
nnoremap <buffer> <LocalLeader>n :call AgdaNormalize("IgnoreAbstract")<CR>
nnoremap <buffer> <LocalLeader>N :call AgdaNormalize("DefaultCompute")<CR>
nnoremap <buffer> <LocalLeader>M :call AgdaShowModule('')<CR>
nnoremap <buffer> <LocalLeader>y :call AgdaWhyInScope('')<CR>
nnoremap <buffer> <LocalLeader>h :call AgdaHelperFunction()<CR>
nnoremap <buffer> <LocalLeader>d :call AgdaGotoAnnotation()<CR>
nnoremap <buffer> <LocalLeader>m :AgdaMetas<CR>

" Show/reload metas
nnoremap <buffer> <C-e> :AgdaMetas<CR>
inoremap <buffer> <C-e> <C-o>:AgdaMetas<CR>

" Go to next/previous meta
nnoremap <buffer> <silent> <C-g>  :let _s=@/<CR>/ {!\\| ?<CR>:let @/=_s<CR>2l
inoremap <buffer> <silent> <C-g>  <C-o>:let _s=@/<CR><C-o>/ {!\\| ?<CR><C-o>:let @/=_s<CR><C-o>2l

nnoremap <buffer> <silent> <C-y>  2h:let _s=@/<CR>? {!\\| \?<CR>:let @/=_s<CR>2l
inoremap <buffer> <silent> <C-y>  <C-o>2h<C-o>:let _s=@/<CR><C-o>? {!\\| \?<CR><C-o>:let @/=_s<CR><C-o>2l

AgdaReload

endif

let &cpo = s:cpo_save
