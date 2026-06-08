#!/usr/bin/env bash
echo "Deteniendo SGCM..."
fuser -k 5050/tcp 2>/dev/null && echo "Servidor detenido." || echo "No habia proceso en puerto 5050."
