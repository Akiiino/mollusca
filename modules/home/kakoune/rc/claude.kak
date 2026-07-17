# Kakoune side of the Claude collaboration workflow (overlays/git-collab.nix +
# modules/home/git.nix): delegate tasks to Claude Code on glabrata and review
# its results without leaving the editor. Like the :git commands, everything
# here runs relative to the session's cwd, so start kak inside the repo.

declare-user-mode claude
map global user c ': enter-user-mode claude<ret>' -docstring 'Claude mode'
map global claude d ': claude ' -docstring 'delegate task (claude-do)'
map global claude r ': claude-review<ret>' -docstring 'fetch + review latest result'
map global claude c 'o#|<space>' -docstring 'insert review comment below cursor'
map global claude s ': claude-review-send<ret>' -docstring 'send review comments to Claude'

# Stream a claude-do run into the *claude* fifo buffer. $1 is "send" (push the
# working tree and reset glabrata to it first) or "keep" (leave glabrata's tree
# alone — for follow-ups on results not accepted yet); $2 is the prompt.
define-command -hidden claude-run -params 2 %{
    evaluate-commands %sh{
        dir=$(mktemp -d)
        mkfifo "$dir/fifo"
        flag=""
        [ "$1" = keep ] && flag="--keep"
        printf '%s' "$2" >"$dir/prompt"
        ( claude-do $flag -- "$(cat "$dir/prompt")" >"$dir/fifo" 2>&1 ) >/dev/null 2>&1 </dev/null &
        printf 'edit! -fifo %s -scroll *claude*\n' "$dir/fifo"
        printf 'hook -always -once buffer BufCloseFifo .* %%{ nop %%sh{ rm -rf %s } }\n' "$dir"
    }
}

define-command claude -params 1.. -docstring %{
    claude <prompt>: delegate a task to Claude on glabrata (claude-do), prepending cursor context
} %{
    claude-run send %sh{
        printf 'Context: I am looking at %s:%s.' "$kak_buffile" "$kak_cursor_line"
        if [ "${#kak_selection}" -gt 1 ]; then
            printf ' Current selection:\n```\n%s\n```' "$kak_selection"
        fi
        printf '\n\n%s' "$*"
    }
}

define-command claude-review -docstring %{
    claude-review: fetch Claude's latest turn (for-user) and open its diff for review
} %{
    evaluate-commands %sh{
        git fetch "$(git claude-url)" "+for-user:for-user" >/dev/null 2>&1 ||
            echo "fail %{claude-review: fetching for-user failed}"
    }
    edit! -scratch *claude-review*
    execute-keys '%|git --no-pager diff for-user^ for-user<ret>gk'
    set-option buffer filetype diff
    echo -markup "{Information}<ret> jumps to source; comment with 'c' in claude mode; :claude-review-send when done"
}

define-command claude-review-send -docstring %{
    claude-review-send: upload the annotated review to glabrata (~/review.diff) and have Claude address it
} %{
    evaluate-commands %sh{
        [ "$kak_bufname" = "*claude-review*" ] ||
            echo "fail %{claude-review-send: run this from the *claude-review* buffer}"
    }
    execute-keys -draft '%<a-|>ssh claude@glabrata "cat > review.diff"<ret>'
    claude-run keep "Address the review comments in ~/review.diff: every #| line is a review comment about the diff line(s) directly above it. Address each comment, or push back with reasons."
}
