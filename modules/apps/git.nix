{
  config,
  pkgs,
  lib,
  ...
}:
{
  programs.git = {
    enable = true;
    userName = "akiiino";
    userEmail = "git@akiiino.me";
    aliases = {
      "git" = "! cd -- \${GIT_PREFIX:-.} && git";
      "fpull" = "! f() { git fetch origin \"$1\":\"$1\"; }; f";
      "remote-main" = "! git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@'";
      "move-branch" =
        "! f() { ONTO=$1 BRANCH=\${2:-$(git branch --show-current)} FROM=\${3:-$(git remote-main)}; git rebase --onto $ONTO $(git merge-base $FROM $BRANCH) $BRANCH; }; f";
    };
    extraConfig = {
      gitsh.historyFile = config.xdg.stateHome + "/gitsh/history";
      push.default = "current";
      blame.ignoreRevsFile = ".git-blame-ignore-revs";
    };
  };
}
