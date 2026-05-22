@echo off
:: ====================================================================
:: MODULO: start.bat -- Lanzador TutoApp (Windows)
:: QUE HACE: Instala dependencias la primera vez y arranca el servidor
::           FastAPI en localhost:8000, luego abre las guias en el
::           browser segun la eleccion del usuario.
:: POR QUE EXISTE: Punto de entrada unico para usuarios no tecnicos --
::                 doble clic y todo funciona sin tocar la terminal.
:: ENCODING: ASCII puro -- SIN Unicode, SIN tildes, SIN caja dibujada.
:: DEPENDENCIAS: Python 3.11+, curl (incluido en Windows 10/11).
:: ====================================================================

:: chcp 65001 fuerza UTF-8 en esta consola.
:: >nul suprime el mensaje "Pagina de codigos activa: 65001".
chcp 65001 >nul

:: Navegar al directorio server/ donde esta main.py.
:: %~dp0 = path absoluto del .bat con trailing backslash.
:: /d    = cambia de unidad si el .bat esta en otro disco.
cd /d "%~dp0server"

:: ====================================================================
:: PASO 1 -- Verificar Python
:: ====================================================================
python --version >nul 2>&1
if errorlevel 1 (
    echo.
    echo  [ERROR] Python no encontrado en el PATH.
    echo.
    echo  Instala Python 3.11+ desde https://www.python.org/downloads/
    echo  y marca "Add Python to PATH" durante la instalacion.
    echo.
    pause
    exit /b 1
)

:: ====================================================================
:: PASO 2 -- Crear entorno virtual (solo la primera vez)
:: ====================================================================
if not exist ".venv" (
    echo.
    echo  [Setup 1/2] Creando entorno virtual en server/.venv ...
    python -m venv .venv
    if errorlevel 1 (
        echo  [ERROR] No se pudo crear el entorno virtual.
        pause
        exit /b 1
    )
    echo  Entorno virtual creado.
)

:: ====================================================================
:: PASO 3 -- Instalar dependencias (solo si uvicorn no existe)
:: ====================================================================
:: Si uvicorn.exe existe, las demas dependencias tambien estan instaladas.
:: Esto evita correr pip en cada arranque, lo que es lento.
if not exist ".venv\Scripts\uvicorn.exe" (
    echo.
    echo  [Setup 2/2] Instalando dependencias (1-2 minutos la primera vez)...
    echo              Paquetes: fastapi, uvicorn, httpx, python-dotenv
    echo.
    ".venv\Scripts\pip" install -r requirements.txt
    if errorlevel 1 (
        echo.
        echo  [ERROR] Fallo la instalacion. Verifica tu conexion a internet.
        pause
        exit /b 1
    )
    echo.
    echo  Dependencias instaladas correctamente.
)

:: ====================================================================
:: PASO 4 -- Crear .env si no existe
:: ====================================================================
:: .env.example = template sin valores (va a Git).
:: .env         = API keys reales del usuario (nunca va a Git).
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
:: Mata procesos que ocupen el puerto 8000 para que uvicorn pueda arrancar.
echo.
echo  Verificando puerto 8000...
powershell -NoProfile -Command "Get-NetTCPConnection -LocalPort 8000 -ErrorAction SilentlyContinue | ForEach-Object { Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue }"

:: ====================================================================
:: PASO 6 -- Menu de seleccion
:: ====================================================================
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
echo   ^|   [5]  Arquitectura Tecnica                      ^|
echo   ^|        Como funciona TutoApp por dentro          ^|
echo   ^|                                                  ^|
echo   ^|   [6]  ^>^>^> Abrir las 5 guias juntas ^<^<^<       ^|
echo   ^|                                                  ^|
echo   ^|   [0]  Solo iniciar servidor (sin browser)      ^|
echo   ^|                                                  ^|
echo   +===================================================+
echo.

:: choice /C 0123456 lee UNA tecla sin necesitar Enter.
:: Mapeo de ERRORLEVEL generado por choice /C 0123456:
::   '0' -> ERRORLEVEL 1
::   '1' -> ERRORLEVEL 2
::   '2' -> ERRORLEVEL 3
::   '3' -> ERRORLEVEL 4
::   '4' -> ERRORLEVEL 5
::   '5' -> ERRORLEVEL 6
::   '6' -> ERRORLEVEL 7
choice /C 0123456 /N /M "   Tu eleccion (presiona 0-6): "

