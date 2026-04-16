# For some reason HDR tries to work on my TV, but doesn't,
# so this disables it gamescope-wide.

_: prev: {
  gamescope = prev.gamescope.overrideAttrs (oldAttrs: {
    postPatch = (oldAttrs.postPatch or "") + ''
      substituteInPlace src/Backends/DRMBackend.cpp \
        --replace-fail \
        'm_Mutable.HDR.bExposeHDRSupport = true;' \
        'm_Mutable.HDR.bExposeHDRSupport = false;'
    '';
  });
}
