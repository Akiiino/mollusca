# nixpkgs ships yafc-ce v2.18.1, which predates Factorio 2.1 support. Upstream
# added 2.1 support in commit 87f5c5b7 ("Add support for Factorio 2.1", #657),
# but that commit also bumped the target framework from net8.0 to net10.0 and is
# not yet in a tagged release. Because buildDotnetModule consumes `dotnet-sdk`
# and `nugetDeps` before the derivation is produced, neither can be changed with
# `overrideAttrs`; switching SDKs and regenerating the NuGet lock requires
# rebuilding the package rather than overriding the nixpkgs one. So this overlay
# replaces yafc-ce with a fresh buildDotnetModule pinned at that commit.
#
# `deps.json` was generated against this exact source with the package's
# `passthru.fetch-deps` script. Regenerate it (and bump rev/hash/version) when
# moving to a newer commit:
#   nix-build -E 'with import <nixpkgs> {}; (callPackage ./yafc-ce.nix {}).fetch-deps' && ./result deps.json
#
# `quality-fix.patch` is *not* upstreamed: upstream's 2.1 support still computes
# the quality-roll distribution with each tier's `next_probability`, but 2.1 set
# every `next_probability` to 1 and moved the per-jump chance to the new
# `chain_probability` field. The unpatched calculation therefore collapses all
# intermediate qualities to 0% and dumps the whole upgrade chance onto the top
# accessible tier (e.g. "Concrete from molten iron" showing only normal +
# legendary at an absurd ratio). The patch reads `chain_probability` (defaulting
# to `next_probability` for pre-2.1 data) and uses next_probability for the first
# jump, then chain_probability for each subsequent jump, matching the game's own
# quality roll. Drop the patch once an equivalent fix lands upstream.
_final: prev:
let
  dotnet = prev.dotnetCorePackages.dotnet_10;
in
{
  yafc-ce = prev.buildDotnetModule (finalAttrs: {
    pname = "yafc-ce";
    version = "2.18.1-unstable-2026-06-26";

    src = prev.fetchFromGitHub {
      owner = "Yafc-CE";
      repo = "yafc-ce";
      rev = "87f5c5b71423c1e1c5083ebb8aeea1610f6f09f9";
      hash = "sha256-VzxoQXhwpsZRXH+AOvuutZsBgY7xNrd/wCcVGiLQd/4=";
    };

    projectFile = [
      "Yafc.I18n.Generator/Yafc.I18n.Generator.csproj"
      "Yafc/Yafc.csproj"
    ];
    testProjectFile = [ "Yafc.Model.Tests/Yafc.Model.Tests.csproj" ];
    nugetDeps = ./deps.json;

    dotnet-sdk = dotnet.sdk;
    dotnet-runtime = dotnet.runtime;

    executables = [ "Yafc" ];

    runtimeDeps = [
      prev.SDL2
      prev.SDL2_ttf
      prev.SDL2_image
    ];

    patches = [ ./quality-fix.patch ];

    postPatch = ''
      # YAFC's TextCache caches each glyph run as an SDL_Texture bound to the
      # renderer that created it (Yafc.UI/ImGui/ImGuiCache.cs, TextCache.Render).
      # It decides whether to regenerate that texture by comparing only the owning
      # DrawingSurface's identity (`texture.surface != surface`), never whether the
      # renderer behind that surface is still the one the texture was made on.
      #
      # UtilityWindowDrawingSurface recreates its software renderer on every window
      # resize (Yafc.UI/Core/WindowUtility.cs, InvalidateRenderer), bumping
      # rendererVersion. Tiling Wayland compositors (niri) resize the window the
      # instant it maps, so by the time text is first drawn every cached texture is
      # already stale. SDL_RenderCopy then silently fails (rc=-1, "Parameter
      # 'texture' is invalid") and no text renders — while fill-rects, icons and
      # freshly-built tooltips, which don't reuse renderer-bound textures, draw fine.
      #
      # TextureHandle already exposes `valid` (surface != null && rendererVersion
      # matches); the render path just never consults it. Add that check so a stale
      # texture is regenerated against the current renderer.
      substituteInPlace Yafc.UI/ImGui/ImGuiCache.cs \
        --replace-fail \
        'if (texture.surface != surface) {' \
        'if (texture.surface != surface || !texture.valid) {'

      # YAFC re-inverts the wheel on SDL_MOUSEWHEEL_FLIPPED, which fights the
      # compositor's natural-scroll direction. SDL3's X11 backend never sets
      # FLIPPED, so this was dormant under XWayland; but its Wayland backend
      # reports niri's natural-scroll touchpad as FLIPPED via wl_pointer v9
      # axis_relative_direction (mouse wheels stay NORMAL). Forcing
      # SDL_VIDEODRIVER=wayland (for HiDPI scaling, see makeWrapperArgs below)
      # therefore made only the touchpad scroll backwards vs every other app.
      # Drop the re-inversion so YAFC follows the compositor's direction
      # (natural touchpad, classic mouse), exactly as it did on XWayland.
      substituteInPlace Yafc.UI/Core/Ui.cs \
        --replace-fail \
        'y = -y;' \
        '_ = y; // do not re-invert FLIPPED: respect the compositor scroll direction'
    '';

    # SDL3 only auto-selects native Wayland over XWayland when the compositor
    # advertises wp_fifo_manager_v1 (SDL_waylandvideo.c, Wayland_IsPreferred),
    # to avoid frame-pacing regressions on GPU-bound apps. niri doesn't expose
    # that protocol, so YAFC lands on XWayland — where it can't read niri's
    # fractional output scale and sizes its whole UI off 96 DPI, i.e. tiny on
    # HiDPI. YAFC has no UI-scale setting (Window.CalculateUnitsToPixels derives
    # everything from SDL_GetDisplayDPI), so the only lever is the backend.
    # Forcing Wayland restores correct scaling; the fifo-v1 rationale is moot
    # for a calculator. --set-default leaves a runtime SDL_VIDEODRIVER override.
    makeWrapperArgs = [
      "--set-default"
      "SDL_VIDEODRIVER"
      "wayland"
    ];

    meta = prev.yafc-ce.meta // {
      mainProgram = "Yafc";
    };
  });
}
