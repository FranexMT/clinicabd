# SGCM — Sistema de Gestión de Clínica Médica

App Flask que conecta 5 nodos MySQL distribuidos via Hamachi.

## Como correrlo (facil)

```bash
./run.sh
```

Eso solo. El script:
- Crea el entorno virtual si no existe
- Instala dependencias
- Verifica Hamachi
- Carga configuracion desde `.env` (si existe)
- Inicia la aplicacion

Luego abre: **http://localhost:5050**

## Requisitos

- Python 3.10+
- MySQL 8.0 corriendo en tu nodo
- Hamachi conectado a la red `SGCM-BDD-2026`

## Configuracion

Cada quien edita su archivo `.env` (copiar desde `.env.example`):

```bash
cp .env.example .env
# Editar IPs Hamachi de los companeros
```

Tu nodo local va como `127.0.0.1`. Los demas van con su IP Hamachi.

### Nodos

| Nodo | Encargado | Tablas |
|------|-----------|--------|
| 1 — Recepcion | Francisco | PACIENTE_V1, MEDICO, ESPECIALIDAD, CITA_F1 |
| 2 — Medicos | Axel | PACIENTE_V2, CITA_F2, EXPEDIENTE, CONSULTA, RECETA |
| 3 — Farmacia | Elmer | MEDICAMENTO, DETALLE_RECETA, CITA_F3 |
| 4 — Admin | Jorge | FACTURA, PAGO, CITA_F4 |
| 5 — Reportes | Oscar | PACIENTE_V3, CITA_F5 |

La app soporta nodos caidos: muestra datos disponibles y marca en rojo los que no responden.

## Acceso remoto

Como la app escucha en `0.0.0.0`, cualquier miembro del equipo puede ver el dashboard
de otro usando la IP Hamachi:

```
http://25.x.x.x:5050
```
