"""
FreeModels.Pro → OpenAI-compatible Proxy
Browser-mimics Cloudflare-protected Worker endpoint.
Run: python proxy.py
"""

import asyncio
import json
import os
import time
from contextlib import asynccontextmanager
from typing import AsyncGenerator

import httpx
from fastapi import FastAPI, Request
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
from playwright.async_api import async_playwright


# ─── Config ──────────────────────────────────────────────────────────────
FREEMODELS_CHAT_URL = "https://freemodels.pro/chat/"
WORKER_API_URL = "https://freemodels-chat.freemodels.workers.dev"

MODEL_MAP = {
    # OpenAI-compatible name → freemodels modelId
    "claude-opus-5.5": "claude-opus-5.5",
    "claude-sonnet-5": "claude-sonnet-5",
    "claude-fable-5": "claude-fable-5",
    "claude-fable-5.1": "claude-fable-5.1",
    "gpt-sol": "sol",
    "gpt-terra": "terra",
    "glm-5.2": "glm-5.2",
    "kimi-k3": "kimi-k3",
    "gpt-6-astra": "gpt-6-astra",
    # Aliases
    "claude-opus": "claude-opus-5.5",
    "claude-sonnet": "claude-sonnet-5",
    "claude-fable": "claude-fable-5.1",
    "gpt-fast": "sol",
    "gpt-reasoning": "terra",
}

HEADERS_BASE = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36",
    "Origin": "https://freemodels.pro",
    "Referer": "https://freemodels.pro/chat/",
    "Accept": "text/event-stream",
    "Content-Type": "application/json",
}


# ─── Browser Session Manager ────────────────────────────────────────────
class BrowserSession:
    def __init__(self):
        self.client: httpx.AsyncClient | None = None
        self.browser = None
        self.context = None
        self.page = None
        self.cookies_ready = asyncio.Event()
        self.last_refresh = 0

    async def start(self):
        """Launch headless browser, solve Cloudflare, extract cookies."""
        pw = await async_playwright().start()
        self.browser = await pw.chromium.launch(
            headless=True,
            args=[
                "--disable-blink-features=AutomationControlled",
                "--no-sandbox",
                "--disable-dev-shm-usage",
            ],
        )
        self.context = await self.browser.new_context(
            user_agent=HEADERS_BASE["User-Agent"],
            locale="en-US",
            timezone_id="Asia/Karachi",
        )
        self.page = await self.context.new_page()

        # Stealth: hide webdriver
        await self.page.add_init_script("""
            Object.defineProperty(navigator, 'webdriver', {get: () => undefined});
            window.chrome = {runtime: {}};
        """)

        # Go to chat page, wait for Cloudflare challenge
        print("[proxy] Opening freemodels.pro/chat/ ...")
        await self.page.goto(FREEMODELS_CHAT_URL, wait_until="networkidle", timeout=60000)

        # Wait a bit for cf_clearance to be set
        await asyncio.sleep(3)

        # Extract cookies into httpx client
        cookies = await self.context.cookies()
        cookie_jar = httpx.Cookies()
        for c in cookies:
            cookie_jar.set(c["name"], c["value"], domain=c["domain"], path=c["path"])

        self.client = httpx.AsyncClient(
            headers=HEADERS_BASE,
            cookies=cookie_jar,
            follow_redirects=True,
            timeout=120.0,
        )
        self.last_refresh = time.time()
        self.cookies_ready.set()
        print(f"[proxy] Session ready. Cookies: {len(cookies)}")

    async def ensure_fresh(self):
        """Refresh cookies if older than 10 min or on 403/429."""
        if not self.cookies_ready.is_set():
            await self.cookies_ready.wait()
        if time.time() - self.last_refresh > 600:  # 10 min
            await self.refresh()

    async def refresh(self):
        print("[proxy] Refreshing session...")
        await self.close()
        await self.start()

    async def close(self):
        if self.client:
            await self.client.aclose()
        if self.browser:
            await self.browser.close()
        self.cookies_ready.clear()

    async def post(self, url: str, json: dict, stream: bool = False):
        await self.ensure_fresh()
        if stream:
            return await self.client.stream("POST", url, json=json)
        return await self.client.post(url, json=json)


