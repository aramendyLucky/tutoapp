@echo off
:: ============================================================
:: MODULO: start.bat -- Lanzador principal TutoApp (Windows)
:: QUE HACE: Instala dependencias la primera vez y arranca el
::           servidor + browser con un doble clic.
:: POR QUE EXISTE: Para que cualquier equipo Windows arranque
::                 el proyecto sin saber Python ni terminales.
:: COMO FUNCIONA:
::   1. Verifica que Python este instalado
::   2. Crea un entorno virtual (venv) la primera vez
::   3. Instala los paquetes en ese venv
::   4. Muestra menu y pide seleccion (usa choice, no set /p)
::   5. Arranca uvicorn (el servidor web)
::   6. Espera que el servidor este listo (health check)
::   7. Abre el browser en la guia elegida
:: ============================================================
chcp 65001 >nul
cd /d "%~dp0server"

:: -- 1. Verificar Python ------------------------------------------
python --version >nul 2>&1
if errorlevel 1 (
    echo.
    echo  [ERROR] Python no encontrado.
    echo.
    echo  Instala Python 3.11 o superior desde:
    echo  https://www.python.org/downloads/
    echo.
    echo  IMPORTANTE: durante la instalacion tilda
    echo  "Add Python to PATH" antes de hacer clic en Install.
    echo.
    pause
    exit /b 1
)

:: -- 2. Crear entorno virtual la primera vez ---------------------
if not exist ".venv" (
    echo  Creando entorno virtual por primera vez...
    python -m venv .venv
    if errorlevel 1 (
        echo  [ERROR] No se pudo crear el entorno virtual.
        pause
        exit /b 1
    )
)

:: -- 3. Instalar/actualizar dependencias -------------------------
echo  Instalando dependencias...
.venv\Scripts\pip install -r requirements.txt -q
if errorlevel 1 (
    echo  [ERROR] Fallo la instalacion de dependencias.
    pause
    exit /b 1
)

:: -- 4. Crear .env si no existe ----------------------------------
if not exist ".env" (
    copy .env.example .env >nul
    echo  Archivo .env creado desde .env.example
)

:: -- 5. Liberar puerto 8000 si esta ocupado ----------------------
for /f "tokens=5" %%P in ('netstat -ano ^| findstr /R ":8000 " 2^>nul') do (
    taskkill /f /pid %%P >nul 2>&1
)

:: -- 6. Menu de seleccion ----------------------------------------
:: POR QUE choice y no set /p:
:: set /p tiene un bug con chcp 65001 (UTF-8) que deja la variable
:: vacia. choice es el comando nativo de Windows para menus y no
:: tiene ese problema. Presiona la tecla directamente, sin Enter.
cls
echo.
echo  +============================================================+
echo  ^|          TutoApp - Guias interactivas con IA             ^|
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

:: choice /C define las teclas validas. ERRORLEVEL indica cual se presiono:
::   tecla "0" -> ERRORLEVEL 1
::   tecla "1" -> ERRORLEVEL 2
::   tecla "2" -> ERRORLEVEL 3
::   tecla "3" -> ERRORLEVEL 4
::   tecla "4" -> ERRORLEVEL 5
choice /C 01234 /N /M "  Tu eleccion (presiona 0, 1, 2, 3 o 4): "
set ELECCION=%ERRORLEVEL%

:: -- 7. Arrancar servidor en ventana minimizada ------------------
echo.
echo  Iniciando servidor en http://localhost:8000 ...
start "TutoApp - Servidor" /min .venv\Scripts\python -m uvicorn main:app --host 0.0.0.0 --port 8000

:: -- 8. Esperar hasta que el servidor responda -------------------
:wait_server
timeout /t 1 /nobreak >nul
curl -s http://localhost:8000/api/health >nul 2>&1
if errorlevel 1 goto wait_server

:: -- 9. Abrir browser segun eleccion ----------------------------
::   ELECCION 1 = tecla "0" = solo servidor
::   ELECCION 2 = tecla "1" = AI Coding Tools
::   ELECCION 3 = tecla "2" = Dev Setup Mac M5
::   ELECCION 4 = tecla "3" = MacBook Pro M5
::   ELECCION 5 = tecla "4" = las 3 juntas
if %ELECCION%==2 start "" "http://localhost:8000/ai-coding-tools.html"
if %ELECCION%==3 start "" "http://localhost:8000/dev-setup-mac-m5.html"
if %ELECCION%==4 start "" "http://localhost:8000/macbook-pro-m5-guia.html"
if %ELECCION%==5 (
    start "" "http://localhost:8000/ai-coding-tools.html"
    timeout /t 1 /nobreak >nul
    start "" "http://localhost:8000/dev-setup-mac-m5.html"
    timeout /t 1 /nobreak >nul
    start "" "http://localhost:8000/macbook-pro-m5-guia.html"
)
if %ELECCION%==1 (
    echo  Servidor corriendo. Abri manualmente: http://localhost:8000
)

echo.
echo  +------------------------------------------------------------+
echo  ^|  Servidor activo en http://localhost:8000                ^|
echo  ^|  Para detenerlo: cerra la ventana "TutoApp - Servidor"  ^|
echo  +------------------------------------------------------------+
echo.
pause
