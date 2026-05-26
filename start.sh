#!/bin/bash
# ============================================================
# MODULO: start.sh — Lanzador principal TutoApp (Mac / Linux)
# QUE HACE: Instala dependencias la primera vez y arranca el
#           servidor + browser con un doble clic (o Terminal).
# POR QUE EXISTE: Para que cualquier Mac arranque el proyecto
#                 sin saber Python ni terminales.
# COMO FUNCIONA:
#   1. Verifica que Python3 este instalado
#   2. Crea un entorno virtual (venv) la primera vez
#   3. Instala los paquetes en ese venv
#   4. Arranca uvicorn (el servidor web) en segundo plano
#   5. Espera que el servidor este listo (health check)
#   6. Abre el browser en la guia elegida
# COMO EJECUTARLO:
#   Abrí Terminal, navegá hasta la carpeta del proyecto y corré:
#   chmod +x start.sh   (solo la primera vez, da permiso de ejecucion)
#   ./start.sh
# ============================================================

# "set -e" hace que el script se detenga si cualquier comando falla
set -e

# Ir al directorio donde está este script (aunque se ejecute desde otro lado)
cd "$(dirname "$0")/server"

# ── 1. Verificar Python ──────────────────────────────────────────────────
# En Mac Python se llama "python3", no "python"
if ! command -v python3 &> /dev/null; then
    echo ""
    echo "  [ERROR] Python3 no encontrado."
    echo ""
    echo "  Instala Python 3.11+ desde: https://www.python.org/downloads/"
    echo "  O con Homebrew: brew install python"
    echo ""
    exit 1
fi

PYTHON_CMD="python3"

# ── 2. Crear entorno virtual la primera vez ──────────────────────────────
# Un venv es una "caja" aislada de paquetes para este proyecto.
# Solo se crea una vez; las veces siguientes se salta este paso.
if [ ! -d ".venv" ]; then
    echo "  Creando entorno virtual por primera vez..."
    $PYTHON_CMD -m venv .venv
fi

# ── 3. Instalar dependencias solo si no estan instaladas ────────────────
# POR QUE: pip install siempre contacta PyPI aunque todo este OK,
# lo que puede tardar o parecer colgado con -q (sin output).
if [ ! -f ".venv/bin/uvicorn" ]; then
    echo "  [2/2] Instalando dependencias (puede tardar 1-2 minutos)..."
    .venv/bin/pip install -r requirements.txt
else
    echo "  Dependencias OK."
fi

# ── 4. Copiar .env.example → .env si no existe ──────────────────────────
# .env es la configuracion local (API keys). .env.example es la plantilla publica.
if [ ! -f ".env" ]; then
    cp .env.example .env
    echo "  Archivo .env creado desde .env.example"
fi

# ── 5. Liberar puerto 8000 si otro proceso lo ocupa ─────────────────────
# POR QUE: Si el servidor ya estaba corriendo, el nuevo no puede arrancar
lsof -ti:8000 | xargs kill -9 2>/dev/null || true

# ── 6. Menu de seleccion de guia ────────────────────────────────────────
clear
echo ""
echo "  +============================================================+"
echo "  |          TutoApp — Guias interactivas con IA              |"
echo "  +============================================================+"
echo ""
echo "  Que guia queres abrir?"
echo ""
echo "  [1]  AI Coding Tools 2026"
echo "       Herramientas, comparativas, Ollama local"
echo ""
echo "  [2]  Dev Setup Mac M5  -  De 0 a 100"
echo "       Homebrew, Docker, Python, PostgreSQL"
echo ""
echo "  [3]  MacBook Pro M5  -  Tips y Atajos"
echo "       Shortcuts, Terminal, Seguridad"
echo ""
echo "  [4]  Tutorial Mac 2026"
echo "       Guia completa de configuracion macOS"
echo ""
echo "  [5]  Arquitectura Tecnica"
echo "       Como funciona TutoApp por dentro"
echo ""
echo "  [6]  >>> Abrir las 5 guias juntas <<<"
echo ""
echo "  [0]  Solo iniciar servidor (sin abrir browser)"
echo ""
read -p "  Tu eleccion [0-6]: " opcion

# ── 7. Arrancar servidor en segundo plano ───────────────────────────────
# "&" al final = proceso en segundo plano (no bloquea el script)
# $! = PID del ultimo proceso en segundo plano (para poder matarlo despues)
echo ""
echo "  Iniciando servidor en http://localhost:8000 ..."
.venv/bin/python -m uvicorn main:app --host 0.0.0.0 --port 8000 > /dev/null 2>&1 &
SERVER_PID=$!

# ── 8. Esperar hasta que el servidor responda ────────────────────────────
# POR QUE: El servidor tarda ~2 segundos en arrancar.
#          Sin esto, el browser abriria antes de que este listo.
echo "  Esperando que el servidor este listo..."
until curl -s http://localhost:8000/api/health > /dev/null 2>&1; do
    sleep 1
done

echo "  Servidor listo."

# ── 9. Abrir browser segun eleccion ─────────────────────────────────────
# "open" es el comando de macOS para abrir URLs. En Linux seria "xdg-open"
open_url() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        open "$1"
    else
        xdg-open "$1" 2>/dev/null || echo "  Abri manualmente: $1"
    fi
}

case "$opcion" in
    1) open_url "http://localhost:8000/ai-coding-tools.html" ;;
    2) open_url "http://localhost:8000/dev-setup-mac-m5.html" ;;
    3) open_url "http://localhost:8000/macbook-pro-m5-guia.html" ;;
    4) open_url "http://localhost:8000/tutorial_mac_2026.html" ;;
    5) open_url "http://localhost:8000/arquitectura-tecnica.html" ;;
    6)
        open_url "http://localhost:8000/ai-coding-tools.html"
        sleep 1
        open_url "http://localhost:8000/dev-setup-mac-m5.html"
        sleep 1
        open_url "http://localhost:8000/macbook-pro-m5-guia.html"
        sleep 1
        open_url "http://localhost:8000/tutorial_mac_2026.html"
        sleep 1
        open_url "http://localhost:8000/arquitectura-tecnica.html"
        ;;
    0)
        echo ""
        echo "  Servidor corriendo. Para abrir manualmente:"
        echo "    http://localhost:8000/ai-coding-tools.html"
        echo "    http://localhost:8000/dev-setup-mac-m5.html"
        echo "    http://localhost:8000/macbook-pro-m5-guia.html"
        echo "    http://localhost:8000/tutorial_mac_2026.html"
        echo "    http://localhost:8000/arquitectura-tecnica.html"
        ;;
    *) open_url "http://localhost:8000/ai-coding-tools.html" ;;
esac

echo ""
echo "  +------------------------------------------------------------+"
echo "  |  Servidor activo. PID del proceso: $SERVER_PID             "
echo "  |  Para detenerlo: kill $SERVER_PID                          "
echo "  |  O cerrá esta ventana de Terminal.                        |"
echo "  +------------------------------------------------------------+"
echo ""

# Mantener el script activo para que el servidor no muera al cerrar
# POR QUE: En algunos sistemas, cerrar el script padre mata los hijos
wait $SERVER_PID
