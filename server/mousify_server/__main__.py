"""CLI: python -m mousify_server run|pair|status|selftest

Dev mode (workspace se seedha):
  ~/.local/share/mousify/venv/bin/python -m mousify_server run --dry-run
"""

import argparse
import asyncio
import logging
import sys

from . import __version__, config

log = logging.getLogger("mousify")


def _setup_logging(debug: bool) -> None:
    logging.basicConfig(
        level=logging.DEBUG if debug else logging.INFO,
        format="%(asctime)s %(levelname)-7s %(name)s: %(message)s",
        datefmt="%H:%M:%S",
    )


def cmd_pair(args: argparse.Namespace) -> int:
    code = config.new_pair_code()
    print(f"\n  Pairing code: {code}\n")
    print("  In the phone app: Settings → 'Pair with 6-digit code' — enter it there.")
    print(f"  (Valid for {config.PAIR_CODE_TTL // 60} minutes.)\n")
    print("  Tip: to pair via QR instead: python -m mousify_server qr\n")
    return 0


def cmd_qr(args: argparse.Namespace) -> int:
    """QR code dikhao — token nahi ho to khud bana leta hai (scan = pairing)."""
    from . import qr

    uri = qr.connect_uri(port=args.port)
    if args.save:
        qr.make_png(uri, args.save)
        print(f"QR saved: {args.save}")
        print(f"URI: {uri}")
        return 0
    qr.show(uri)
    return 0


def cmd_manager(args: argparse.Namespace) -> int:
    """Desktop manager GUI (ya CLI flags ke saath)."""
    from . import manager

    return manager.main(args.manager_args)


def cmd_status(args: argparse.Namespace) -> int:
    _setup_logging(args.debug)
    token = config.load_token()
    print(f"version     : {__version__}")
    print(f"config dir  : {config.CONFIG_DIR}")
    print(f"token       : {'set hai' if token else 'set nahi — pehle `pair` chalao'}")
    try:
        import subprocess

        out = subprocess.run(
            ["systemctl", "--user", "is-active", "mousify.service"],
            capture_output=True, text=True,
        ).stdout.strip()
        print(f"systemd     : mousify.service = {out}")
    except Exception:
        pass
    return 0


def cmd_selftest(args: argparse.Namespace) -> int:
    _setup_logging(args.debug)
    from . import keymap
    from .injector import MockInjector
    from .uinput import BTN_LEFT, EV_KEY, EV_REL, REL_WHEEL

    missing = [chr(c) for c in range(32, 127) if chr(c) not in keymap.CHAR_TO_KEY]
    if missing:
        print(f"FAIL: keymap me missing chars: {missing!r}")
        return 1

    mock = MockInjector()
    mock.move(10, -5)
    mock.scroll(2)
    mock.button("left", "click")
    typed, skipped = mock.type_text("Salaam Mousify! test 123 @#%")
    if typed != len("Salaam Mousify! test 123 @#%") or skipped:
        print(f"FAIL: type_text typed={typed} skipped={skipped}")
        return 1

    caps = keymap.capabilities()
    assert BTN_LEFT in caps[EV_KEY]
    assert REL_WHEEL in caps[EV_REL]

    print("selftest OK — keymap, capabilities aur mock injector theek hain.")
    return 0


def cmd_run(args: argparse.Namespace) -> int:
    _setup_logging(args.debug)
    from .injector import Injector, MockInjector
    from .server import MousifyServer

    injector: Injector | MockInjector
    if args.dry_run:
        injector = MockInjector()
    else:
        try:
            injector = Injector()
        except PermissionError:
            log.error(
                "/dev/uinput khul nahi saka — DRY-RUN me chal raha hai. "
                "Asli input ke liye udev rule + input group setup karo (README dekho)."
            )
            injector = MockInjector()
        except FileNotFoundError:
            log.error("/dev/uinput nahi mila — dry-run me chal raha hai.")
            injector = MockInjector()

    advertiser = None
    if not args.no_discovery:
        try:
            from .discovery import Advertiser

            advertiser = Advertiser(port=args.port)
            advertiser.start()
        except Exception:
            log.exception("mDNS advertise fail — phone me manual IP use karo")

    server = MousifyServer(injector, port=args.port)
    try:
        asyncio.run(server.run())
    except KeyboardInterrupt:
        log.info("bye")
    finally:
        if advertiser:
            advertiser.stop()
        injector.close()
    return 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="mousify-server")
    parser.add_argument("--version", action="version", version=__version__)
    sub = parser.add_subparsers(dest="command", required=True)

    p_run = sub.add_parser("run", help="server chalao (default daemon)")
    p_run.add_argument("--port", type=int, default=config.DEFAULT_PORT)
    p_run.add_argument("--dry-run", action="store_true", help="uinput ke bina sirf log karo")
    p_run.add_argument("--no-discovery", action="store_true", help="mDNS advertise band karo")
    p_run.add_argument("--debug", action="store_true")
    p_run.set_defaults(func=cmd_run)

    p_pair = sub.add_parser("pair", help="naya pairing code print karo")
    p_pair.add_argument("--debug", action="store_true")
    p_pair.set_defaults(func=cmd_pair)

    p_qr = sub.add_parser("qr", help="QR code dikhao (scan karke connect)")
    p_qr.add_argument("--port", type=int, default=config.DEFAULT_PORT)
    p_qr.add_argument("--save", metavar="PATH", help="window ke bajaye PNG file me save karo")
    p_qr.set_defaults(func=cmd_qr)

    p_mgr = sub.add_parser("manager", help="desktop manager GUI")
    p_mgr.add_argument("manager_args", nargs=argparse.REMAINDER, help=argparse.SUPPRESS)
    p_mgr.set_defaults(func=cmd_manager)

    p_status = sub.add_parser("status", help="config/service status")
    p_status.add_argument("--debug", action="store_true")
    p_status.set_defaults(func=cmd_status)

    p_test = sub.add_parser("selftest", help="keymap/injector self test")
    p_test.add_argument("--debug", action="store_true")
    p_test.set_defaults(func=cmd_selftest)

    args = parser.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
