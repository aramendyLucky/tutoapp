@echo off
:: ============================================================
:: MODULO: start.bat — Lanzador principal TutoApp (Windows)
:: QUE HACE: Instala dependencias la primera vez y arranca el
::           servidor + browser con un doble clic.
:: POR QUE EXISTE: Para que cualquier equipo Windows arranque
::                 el proyecto sin saber Python ni terminales.
:: COMO FUNCIONA:
::   1. Verifica que Python este instalado
::   2. Crea un entorno virtual (venv) la primera vez
::   3. Instala los paquetes en ese venv
::   4. Arranca uvicorn (el servidor web)
::   5. Espera que el servidor este listo (health check)
::   6. Abre el browser en la guia elegida
:: ============================================================
chcp 65001 >nul
cd /d "%~dp0server"

:: ── 1. Verificar Python ──────────────────────────────────────────────────
:: python --version devuelve 0 si esta instalado, errorlevel 1 si no
python --version >nul 2>&1
if errorlevel 1 (
    echo.
    echo  [ERROR] Python no encontrado.
    echo.
    echo  Instala Python 3.11 o superior desde:
    echo  https://www.python.org/downloads/
    echo.
    echo  IMPORTANTE: Durante la instalacion, tilda la casilla
    echo  "Add Python to PATH" antes de hacer clic en Install.
    echo.
    pause
    exit /b 1
)

:: ── 2. Crear entorno virtual la primera vez ──────────────────────────────
:: Un venv es una "caja" aislada de paquetes para este proyecto.
:: Solo se crea una vez; las veces siguientes se salta este paso.
if not exist ".venv" (
    echo Creando entorno virtual por primera vez...
    python -m venv .venv
    if errorlevel 1 (
        echo [ERROR] No se pudo crear el entorno virtual.
        pause
        exit /b 1
    )
)

:: ── 3. Instalar/actualizar dependencias ─────────────────────────────────
:: pip es el gestor de paquetes de Python (como npm para Node).
:: -q = silencioso, solo muestra errores.
echo Instalando dependencias...
.venv\Scripts\pip install -r requirements.txt -q
if errorlevel 1 (
    echo [ERROR] Fallo la instalacion de dependencias.
    pause
    exit /b 1
)

:: ── 4. Copiar .env.example → .env si no existe ──────────────────────────
:: .env guarda configuracion local (como API keys).
:: .env.example es la plantilla publica; .env es la copia privada local.
if not exist ".env" (
    copy .env.example .env >nul
    echo Archivo .env creado desde .env.example
)

:: ── 5. Liberar puerto 8000 si otro proceso lo esta usando ───────────────
:: POR QUE: Si el servidor ya estaba corriendo, el nuevo no puede arrancar
for /f "tokens=5" %%P in ('netstat -ano ^| findstr /R ":8000 " 2^>nul') do (
    taskkill /f /pid %%P >nul 2>&1
)

:: ── 6. Menu de seleccion de guia ─────────────────────────────────────────
cls
echo.
echo  +============================================================+
echo  ^|          TutoApp — Guias interactivas con IA              ^|
echo  +============================================================+
echo.
echo  Que guia queres abrir?
echo.
echo  [1]  AI Coding Tools 2026
echo       Herramientas, comparativas, Ollama local
echo.
echo  [2]  Dev Setup Mac M5  -  De 0 a 100
echo       Homebrew, Docker, Python, PostgreSQL
echo.
echo  [3]  MacBook Pro M5  -  Tips y Atajos
echo       Shortcuts, Terminal, Seguridad
echo.
echo  [4]  Abrir las 3 guias juntas
echo.
echo  [0]  Solo iniciar servidor (sin abrir browser)
echo.
set /p opcion="  Tu eleccion [0-4]: "

:: ── 7. Arrancar servidor en ventana separada ────────────────────────────
:: "start /b" arranca uvicorn en segundo plano dentro de la misma ventana.
:: --host 0.0.0.0 permite acceso desde otros dispositivos en la red local.
echo.
echo  Iniciando servidor en http://localhost:8000 ...
start "TutoApp - Servidor" /min .venv\Scripts\python -m uvicorn main:app --host 0.0.0.0 --port 8000

:: ── 8. Esperar hasta que el servidor responda ────────────────────────────
:: POR QUE: El servidor tarda ~2 segundos en arrancar.
::          Sin esto, el browser abriria antes de que este listo.
:wait_server
timeout /t 1 /nobreak >nul
curl -s http://localhost:8000/api/health >nul 2>&1
if errorlevel 1 goto wait_server

:: ── 9. Abrir browser segun eleccion ─────────────────────────────────────
if "%opcion%"=="1" start "" "http://localhost:8000/ai-coding-tools.html"
if "%opcion%"=="2" start "" "http://localhost:8000/dev-setup-mac-m5.html"
if "%opcion%"=="3" start "" "http://localhost:8000/macbook-pro-m5-guia.html"
if "%opcion%"=="4" (
    start "" "http://localhost:8000/ai-coding-tools.html"
    timeout /t 1 /nobreak >nul
    start "" "http://localhost:8000/dev-setup-mac-m5.html"
    timeout /t 1 /nobreak >nul
    start "" "http://localhost:8000/macbook-pro-m5-guia.html"
)
if "%opcion%"=="0" (
    echo  Servidor corriendo. Abrilo en: http://localhost:8000
)

echo.
echo  +------------------------------------------------------------+
echo  ^|  Servidor activo en http://localhost:8000                 ^|
echo  ^|  Para detenerlo: cerrá la ventana "TutoApp - Servidor"   ^|
echo  +------------------------------------------------------------+
echo.
pause