# ─── FastAPI App ────────────────────────────────────────────────────────
session = BrowserSession()


@asynccontextmanager
async def lifespan(app: FastAPI):
    await session.start()
    yield
    await session.close()


app = FastAPI(title="FreeModels Proxy", lifespan=lifespan)


# ─── OpenAI-compatible models ──────────────────────────────────────────
class ChatMessage(BaseModel):
    role: str
    content: str


class ChatRequest(BaseModel):
    model: str
    messages: list[ChatMessage]
    stream: bool = False
    temperature: float | None = None
    max_tokens: int | None = None


class ChatChoice(BaseModel):
    index: int = 0
    message: ChatMessage
    finish_reason: str = "stop"


class ChatResponse(BaseModel):
    id: str = "chatcmpl-proxy"
    object: str = "chat.completion"
    created: int = int(time.time())
    model: str
    choices: list[ChatChoice]


# ─── Helpers ────────────────────────────────────────────────────────────
def map_model(model: str) -> str:
    return MODEL_MAP.get(model, model)


def to_freemodels_payload(req: ChatRequest) -> dict:
    return {
        "messages": [{"role": m.role, "content": m.content} for m in req.messages],
        "modelId": map_model(req.model),
        "thinking": False,
        "deepSearch": False,
        "stream": req.stream,
    }


def parse_sse_line(line: str) -> dict | None:
    line = line.strip()
    if not line or line == "data: [DONE]":
        return None
    if line.startswith("data: "):
        try:
            return json.loads(line[6:])
        except json.JSONDecodeError:
            return None
    return None


# ─── Endpoints ──────────────────────────────────────────────────────────
@app.get("/health")
async def health():
    return {"status": "ok", "session_ready": session.cookies_ready.is_set()}


@app.get("/v1/models")
async def list_models():
    return {
        "object": "list",
        "data": [
            {"id": k, "object": "model", "owned_by": "freemodels-proxy"}
            for k in MODEL_MAP.keys()
        ],
    }


@app.post("/v1/chat/completions")
async def chat_completions(req: ChatRequest):
    payload = to_freemodels_payload(req)

    if req.stream:
        return StreamingResponse(
            stream_generator(payload),
            media_type="text/event-stream",
            headers={"Cache-Control": "no-cache", "Connection": "keep-alive"},
        )

    # Non-streaming
    resp = await session.post(WORKER_API_URL, payload)
    if resp.status_code in (403, 429):
        await session.refresh()
        resp = await session.post(WORKER_API_URL, payload)

    data = resp.json()
    content = data.get("content") or data.get("message") or ""
    if isinstance(content, dict):
        content = content.get("content", "")

    return ChatResponse(
        model=req.model,
        choices=[ChatChoice(message=ChatMessage(role="assistant", content=content))],
    )


async def stream_generator(payload: dict) -> AsyncGenerator[str, None]:
    resp = await session.post(WORKER_API_URL, payload, stream=True)
    if resp.status_code in (403, 429):
        await session.refresh()
        resp = await session.post(WORKER_API_URL, payload, stream=True)

    async for line in resp.aiter_lines():
        parsed = parse_sse_line(line)
        if parsed is None:
            continue

        # Worker returns: {"choices":[{"delta":{"content":"..."}}]}
        delta = (
            parsed.get("choices", [{}])[0]
            .get("delta", {})
            .get("content", "")
        )
        if delta:
            chunk = {
                "id": f"chatcmpl-{int(time.time()*1000)}",
                "object": "chat.completion.chunk",
                "created": int(time.time()),
                "model": payload.get("modelId", "unknown"),
                "choices": [{"index": 0, "delta": {"content": delta}, "finish_reason": None}],
            }
            yield f"data: {json.dumps(chunk)}\n\n"

    yield "data: [DONE]\n\n"


# ─── Run ────────────────────────────────────────────────────────────────
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000, log_level="info")