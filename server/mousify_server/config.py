"""Paths, port, token aur pairing state."""

import os
import secrets
import time
from pathlib import Path

APP_NAME = "mousify"
DEFAULT_PORT = 9898
SERVICE_TYPE = "_mousify._tcp"
PAIR_CODE_TTL = 300  # seconds

CONFIG_DIR = Path(
    os.environ.get("MOUSIFY_CONFIG_DIR", str(Path.home() / ".config" / "mousify"))
)
TOKEN_FILE = CONFIG_DIR / "token"
PAIR_FILE = CONFIG_DIR / "paircode"


def ensure_config_dir() -> None:
    CONFIG_DIR.mkdir(parents=True, exist_ok=True)


def load_token() -> str | None:
    try:
        tok = TOKEN_FILE.read_text().strip()
        return tok or None
    except FileNotFoundError:
        return None


def save_token(token: str) -> None:
    ensure_config_dir()
    TOKEN_FILE.write_text(token)
    TOKEN_FILE.chmod(0o600)


def new_token() -> str:
    """Naya token banakar save karta hai (QR flow pehli pairing ke liye)."""
    token = secrets.token_hex(16)
    save_token(token)
    return token


def new_pair_code() -> str:
    """Naya 6-digit code banata hai (PAIR_CODE_TTL tak valid) aur file me likhta hai."""
    ensure_config_dir()
    code = f"{secrets.randbelow(1000000):06d}"
    PAIR_FILE.write_text(f"{code} {int(time.time())}")
    return code


def check_pair_code(code: str) -> bool:
    try:
        saved, ts = PAIR_FILE.read_text().split()
    except (FileNotFoundError, ValueError):
        return False
    if time.time() - int(ts) > PAIR_CODE_TTL:
        return False
    return secrets.compare_digest(saved, code.strip())
