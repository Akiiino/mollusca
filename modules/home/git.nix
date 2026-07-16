{
  config,
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
      };
      user = {
        email = minor-secrets.gitEmail;
        name = "akiiino";
      };
      gitsh.historyFile = config.xdg.stateHome + "/gitsh/history";
      push.default = "current";
      blame.ignoreRevsFile = ".git-blame-ignore-revs";
    };
  };
  home.file."${config.programs.git.settings.gitsh.historyFile}/../.keep".text = "";
}
