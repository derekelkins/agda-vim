let s:agda_version = [0,0,0,0]

let s:quiet = v:false

function! agda#job#set_version(version)
  let s:agda_version = a:version
endfunction

" define a common interface to differing vim/nvim job control
if has('nvim')
  function! s:interp(on_out, job, dat, ...)
    for l:line in a:dat
      if l:line =~ 'Agda2>.*'
        call AgdaReloadSyntax()
      endif
    endfor
    call a:on_out(a:dat, s:quiet)
  endfunction

  function! s:job_start(cmd, on_out)
    let l:opts = {}
    let l:opts.on_stdout = function('s:interp', [a:on_out])
    let l:opts.on_stderr = function('s:interp', [a:on_out])

    let s:job = jobstart(a:cmd, l:opts)
    return s:job
  endfunction

  function! s:job_send(txt)
    call jobsend(s:job, a:txt)
  endfunction

else " vim 8
  function! s:interp(on_out, job, dat, ...)
    call a:on_out([a:dat], s:quiet)
  endfunction
  function! s:job_start(cmd, on_out)
    let l:opts = {}
    let l:opts.callback = function('s:interp', [a:on_out])

    let s:job = job_start(a:cmd, l:opts)
    if job_status(s:job) == 'fail'
      return -1
    else
      return 1
    endif
  endfunction

  function! s:job_send(txt)
    call ch_sendraw(job_getchannel(s:job), a:txt)
  endfunction
endif

function! agda#job#start(interp)
  if exists('s:job')
    echom 'Agda already started'
    return
  endif

  let l:result = s:job_start(['agda', '--interaction', '--vim'], a:interp)

  if l:result == -1
    echom 'Failed to start agda'
  elseif l:result == 0
    echom 'agda#job#start: invalid arguments'
  endif
endfunction

function! s:escape(arg)
  return escape(a:arg, "\n\r\\'\"\t")
endfunction

function! agda#job#send(arg, quiet)
  let s:quiet = a:quiet
  if !exists('s:job')
    echom 'Agda not started'
    return
  end
  silent! write
  let l:file = s:escape(expand('%'))
  let l:cmd = printf('IOTCM "%s" None Direct (%s)' . "\n", l:file, a:arg)
  call s:job_send(l:cmd)
endfunction

function! agda#job#sendLoadHighlightInfo(file, quiet)
  let l:cmd = printf('Cmd_load_highlighting_info "%s"', s:escape(a:file))
  call agda#job#send(l:cmd, a:quiet)
endfunction

function! agda#job#sendLoad(file, quiet)
  " Pre 2.5
  " l:incpaths_str = join(g:agdavim_agda_includepathlist, ',')
  let l:incpaths_str = '"-i",' . join(g:agdavim_agda_includepathlist, ',"-i",')
  let l:cmd = printf('Cmd_load "%s" [%s]', s:escape(a:file), l:incpaths_str)
  call agda#job#send(l:cmd, a:quiet)
endfunction
