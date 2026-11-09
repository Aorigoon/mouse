"""Installed apps detect karna (.desktop files), icons PNG me extract, launch.

Scan locations: system + user + flatpak applications dirs.
Icons: PyGObject (GTK IconTheme) se 128px PNG me render karke cache karta hai
(~/.local/share/mousify/icons/<id>.png). PyGObject na mile to path-based icons
hi use hote hain, warna phone fallback letter tile dikhata hai.
"""

import logging
import shutil
import subprocess
from configparser import ConfigParser, DuplicateOptionError
from pathlib import Path

log = logging.getLogger("mousify.apps")

APP_DIRS = [
    Path("/usr/share/applications"),
    Path.home() / ".local/share/applications",
    Path("/var/lib/flatpak/exports/share/applications"),
    Path.home() / ".local/share/flatpak/exports/share/applications",
]

ICON_CACHE = Path.home() / ".local/share/mousify/icons"
ICON_SIZE = 128


class AppEntry:
    __slots__ = ("id", "name", "file", "icon_raw")

    def __init__(self, id: str, name: str, file: Path, icon_raw: str) -> None:
        self.id = id
        self.name = name
        self.file = file
        self.icon_raw = icon_raw


class AppRegistry:
    def __init__(self) -> None:
        self.apps: dict[str, AppEntry] = {}

    # ---- scan ----------------------------------------------------------------
    def scan(self) -> list[AppEntry]:
        self.apps.clear()
        for directory in APP_DIRS:
            if not directory.is_dir():
                continue
            for file in sorted(directory.glob("*.desktop")):
                app_id = file.name
                try:
                    info = self._parse_desktop(file)
                except Exception:
                    continue
                if info is None:
                    continue
                self.apps[app_id] = AppEntry(app_id, info[0], file, info[1])
        # naam se sort (case-insensitive)
        return sorted(self.apps.values(), key=lambda a: a.name.lower())

    @staticmethod
    def _parse_desktop(file: Path) -> tuple[str, str] | None:
        parser = ConfigParser(interpolation=None, strict=False)
        try:
            parser.read(file, encoding="utf-8")
        except Exception:
            return None
        if not parser.has_section("Desktop Entry"):
            return None
        entry = parser["Desktop Entry"]
        if entry.get("Type", "").strip() != "Application":
            return None
        if entry.get("NoDisplay", "false").strip().lower() in ("true", "1"):
            return None
        if entry.get("Hidden", "false").strip().lower() in ("true", "1"):
            return None
        name = (entry.get("Name") or "").strip()
        if not name:
            return None
        icon = (entry.get("Icon") or "").strip()
        return name, icon

    # ---- icons ----------------------------------------------------------------
    def icon_png(self, app_id: str) -> Path | None:
        """App ka 128px PNG return karta hai (cache se, warna render karke)."""
        if not self.apps:
            self.scan()
        entry = self.apps.get(app_id)
        if entry is None:
            return None
        ICON_CACHE.mkdir(parents=True, exist_ok=True)
        cache_file = ICON_CACHE / f"{app_id}.png"
        if cache_file.exists():
            return cache_file
        if not entry.icon_raw:
            return None

        png_path = None
        if entry.icon_raw.startswith("/"):
            png_path = self._pixbuf_to_png(Path(entry.icon_raw), cache_file)
        if png_path is None:
            png_path = self._theme_icon_to_png(entry.icon_raw, cache_file)
        if png_path is None:
            png_path = self._fs_icon_to_png(entry.icon_raw, cache_file)
        return png_path

    @staticmethod
    def _pixbuf_to_png(source: Path, dest: Path) -> Path | None:
        if not source.is_file():
            return None
        try:
            import gi

            gi.require_version("GdkPixbuf", "2.0")
            from gi.repository import GdkPixbuf

            pix = GdkPixbuf.Pixbuf.new_from_file_at_size(
                str(source), ICON_SIZE, ICON_SIZE
            )
            pix.savev(str(dest), "png", [], [])
            return dest
        except Exception:
            return None

    @staticmethod
    def _theme_icon_to_png(icon_name: str, dest: Path) -> Path | None:
        try:
            import gi

            gi.require_version("Gtk", "3.0")
            from gi.repository import Gtk

            theme = Gtk.IconTheme.get_default()
            info = theme.lookup_icon(icon_name, ICON_SIZE, 0)
            if info is None:
                return None
            filename = info.get_filename()
            if not filename:
                return None
            return AppRegistry._pixbuf_to_png(Path(filename), dest)
        except Exception:
            return None

    @staticmethod
    def _fs_icon_to_png(icon_name: str, dest: Path) -> Path | None:
        """Headless fallback — hicolor theme me best-size icon dhoondo."""
        base = Path("/usr/share/icons/hicolor")
        candidates: list[Path] = []
        for size in (128, 256, 512, 96, 72, 64, 48, 32):
            candidates.append(base / f"{size}x{size}/apps/{icon_name}.png")
        candidates.append(base / f"scalable/apps/{icon_name}.svg")
        candidates.append(Path("/usr/share/pixmaps") / f"{icon_name}.png")
        candidates.append(Path("/usr/share/pixmaps") / f"{icon_name}.xpm")
        for c in candidates:
            if c.is_file():
                out = AppRegistry._pixbuf_to_png(c, dest)
                if out:
                    return out
        return None

    # ---- launch ----------------------------------------------------------------
    def launch(self, app_id: str) -> str:
        """App launch/switch. Return: 'focused' (pehle se chal rahi thi) ya 'launched'."""
        entry = self.apps.get(app_id)
        if entry is None:
            return "not-found"
        # pehle: kya ye app pehle se chal rahi hai? (AT-SPI focus switch)
        if self.focus_running_window(entry.name):
            return "focused"
        gio = shutil.which("gio")
        try:
            if gio:
                subprocess.Popen(
                    [gio, "launch", str(entry.file)],
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                    start_new_session=True,
                )
            else:
                # fallback: Exec se (terminal flag ignore karke)
                import shlex

                parser = ConfigParser(interpolation=None, strict=False)
                parser.read(entry.file, encoding="utf-8", errors="ignore")
                exec_line = parser["Desktop Entry"].get("Exec", "")
                cmd = [c for c in shlex.split(exec_line) if not c.startswith("%")]
                if not cmd:
                    return "not-found"
                subprocess.Popen(
                    cmd,
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                    start_new_session=True,
                )
            log.info("launched: %s", app_id)
            return "launched"
        except Exception:
            log.exception("launch fail: %s", app_id)
            return "not-found"

    @staticmethod
    def focus_running_window(app_name: str) -> bool:
        """App pehle se chal rahi ho to uski window par focus la do (AT-SPI)."""
        if not app_name:
            return False
        try:
            import pyatspi
        except ImportError:
            return False
        needle = app_name.strip().lower()
        try:
            desktop = pyatspi.Registry.getDesktop(0)
            for app in desktop:
                try:
                    running_name = (app.name or "").strip().lower()
                    # fuzzy match — dono taraf se
                    if not (
                        needle in running_name or running_name in needle
                    ) or len(running_name) < 4:
                        continue
                    for frame in app:
                        try:
                            frame.queryComponent().grabFocus()
                            log.info(
                                "focused running window: %s (%s)",
                                running_name, app_name,
                            )
                            return True
                        except Exception:
                            continue
                except Exception:
                    continue
        except Exception:
            return False
        return False
