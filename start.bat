@echo off
:: ====================================================================
:: MÓDULO: start.bat — Lanzador principal TutoApp (Windows)
:: QUÉ HACE: Con un doble clic instala dependencias (primera vez) y
::           arranca el servidor local en :8000, luego abre el browser.
:: ARQUITECTURA:
::   - Este .bat corre en la ventana de CMD del usuario.
::   - El servidor uvicorn corre en una ventana separada minimizada.
::   - El browser se abre solo cuando el servidor confirma estar listo.
:: DEPENDENCIAS: Python 3.11+, acceso a internet (pip install).
:: ====================================================================

:: chcp 65001 — fuerza codificación UTF-8 en esta ventana de CMD
:: sin esto, los caracteres especiales (tildes, ñ, etc.) se muestran mal
:: >nul — suprime el mensaje "Página de códigos activa: 65001"
chcp 65001 >nul

:: cd /d "%~dp0server" — navega al directorio server/ donde está main.py
:: %~dp0 = path completo del .bat (incluyendo trailing backslash)
:: /d   = cambia también el drive si fuera necesario (C:, D:, etc.)
:: Esto garantiza que todos los paths relativos (.venv\...) funcionen
:: sin importar desde dónde el usuario ejecutó el .bat.
cd /d "%~dp0server"

:: ════════════════════════════════════════════════════════════════════
:: PASO 1 — Verificar que Python está instalado y accesible en el PATH
:: ════════════════════════════════════════════════════════════════════
:: python --version intenta mostrar "Python X.Y.Z"
:: >nul 2>&1 — suprime stdout Y stderr (evitamos output basura)
:: if errorlevel 1 — se cumple si el exit code es >= 1 (comando no encontrado)
python --version >nul 2>&1
if errorlevel 1 (
    echo.
    echo  [ERROR] Python no encontrado en el PATH.
    echo.
    echo  Instala Python 3.11 o superior desde:
    echo    https://www.python.org/downloads/
    echo.
    echo  IMPORTANTE: durante la instalacion marca la opcion
    echo  "Add Python to PATH" antes de hacer clic en Install.
    echo.
    :: pause — espera que el usuario presione una tecla antes de cerrar
    :: sin esto la ventana se cierra antes de que el usuario lea el error
    pause
    :: exit /b 1 — sale del .bat con código de error 1 (sin cerrar CMD si fue llamado)
    exit /b 1
)

:: ════════════════════════════════════════════════════════════════════
:: PASO 2 — Crear entorno virtual (solo la primera vez)
:: ════════════════════════════════════════════════════════════════════
:: Un venv aísla las dependencias del proyecto del Python global del sistema.
:: Esto evita conflictos de versiones con otros proyectos.
:: ".venv" = carpeta creada en server/.venv/
:: if not exist ".venv" — solo crea si aún no existe (idempotente)
if not exist ".venv" (
    echo.
    echo  [1/2] Creando entorno virtual (solo ocurre la primera vez)...
    :: python -m venv .venv — crea la carpeta con Python aislado + pip
    python -m venv .venv
    if errorlevel 1 (
        echo.
        echo  [ERROR] No se pudo crear el entorno virtual.
        echo  Asegurate de tener Python 3.11+ correctamente instalado.
        pause
        exit /b 1
    )
    echo  Entorno virtual creado OK.
)

:: ════════════════════════════════════════════════════════════════════
:: PASO 3 — Instalar dependencias (solo si uvicorn no existe)
:: ════════════════════════════════════════════════════════════════════
:: Por qué chequeamos uvicorn.exe específicamente:
::   uvicorn es la dependencia "final" — si existe, las demás también están.
::   Esto evita llamar a pip en cada arranque (pip siempre contacta PyPI,
::   lo que es lento y requiere internet aunque todo esté instalado).
:: Si uvicorn.exe no existe = primera instalación o venv corrupto.
if not exist ".venv\Scripts\uvicorn.exe" (
    echo.
    echo  [2/2] Instalando dependencias (puede tardar 1-2 minutos)...
    echo        Paquetes: fastapi, uvicorn, httpx, python-dotenv
    echo.
    :: Usamos la ruta completa al pip del venv (entre comillas por seguridad)
    :: -r requirements.txt — instala todo lo que lista ese archivo
    ".venv\Scripts\pip" install -r requirements.txt
    if errorlevel 1 (
        echo.
        echo  [ERROR] Fallo la instalacion de dependencias.
        echo  Verificá tu conexion a internet e intentalo de nuevo.
        pause
        exit /b 1
    )
    echo.
    echo  Dependencias instaladas correctamente.
)

