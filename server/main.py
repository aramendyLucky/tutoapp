"""
MÓDULO: TutoApp Backend — Proxy local de IA + servidor estático
QUÉ HACE: Sirve los HTML tutoriales en localhost:8000 y proxea llamadas
          a Claude/Gemini/Ollama para mantener las API keys fuera del browser.
POR QUÉ EXISTE: Los HTML usan Puter.js gratis por defecto, pero cuando el
               usuario quiere Claude o Gemini con su propia key, esta capa
               proxy la guarda de forma segura en .env (nunca en el frontend).
CÓMO SE CONECTA: Los HTML detectan si este servidor está corriendo via
                 GET /api/health y redirigen las llamadas al proveedor
                 seleccionado a través de /api/{proveedor}.
"""

from __future__ import annotations

import json
import logging
import os
from pathlib import Path

import httpx
from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse, StreamingResponse
from fastapi.staticfiles import StaticFiles

load_dotenv()

logging.basicConfig(level=logging.INFO, format="%(levelname)s  %(message)s")
log = logging.getLogger("tutoapp")

ANTHROPIC_KEY: str = os.getenv("ANTHROPIC_API_KEY", "")
GEMINI_KEY: str = os.getenv("GEMINI_API_KEY", "")
OLLAMA_URL: str = os.getenv("OLLAMA_URL", "http://localhost:11434")

app = FastAPI(title="TutoApp Local Backend", version="1.0.0", docs_url="/api/docs")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # solo corre local — no hay riesgo de CORS amplio
    allow_methods=["*"],
    allow_headers=["*"],
)


# ─── HEALTH ──────────────────────────────────────────────────────────────────

@app.get("/api/health")
async def health() -> dict:
    """Endpoint que los HTML consultan al arrancar para detectar si el backend está activo."""
    return {
        "status": "ok",
        "providers": {
            "claude": bool(ANTHROPIC_KEY),
            "gemini": bool(GEMINI_KEY),
            "ollama": True,
        },
    }


# ─── PROXY CLAUDE ─────────────────────────────────────────────────────────────

@app.post("/api/claude")
async def proxy_claude(request: Request) -> StreamingResponse:
    """
    QUÉ HACE: Proxea requests a Anthropic API con la key del .env
    POR QUÉ: La API key nunca queda expuesta en el código del browser
    """
    if not ANTHROPIC_KEY:
        raise HTTPException(400, detail="ANTHROPIC_API_KEY no configurada en .env")

    body = await request.json()
    log.info("Claude proxy → model=%s", body.get("model", "?"))

    async def stream() -> bytes:
        async with httpx.AsyncClient(timeout=120.0) as client:
            async with client.stream(
                "POST",
                "https://api.anthropic.com/v1/messages",
                headers={
                    "x-api-key": ANTHROPIC_KEY,
                    "anthropic-version": "2023-06-01",
                    "content-type": "application/json",
                },
                json=body,
            ) as resp:
                async for chunk in resp.aiter_bytes():
                    yield chunk

    return StreamingResponse(stream(), media_type="text/event-stream")


# ─── PROXY GEMINI ─────────────────────────────────────────────────────────────

@app.post("/api/gemini")
async def proxy_gemini(request: Request) -> StreamingResponse:
    """
    QUÉ HACE: Proxea requests a Google Gemini API con la key del .env
    POR QUÉ: Gemini acepta key como query param — seguro mantenerla en servidor
    """
    if not GEMINI_KEY:
        raise HTTPException(400, detail="GEMINI_API_KEY no configurada en .env")

    body = await request.json()
    model = body.pop("_model", "gemini-2.5-flash")
    log.info("Gemini proxy → model=%s", model)

    async def stream() -> bytes:
        url = (
            f"https://generativelanguage.googleapis.com/v1beta/models"
            f"/{model}:streamGenerateContent?key={GEMINI_KEY}&alt=sse"
        )
        async with httpx.AsyncClient(timeout=120.0) as client:
            async with client.stream("POST", url, json=body) as resp:
                async for chunk in resp.aiter_bytes():
                    yield chunk

    return StreamingResponse(stream(), media_type="text/event-stream")


