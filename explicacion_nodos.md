# SGCM — Explicación de los 5 Nodos Distribuidos

## Arquitectura general

El SGCM tiene **5 nodos MySQL 8.0** distribuidos en la red VPN Hamachi
(`SGCM-BDD-2026`). Cada nodo representa un **área funcional** de la clínica.

Las tablas se fragmentaron usando dos técnicas:

- **Fragmentación horizontal (COM-MIN)** → tabla `CITA` (partida por filas)
- **Fragmentación vertical (BEA/MAC)** → tabla `PACIENTE` (partida por columnas)

---

## Nodo 1 — Recepción (Francisco)

### Base de datos
```sql
sgcm_nodo1
```

### Tablas
| Tabla | Tipo | Descripción |
|-------|------|-------------|
| `ESPECIALIDAD` | Local (completa) | Catálogo de especialidades médicas (Medicina General, Pediatría, etc.) |
| `MEDICO` | Local (completa) | Médicos de la clínica con su cédula, teléfono, turno |
| `PACIENTE_V1` | Fragmento vertical | Datos de contacto del paciente (nombre, teléfono, email, activo) |
| `CITA_F1` | Fragmento horizontal | Citas **programadas** del **1er semestre 2026** (enero-junio) |

### ¿Por qué este nodo es así?

Recepción es el **primer punto de contacto** con el paciente. Sus
operaciones principales son:

- **Registrar pacientes** → necesita `PACIENTE_V1` (nombre, teléfono, email)
- **Agendar citas** → necesita `CITA_F1` (citas programadas del semestre actual)
- **Asignar médico** → necesita `MEDICO` + `ESPECIALIDAD`

Los datos clínicos (`fecha_nac`, `sexo`, `tipo_sangre`) NO los necesita
recepción, por eso están en otro fragmento (V2 en Nodo 2).

### Dependencias (FKs reales)
```
MEDICO.id_especialidad → ESPECIALIDAD
CITA_F1.id_paciente    → PACIENTE_V1
CITA_F1.id_medico      → MEDICO
```

### Consulta óptima
```sql
-- Citas programadas de un paciente con médico y especialidad
SELECT c.id_cita, c.fecha_cita, c.hora_cita, c.motivo,
       CONCAT(m.nombre, ' ', m.apellido_p) AS medico,
       e.nombre AS especialidad
FROM CITA_F1 c
JOIN MEDICO       m ON c.id_medico   = m.id_medico
JOIN ESPECIALIDAD e ON m.id_especialidad = e.id_especialidad
WHERE c.id_paciente = 1
ORDER BY c.fecha_cita, c.hora_cita;
```

---

## Nodo 2 — Médicos (Axel)

### Base de datos
```sql
sgcm_nodo2
```

### Tablas
| Tabla | Tipo | Descripción |
|-------|------|-------------|
| `PACIENTE_V2` | Fragmento vertical | Datos clínicos del paciente (fecha_nac, sexo, tipo_sangre) |
| `CITA_F2` | Fragmento horizontal | Citas **programadas** del **2do semestre 2026** (julio-diciembre) |
| `EXPEDIENTE` | Local (completa) | Expediente médico: alergias, antecedentes, fecha de apertura |
| `CONSULTA` | Local (completa) | Diagnósticos y observaciones de cada consulta |
| `RECETA` | Local (completa) | Recetas emitidas con indicaciones |
| `DETALLE_RECETA` | Local (origen) | Detalle de medicamentos por receta (cantidad, duración) |

### ¿Por qué este nodo es así?

El **área médica** es el núcleo clínico del sistema. Cuando un médico
atiende a un paciente necesita:

- **Datos clínicos** → `PACIENTE_V2` (fecha de nacimiento, tipo de sangre, sexo)
- **Historial médico** → `EXPEDIENTE` (alergias, antecedentes)
- **Consultas previas** → `CONSULTA` (diagnósticos anteriores)
- **Recetar medicamentos** → `RECETA` + `DETALLE_RECETA`
- **Citas futuras** → `CITA_F2` (programadas para el próximo semestre)

Este es el nodo **más complejo** (6 tablas) porque centraliza toda la
actividad clínica. Las FKs a `PACIENTE_V2` y `CITA_F2` son locales,
lo que permite joins rápidos sin cruzar la red.

### Réplica de DETALLE_RECETA
`DETALLE_RECETA` existe también en **Nodo 3** (Farmacia) con una columna
extra `dispensado`. La farmacia necesita saber qué medicamentos surtir,
pero la receta la emite el médico desde Nodo 2. La réplica es
**unidireccional** (N2 → N3).

