# Kakoune side of the Claude collaboration workflow (overlays/git-collab.nix +
# modules/home/git.nix): delegate tasks to Claude Code on glabrata and send it
# prr-style reviews without leaving the editor. Like the :git commands,
# everything here runs relative to the session's cwd, so start kak inside the
# repo.
#
# Reading and navigating Claude's branches is stock git.kak territory —
# :git diff main...add-x (<ret> jumps to source), :git blame, :git apply
# --cached on selections. This file only adds the chat buffer and the
# review-comment round-trip.
#
# *claude* is a persistent, editable chat buffer — a best-effort reconstruction
# of the conversation. Send a message (:claude with cursor context, or
# :claude-send with the selection) and Claude's reply streams in below it; type
# a follow-up in the buffer, select it, :claude-send, and keep going.

declare-user-mode claude
map global user c ': enter-user-mode claude<ret>' -docstring 'Claude mode'
map global claude d ': claude ' -docstring 'delegate task with cursor context (claude-do)'
map global claude m ': claude-send<ret>' -docstring 'send selection as a chat message'
map global claude b ': buffer *claude*<ret>' -docstring 'jump to the *claude* chat buffer'
map global claude r ': claude-review<ret>' -docstring 'open quoted diff for prr-style review'
map global claude s ': claude-review-send<ret>' -docstring 'send review to Claude'

# Path of the fifo backing the current *claude* buffer (set by claude-open).
declare-option -hidden str claude_fifo

# Ensure the persistent *claude* chat buffer exists. A -fifo buffer is a scratch
# buffer Kakoune appends to as data arrives, and it stays open as long as any
# writer holds the fifo — so a `sleep infinity` holder keeps it alive across
# turns (each turn appends without wiping history) while leaving it editable
# between turns. A BufClose hook kills the holder and removes the temp dir.
define-command -hidden claude-open %{
    evaluate-commands %sh{
        case " $kak_buflist " in
            *" *claude* "*) ;;  # already open — nothing to do
            *)
                dir=$(mktemp -d)
                mkfifo "$dir/fifo"
                sleep infinity > "$dir/fifo" &
                hp=$!
                printf 'set-option global claude_fifo %s\n' "$dir/fifo"
                printf 'edit! -fifo %s -scroll *claude*\n' "$dir/fifo"
                printf 'set-option buffer filetype markdown\n'
                printf 'hook -always -once buffer BufClose \\*claude\\* %%{ nop %%sh{ kill %s 2>/dev/null; rm -rf %s } }\n' "$hp" "$dir"
                ;;
        esac
    }
}

# claude-run <flags> <promptfile>: append one turn to the *claude* chat buffer
# and stream claude-do's reply into it. <flags> is passed verbatim to claude-do
# (e.g. "--new" or ""); <promptfile> is a temp file holding the message
# (a file sidesteps re-quoting multi-line prompts back through Kakoune).
define-command -hidden claude-run -params 2 %{
    claude-open
    evaluate-commands %sh{
        fifo=$kak_opt_claude_fifo
        prompt=$(cat "$2")
        printf '\n\n──────── you ────────\n\n%s\n\n──────── claude ────────\n\n' "$prompt" >> "$fifo"
        ( claude-do $1 -- "$prompt" >> "$fifo" 2>&1; rm -f "$2" ) >/dev/null 2>&1 </dev/null &
    }
}

define-command claude -params 1.. -docstring %{
    claude [-n|--new] <prompt>: delegate a task to Claude on glabrata
    (claude-do), prepending cursor context; reply streams into the *claude* buffer
} %{
    evaluate-commands %sh{
        flags=""
        while [ $# -gt 0 ]; do
            case "$1" in
                -n|--new)  flags="$flags --new";  shift ;;
                --) shift; break ;;
                *) break ;;
            esac
        done
        pf=$(mktemp)
        {
            printf 'Context: I am looking at %s:%s.' "$kak_buffile" "$kak_cursor_line"
            [ "${#kak_selection}" -gt 1 ] && printf ' Current selection:\n```\n%s\n```' "$kak_selection"
            printf '\n\n%s' "$*"
        } > "$pf"
        printf "claude-run '%s' '%s'" "$flags" "$pf"
    }
}

define-command claude-send -params 0.. -docstring %{
    claude-send [-n|--new]: send the current selection to Claude as a
    chat message; reply streams into the *claude* chat buffer
} %{
    evaluate-commands %sh{
        flags=""
        while [ $# -gt 0 ]; do
            case "$1" in
                -n|--new)  flags="$flags --new";  shift ;;
                *) break ;;
            esac
        done
        if [ "${#kak_selection}" -le 1 ]; then
            echo 'fail %{claude-send: select the message text to send first}'
        else
            pf=$(mktemp)
            printf '%s' "$kak_selection" > "$pf"
            # If composing in *claude*, drop the raw typed text; claude-run
            # re-adds it under the "you" header, so it is not duplicated.
            [ "$kak_bufname" = "*claude*" ] && printf 'execute-keys d\n'
            printf "claude-run '%s' '%s'" "$flags" "$pf"
        fi
    }
}

define-command claude-review -params .. -docstring %{
    claude-review [<git diff args>]: open the diff (default main...HEAD) in a
    *review* buffer, quoted prr-style, ready for inline comments
} %{
    edit! -scratch *review*
    evaluate-commands %sh{
        args="$*"
        [ -n "$args" ] || args="main...HEAD"
        printf "execute-keys '%%|git --no-pager diff %s | sed \"s/^/> /\"<ret>gk'" "$args"
    }
    echo -markup "{Information}unquoted line(s) under a quoted line = comment; blank line before a quote block = spanned; :claude-review-send when done"
}

define-command claude-review-send -docstring %{
    claude-review-send: upload the review to glabrata (~/reviews/) and have Claude address it
} %{
    evaluate-commands %sh{
        [ "$kak_bufname" = "*review*" ] ||
            echo "fail %{claude-review-send: run this from the *review* buffer}"
    }
    evaluate-commands %sh{
        name=$(basename "$(git rev-parse --show-toplevel)")
        branch=$(git branch --show-current | tr / -)
        path="reviews/$name--${branch:-detached}.prr"
        printf "execute-keys -draft '%%<a-|>ssh claude@glabrata \"cat > %s\"<ret>'\n" "$path"
        pf=$(mktemp)
        printf '%s' "Address the review in ~/$path. It is in prr format: the diff is quoted with \"> \"; unquoted lines are comments on the quoted line(s) directly above; a blank line before a quote block widens the comment to span that whole block; [...] lines are snips of elided context. Commit fixes on the current branch. Address every comment, or push back with reasons." > "$pf"
        printf "claude-run \"\" '%s'\n" "$pf"
    }
}
