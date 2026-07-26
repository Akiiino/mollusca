"""Coalescing brightness daemon for niri.

Reads signed percentage steps, one per line, from a FIFO and applies them to
the focused output: kernel backlight via swayosd for internal panels, DDC/CI
via ddcutil-service for anything else.

The loop is self-clocking rather than timer-based. DDC/CI section 4.4 requires
the host to wait 50ms after a Set VCP Feature command, and libddcutil enforces
that internally (SE_POST_WRITE in tuned_sleep.c), so a synchronous SetVcp
cannot return in under ~50ms no matter how fast the keys arrive. Whatever
queues up during a write is summed into the next one, which bounds us to the
protocol's own write rate without inventing a debounce interval.
"""

import base64
import glob
import json
import logging
import os
import select
import socket
import subprocess
import time

log = logging.getLogger("brightnessd")

# systemd's ListenFIFO hands us the FIFO as fd 3, already opened O_RDWR |
# O_NONBLOCK after an mkfifo and an S_ISFIFO check -- exactly the dance we
# would otherwise write by hand (fifo_address_create in systemd's socket.c).
# O_RDWR is the important part: the pipe always has a reader and a writer, so
# reads never see EOF with no client connected. To run by hand for debugging:
#   3<>"$XDG_RUNTIME_DIR/brightness.fifo" brightnessd
CONTROL_FD = 3

INTERNAL = ("eDP-", "LVDS-", "DSI-")

# How long a cached value is trusted. Not derivable: it is the trade-off
# between a DDC read per keypress and being wrong after someone turns the
# monitor off and on again. The one genuine policy knob left.
STALE_AFTER = 30.0

SVC = "com.ddcutil.DdcutilService"
OBJ = "/com/ddcutil/DdcutilObject"
IFC = "com.ddcutil.DdcutilInterface"

# VESA MCCS feature 0x10, Luminance. A protocol constant, not a tunable, and
# not discoverable: the service can describe a feature code you already know
# (GetVcpMetadata) but cannot tell you which code means "brightness".
LUMINANCE = str(0x10)

# ddcutil-service(1): "When passing an EDID, pass -1 for display_number".
DISPLAY_BY_EDID = "-1"

# Flag bit values are read from the service at runtime, see flag().
FLAGS = {}


class Unavailable(Exception):
    """ddcutil-service is not reachable on the session bus."""


def bus(verb, *args):
    """Call busctl and return the parsed .data, or None.

    Two shapes to keep straight: for `call`, .data is the list of reply
    out-arguments (GetVcp returns five, qqsis); for `get-property` it is the
    value itself. The leading `--` stops getopt from swallowing the -1
    display number as an option.
    """
    cmd = ["busctl", "--user", "--json=short", "--", verb, SVC, OBJ, IFC]
    try:
        proc = subprocess.run(
            cmd + list(args),
            capture_output=True,
            text=True,
            timeout=10,
            check=False,
        )
    except (OSError, subprocess.TimeoutExpired) as err:
        log.debug("busctl %s: %s", verb, err)
        return None
    if proc.returncode != 0:
        log.debug("busctl %s failed: %s", verb, proc.stderr.strip())
        return None
    try:
        return json.loads(proc.stdout)["data"]
    except (ValueError, KeyError):
        return None


def flag(name):
    """Resolve a method flag by name from the service's own flag table.

    ServiceFlagOptions is a{is}, mapping bit value to name, so there is no
    reason to hardcode NO_VERIFY=4 or DETECT_ALL=8. Raises Unavailable rather
    than KeyError: this is called from the error-recovery path, so a dead
    service must not turn a clean no-op into a traceback.
    """
    if not FLAGS:
        table = bus("get-property", "ServiceFlagOptions")
        if not table:
            raise Unavailable(
                "cannot reach ddcutil-service on the session bus -- is it "
                "installed and is its D-Bus activation file registered?"
            )
        FLAGS.update({label: int(bit) for bit, label in table.items()})
    if name not in FLAGS:
        raise Unavailable(f"service does not advertise {name}")
    return str(FLAGS[name])


def edid_of(name):
    """Base64 of the 128-byte EDID base block for a DRM connector.

    ddcutil-service base64-encodes exactly 128 bytes and matches with strcmp,
    so the CTA-861 extension blocks sysfs also hands us must be dropped. Note
    we read the file rather than trusting its size: the DRM edid attribute is
    declared with .size = 0, so stat() always reports zero.
    """
    for path in glob.glob(f"/sys/class/drm/card*-{name}/edid"):
        try:
            with open(path, "rb") as handle:
                raw = handle.read(128)
        except OSError:
            continue
        if len(raw) == 128:
            return base64.b64encode(raw).decode()
    return None


