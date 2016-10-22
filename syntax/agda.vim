" File: ~/.vim/syntax/agda.vim

" This is reproduced from 
" http://wiki.portal.chalmers.se/agda/pmwiki.php?n=Main.VIMEditing
" for convenience

if version < 600
    syn clear
elseif exists("b:current_syntax")
    finish
endif

" To tokenize, the best pattern I've found so far is this:
"   (^|\s|[.(){};])@<=token($|\s|[.(){};])@=
" The patterns @<= and @= look behind and ahead, respectively, without matching.

" `agda --vim` extends these groups:
"   agdaConstructor
"   agdaFunction
"   agdaInfixConstructor
"   agdaInfixFunction

syn match   agdaKeywords     "\v(^|\s|[.(){};])@<=(abstract|data|hiding|import|as|infix|infixl|infixr|module|mutual|open|primitive|private|public|record|renaming|rewrite|using|where|with|field|constructor|instance|syntax|pattern|inductive|coinductive)($|\s|[.(){};])@="
syn match   agdaDubious      "\v(^|\s|[.(){};])@<=(postulate|codata)($|\s|[.(){};])@="
syn match   agdaOperator     "\v(^|\s|[.(){};])@<=(let|in|forall|λ|→|-\>|:|∀|\=|\||\\)($|\s|[.(){};])@="
syn match   agdaFunction     "\v(^|\s|[.(){};])@<=(Set[0-9₀-₉]*)($|\s|[.(){};])@="
syn match   agdaNumber       "\v(^|\s|[.(){};])@<=-?[0-9]+($|\s|[.(){};])@="
syn match   agdaCharCode     contained "\\\([0-9]\+\|o[0-7]\+\|x[0-9a-fA-F]\+\|[\"\\'&\\abfnrtv]\|^[A-Z^_\[\\\]]\)"
syn match   agdaCharCode     contained "\v\\(NUL|SOH|STX|ETX|EOT|ENQ|ACK|BEL|BS|HT|LF|VT|FF|CR|SO|SI|DLE|DC1|DC2|DC3|DC4|NAK|SYN|ETB|CAN|EM|SUB|ESC|FS|GS|RS|US|SP|DEL)"
syn match   agdaCharCodeErr  contained "\\&\|'''\+"
syn region  agdaString       start=+"+ skip=+\\\\\|\\"+ end=+"+ contains=agdaCharCode
syn match   agdaHole         "\v(^|\s|[.(){};])@<=(\?)($|\s|[.(){};])@="
syn region  agdaX            matchgroup=agdaHole start="{!" end="!}" contains=ALL
syn match   agdaLineComment  "\v(^|\s|[.(){};])@<=--.*$" contains=@agdaInComment
syn region  agdaBlockComment start="{-"  end="-}" contains=agdaBlockComment,@agdaInComment
syn region  agdaPragma       start="{-#" end="#-}"
syn cluster agdaInComment    contains=agdaTODO,agdaFIXME,agdaXXX
syn keyword agdaTODO         contained TODO
syn keyword agdaFIXME        contained FIXME
syn keyword agdaXXX          contained XXX

hi def link agdaNumber           Number
hi def link agdaString           String
hi def link agdaConstructor      Constant
hi def link agdaCharCode         SpecialChar
hi def link agdaCharCodeErr      Error
hi def link agdaHole             WarningMsg
hi def link agdaDubious          WarningMsg
hi def link agdaKeywords         Structure
hi def link agdaFunction         Macro
hi def link agdaOperator         Operator
hi def link agdaInfixConstructor Operator
hi def link agdaInfixFunction    Operator
hi def link agdaLineComment      Comment
hi def link agdaBlockComment     Comment
hi def link agdaPragma           Comment
hi def      agdaTODO             cterm=bold,underline ctermfg=2 " green
hi def      agdaFIXME            cterm=bold,underline ctermfg=3 " yellow
hi def      agdaXXX              cterm=bold,underline ctermfg=1 " red
