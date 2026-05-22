@echo off
:: ====================================================================
:: MODULO: start.bat -- Lanzador TutoApp (Windows)
:: QUE HACE: Instala dependencias la primera vez y arranca el servidor
::           FastAPI en localhost:8000, luego abre las guias en el
::           browser segun la eleccion del usuario.
:: POR QUE EXISTE: Punto de entrada unico para usuarios no tecnicos --
::                 doble clic y todo funciona sin tocar la terminal.
:: ENCODING: ASCII puro -- SIN Unicode, SIN tildes, SIN caja dibujada.
::           Los caracteres especiales (=, -, |, +, *) no necesitan
::           chcp ni escaping, garantizando compatibilidad total.
:: DEPENDENCIAS: Python 3.11+, curl (incluido en Windows 10/11).
:: ARQUITECTURA:
::   start.bat (esta ventana)
::     --> server/.venv/Scripts/uvicorn.exe (ventana minimizada)
::     --> browser (abre las guias cuando el servidor esta listo)
:: ====================================================================

:: chcp 65001 -- fuerza UTF-8 en esta consola CMD.
:: >nul -- suprime el mensaje "Pagina de codigos activa: 65001".
:: Se pone ANTES de cualquier echo para que los paths con acentos
:: (si los hay) se muestren correctamente.
chcp 65001 >nul

:: cd /d "%~dp0server" -- navega al directorio server/ donde esta main.py.
:: %~dp0 = path absoluto del .bat con trailing backslash.
:: /d    = cambia de unidad si el .bat esta en otro disco (D:, E:, etc.).
:: Esto garantiza que ".venv\..." resuelva correctamente sin importar
:: desde donde el usuario ejecuto el .bat.
cd /d "%~dp0server"

:: ====================================================================
:: PASO 1 -- Verificar que Python esta instalado y en el PATH
:: ====================================================================
:: python --version >nul 2>&1 -- corre python en modo silencioso.
:: Si Python no esta en el PATH, el comando falla y errorlevel queda en 1.
:: errorlevel 1 se cumple si el exit code es >= 1 (falla o no encontrado).
python --version >nul 2>&1
if errorlevel 1 (
    echo.
    echo  [ERROR] Python no encontrado en el PATH.
    echo.
    echo  Instala Python 3.11+ desde:
    echo    https://www.python.org/downloads/
    echo.
    echo  IMPORTANTE: durante la instalacion marca la opcion
    echo  "Add Python to PATH" antes de hacer clic en Install.
    echo.
    pause
    exit /b 1
)

:: ====================================================================
:: PASO 2 -- Crear entorno virtual (solo la primera vez)
:: ====================================================================
:: Un venv aisla las dependencias del proyecto del Python global.
:: Si ya existe .venv, este bloque se salta completamente (idempotente).
if not exist ".venv" (
    echo.
    echo  [Setup 1/2] Creando entorno virtual en server/.venv ...
    echo              Solo ocurre la primera vez.
    python -m venv .venv
    if errorlevel 1 (
        echo.
        echo  [ERROR] No se pudo crear el entorno virtual.
        echo  Asegurate de tener Python 3.11+ correctamente instalado.
        pause
        exit /b 1
    )
    echo  Entorno virtual creado.
)

:: ====================================================================
:: PASO 3 -- Instalar dependencias (solo si uvicorn no existe)
:: ====================================================================
:: Por que chequear uvicorn.exe especificamente:
::   Es la dependencia "final" -- si existe, las demas tambien estan.
::   Evita llamar a pip en cada arranque (pip contacta PyPI aunque todo
::   este instalado, lo que es lento y requiere internet innecesariamente).
:: Si no existe = primera instalacion o venv corrupto.
if not exist ".venv\Scripts\uvicorn.exe" (
    echo.
    echo  [Setup 2/2] Instalando dependencias (1-2 minutos la primera vez)...
    echo              Paquetes: fastapi, uvicorn, httpx, python-dotenv
    echo.
    ".venv\Scripts\pip" install -r requirements.txt
    if errorlevel 1 (
        echo.
        echo  [ERROR] Fallo la instalacion de dependencias.
        echo  Verifica tu conexion a internet e intenta de nuevo.
        pause
        exit /b 1
    )
    echo.
    echo  Dependencias instaladas correctamente.
)

