"""mDNS advertise — phone app me PC khud-ba-khud dikh jaye (bonsoir/avahi)."""

import logging
import socket

from zeroconf import ServiceInfo, Zeroconf

from . import config

log = logging.getLogger("mousify.discovery")


def lan_ip() -> str:
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(("10.255.255.255", 1))
        return s.getsockname()[0]
    except OSError:
        return "127.0.0.1"
    finally:
        s.close()


class Advertiser:
    def __init__(self, port: int) -> None:
        self._zc: Zeroconf | None = None
        self._port = port
        self._info: ServiceInfo | None = None

    def start(self) -> None:
        ip = lan_ip()
        host = socket.gethostname()
        self._zc = Zeroconf()
        self._info = ServiceInfo(
            f"{config.SERVICE_TYPE}.local.",
            f"Mousify on {host}.{config.SERVICE_TYPE}.local.",
            addresses=[socket.inet_aton(ip)],
            port=self._port,
            properties={"app": "mousify", "v": "1"},
        )
        self._zc.register_service(self._info)
        log.info("mDNS advertise: 'Mousify on %s' @ %s:%s", host, ip, self._port)

    def stop(self) -> None:
        if self._zc and self._info:
            try:
                self._zc.unregister_service(self._info)
                self._zc.close()
            except Exception:
                pass
            self._zc = None
            self._info = None
