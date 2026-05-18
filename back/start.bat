@echo off
:: Este archivo redirige al lanzador principal en la carpeta raiz.
:: Ejecuta start.bat desde la carpeta tutoapp/ para el menu completo.
cd /d "%~dp0.."
call start.bat
