# SGCM — Guía de uso

## Requisitos

- Python 3.10+
- MySQL 8.0
- Hamachi (conexion a red SGCM-BDD-2026)

## Instalacion

```bash
git clone <repo>
cd sgcm_app
```

## Ejecutar

```bash
./run.sh
```

Esto crea el entorno virtual, instala dependencias y arranca el servidor.

Abrir: http://localhost:5050

## Detener

```bash
./stop.sh
```

## Configurar IPs (opcional)

```bash
cp .env.example .env
# Editar .env con las IPs Hamachi de cada nodo
```

Si no se configura .env, usa valores por defecto para Nodo 1 (local)
e IPs Hamachi de los compañeros.

## Paginas

| Pagina | Ruta | Descripcion |
|--------|------|-------------|
| Inicio | / | Estado de los 5 nodos |
| Pacientes | /pacientes | CRUD pacientes (fragmentos V1, V2, V3) |
| Citas | /citas | CRUD citas (fragmentos F1 a F5) |
| Medicos | /medicos | CRUD medicos (Nodo 1) |
| Farmacia | /farmacia | Inventario y dispensar recetas (Nodo 3) |
| Admin | /admin | Facturas y pagos (Nodo 4) |
| Reportes | /reportes | Estadisticas (Nodo 5) |

## Nodos

| Nodo | Encargado | Base |
|:----:|-----------|------|
| 1 | Francisco | sgcm_nodo1 |
| 2 | Axel | sgcm_nodo2 |
| 3 | Elmer | sgcm_nodo3 |
| 4 | Jorge | sgcm_nodo4 |
| 5 | Oscar | sgcm_nodo5 |

Todas las bases usan: usuario `bdd_user`, password `Sgcm2026#`

## Base de datos completa

Para cargar los 5 nodos en una maquina limpia:

```bash
mysql -u root -p < sgcm_completo.sql
```

## Queries por nodo

Archivos individuales: `query_nodo1.sql` a `query_nodo5.sql`
