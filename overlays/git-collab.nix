# Tooling for the human<->Claude collaboration workflow: working trees travel
# between aspersum and glabrata as disposable "snapshot" commits pushed/fetched
# directly over Tailscale SSH (no GitHub round-trip, no patch files). The
# workflow itself is documented in the CLAUDE.md text in
# machines/glabrata/default.nix; the aspersum-side git aliases live in
# modules/home/git.nix.
final: prev:
let
  # Snapshot commit of the working tree (tracked AND untracked files, honoring
  # .gitignore) built in a throwaway index — no commit, branch, index, or
  # worktree mutation. Named `git-snapshot` so it is also callable as
  # `git snapshot` where it's on PATH (glabrata). Prints the commit sha.
  git-snapshot = final.writeShellApplication {
    name = "git-snapshot";
    runtimeInputs = [
      final.git
      final.coreutils
    ];
    text = ''
      ref="" msg=""
      while [ $# -gt 0 ]; do
        case "$1" in
          --ref) ref=$2; shift 2 ;;
          -m) msg=$2; shift 2 ;;
          *)
            echo "usage: git snapshot [--ref NAME] [-m MESSAGE]" >&2
            exit 64
            ;;
        esac
      done
      git rev-parse --verify -q HEAD >/dev/null || {
        echo "git-snapshot: need a repository with at least one commit" >&2
        exit 1
      }
      [ -n "$msg" ] || msg="snapshot: $(uname -n) $(date -Iseconds)"
      tmpindex=$(mktemp)
      trap 'rm -f "$tmpindex"' EXIT
      GIT_INDEX_FILE="$tmpindex" git read-tree HEAD
      GIT_INDEX_FILE="$tmpindex" git add -A
      tree=$(GIT_INDEX_FILE="$tmpindex" git write-tree)
      commit=$(git commit-tree "$tree" -p HEAD -m "$msg")
      if [ -n "$ref" ]; then
        git update-ref "refs/heads/$ref" "$commit"
      fi
      echo "$commit"
    '';
  };

  # Delegate a task to Claude Code on glabrata without leaving the shell:
  # snapshot-push the working tree, run `claude -p` there (same session pool as
  # interactive use — subscription-covered), fetch the result back as the
  # `for-user` snapshot ref. Only glabrata's clone must live at ~/git/<name>;
  # the local one can be anywhere, its directory basename just has to match.
  claude-do = final.writeShellApplication {
    name = "claude-do";
    runtimeInputs = [
      final.git
      final.openssh
      final.coreutils
      final.jq
      git-snapshot
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
      usage: claude-do [-n|--new] [-i|--interactive] [-k|--keep] [--] [prompt...]

      Delegate a task to Claude Code on glabrata: push your working tree as a
      snapshot (from-user), run claude there against it, fetch the result back
      (for-user). Each run resets glabrata to YOUR current tree (unless -k), so
      review or `git accept` results before delegating again.

        -n  start a new session instead of continuing the most recent one
        -i  attach a full interactive session (TUI over ssh) instead of -p
        -k  keep glabrata's tree: skip the send/catchup step, so Claude keeps
            working on results you haven't accepted yet (review follow-ups)
      EOF
        exit 64
      }

      new=0 interactive=0 keep=0
      while [ $# -gt 0 ]; do
        case "$1" in
          -n | --new) new=1; shift ;;
          -i | --interactive) interactive=1; shift ;;
          -k | --keep) keep=1; shift ;;
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
      url="$host:git/$name"

      sync="git catchup"
      if [ "$keep" = 1 ]; then
        sync="true"
      else
        echo ">> claude-do: sending working tree to $url (from-user)" >&2
        sha=$(git-snapshot)
        git push --force --quiet "$url" "$sha:refs/heads/from-user"
      fi

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
      # not trigger direnv on its own. Keep the stream that reaches the caller
      # (e.g. the *claude* buffer in Kakoune) quiet: the automated catchup's
      # stdout is silenced (errors still surface on stderr and abort the &&
      # chain) and DIRENV_LOG_FORMAT= mutes direnv's loading chatter, so
      # Claude's reply isn't buried under setup noise.
      remote_cmd="cd 'git/$name' && { $sync; } >/dev/null && if [ -e .envrc ]; then exec env DIRENV_LOG_FORMAT= direnv exec . claude $args; else exec claude $args; fi"

      if [ "$interactive" = 1 ]; then
        ssh -t "''${ssh_opts[@]}" "$host" "$remote_cmd" || echo ">> claude-do: remote claude exited nonzero" >&2
      else
        { ssh "''${ssh_opts[@]}" "$host" "$remote_cmd" | fmt_stream; } || echo ">> claude-do: remote claude exited nonzero" >&2
      fi

      echo ">> claude-do: fetching result (for-user)" >&2
      git fetch --quiet "$url" "+for-user:for-user"
      git --no-pager diff --stat for-user^ for-user || true
      cat >&2 <<'EOF'
      >> review:  git diff for-user^ for-user    (:claude-review in kakoune)
      >> apply:   git accept    (applies to worktree; stage + commit yourself)
      EOF
    '';
  };
in
{
  mollusca = (prev.mollusca or { }) // {
    inherit git-snapshot claude-do;
  };
}
