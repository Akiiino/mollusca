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

## 1. Waybar — configure it properly — DONE

**Problem:** the bar currently runs Waybar's *stock default config* (niri just
`spawn`s `waybar` with no config/style files — see `modules/apps/niri/default.nix`
spawn-at-startup). That's why several modules are mysterious icon+number pairs
you can't interact with — they're the default CPU/memory/temperature/etc.
modules, and the default workspace module isn't even niri-aware.

**Goal:** a functional, thought-out, *legible* config that's also a good base to
tinker with. Nothing fancy.

- [x] Replace the default with an explicit `programs.waybar` config (settings +
      style) in home-manager. Set `systemd.enable = true` and `layer = "top"`.
- [x] Use niri-native modules (`niri/workspaces`, `niri/window`) instead of the
      sway/hyprland defaults. Optional niri extras: niri-taskbar,
      waybar-niri-windows, niri_window_buttons (see refs).
- [x] Otherwise preserve the default module set; list them explicitly.
- [x] Style it: nicer colors + spacing. Waybar colors come from Flexoki-light
      via the upstream port shipped by `inputs.flexoki`
      (`waybar/flexoki-light.css`, same precedent as the qt6ct module), with a
      small structural `waybar-style.css` layered on top.
- [x] Drop the `waybar` spawn-at-startup entry in favor of the
      systemd user service (`programs.waybar.systemd.enable`).

## 2. Sleep / idle — keep swayidle, but configure it *well* — DONE