:: ════════════════════════════════════════════════════════════════════
:: PASO 4 — Crear .env si no existe
:: ════════════════════════════════════════════════════════════════════
:: .env.example es el template con las variables pero sin valores.
:: .env es donde el usuario pone sus API keys reales (nunca va a Git).
:: Si ya existe un .env (sesión anterior), no lo sobreescribimos.
if not exist ".env" (
    if exist ".env.example" (
        :: copy — copia el archivo. >nul suprime "1 archivo(s) copiado(s)"
        copy ".env.example" ".env" >nul
        echo  Archivo .env creado a partir de .env.example
        echo  Podés completar tus API keys en server\.env
    )
)

:: ════════════════════════════════════════════════════════════════════
:: PASO 5 — Liberar el puerto 8000 si está ocupado
:: ════════════════════════════════════════════════════════════════════
:: Por qué: si una sesión anterior quedó colgada, el puerto sigue ocupado
:: y uvicorn fallaría al intentar bindear.
:: Usamos PowerShell en vez de parsear netstat porque:
::   - netstat tiene formato variable (IPv4 vs IPv6, espacios irregulares)
::   - PowerShell Get-NetTCPConnection es más robusto y tipado
:: -NoProfile : no carga el perfil de PowerShell (más rápido)
:: -ErrorAction SilentlyContinue : no falla si el puerto está libre
:: Stop-Process -Force : cierra sin preguntar
echo.
echo  Verificando puerto 8000...
powershell -NoProfile -Command "Get-NetTCPConnection -LocalPort 8000 -ErrorAction SilentlyContinue | ForEach-Object { Write-Host '  Puerto liberado: PID' $_.OwningProcess; Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue }"

:: ════════════════════════════════════════════════════════════════════
:: PASO 6 — Menú de selección de guía
:: ════════════════════════════════════════════════════════════════════
:: cls — limpia la pantalla para que el menú quede centrado y prolijo
cls
echo.
echo  +============================================================+
echo  ^|          TutoApp - Guias interactivas con IA              ^|
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

:: choice — lee UNA tecla sin necesitar Enter (a diferencia de set /p)
:: /C 01234  : teclas válidas, en ese orden exacto
:: /N        : NO imprime la lista "[0,1,2,3,4]?" — la mostramos nosotros arriba
:: /M "..."  : muestra este prompt antes de esperar la tecla
::
:: Mapeo ERRORLEVEL que genera choice /C 01234:
::   Tecla '0' presionada → ERRORLEVEL = 1  (posición 1 en "01234")
::   Tecla '1' presionada → ERRORLEVEL = 2  (posición 2 en "01234")
::   Tecla '2' presionada → ERRORLEVEL = 3  (posición 3 en "01234")
::   Tecla '3' presionada → ERRORLEVEL = 4  (posición 4 en "01234")
::   Tecla '4' presionada → ERRORLEVEL = 5  (posición 5 en "01234")
choice /C 01234 /N /M "  Tu eleccion (presiona 0, 1, 2, 3 o 4): "

:: Guardamos el ERRORLEVEL inmediatamente en una variable.
:: IMPORTANTE: ERRORLEVEL se sobreescribe con cada comando nuevo,
:: por eso hay que capturarlo ahora antes de que cualquier if lo cambie.
set ELECCION=%ERRORLEVEL%

:: ════════════════════════════════════════════════════════════════════
:: PASO 7 — Arrancar uvicorn en ventana separada minimizada
:: ════════════════════════════════════════════════════════════════════
:: start "titulo" /min "programa" argumentos
::   "TutoApp - Servidor" → título de la ventana (aparece en barra de tareas)
::   /min                 → inicia minimizada (no interrumpe al usuario)
::   ".venv\Scripts\python" → Python del venv (entre comillas por si hay espacios)
::   -m uvicorn main:app  → corre uvicorn como módulo de Python
::   --host 0.0.0.0       → escucha en todas las interfaces (LAN + localhost)
::   --port 8000          → puerto que usan los HTML para conectar
echo.
echo  Iniciando servidor en http://localhost:8000 ...
start "TutoApp - Servidor" /min ".venv\Scripts\python" -m uvicorn main:app --host 0.0.0.0 --port 8000