### Consulta óptima
```sql
-- Expediente clínico completo de un paciente
SELECT p.id_paciente,
       CONCAT(p.nombre, ' ', p.apellido_p) AS paciente,
       p.fecha_nac, p.tipo_sangre,
       exp.alergias, exp.antecedentes,
       con.id_consulta, con.fecha_consulta, con.diagnostico,
       rec.id_receta, rec.indicaciones
FROM (
    SELECT id_paciente, nombre, apellido_p, fecha_nac, tipo_sangre
    FROM PACIENTE_V2
    WHERE id_paciente = 1
) p
JOIN EXPEDIENTE exp ON exp.id_paciente = p.id_paciente
JOIN CONSULTA   con ON con.id_consulta IS NOT NULL
JOIN RECETA     rec ON rec.id_consulta = con.id_consulta
ORDER BY con.fecha_consulta DESC;
```

---

## Nodo 3 — Farmacia (Elmer)

### Base de datos
```sql
sgcm_nodo3
```

### Tablas
| Tabla | Tipo | Descripción |
|-------|------|-------------|
| `MEDICAMENTO` | Local (completa) | Inventario: nombre, presentación, dosis, stock, precio |
| `DETALLE_RECETA` | Réplica (desde N2) | Recetas a surtir, con columna extra `dispensado` |
| `CITA_F3` | Fragmento horizontal | Citas **completadas** del **1er semestre 2025** (enero-junio) |

### ¿Por qué este nodo es así?

Farmacia necesita:

- **Consultar medicamentos** → `MEDICAMENTO` (stock, precio)
- **Surtir recetas** → `DETALLE_RECETA` (qué medicamentos y en qué cantidad)
- **Validar contra citas** → `CITA_F3` (citas completadas donde se emitieron recetas)

La columna `dispensado` en `DETALLE_RECETA` (réplica) es exclusiva de
farmacia: indica si el medicamento ya fue entregado al paciente. En el
Nodo 2 no existe este campo porque los médicos no necesitan saber el
estado de dispensación.

### Diferencia con el origen (Nodo 2)
| Atributo | N2 (origen) | N3 (réplica) |
|----------|:-----------:|:------------:|
| `id_detalle` | ✅ | ✅ |
| `id_receta` | ✅ | ✅ |
| `id_medicamento` | ✅ | ✅ |
| `cantidad` | ✅ | ✅ |
| `duracion_dias` | ✅ | ✅ |
| `dispensado` | ❌ | ✅ (TINYINT, DEFAULT 0) |

### Consulta óptima
```sql
-- Recetas pendientes de dispensar con costo total
SELECT dr.id_receta,
       m.nombre AS medicamento,
       m.presentacion, m.precio,
       dr.cantidad, dr.duracion_dias,
       dr.cantidad * m.precio AS costo_total
FROM DETALLE_RECETA dr
JOIN MEDICAMENTO m ON m.id_medicamento = dr.id_medicamento
WHERE dr.dispensado = 0
ORDER BY dr.id_receta;
```

---

## Nodo 4 — Administración (Jorge)

### Base de datos
```sql
sgcm_nodo4
```

### Tablas
| Tabla | Tipo | Descripción |
|-------|------|-------------|
| `CITA_F4` | Fragmento horizontal | Citas **completadas** del **2do semestre 2025** (julio-diciembre) |
| `FACTURA` | Local (completa) | Facturas: subtotal, IVA (16%), total, estatus de pago |
| `PAGO` | Local (completa) | Pagos registrados: monto, método (efectivo/tarjeta/transferencia) |

### ¿Por qué este nodo es así?

Administración se encarga de:

- **Facturar consultas** → necesita `CITA_F4` (citas ya atendidas)
- **Generar facturas** → `FACTURA` (con cálculo de IVA)
- **Registrar pagos** → `PAGO` (monto, método de pago)

La relación entre citas y facturas es:

```
CITA (completada) → CONSULTA (diagnóstico) → FACTURA (cobro)
```

`FACTURA.id_consulta` es una **FK lógica** que apunta a `CONSULTA`
en el Nodo 2 (no hay constraint físico entre nodos).

### Atributo derivado en FACTURA
El campo `total` es un **atributo derivado** (`total = subtotal + iva`).
Se conserva por rendimiento (evita recalcular en cada consulta de
reporte), documentado como excepción justificada a 3FN.

### Consulta óptima
```sql
-- Facturas pendientes de pago con días de vencimiento
SELECT f.id_factura, f.fecha_emision,
       c.id_paciente,
       f.subtotal, f.iva, f.total,
       f.estatus_pago,
       DATEDIFF(CURDATE(), f.fecha_emision) AS dias_vencida
FROM (
    SELECT id_factura, id_consulta, fecha_emision,
           subtotal, iva, total, estatus_pago
    FROM FACTURA
    WHERE estatus_pago = 'pendiente'
) f
JOIN CITA_F4 c ON c.id_cita = f.id_consulta
ORDER BY dias_vencida DESC, f.total DESC;
```

