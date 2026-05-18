# TutoApp — Guías interactivas con IA integrada

Tres tutoriales HTML interactivos con asistente de IA incorporado.
Funcionan en cualquier equipo Windows o Mac sin configuración de API keys
(usa Puter.js gratis por defecto).

## Guías incluidas

| Guía | Contenido |
|------|-----------|
| **AI Coding Tools 2026** | Top herramientas, comparativas, Ollama local |
| **Dev Setup Mac M5** | De 0 a 100: Homebrew, Docker, Python, PostgreSQL |
| **MacBook Pro M5** | Atajos, Terminal, Seguridad, Tips avanzados |

---

## Cómo instalar y ejecutar

### Requisitos previos

Necesitás tener instalado:

- **Python 3.11 o superior** — [descargar aquí](https://www.python.org/downloads/)
  - Windows: durante la instalación, tildá "Add Python to PATH"
  - Mac: viene preinstalado en macOS 12+, o instalá con `brew install python`
- **Git** — [descargar aquí](https://git-scm.com/downloads) (para clonar el repo)

### Paso 1 — Clonar el repositorio

Abrí una terminal (Windows: PowerShell o CMD; Mac: Terminal) y ejecutá:

```bash
git clone https://github.com/TU-USUARIO/tutoapp.git
cd tutoapp
```

*(Reemplazá `TU-USUARIO` con tu usuario de GitHub)*

### Paso 2 — Arrancar la app

**En Windows** — doble clic en `start.bat`, o desde PowerShell:
```powershell
.\start.bat
```

**En Mac / Linux** — desde Terminal:
```bash
chmod +x start.sh   # Solo la primera vez (da permiso de ejecución)
./start.sh
```

El script hace todo automáticamente:
1. Crea un entorno virtual de Python (solo la primera vez, tarda ~30 seg)
2. Instala las dependencias
3. Arranca el servidor en http://localhost:8000
4. Abre el browser con la guía que elijas

---

## Estructura del proyecto

```
tutoapp/
├── front/                  ← Los 3 archivos HTML (las guías)
│   ├── ai-coding-tools.html
│   ├── dev-setup-mac-m5.html
│   └── macbook-pro-m5-guia.html
├── back/                   ← Servidor Python (FastAPI)
│   ├── main.py             ← Código del servidor
│   ├── requirements.txt    ← Lista de dependencias Python
│   └── .env.example        ← Plantilla de configuración (sin keys)
├── start.bat               ← Lanzador Windows
├── start.sh                ← Lanzador Mac/Linux
└── README.md               ← Este archivo
```

---

## Cómo funciona el asistente de IA

Por defecto usa **Puter.js** — un servicio gratuito que funciona directo en el
browser sin ninguna API key. No necesitás crear ninguna cuenta.

Si querés usar Claude o Gemini con tu propia API key, editá el archivo
`back/.env` (se crea automáticamente la primera vez que ejecutás el script):

```env
ANTHROPIC_API_KEY=tu-key-aqui   # claude.anthropic.com
GEMINI_API_KEY=tu-key-aqui      # aistudio.google.com
```

---

## Solución de problemas comunes

**"Python no encontrado"**
→ Instalá Python 3.11+ y durante la instalación tildá "Add Python to PATH"

**"Puerto 8000 ocupado"**
→ El script lo libera automáticamente. Si persiste, reiniciá el equipo.

**Mac: "Permission denied"**
→ Ejecutá `chmod +x start.sh` antes de `./start.sh`

**El browser no se abre solo**
→ Abrí manualmente: http://localhost:8000

---

## Tecnologías usadas

- **FastAPI** — servidor web Python (rápido y moderno)
- **Uvicorn** — servidor ASGI que corre FastAPI
- **Puter.js** — IA gratuita en el browser
- **HTML + CSS + JS** — las guías son archivos estáticos autocontenidos