:: ====================================================================
:: PASO 4 -- Crear .env si no existe
:: ====================================================================
:: .env.example = template con variables sin valores (va a Git).
:: .env         = API keys reales del usuario (nunca va a Git).
:: Si ya existe un .env (sesion anterior), NO lo sobreescribimos.
if not exist ".env" (
    if exist ".env.example" (
        copy ".env.example" ".env" >nul
        echo.
        echo  Archivo .env creado desde .env.example.
        echo  Podes completar tus API keys en server\.env
    )
)

:: ====================================================================
:: PASO 5 -- Liberar el puerto 8000 si esta ocupado
:: ====================================================================
:: Por que: si una sesion anterior quedo colgada, el puerto sigue
:: ocupado y uvicorn fallaria al intentar bindear.
:: PowerShell Get-NetTCPConnection es mas robusto que parsear netstat.
:: -NoProfile       : no carga el perfil de PS (mas rapido)
:: -ErrorAction ... : no falla si el puerto esta libre
:: Stop-Process -Force : cierra sin preguntar
echo.
echo  Verificando puerto 8000...
powershell -NoProfile -Command "Get-NetTCPConnection -LocalPort 8000 -ErrorAction SilentlyContinue | ForEach-Object { Write-Host '  Puerto 8000 liberado: PID ' $_.OwningProcess; Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue }"

:: ====================================================================
:: PASO 6 -- Menu de seleccion (ASCII puro, sin Unicode)
:: ====================================================================
:: cls -- limpia la pantalla para que el menu se vea centrado y prolijo.
cls
echo.
echo.
echo    ___________________________________________________
echo   /                                                   \
echo   ^|      ***  T U T O A P P   v2.0  ***             ^|
echo   ^|      Guias Interactivas con Inteligencia         ^|
echo   ^|      Artificial  --  Python + FastAPI            ^|
echo   \___________________________________________________/
echo.
echo   +===================================================+
echo   ^|   Que guia queres abrir?                        ^|
echo   +===================================================+
echo   ^|                                                  ^|
echo   ^|   [1]  AI Coding Tools 2026                     ^|
echo   ^|        Herramientas, IA comparativa, Ollama      ^|
echo   ^|                                                  ^|
echo   ^|   [2]  Dev Setup Mac M5  --  De 0 a 100        ^|
echo   ^|        Homebrew, Docker, Python, PostgreSQL      ^|
echo   ^|                                                  ^|
echo   ^|   [3]  MacBook Pro M5  --  Tips y Atajos       ^|
echo   ^|        Shortcuts, Terminal, Seguridad            ^|
echo   ^|                                                  ^|
echo   ^|   [4]  Tutorial Mac 2026                        ^|
echo   ^|        Guia completa de configuracion            ^|
echo   ^|                                                  ^|
echo   ^|   [5]  ^>^>^> Abrir las 4 guias juntas ^<^<^<       ^|
echo   ^|                                                  ^|
echo   ^|   [0]  Solo iniciar servidor (sin browser)      ^|
echo   ^|                                                  ^|
echo   +===================================================+
echo.

:: choice /C 012345 -- lee UNA tecla sin necesitar Enter.
:: /N  -- no imprime la lista "[0,1,2,3,4,5]?" automaticamente.
:: /M  -- muestra este prompt antes de esperar la tecla.
::
:: Mapeo ERRORLEVEL que genera choice /C 012345:
::   Tecla '0' -> ERRORLEVEL 1   (posicion 1 en la cadena "012345")
::   Tecla '1' -> ERRORLEVEL 2   (posicion 2)
::   Tecla '2' -> ERRORLEVEL 3   (posicion 3)
::   Tecla '3' -> ERRORLEVEL 4   (posicion 4)
::   Tecla '4' -> ERRORLEVEL 5   (posicion 5)
::   Tecla '5' -> ERRORLEVEL 6   (posicion 6)
choice /C 012345 /N /M "   Tu eleccion (presiona 0, 1, 2, 3, 4 o 5): "

:: Capturar ERRORLEVEL inmediatamente en una variable.
:: CRITICO: ERRORLEVEL se sobreescribe con CADA comando (incluso los if).
:: Por eso lo guardamos aqui antes de que cualquier if lo cambie.
set ELECCION=%ERRORLEVEL%

:: ====================================================================
:: PASO 7 -- Arrancar uvicorn en ventana separada minimizada
:: ====================================================================
:: start "titulo" /min "programa" argumentos
::   "TutoApp - Servidor" -> titulo visible en la barra de tareas
::   /min                 -> inicia minimizada (no interrumpe al usuario)
::   ".venv\Scripts\python" -> Python del venv (comillas por si hay espacios)
::   -m uvicorn main:app  -> corre uvicorn como modulo de Python
::   --host 0.0.0.0       -> escucha en todas las interfaces (LAN + localhost)
::   --port 8000          -> puerto que usan los HTML para conectar
echo.
echo  Iniciando servidor en http://localhost:8000 ...
start "TutoApp - Servidor" /min ".venv\Scripts\python" -m uvicorn main:app --host 0.0.0.0 --port 8000