---

## Nodo 5 — Reportes (Oscar)

### Base de datos
```sql
sgcm_nodo5
```

### Tablas
| Tabla | Tipo | Descripción |
|-------|------|-------------|
| `PACIENTE_V3` | Fragmento vertical | Datos estadísticos: sexo, tipo_sangre, fecha_registro, activo |
| `CITA_F5` | Fragmento horizontal | Citas **canceladas** (cualquier fecha, sin restricción) |

### Vistas
| Vista | Descripción |
|-------|-------------|
| `v_cancelaciones_mes` | Cancelaciones agrupadas por mes |
| `v_demografia_sangre` | Distribución de tipos de sangre de pacientes activos |
| `v_demografia_sexo` | Distribución por sexo |
| `v_crecimiento_pacientes` | Nuevos registros por mes |

### ¿Por qué este nodo es así?

Reportes centraliza datos para **análisis estadístico**:

- **Análisis de cancelaciones** → `CITA_F5` captura todas las citas
  canceladas sin importar la fecha (no tiene CHECK de fecha como F1-F4)
- **Demografía de pacientes** → `PACIENTE_V3` tiene solo los atributos
  necesarios para estadísticas (sexo, tipo_sangre, activo)

Nodo 5 es el más **liviano** (2 tablas + vistas) porque solo almacena
los subconjuntos de datos necesarios para reportes.

### Diferencia con Nodo 5 en la fragmentación de CITA
`CITA_F5` es especial porque **NO tiene restricción de fecha**:
```sql
CONSTRAINT chk_cita_f5_estatus CHECK (estatus = 'cancelada')
-- Sin CHECK de fecha → cualquier fecha
```
Mientras que F1-F4 tienen CHECK de estatus + fecha.

### Consulta óptima
```sql
-- Top 10 pacientes con más cancelaciones (ausentismo)
SELECT id_paciente,
       COUNT(*) AS num_cancelaciones,
       MIN(fecha_cita) AS primera_cancelacion,
       MAX(fecha_cita) AS ultima_cancelacion
FROM CITA_F5
GROUP BY id_paciente
ORDER BY num_cancelaciones DESC
LIMIT 10;
```

---

## Resumen de fragmentación

### Horizontal — CITA (COM-MIN)

Por estatus y fecha, 5 fragmentos disjuntos y completos:

| Fragmento | Nodo | Estatus | Rango | CHECK |
|-----------|:----:|---------|-------|-------|
| `CITA_F1` | 1 | programada | 2026-01-01 a 2026-06-30 | estatus + fecha |
| `CITA_F2` | 2 | programada | 2026-07-01 a 2026-12-31 | estatus + fecha |
| `CITA_F3` | 3 | completada | 2025-01-01 a 2025-06-30 | estatus + fecha |
| `CITA_F4` | 4 | completada | 2025-07-01 a 2025-12-31 | estatus + fecha |
| `CITA_F5` | 5 | cancelada | cualquier fecha | solo estatus |

### Vertical — PACIENTE (BEA/MAC)

Por afinidad de atributos, 3 fragmentos:

| Fragmento | Nodo | Atributos | Uso principal |
|-----------|:----:|-----------|---------------|
| `PACIENTE_V1` | 1 | id, nombre, apellidos, teléfono, email, activo | Contacto |
| `PACIENTE_V2` | 2 | id, nombre, apellidos, fecha_nac, sexo, tipo_sangre | Clínico |
| `PACIENTE_V3` | 5 | id, sexo, tipo_sangre, fecha_registro, activo | Estadístico |

Reconstrucción:
```sql
SELECT * FROM PACIENTE_V1
JOIN PACIENTE_V2 USING (id_paciente)
JOIN PACIENTE_V3 USING (id_paciente);
```

---

## FKs lógicas (entre nodos)

| FK | Origen | Destino | Tipo |
|----|--------|---------|------|
| `CONSULTA.id_cita` | N2 | N1, N2, N3, N4, N5 | Lógica (CITA está fragmentada) |
| `FACTURA.id_consulta` | N4 | N2 | Lógica (CONSULTA está en N2) |
| `DETALLE_RECETA.id_medicamento` | N2 | N3 | Lógica (MEDICAMENTO está en N3) |
| `EXPEDIENTE.id_paciente` | N2 | N1, N2, N5 | Lógica (PACIENTE está fragmentado) |

No existen constraints `FOREIGN KEY` entre bases de datos distintas.
La integridad referencial se gestiona a nivel de aplicación (Flask).
