# config.py
# ─────────────────────────────────────────────────────────────
# Configuracion de los 5 nodos MySQL distribuidos via Hamachi.
# Las variables de entorno se cargan desde .env en app.py
# y se usan aqui con fallback a valores por defecto.
# ─────────────────────────────────────────────────────────────
import os

def _env(key, default):
    return os.environ.get(key, default)


NODOS = {
    1: {
        "nombre": "Recepción",
        "host":   _env("NODO1_HOST", "127.0.0.1"),
        "port":   int(_env("NODO1_PORT", "3306")),
        "user":   _env("NODO1_USER", "bdd_user"),
        "password": _env("NODO1_PASS", "Sgcm2026#"),
        "database": _env("NODO1_DB", "sgcm_nodo1"),
        "tablas": ["ESPECIALIDAD", "MEDICO", "PACIENTE_V1", "CITA_F1"],
        "color":  "#2196F3",
        "encargado": "Francisco"
    },
    2: {
        "nombre": "Médicos",
        "host":   _env("NODO2_HOST", "25.19.18.201"),
        "port":   int(_env("NODO2_PORT", "3306")),
        "user":   _env("NODO2_USER", "bdd_user"),
        "password": _env("NODO2_PASS", "Sgcm2026#"),
        "database": _env("NODO2_DB", "sgcm_nodo2"),
        "tablas": ["PACIENTE_V2", "CITA_F2", "EXPEDIENTE", "CONSULTA", "RECETA", "DETALLE_RECETA"],
        "color":  "#1B8A4C",
        "encargado": "Axel"
    },
    3: {
        "nombre": "Farmacia",
        "host":   _env("NODO3_HOST", "25.33.183.45"),
        "port":   int(_env("NODO3_PORT", "3306")),
        "user":   _env("NODO3_USER", "bdd_user"),
        "password": _env("NODO3_PASS", "Sgcm2026#"),
        "database": _env("NODO3_DB", "sgcm_nodo3"),
        "tablas": ["MEDICAMENTO", "DETALLE_RECETA", "CITA_F3"],
        "color":  "#7D3C98",
        "encargado": "Elmer"
    },
    4: {
        "nombre": "Administración",
        "host":   _env("NODO4_HOST", "25.4.227.153"),
        "port":   int(_env("NODO4_PORT", "3306")),
        "user":   _env("NODO4_USER", "bdd_user"),
        "password": _env("NODO4_PASS", "Sgcm2026#"),
        "database": _env("NODO4_DB", "sgcm_nodo4"),
        "tablas": ["CITA_F4", "FACTURA", "PAGO"],
        "color":  "#D35400",
        "encargado": "Jorge"
    },
    5: {
        "nombre": "Reportes",
        "host":   _env("NODO5_HOST", "25.22.219.100"),
        "port":   int(_env("NODO5_PORT", "3306")),
        "user":   _env("NODO5_USER", "bdd_user"),
        "password": _env("NODO5_PASS", "Sgcm2026#"),
        "database": _env("NODO5_DB", "sgcm_nodo5"),
        "tablas": ["PACIENTE_V3", "CITA_F5"],
        "color":  "#C0392B",
        "encargado": "Oscar"
    }
}