**Decision:** stay on **swayidle** (it's the right choice on niri — hypridle
misbehaves because niri doesn't implement `hyprland-lock-notify-v1`). Hand-rolling
sleep logic as a *script* is fine; stitching shell fragments through Nix as if
it's a general-purpose language is not (the old `mkTimeout` machinery in
`modules/apps/desktop-shell/default.nix` was exactly the "ossified, afraid to
touch it" trap). Idle inhibition already works (don't re-solve it).

**What landed:** the idle/lock/sleep stack now uses community-standard
primitives instead of hand-rolled shell:
- **`chayang`** for dim-before-lock — a gradual-dim grace-period overlay that
  aborts on input and restores instantly. It never touches the backlight, so the
  "locker resume event fights brightness scripts" gotcha simply doesn't exist
  (no `brightnessctl`, no `video` group, no udev rules). The dim is a *visual
  warning* overlay, which is how item 2 framed it.
- **`systemd-lock-handler`** (`services.systemd-lock-handler.enable` in
  `users/akiiino/desktop.nix`) bridges logind lock/sleep to user systemd targets,
  with **`swaylock` run as a `lock.target`-bound service**. `sleep.target` is
  ordered after `lock.target`, so the machine is provably locked before it
  sleeps — one lock path for manual/idle/lid/sleep.
- **`swayidle`** shrank to *idle timeouts only*, in one legible script
  (`modules/apps/desktop-shell/idle.sh`).
- Latent bug fixed: added `security.pam.services.swaylock` (was absent — the
  classic "swaylock won't accept my password" trap).

- [x] Rework the swayidle config to be legible and maintainable — a readable
      standalone `idle.sh` (timeouts only) plus systemd-lock-handler for the
      lock/unlock/sleep event wiring.
- [x] Add **suspend-then-hibernate**: idle-suspend on battery now calls
      `systemctl suspend-then-hibernate`, with `systemd.sleep.extraConfig`
      `HibernateDelaySec=30min` in `machines/aspersum/default.nix`. The existing
      `rtc_cmos.use_acpi_alarm=1` kernelParam is the RTC wake that fires it
      (mystery resolved; comment updated).
- [x] Add **dim-before-lock** via `chayang` (`chayang -d 10 && loginctl
      lock-session`) — no brightness scripting, so the resume-vs-brightness
      gotcha is sidestepped entirely.
- [x] Keep the AC-vs-battery distinction (don't suspend on AC), expressed
      cleanly in `idle.sh`'s `on_ac` check.

## 3. Theming — DONE

**Decision:** adopt declarative, system-wide theming; use Flexoki-light.
- [x] Start with theming the core apps that are in active use every day:
      Niri, Kitty, Kakoune, Walker, Waybar, Swaylock, Firefox, and GTK+Qt apps.
- [x] Where possible, use popular first- or third-party implementations of
      the theme (as-is or as a base), as opposed to hand-rolling the theming completely.
- [x] Replace pre-existing hardcoded colors with ones derived from the theme.

**Requirement:** avoid Stylix and base16 in general! base16's theme handling is lossy,
and Stylix generally suffers from the "does everything, poorly" problem.

## 4. Wallpaper — DONE
- [x] Set a static wallpaper — no video/parallax needed, rarely changed. Currently
      there's **no wallpaper at all** — blank background. Painted with swaybg
      (`-m fill`) from `users/akiiino/wallpaper.png`, spawned at niri startup.

## 5. Cursor theme/size — DONE
- [x] No problems noticed, but set a proper cursor theme + size while we're here
      (HiDPI 1.75× panel). phinger-cursors (dark variant), size 24 — set via
      `home.pointerCursor` for GTK/XWayland and niri's own `cursor` block.

## 6. Fonts — DONE

~~Set Nokia Sans as a system-wide font~~; keep Iosevka as the monospaced font.

**Requirement changed:** Nokia Sans is owned by Nokia, was never released publicly,
and is not in nixpkgs — only dubious third-party sites host it. mollusca is a public
repo, so shipping an unlicensed font is a non-starter. **Using Inter instead** (SIL OFL,
`pkgs.inter`, well-regarded system UI font). Iosevka stays as monospace.

- [x] Inter as the UI/sans font (`gtk.font` + a user fontconfig `sans-serif` alias);
      `monospace` aliased to Iosevka. kitty already names Iosevka directly.

## 7. Night light — nice-to-have, manually toggleable — DONE

Requirement: **must be manually toggleable in addition to a timer**
(tray icon or a Waybar module), not just a schedule.

**Decision:** `services.gammastep` with `provider = "manual"` (no geoclue) and
`tray = true`, so `gammastep-indicator` lands in the Waybar `tray` module from
item 1 with a native enable/disable/suspend menu — manual toggle + schedule, no
custom scripting. Coords (Berlin, matching `time.timeZone`) and temperatures
(6500K day / 4000K night) are plain data to tune later.

- [x] Add `gammastep` (chose it over `wlsunset` for the built-in tray applet).
- [x] Manual toggle via the `gammastep-indicator` tray icon in Waybar (ties into
      item 1's `tray` module).

## 8. Battery status notifications — DONE

**Problem:** poweralertd works, but produces multiple notifications on every event
(AC power enabled, battery power disabled, battery charging), as well as spams
notifications every few minutes at 100% battery charge (battery charging, battery
stopped charging).

**Decision:** configure properly or replace with a less chatty alternative; the only
notifications that should happen are "battery low", "battery very low", "battery charging",
"battery stopped charging", **without** oscillating between the last two at 100%.

- [x] Replaced poweralertd with **batsignal** (`services.batsignal`). It's
      state-transition based: charging/discharging messages fire only on a plug/unplug
      transition (no 100% flap), and low/very-low fire once each at 15%/5%. Battery
      device auto-discovered (BAT1). Args: `-w 15 -c 5 -p -P Charging -U "On battery" -e`.

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

### Sleep / idle (item 2)
- [Configure Swayidle for Niri (Andrew McCall)](https://andrew-mccall.com/blog/2026/01/configure-swayidle-for-niri-and-noctalia-quickshell/) — niri-specific swayidle writeup.
- [niri lock-notify discussion #3459](https://github.com/niri-wm/niri/discussions/3459) — why swayidle > hypridle on niri.
- [niri idle-inhibit issue #2006](https://github.com/niri-wm/niri/issues/2006) — inhibitor edge case when already locked.
- [NixOS discourse — locker resume vs. brightness gotcha](https://discourse.nixos.org/t/swaylock-and-hyprlock-trigger-idle-resume-event-disrupting-screen-brightness/49958) (relevant to dim-before-lock).
- [Arch wiki — Session lock](https://wiki.archlinux.org/title/Session_lock)
- Modern alternative (not chosen): [Stasis](https://github.com/saltnpepper97/stasis) — media-aware idle manager.

### Fonts (item 6)
- [Nokia Sans](https://www.osnews.com/story/143222/it-turns-out-nokias-legendary-font-makes-for-a-great-general-user-interface-font/)

### Handy niri-ecosystem extras (from awesome-niri, for later tinkering)
- Scratchpad: [niri-scratchpad](https://github.com/gvolpe/niri-scratchpad).
- Session save/restore: [nirinit](https://github.com/amaanq/nirinit).
- Per-keyboard layout: [kunai](https://github.com/mikkurogue/kunai).
