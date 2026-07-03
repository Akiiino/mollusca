# aspersum desktop polish — TODO

Working plan for getting `aspersum`'s niri desktop from "usable daily driver" to
"properly polished". Decision taken up front: **stay à-la-carte** (individual,
well-understood tools) rather than adopt an all-in-one Quickshell shell
(DankMaterialShell / Noctalia). DMS was trialed and does too much / hides too
many moving parts. We want to know what every piece does, even at the cost of
missing some conveniences until we get to them.

Priority ordering is rough; items are largely independent unless noted.
See [References](#references) at the bottom for all the config repos, wikis, and
tools gathered during the survey.

---

## 1. Waybar — configure it properly

**Problem:** the bar currently runs Waybar's *stock default config* (niri just
`spawn`s `waybar` with no config/style files — see `modules/apps/niri/default.nix`
spawn-at-startup). That's why several modules are mysterious icon+number pairs
you can't interact with — they're the default CPU/memory/temperature/etc.
modules, and the default workspace module isn't even niri-aware.

**Goal:** a functional, thought-out, *legible* config that's also a good base to
tinker with. Nothing fancy.

- [ ] Replace the default with an explicit `programs.waybar` config (settings +
      style) in home-manager. Set `systemd.enable = true` and `layer = "top"`.
- [ ] Use niri-native modules (`niri/workspaces`, `niri/window`) instead of the
      sway/hyprland defaults. Optional niri extras: niri-taskbar,
      waybar-niri-windows, niri_window_buttons (see refs).
- [ ] Decide the module set deliberately and know what each shows: workspaces,
      window title, clock, tray, audio, network, battery/power-profile,
      backlight, plus a night-light toggle (see item 5). Drop metrics we don't
      actually want.
- [ ] Style it: nicer colors + spacing. **Depends on Stylix (item 4)** — Waybar
      colors come from Stylix's base16 palette. Do the Stylix wiring
      first before deep-styling the bar.
- [ ] Drop the `waybar` spawn-at-startup entry in favor of the
      systemd user service.

## 2. File managers — give Dolphin a proper second try; keep Thunar

**Context:** Keep Thunar available. Dolphin was tried before on niri but
"didn't look right" and didn't pick up file associations — worth doing properly
this time, since the Dolphin niceties (ark archive integration — already
installed! — split view, embedded terminal, service menus) are exactly what's
missing from Thunar.

- [ ] Install Dolphin properly for a Wayland/niri-outside-Plasma environment.
- [ ] Fix the "doesn't look right": Qt/KDE theming outside Plasma (qt platform
      theme, icon theme, color scheme). **Overlaps with Stylix (item 4)** — Stylix
      themes Qt/KDE too, so this may largely fall out of that work.
- [ ] Fix file-type associations: Dolphin uses KDE's mimeapps handling; make sure
      our `xdg.mimeApps` defaults (in `users/akiiino/desktop.nix`) are actually
      honored. Investigate whether the KDE side needs its own config.
- [ ] Keep both installed; leave Thunar as the default `inode/directory` handler
      unless Dolphin proves better, then flip the association.

## 3. Sleep / idle — keep swayidle, but configure it *well*

