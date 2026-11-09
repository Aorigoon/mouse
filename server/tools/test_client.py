#!/usr/bin/env python3
"""Mousify protocol test client — PC par hi (dry-run) server ke against chalao.

Usage:
  ~/.local/share/mousify/venv/bin/python tools/test_client.py [token] [pair_code]
"""

import asyncio
import json
import sys

from websockets.asyncio.client import connect

URI = "ws://127.0.0.1:9898"


async def main() -> None:
    token = sys.argv[1] if len(sys.argv) > 1 else None
    pair_code = sys.argv[2] if len(sys.argv) > 2 else None

    async with connect(URI) as ws:
        hello: dict = {"t": "hello", "name": "test-client"}
        if token:
            hello["token"] = token
        if pair_code:
            hello["pair_code"] = pair_code
        await ws.send(json.dumps(hello))
        print("<<", await ws.recv())

        script = [
            {"t": "ping"},
            {"t": "move", "dx": 15, "dy": -3},
            {"t": "scroll", "dy": 2},
            {"t": "button", "b": "left", "a": "click"},
            {"t": "button", "b": "right", "a": "click"},
            {"t": "key", "k": "enter"},
            {"t": "text", "s": "Salaam from Mousify! @#123"},
            {"t": "text", "s": "Unicode typing test — سلام"},
            {"t": "badtype"},
        ]
        for msg in script:
            await ws.send(json.dumps(msg))
            print(">>", msg)

        try:
            while True:
                reply = await asyncio.wait_for(ws.recv(), timeout=1.5)
                print("<<", reply)
        except asyncio.TimeoutError:
            pass
        print("done.")


if __name__ == "__main__":
    asyncio.run(main())
