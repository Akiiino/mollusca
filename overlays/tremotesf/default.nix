# When the user clicks a notification, Tremotesf does not check if it belongs to it
# and tries to get focus

_: prev: {
  tremotesf = prev.tremotesf.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [ ./notifications.patch ];
  });
}
