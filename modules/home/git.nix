{
  config,
  pkgs,
  minor-secrets,
  ...
}:
{
  programs.git = {
    enable = true;
    settings = {
      alias = {
        # Makes a doubled "git git status" work; ! aliases run from the repo
        # root, so cd back to $GIT_PREFIX to keep relative paths working.
        "git" = "! cd -- \${GIT_PREFIX:-.} && git";
        "fpull" = "! f() { git fetch origin \"$1\":\"$1\"; }; f";
        "remote-main" = "! git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@'";
        # move-branch <onto> [branch] [from]: transplant only the branch's own
        # commits (since its merge-base with <from>, default main) onto <onto>.
        "move-branch" =
          "! f() { ONTO=$1 BRANCH=\${2:-$(git branch --show-current)} FROM=\${3:-$(git remote-main)}; git rebase --onto $ONTO $(git merge-base $FROM $BRANCH) $BRANCH; }; f";

        # Claude collaboration: one-time per-repo setup is
        # `git remote add glabrata "$(git claude-url)"`; after that it's all
        # stock git (push/fetch the shared topic branch). Assumes glabrata uses
        # the ~/git/<name> convention; the local clone can live anywhere, its
        # directory basename just has to match.
        "claude-url" = "! echo \"claude@glabrata:git/$(basename \"$(git rev-parse --show-toplevel)\")\"";

        "dft" = "difftool";
        # `git diff`, but side-by-side; takes the same arguments.
        "sdiff" = "! cd -- \${GIT_PREFIX:-.} && git -c delta.side-by-side=true diff";
      };
      user = {
        email = minor-secrets.gitEmail;
        name = "akiiino";
      };
      gitsh.historyFile = config.xdg.stateHome + "/gitsh/history";
      push.default = "current";
      blame.ignoreRevsFile = ".git-blame-ignore-revs";

      # delta renders all diff output (side-by-side via `git sdiff`);
      # difftastic stays opt-in as `git dft` for structural diffs.
      core.pager = "${pkgs.delta}/bin/delta";
      interactive.diffFilter = "${pkgs.delta}/bin/delta --color-only";
      delta = {
        navigate = true;
        line-numbers = true;
      };
      diff.colorMoved = "default";
      diff.tool = "difftastic";
      difftool = {
        prompt = false;
        difftastic.cmd = "${pkgs.difftastic}/bin/difft \"$LOCAL\" \"$REMOTE\"";
      };
      # difft output must not go through delta; page it with plain less.
      pager.difftool = "less -RFX";
    };
  };
  # claude-do is the entry point itself, not a dependency (and claude.kak
  # invokes it from PATH); everything else is baked in by store path above.
  home.packages = [ pkgs.mollusca.claude-do ];
  home.file."${config.programs.git.settings.gitsh.historyFile}/../.keep".text = "";
}