:: Guardar ERRORLEVEL inmediatamente.
:: CRITICO: ERRORLEVEL se sobreescribe con CADA comando posterior (incluso los if).
:: Por eso lo capturamos aqui antes de que cualquier otro comando lo pise.
set ELECCION=%ERRORLEVEL%

:: ====================================================================
:: PASO 7 -- Arrancar uvicorn en ventana separada minimizada
:: ====================================================================
:: start "titulo" /min "programa" argumentos
::   /min   = inicia la ventana minimizada
::   main:app = modulo:objeto FastAPI que uvicorn debe cargar
echo.
echo  Iniciando servidor en http://localhost:8000 ...
start "TutoApp - Servidor" /min ".venv\Scripts\uvicorn.exe" main:app --host 0.0.0.0 --port 8000

:: ====================================================================
:: PASO 8 -- Esperar hasta que el servidor responda
:: ====================================================================
:: Logica: curl verifica /api/health cada segundo hasta 30 intentos.
:: Si supera 30 segundos, abre el browser de todas formas.
set INTENTOS=0

:wait_server
set /a INTENTOS+=1

if %INTENTOS% GTR 30 (
    echo.
    echo  [AVISO] El servidor tarda mas de 30 segundos.
    echo  Revisa la ventana "TutoApp - Servidor" si hay un error.
    echo.
    goto abrir_browser
)

timeout /t 1 /nobreak >nul

curl -s --max-time 2 http://localhost:8000/api/health >nul 2>&1
if errorlevel 1 goto wait_server

echo  Servidor listo.

:: ====================================================================
:: PASO 9 -- Abrir browser segun la eleccion
:: ====================================================================
:: Mapeo ELECCION -> URL:
::   ELECCION 2 (tecla 1) -> ai-coding-tools.html
::   ELECCION 3 (tecla 2) -> dev-setup-mac-m5.html
::   ELECCION 4 (tecla 3) -> macbook-pro-m5-guia.html
::   ELECCION 5 (tecla 4) -> tutorial_mac_2026.html
::   ELECCION 6 (tecla 5) -> arquitectura-tecnica.html
::   ELECCION 7 (tecla 6) -> las 5 juntas
::   ELECCION 1 (tecla 0) -> solo servidor, sin browser
::
:: NOTA sobre "start URL":
::   Se usa sin comillas alrededor de la URL para maxima compatibilidad.
::   La forma "start http://..." es la mas confiable en CMD de Windows.
:abrir_browser
if %ELECCION%==2 start http://localhost:8000/ai-coding-tools.html
if %ELECCION%==3 start http://localhost:8000/dev-setup-mac-m5.html
if %ELECCION%==4 start http://localhost:8000/macbook-pro-m5-guia.html
if %ELECCION%==5 start http://localhost:8000/tutorial_mac_2026.html
if %ELECCION%==6 start http://localhost:8000/arquitectura-tecnica.html
if %ELECCION%==7 (
    start http://localhost:8000/ai-coding-tools.html
    timeout /t 1 /nobreak >nul
    start http://localhost:8000/dev-setup-mac-m5.html
    timeout /t 1 /nobreak >nul
    start http://localhost:8000/macbook-pro-m5-guia.html
    timeout /t 1 /nobreak >nul
    start http://localhost:8000/tutorial_mac_2026.html
    timeout /t 1 /nobreak >nul
    start http://localhost:8000/arquitectura-tecnica.html
)
if %ELECCION%==1 (
    echo.
    echo  Servidor corriendo. Para abrir manualmente:
    echo    http://localhost:8000/ai-coding-tools.html
    echo    http://localhost:8000/dev-setup-mac-m5.html
    echo    http://localhost:8000/macbook-pro-m5-guia.html
    echo    http://localhost:8000/tutorial_mac_2026.html
    echo    http://localhost:8000/arquitectura-tecnica.html
)

:: ====================================================================
:: PASO 10 -- Mensaje final
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