# ─── PROXY OLLAMA ─────────────────────────────────────────────────────────────

@app.post("/api/ollama")
async def proxy_ollama(request: Request) -> StreamingResponse:
    """
    QUÉ HACE: Proxea requests a Ollama local — elimina problemas de CORS
    POR QUÉ: Ollama corre en :11434 y los HTML en :8000 — CORS bloqueaba
    """
    body = await request.json()
    log.info("Ollama proxy → model=%s", body.get("model", "?"))

    async def stream() -> bytes:
        try:
            async with httpx.AsyncClient(timeout=300.0) as client:
                async with client.stream(
                    "POST",
                    f"{OLLAMA_URL}/api/chat",
                    json=body,
                ) as resp:
                    async for chunk in resp.aiter_bytes():
                        yield chunk
        except httpx.ConnectError:
            err = json.dumps({"error": "Ollama no está corriendo. Ejecutá: ollama serve"})
            yield err.encode()

    return StreamingResponse(stream(), media_type="application/x-ndjson")


# ─── GUARDAR SECCIÓN ─────────────────────────────────────────────────────────

_ALLOWED_FILES = {
    "ai-coding-tools.html",
    "dev-setup-mac-m5.html",
    "macbook-pro-m5-guia.html",
    "tutorial_mac_2026.html",
}


@app.post("/api/save-section")
async def save_section(request: Request) -> dict:
    """
    QUÉ HACE: Inserta HTML nuevo al final de una sección en el archivo fuente.
    POR QUÉ: El DOM se pierde al recargar — esto persiste el contenido en el HTML.
    CÓMO: Busca id="sectionId" en el archivo, localiza su </section> de cierre
          e inserta el nuevo HTML justo antes de él.
    """
    body = await request.json()
    filename: str = body.get("filename", "")
    section_id: str = body.get("sectionId", "")
    html_to_append: str = body.get("htmlToAppend", "")

    if not filename or not section_id or not html_to_append:
        raise HTTPException(400, "Faltan campos: filename, sectionId, htmlToAppend")

    # Seguridad: solo archivos permitidos, sin path traversal
    if filename not in _ALLOWED_FILES:
        raise HTTPException(400, f"Archivo no permitido: {filename}")

    front_dir = Path(__file__).parent.parent / "client"
    filepath = front_dir / filename

    if not filepath.exists():
        raise HTTPException(404, f"Archivo no encontrado: {filename}")

    content = filepath.read_text(encoding="utf-8")

    # Encontrar la sección por su id
    search_str = f'id="{section_id}"'
    idx = content.find(search_str)
    if idx == -1:
        raise HTTPException(404, f"Sección '{section_id}' no encontrada en {filename}")

    # Localizar el </section> de cierre de esta sección
    close_idx = content.find("</section>", idx)
    if close_idx == -1:
        raise HTTPException(500, "No se encontró el cierre </section>")

    # Insertar el HTML nuevo antes del cierre
    new_content = (
        content[:close_idx]
        + "\n\n"
        + html_to_append.strip()
        + "\n\n"
        + content[close_idx:]
    )

    filepath.write_text(new_content, encoding="utf-8")
    log.info("Sección '%s' actualizada en %s (%d chars)", section_id, filename, len(html_to_append))
    return {"status": "ok", "filename": filename, "sectionId": section_id}


# ─── STATIC FILES — debe ir al FINAL para no pisar las rutas /api/ ───────────

_client_dir = Path(__file__).parent.parent / "client"
if _client_dir.exists():
    app.mount("/", StaticFiles(directory=str(_client_dir), html=True), name="static")
    log.info("Sirviendo HTML desde: %s", _client_dir)
else:
    log.warning("No encontré el directorio client/ en: %s", _client_dir)