:: ====================================================================
:: PASO 8 -- Esperar hasta que el servidor responda en /api/health
:: ====================================================================
:: Por que esperar: si abrimos el browser antes de que uvicorn este listo,
:: el browser muestra "conexion rechazada" y el usuario se confunde.
::
:: Logica:
::   INTENTOS cuenta cuantas veces chequeamos. Maximo 30 (~30 seg).
::   Si supera 30, el servidor probablemente fallo -- mostramos aviso.
::   curl -s --max-time 2: silencioso, timeout 2s, retorna 0 si ok.
::   errorlevel 1: curl retorna 7 si "connection refused" -> reintentar.
set INTENTOS=0

:wait_server
set /a INTENTOS+=1

if %INTENTOS% GTR 30 (
    echo.
    echo  [AVISO] El servidor tarda mas de 30 segundos.
    echo  Si hay un error, revisa la ventana "TutoApp - Servidor".
    echo  Intentando abrir el browser de todas formas...
    echo.
    goto abrir_browser
)

:: timeout /t 1 /nobreak -- espera 1 segundo sin capturar teclas
timeout /t 1 /nobreak >nul

:: Verificar si el servidor ya responde
curl -s --max-time 2 http://localhost:8000/api/health >nul 2>&1
if errorlevel 1 goto wait_server

echo  Servidor listo.

:: ====================================================================
:: PASO 9 -- Abrir browser segun la eleccion del usuario
:: ====================================================================
:: Recordar mapeo ELECCION (= ERRORLEVEL capturado de choice):
::   ELECCION 2 -> tecla '1' -> AI Coding Tools 2026
::   ELECCION 3 -> tecla '2' -> Dev Setup Mac M5
::   ELECCION 4 -> tecla '3' -> MacBook Pro M5
::   ELECCION 5 -> tecla '4' -> Tutorial Mac 2026
::   ELECCION 6 -> tecla '5' -> las 4 juntas
::   ELECCION 1 -> tecla '0' -> solo servidor (sin browser)
:abrir_browser
if %ELECCION%==2 (
    start "" "http://localhost:8000/ai-coding-tools.html"
)
if %ELECCION%==3 (
    start "" "http://localhost:8000/dev-setup-mac-m5.html"
)
if %ELECCION%==4 (
    start "" "http://localhost:8000/macbook-pro-m5-guia.html"
)
if %ELECCION%==5 (
    start "" "http://localhost:8000/tutorial_mac_2026.html"
)
if %ELECCION%==6 (
    :: Abrir las 4 con 1 seg de pausa entre cada una.
    :: Sin pausa, algunos browsers las abren en orden incorrecto.
    start "" "http://localhost:8000/ai-coding-tools.html"
    timeout /t 1 /nobreak >nul
    start "" "http://localhost:8000/dev-setup-mac-m5.html"
    timeout /t 1 /nobreak >nul
    start "" "http://localhost:8000/macbook-pro-m5-guia.html"
    timeout /t 1 /nobreak >nul
    start "" "http://localhost:8000/tutorial_mac_2026.html"
)
if %ELECCION%==1 (
    echo  Servidor corriendo. Para abrir manualmente:
    echo    http://localhost:8000/ai-coding-tools.html
    echo    http://localhost:8000/dev-setup-mac-m5.html
    echo    http://localhost:8000/macbook-pro-m5-guia.html
    echo    http://localhost:8000/tutorial_mac_2026.html
)

:: ====================================================================
:: PASO 10 -- Mensaje final con instrucciones
:: ====================================================================
echo.
echo  +------------------------------------------------------+
echo  ^|  Servidor activo en http://localhost:8000           ^|
echo  ^|                                                      ^|
echo  ^|  Para detenerlo:                                     ^|
echo  ^|    Cerrar la ventana "TutoApp - Servidor"           ^|
echo  ^|    O presionar Ctrl+C en esa ventana.               ^|
echo  ^|                                                      ^|
echo  ^|  Desde la LAN (otro dispositivo en tu red):         ^|
echo  ^|    Reemplaza localhost por tu IP local.             ^|
echo  ^|    Ejemplo: http://192.168.1.100:8000/              ^|
echo  +------------------------------------------------------+
echo.
pause
