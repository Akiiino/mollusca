# Delegation entry point for the human<->Claude collaboration workflow. Code
# travels as ordinary git commits on shared topic branches, pushed/fetched
# directly between the user's clone and glabrata's over Tailscale SSH (no
# GitHub round-trip); claude-do only carries the conversation. The workflow is
# documented in the CLAUDE.md text in machines/glabrata/default.nix; the
# user-side git setup lives in modules/home/git.nix.
final: prev:
let
  # Delegate a task to Claude Code on glabrata without leaving the shell: run
  # `claude -p` there (same session pool as interactive use —
  # subscription-covered) and stream the reply. Only glabrata's clone must live
  # at ~/git/<name>; the local one can be anywhere, its directory basename just
  # has to match.
  claude-do = final.writeShellApplication {
    name = "claude-do";
    runtimeInputs = [
      final.git
      final.openssh
      final.coreutils
      final.jq
    ];
    # SC2029: expanding $remote_cmd client-side is the whole point.
    # SC2016: the jq formatter program is single-quoted on purpose ($m/$e/$d
    # are jq variables, not shell ones).
    excludeShellChecks = [
      "SC2029"
      "SC2016"
    ];
    text = ''
      usage() {
        cat >&2 <<'EOF'
      usage: claude-do [-n|--new] [-i|--interactive] [--] [prompt...]

      Delegate a task to Claude Code on glabrata: run claude in glabrata's
      clone of the current repo and stream the reply. Code travels separately
      as regular git commits: push first if Claude needs your work
      (`git push glabrata`), fetch afterwards to review Claude's
      (`git fetch glabrata`).

        -n  start a new session instead of continuing the most recent one
        -i  attach a full interactive session (TUI over ssh) instead of -p
      EOF
        exit 64
      }

      new=0 interactive=0
      while [ $# -gt 0 ]; do
        case "$1" in
          -n | --new) new=1; shift ;;
          -i | --interactive) interactive=1; shift ;;
          -h | --help) usage ;;
          --) shift; break ;;
          -*) usage ;;
          *) break ;;
        esac
      done
      prompt="$*"
      if [ "$interactive" = 0 ] && [ -z "$prompt" ]; then
        usage
      fi

      root=$(git rev-parse --show-toplevel)
      name=$(basename "$root")
      host="claude@glabrata"

      cont="--continue"
      [ "$new" = 1 ] && cont=""
      qprompt=""
      [ -n "$prompt" ] && qprompt=$(printf '%q' "$prompt")

      if [ "$interactive" = 1 ]; then
        args="$cont $qprompt"
      else
        # stream-json + partial messages so the reply arrives progressively;
        # --verbose is required for stream-json under -p. fmt_stream renders it.
        args="-p $cont --permission-mode bypassPermissions --output-format stream-json --include-partial-messages --verbose $qprompt"
      fi

      # Bound SSH hangs: probe every 15s, give up after 4 missed probes (~1min),
      # and cap the initial connect at 10s.
      ssh_opts=(-o ServerAliveInterval=15 -o ServerAliveCountMax=4 -o ConnectTimeout=10)

      # Render claude's stream-json events into readable text as they arrive:
      # streamed prose, [thinking] blocks, and ⏺ tool-use markers (with args
      # streamed via input_json_delta). Stateless per line so it stays live;
      # fromjson? tolerates any stray non-JSON line.
      fmt_stream() {
        jq -Rj --unbuffered '
          fromjson? as $m
          | if   $m == null then empty
            elif $m.type == "stream_event" then
              $m.event as $e
              | if   $e.type == "content_block_start" then
                  ( $e.content_block.type ) as $t
                  | if   $t == "thinking" then "\n\n[thinking] "
                    elif $t == "tool_use" then "\n⏺ " + ( $e.content_block.name // "tool" ) + " "
                    else "\n\n" end
                elif $e.type == "content_block_delta" then
                  ( $e.delta ) as $d
                  | if   $d.type == "text_delta"       then $d.text
                    elif $d.type == "thinking_delta"   then $d.thinking
                    elif $d.type == "input_json_delta" then $d.partial_json
                    else "" end
                else "" end
            elif $m.type == "result" then
              ( if $m.is_error then "\n[error] " + ( $m.result // "" ) else "" end ) + "\n"
            else "" end
        '
      }
      # Run claude through the repo's direnv devshell when there is one (hooks
      # on glabrata expect its env, e.g. NIX_CONFIG); non-interactive ssh does
      # not trigger direnv on its own. DIRENV_LOG_FORMAT= mutes direnv's
      # loading chatter, so Claude's reply (e.g. in the *claude* buffer in
      # Kakoune) isn't buried under setup noise.
      remote_cmd="cd 'git/$name' && if [ -e .envrc ]; then exec env DIRENV_LOG_FORMAT= direnv exec . claude $args; else exec claude $args; fi"

      if [ "$interactive" = 1 ]; then
        ssh -t "''${ssh_opts[@]}" "$host" "$remote_cmd" || echo ">> claude-do: remote claude exited nonzero" >&2
      else
        { ssh "''${ssh_opts[@]}" "$host" "$remote_cmd" | fmt_stream; } || echo ">> claude-do: remote claude exited nonzero" >&2
      fi
    '';
  };
in
{
  mollusca = (prev.mollusca or { }) // {
    inherit claude-do;
  };
}