:: ════════════════════════════════════════════════════════════════════
:: PASO 8 — Esperar hasta que el servidor responda en /api/health
:: ════════════════════════════════════════════════════════════════════
:: Por qué esperar: si abrimos el browser antes de que uvicorn esté listo,
:: el browser muestra "conexión rechazada" y el usuario se confunde.
::
:: Lógica: INTENTOS cuenta cuántas veces chequeamos. Máx 30 (≈30 seg).
:: Si pasa de 30, el servidor probablemente falló; mostramos advertencia.
::
:: curl -s             → modo silencioso (no imprime la respuesta)
:: --max-time 2        → timeout de 2 seg por request (no queda colgado)
:: >nul 2>&1          → suprime stdout y stderr
:: if errorlevel 1    → curl retorna 0 si conectó, 7 si "connection refused"
::                       errorlevel 1 = el servidor aún no está listo → reintentar
set INTENTOS=0

:wait_server
:: Incrementar contador de intentos
set /a INTENTOS+=1

:: Si llevamos más de 30 segundos esperando, algo salió mal
if %INTENTOS% GTR 30 (
    echo.
    echo  [ADVERTENCIA] El servidor tarda mas de 30 segundos.
    echo  Es posible que haya un error. Revisa la ventana "TutoApp - Servidor".
    echo  Intentando abrir el browser de todas formas...
    echo.
    goto abrir_browser
)

:: Esperar 1 segundo antes de intentar nuevamente
:: /nobreak — ignora teclas durante la espera (evita saltar el timeout con Enter)
timeout /t 1 /nobreak >nul

:: Probar si el servidor ya responde
curl -s --max-time 2 http://localhost:8000/api/health >nul 2>&1
if errorlevel 1 goto wait_server

:: Llegamos aquí solo si curl retornó 0 = servidor listo
echo  Servidor listo.

:: ════════════════════════════════════════════════════════════════════
:: PASO 9 — Abrir el browser según la elección del usuario
:: ════════════════════════════════════════════════════════════════════
:: Recordar mapeo ERRORLEVEL → tecla → guía:
::   ELECCION 2 → tecla '1' → AI Coding Tools
::   ELECCION 3 → tecla '2' → Dev Setup Mac M5
::   ELECCION 4 → tecla '3' → MacBook Pro M5
::   ELECCION 5 → tecla '4' → las 3 juntas
::   ELECCION 1 → tecla '0' → solo servidor (sin browser)
:abrir_browser
if %ELECCION%==2 (
    :: start "" "url" — abre la URL en el browser predeterminado
    :: Las comillas vacías "" son el "título de ventana" requerido por start
    start "" "http://localhost:8000/ai-coding-tools.html"
)
if %ELECCION%==3 (
    start "" "http://localhost:8000/dev-setup-mac-m5.html"
)
if %ELECCION%==4 (
    start "" "http://localhost:8000/macbook-pro-m5-guia.html"
)
if %ELECCION%==5 (
    :: Abrir las 3 con 1 seg de pausa entre cada una
    :: Sin pausa, algunos browsers las abren en pestañas desordenadas
    start "" "http://localhost:8000/ai-coding-tools.html"
    timeout /t 1 /nobreak >nul
    start "" "http://localhost:8000/dev-setup-mac-m5.html"
    timeout /t 1 /nobreak >nul
    start "" "http://localhost:8000/macbook-pro-m5-guia.html"
)
if %ELECCION%==1 (
    :: Usuario eligió "Solo servidor" — no abrimos browser
    echo  Servidor corriendo. Para abrir manualmente:
    echo    http://localhost:8000/ai-coding-tools.html
    echo    http://localhost:8000/dev-setup-mac-m5.html
    echo    http://localhost:8000/macbook-pro-m5-guia.html
)

:: ════════════════════════════════════════════════════════════════════
:: PASO 10 — Mensaje final con instrucciones para el usuario
:: ════════════════════════════════════════════════════════════════════
echo.
echo  +------------------------------------------------------------+
echo  ^|  Servidor activo en http://localhost:8000                 ^|
echo  ^|                                                           ^|
echo  ^|  Para detenerlo:                                          ^|
echo  ^|    - Cerra la ventana "TutoApp - Servidor"               ^|
echo  ^|    - O presiona Ctrl+C en esa ventana                    ^|
echo  ^|                                                           ^|
echo  ^|  Para acceder desde otro dispositivo en la misma red:    ^|
echo  ^|    Reemplaza localhost con tu IP local (ej: 192.168.x.x) ^|
echo  +------------------------------------------------------------+
echo.
:: pause — mantiene esta ventana abierta hasta que el usuario presione Enter
:: sin esto la ventana se cierra inmediatamente y el usuario no puede leer
pause
