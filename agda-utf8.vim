let s:cpo_save = &cpo
set cpo&vim

for [sequence, symbol] in items(g:agda#glyphs)
  execute printf('noremap! <buffer> <LocalLeader>%s %s', sequence, symbol)
endfor

" The only mapping that was not prefixed by LocalLeader:
noremap! <buffer> <C-_> →

let &cpo = s:cpo_save