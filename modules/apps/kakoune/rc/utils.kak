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
