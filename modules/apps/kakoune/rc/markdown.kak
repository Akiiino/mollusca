define-command markdown-surround -params 1 -docstring 'Surround selections with markers' %{
    evaluate-commands -itersel -save-regs '^"' %{
        execute-keys -draft 'Z'
        set-register '"' "%arg{1}%reg{dot}%arg{1}"
        execute-keys 'R'
        execute-keys -draft 'z'
    }
}
define-command markdown-header -params 1 -docstring 'Set header level (1-6) for selected lines' %{
    evaluate-commands -itersel %{
        try %{ execute-keys 'xs^\s*#+\s*<ret>d' }
        evaluate-commands %sh{
            hashes=$(printf '#%.0s' $(seq 1 $1))
            echo "execute-keys 'ghi${hashes} <esc>'"
        }
    }
}

define-command markdown-quote-add -docstring 'Add a level of blockquoting to selected lines' %{
    evaluate-commands -itersel %{
        execute-keys 'xghi> <esc>'
    }
}

define-command markdown-quote-remove -docstring 'Remove a level of blockquoting from selected lines' %{
    evaluate-commands -itersel %{
        try %{ execute-keys 'xs^>\s?<ret>d' }
    }
}

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
