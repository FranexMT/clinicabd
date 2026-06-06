# SGCM — Sistema de Gestión de Clínica Médica
**Bases de Datos Distribuidas — UABC 2026**

App Flask que conecta los 5 nodos MySQL distribuidos vía Hamachi.

## Requisitos
- Python 3.10+
- MySQL corriendo en tu nodo
- Hamachi conectado a la red `SGCM-BDD-2026`

## Instalación (solo la primera vez)

```bash
# 1. Clonar
git clone https://github.com/franex01/sgcm-app.git
cd sgcm-app

# 2. Crear entorno virtual
python3 -m venv venv
source venv/bin/activate        # Linux/Mac
# venv\Scripts\activate         # Windows

# 3. Instalar dependencias
pip install -r requirements.txt
```

## Ejecutar

```bash
source venv/bin/activate
python app.py
```

Luego abrir en el navegador: **http://localhost:5050**

## IPs de Hamachi configuradas

| Nodo | Alumno | IP Hamachi |
|------|--------|------------|
| 1 — Recepción | Francisco | 127.0.0.1 (local) |
| 2 — Médicos | Axel | 25.19.18.201 |
| 3 — Farmacia | Elmer | 25.33.183.45 |
| 4 — Administración | Jorge | 25.4.227.153 |
| 5 — Reportes | Oscar | 25.22.219.100 |

> Las IPs cambian cada sesión de Hamachi. Si cambian, editar `config.py`.

## Notas
- El nodo que corre la app debe tener Hamachi activo y conectado
- Si un nodo está caído, la app sigue funcionando mostrando ese nodo en rojo
- Credenciales MySQL: `bdd_user` / `Sgcm2026#`
