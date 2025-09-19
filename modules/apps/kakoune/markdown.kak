set-option buffer lintcmd "sh -c 'command -v proselint || echo %arg{1}'"
hook buffer BufWritePost .* %{
    lint-buffer
}

map buffer user b ': markdown-surround **<ret>' -docstring 'surround with ** (bold)'
map buffer user i ': markdown-surround _<ret>' -docstring 'surround with _ (italic)'
map buffer user 1 ': markdown-header 1<ret>' -docstring 'set header level 1'
map buffer user 2 ': markdown-header 2<ret>' -docstring 'set header level 2'
map buffer user 3 ': markdown-header 3<ret>' -docstring 'set header level 3'
map buffer user 4 ': markdown-header 4<ret>' -docstring 'set header level 4'
map buffer user 5 ': markdown-header 5<ret>' -docstring 'set header level 5'
map buffer user 6 ': markdown-header 6<ret>' -docstring 'set header level 6'
map buffer user <gt> ': markdown-quote-add<ret>' -docstring 'add blockquote level'
map buffer user <lt> ': markdown-quote-remove<ret>' -docstring 'remove blockquote level'
