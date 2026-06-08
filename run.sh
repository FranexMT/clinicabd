#!/usr/bin/env bash
set -e

APP_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$APP_DIR"

# ─── Colores ───
BOLD='\033[1m'
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}${BOLD}========================================${NC}"
echo -e "${BLUE}${BOLD}  SGCM — Sistema de Gestion de Clinica  ${NC}"
echo -e "${BLUE}${BOLD}========================================${NC}"

# ─── Verificar Python ───
PYTHON=$(command -v python3 || command -v python)
if [ -z "$PYTHON" ]; then
    echo -e "${RED}Error: Python 3 no encontrado. Instala Python 3.10+${NC}"
    exit 1
fi

# ─── Verificar / crear venv ───
if [ ! -d "venv" ]; then
    echo -e "${BLUE}Creando entorno virtual...${NC}"
    $PYTHON -m venv venv
fi
source venv/bin/activate
PYTHON="python"

# ─── Instalar dependencias si falta alguna ───
if [ ! -f "venv/installed" ]; then
    echo -e "${BLUE}Instalando dependencias...${NC}"
    pip install -r requirements.txt
    touch venv/installed
fi

# ─── Verificar Hamachi ───
if command -v hamachi &>/dev/null; then
    HAMACHI_STATUS=$(hamachi 2>/dev/null | grep status | awk '{print $3}')
    if [ "$HAMACHI_STATUS" = "logged" ]; then
        HAMACHI_IP=$(hamachi 2>/dev/null | grep address | awk '{print $3}')
        echo -e "${GREEN}Hamachi conectado — IP: $HAMACHI_IP${NC}"
    else
        echo -e "${RED}Hamachi no conectado. Conectate a la red SGCM-BDD-2026.${NC}"
    fi
else
    echo -e "${RED}Hamachi no instalado. Instala LogMeIn Hamachi.${NC}"
fi

# ─── Cargar .env si existe ───
if [ -f ".env" ]; then
    echo -e "${BLUE}Cargando configuracion desde .env${NC}"
    export $(grep -v '^\s*#' .env | xargs)
fi

# ─── Iniciar app ───
echo -e "${GREEN}${BOLD}Iniciando SGCM en http://0.0.0.0:5050${NC}"
echo -e "${GREEN}Accede desde tu navegador: http://localhost:5050${NC}"
echo -e "${GREEN}Otros en la red Hamachi: http://$HAMACHI_IP:5050${NC}"
echo ""

$PYTHON app.py
