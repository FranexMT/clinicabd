# config.py
# ─────────────────────────────────────────────────────────────
# Reemplazar cada IP_HAMACHI_NODOx con la IP real de Hamachi
# del compañero que tiene ese nodo (formato 25.x.x.x)
# ─────────────────────────────────────────────────────────────

NODOS = {
    1: {
        "nombre": "Recepción",
        "host":   "127.0.0.1",            # Francisco — nodo local
        "port":   3306,
        "user":   "bdd_user",
        "password": "Sgcm2026#",
        "database": "sgcm_nodo1",
        "tablas": ["ESPECIALIDAD", "MEDICO", "PACIENTE_V1", "CITA_F1"],
        "color":  "#2196F3"
    },
    2: {
        "nombre": "Médicos",
        "host":   "25.19.18.201",          # Axel
        "port":   3306,
        "user":   "bdd_user",
        "password": "Sgcm2026#",
        "database": "sgcm_nodo2",
        "tablas": ["PACIENTE_V2", "CITA_F2", "EXPEDIENTE", "CONSULTA", "RECETA", "DETALLE_RECETA"],
        "color":  "#1B8A4C"
    },
    3: {
        "nombre": "Farmacia",
        "host":   "25.33.183.45",          # Elmer
        "port":   3306,
        "user":   "bdd_user",
        "password": "Sgcm2026#",
        "database": "sgcm_nodo3",
        "tablas": ["MEDICAMENTO", "DETALLE_RECETA", "CITA_F3"],
        "color":  "#7D3C98"
    },
    4: {
        "nombre": "Administración",
        "host":   "25.4.227.153",              # Jorge (japodaca_laptop)
        "port":   3306,
        "user":   "bdd_user",
        "password": "Sgcm2026#",
        "database": "sgcm_nodo4",
        "tablas": ["CITA_F4", "FACTURA", "PAGO"],
        "color":  "#D35400"
    },
    5: {
        "nombre": "Reportes",
        "host":   "25.22.219.100",         # Oscar (TorresPC)
        "port":   3306,
        "user":   "bdd_user",
        "password": "Sgcm2026#",
        "database": "sgcm_nodo5",
        "tablas": ["PACIENTE_V3", "CITA_F5"],
        "color":  "#C0392B"
    }
}
