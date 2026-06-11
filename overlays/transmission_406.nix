# revert to Transmission 4.0.6
_final: prev: {
  transmission_4 =
    prev.callPackage
      (builtins.fetchurl {
        url = "https://raw.githubusercontent.com/NixOS/nixpkgs/48b3a1cabf2a92a4ae6f254ee0c726c0226768d5/pkgs/applications/networking/p2p/transmission/4.nix";
        sha256 = "5c9da7584ad50242ea2619f32deed9eeb166472e1c25026b78e7bffe7ac40f54";
      })
      {
        fmt = prev.fmt_9;
        libutp = prev.libutp_3_4;
      };
}
