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
_final: prev: {
  yafc-ce = prev.yafc-ce.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      substituteInPlace Yafc.UI/ImGui/ImGuiCache.cs \
        --replace-fail \
        'if (texture.surface != surface) {' \
        'if (texture.surface != surface || !texture.valid) {'
    '';
  });
}