**Decision:** stay on **swayidle** (it's the right choice on niri — hypridle
misbehaves because niri doesn't implement `hyprland-lock-notify-v1`). Hand-rolling
sleep logic as a *script* is fine; stitching shell fragments through Nix as if
it's a general-purpose language is not (the current `mkTimeout` machinery in
`modules/apps/desktop-shell.nix` is exactly the "ossified, afraid to touch it"
trap). Idle inhibition already works (don't re-solve it).

- [ ] Rework the swayidle config to be legible and maintainable. Prefer a
      readable standalone script (well-commented, one place) over Nix-generated
      shell. Look at how others structure swayidle-for-niri (see refs — the
      Andrew McCall niri+swayidle writeup).
- [ ] Add **suspend-then-hibernate**: currently plain `systemctl suspend`. We
      already have hibernate wired (resumeDevice + resume_offset in
      `machines/aspersum/default.nix`), so switch idle-suspend to
      `systemctl suspend-then-hibernate` and tune `systemd` sleep.conf
      (`HibernateDelaySec`). This is the biggest "feels like a real laptop" win,
      esp. on Framework s2idle drain.
- [ ] Add **dim-before-lock**: a pre-lock timeout that lowers brightness as a
      warning, restored on resume. Mind the known gotcha where the locker's own
      resume event fights brightness scripts (see refs).
- [ ] Keep the AC-vs-battery distinction (don't suspend on AC) but express it
      cleanly.

## 4. Stylix — unified theming (the keystone)

**Decision:** adopt Stylix for declarative, system-wide theming. **IMPORTANT:
light theme, not dark** — pick a light base16 scheme (`polarity = "light"`).
This is the keystone task: it clears several separate papercuts at once and
several other items above depend on it.

- [ ] Wire Stylix (NixOS + home-manager). Choose a light base16 color scheme and
      fonts (we already have Fira Code / Iosevka / Hack Nerd / Noto).
- [ ] Let Stylix theme: GTK, Qt/KDE (helps Dolphin, item 2), swaylock, Waybar
      (coordinate with item 1), terminal (kitty), cursor theme + size, and the
      wallpaper (item 4a).
- [ ] Where makes sense, bring existing hard-coded colors under Stylix's umbrella.

### 4a. Wallpaper (folded into Stylix)
- [ ] Set a static wallpaper via Stylix (no video/parallax needed, rarely
      changed). Currently there's **no wallpaper at all** — blank background.

### 4b. Cursor theme/size (folded into Stylix)
- [ ] No problems noticed, but set a proper cursor theme + size via Stylix while
      we're here (HiDPI 1.75× panel).

## 5. Night light — nice-to-have, manually toggleable

Requirement: **must be manually toggleable in addition to a timer**
(tray icon or a Waybar module), not just a schedule.

- [ ] Add `wlsunset` (schedule/geo-based) or `gammastep`. wlsunset is the simpler
      pick if we just want warm-at-night.
- [ ] Add a manual toggle — a Waybar module or a tray icon (click to toggle on/off /
      cycle) is the natural home, ties into item 1.

## 6. Screenshot annotation / light image editor

**Context:** niri's built-in screenshot flow is fine (interactive, saves +
clipboard). Just want a *lightweight* editor for quick annotation — way lighter
than GIMP (already installed).

- [ ] Add a light raster editor (e.g. Pinta / Drawing).

---

## Already handled / confirmed working (baseline — don't redo)

These came up in the survey and are **done** or confirmed working on the current system:

- **Launcher:** walker + elephant (app search, calc, clipboard history, emoji,
  window switch, niri actions). fuzzel kept as fallback + power-menu dmenu.
- **Notifications:** swaync (notification center, not bare mako).
- **Clipboard history:** done via walker/elephant + wl-clip-persist
  (April deferral — now resolved).
- **Secret service / keyring:** works (Spotify, ProtonVPN save creds; keyring
  unlock prompt appears on first use after auto-login).
- **Polkit agent:** works (GUI password prompts appear, incl. keyring unlock).
  Survey statically flagged "no agent configured" — reality says something
  provides one; not worth chasing.
- **Idle inhibition:** works (video playback inhibits idle).
- **Lock:** swaylock-effects (blur, clock, date).
- **OSD:** swayosd.
- **Media keys:** playerctld.
- **Battery alerts:** poweralertd.


## Config-plumbing notes (low priority)

- We're on **sodiboo/niri-flake** (`inputs.niri`) for the `programs.niri.settings`
  API. The awesome-niri list flags that module as lagging newer niri config
  options vs. the freeform **niri-nix**; niri-flake is normally actively
  maintained, so treat as "verify before trusting" if we ever hit an unsupported
  option — not an action item.

---

## References

Everything useful gathered during the July 2026 survey.

### Niri ecosystem (start here)
- [awesome-niri](https://github.com/niri-wm/awesome-niri) — master curated index
  (bars, shells, idle managers, workspace tools, wallpapers, rices).
- [niri wiki](https://niri-wm.github.io/niri) / [niri wiki — Important Software](https://github.com/niri-wm/niri/wiki)
- [NixOS wiki — Niri](https://wiki.nixos.org/wiki/Niri) — canonical NixOS component checklist.
- [niri Setup Showcase (discussion #325)](https://github.com/niri-wm/niri/discussions/325) — real user configs.
- [OOTB setups list](https://github.com/Vortriz/awesome-niri/discussions/30)

### Reference NixOS + niri configs to steal from
- [louis-thevenet/nixos-config](https://github.com/louis-thevenet/nixos-config) — modular niri + waybar + swaync.
- [Ricardo Fuhrmann — NixOS + Niri + Home Manager writeup](https://blog.ricardof.dev/setting-up-nixos-niri-home-manager/)
- [eduardofuncao/nixferatu](https://github.com/eduardofuncao/nixferatu) — niri + Stylix.
- [Kanjurito/dotfiles](https://github.com/Kanjurito/dotfiles) — niri rice.

### Bars (item 1)
- [Waybar](https://github.com/Alexays/Waybar) — what we're using.
- Niri Waybar modules: [niri-taskbar](https://github.com/LawnGnome/niri-taskbar),
  [waybar-niri-windows](https://github.com/calico32/waybar-niri-windows),
  [niri_window_buttons](https://github.com/adelmonte/niri_window_buttons).
- Alternatives considered: [ashell](https://github.com/MalpenZibo/ashell) (niri-native, ready-to-go),
  [ironbar](https://github.com/JakeStanger/ironbar), [nwg-panel](https://github.com/nwg-piotr/nwg-panel) (GUI config),
  [vibepanel](https://github.com/prankstr/vibepanel).
- [Hyprland wiki — Status bars](https://wiki.hypr.land/Useful-Utilities/Status-Bars/) (general Wayland reference).

### File managers (item 2)
- [Hyprland wiki — File Managers](https://wiki.hypr.land/Useful-Utilities/File-Managers/)
- [NixOS Thunar settings issue #65771](https://github.com/NixOS/nixpkgs/issues/65771) (the xfconf fix).
- [Thunar FAQ — xfconf](https://docs.xfce.org/xfce/thunar/faq)

### Sleep / idle (item 3)
- [Configure Swayidle for Niri (Andrew McCall)](https://andrew-mccall.com/blog/2026/01/configure-swayidle-for-niri-and-noctalia-quickshell/) — niri-specific swayidle writeup.
- [niri lock-notify discussion #3459](https://github.com/niri-wm/niri/discussions/3459) — why swayidle > hypridle on niri.
- [niri idle-inhibit issue #2006](https://github.com/niri-wm/niri/issues/2006) — inhibitor edge case when already locked.
- [NixOS discourse — locker resume vs. brightness gotcha](https://discourse.nixos.org/t/swaylock-and-hyprlock-trigger-idle-resume-event-disrupting-screen-brightness/49958) (relevant to dim-before-lock).
- [Arch wiki — Session lock](https://wiki.archlinux.org/title/Session_lock)
- Modern alternative (not chosen): [Stasis](https://github.com/saltnpepper97/stasis) — media-aware idle manager.

### Theming (item 4)
- [Stylix](https://github.com/nix-community/stylix) — the framework.
- [Stylix — configuration](https://nix-community.github.io/stylix/configuration.html) · [tips & tricks](https://nix-community.github.io/stylix/tricks.html)

### All-in-one shells (surveyed, NOT chosen — kept for reference)
- [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell) — trialed, too much.
- [Noctalia](https://github.com/noctalia-dev/noctalia-shell) — KaOS default niri shell.

### Handy niri-ecosystem extras (from awesome-niri, for later tinkering)
- Scratchpad: [niri-scratchpad](https://github.com/gvolpe/niri-scratchpad). Run-or-raise: [niri-ror](https://github.com/boomskats/niri-ror).
- Session save/restore: [nirinit](https://github.com/amaanq/nirinit). Per-keyboard layout: [kunai](https://github.com/mikkurogue/kunai).
- Auto screen-rotation (if the Framework has the sensor): [iio-niri](https://github.com/Zhaith-Izaliel/iio-niri).