def focused_output():
    """Ask niri which output has focus, over its IPC socket."""
    path = os.environ.get("NIRI_SOCKET")
    if not path:
        log.warning("NIRI_SOCKET unset")
        return None
    try:
        with socket.socket(socket.AF_UNIX) as sock:
            sock.settimeout(1.0)
            sock.connect(path)
            sock.sendall(b'"FocusedOutput"\n')
            buf = b""
            while not buf.endswith(b"\n"):
                chunk = sock.recv(4096)
                if not chunk:
                    return None
                buf += chunk
        output = json.loads(buf)["Ok"]["FocusedOutput"]
    except (OSError, ValueError, KeyError, TypeError) as err:
        log.warning("niri IPC: %s", err)
        return None
    return output["name"] if output else None


def osd(name, *args):
    """Fire the OSD on a specific monitor."""
    try:
        subprocess.run(
            ["swayosd-client", "--monitor", name, *args],
            timeout=5,
            check=False,
        )
    except (OSError, subprocess.TimeoutExpired) as err:
        log.warning("swayosd-client: %s", err)


def state_of(name, cache):
    """(edid, current, maximum, read_at), read from the monitor if stale."""
    entry = cache.get(name)
    if entry and time.monotonic() - entry[3] < STALE_AFTER:
        return entry
    edid = entry[0] if entry else edid_of(name)
    if edid is None:
        return None
    for retry in (False, True):
        if retry:
            # Either a cold service still initialising libddcutil, or the
            # display set changed since its last detect. One re-detect covers
            # both; DETECT_ALL so a sleeping monitor still counts.
            bus("call", "Detect", "u", flag("DETECT_ALL"))
        reply = bus(
            "call",
            "GetVcp",
            "isyu",
            DISPLAY_BY_EDID,
            edid,
            LUMINANCE,
            "0",
        )
        if reply and reply[3] == 0 and reply[1] > 0:
            entry = cache[name] = (edid, reply[0], reply[1], time.monotonic())
            return entry
    cache.pop(name, None)
    return None


def apply(delta, cache):
    """Apply an accumulated percentage delta to the focused output."""
    name = focused_output()
    if not name:
        return
    if name.startswith(INTERNAL):
        osd(name, "--brightness", f"{delta:+d}")
        return

    entry = state_of(name, cache)
    if entry is None:
        return
    edid, cur, top, _ = entry

    # delta is a percentage; VCP 0x10's max is usually 100, but not always.
    step = delta * top // 100 or (1 if delta > 0 else -1)
    new = min(top, max(0, cur + step))
    if new != cur:
        reply = bus(
            "call",
            "SetVcp",
            "isyqu",
            DISPLAY_BY_EDID,
            edid,
            LUMINANCE,
            str(new),
            flag("NO_VERIFY"),
        )
        if not reply or reply[0] != 0:
            cache.pop(name, None)
            return
        cache[name] = (edid, new, top, time.monotonic())
        log.info("%s %+d%% -> %d/%d", name, delta, new, top)
    osd(
        name,
        "--custom-icon",
        "display-brightness-symbolic",
        "--custom-progress",
        f"{new / top:.4f}",
        "--custom-progress-text",
        f"{new * 100 // top}%",
    )


def main():
    logging.basicConfig(
        level=os.environ.get("BRIGHTNESSD_LOG", "INFO"), format="%(message)s"
    )
    fd = CONTROL_FD
    cache = {}
    buf = b""
    complaint = None
    while True:
        select.select([fd], [], [])
        try:
            buf += os.read(fd, 4096)
        except BlockingIOError:
            continue
        *lines, buf = buf.split(b"\n")
        delta = 0
        for line in lines:
            try:
                delta += int(line)
            except ValueError:
                log.warning("ignoring %r", line)
        if delta:
            try:
                apply(delta, cache)
            except Unavailable as err:
                if str(err) != complaint:  # do not spam on every key repeat
                    log.warning("%s", err)
                    complaint = str(err)
            except Exception:
                log.exception("step %+d failed", delta)
            else:
                complaint = None


if __name__ == "__main__":
    main()
