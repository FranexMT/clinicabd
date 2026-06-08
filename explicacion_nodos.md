# SGCM — Explicación completa de los 5 Nodos Distribuidos

## 1. ¿Por qué una base de datos distribuida?

En lugar de tener un solo servidor MySQL centralizado, decidimos
distribuir los datos en 5 nodos independientes conectados via VPN
Hamachi. Las razones:

| Problema del modelo centralizado | Solución distribuida |
|----------------------------------|----------------------|
| Un solo servidor = punto único de falla | Cada nodo MySQL corre independientemente; si uno falla, los demás nodos y la app continúan operando con los datos disponibles |
| Todo el tráfico pasa por el mismo servidor | Cada nodo procesa sus consultas localmente en su propia instancia MySQL |
| Los datos clínicos viajan innecesariamente | Cada área tiene solo los datos que necesita |
| Escalabilidad limitada | Podemos agregar más nodos sin reestructurar todo |

En una clínica real, recepción no necesita saber el tipo de sangre
del paciente para agendar una cita, y farmacia no necesita el
diagnóstico completo para surtir una receta. Distribuir los datos
reduce el tráfico innecesario en la red y refleja la organización
física de la clínica.

### 1.1 Precisión sobre disponibilidad

Es importante aclarar qué significa "si un nodo cae, los demás
siguen funcionando":

- Cada **instancia MySQL** corre de forma autónoma en su propia
  máquina. Si la computadora de Axel se apaga, su Nodo 2 deja de
  responder, pero los MySQL de Francisco, Elmer, Jorge y Oscar
  siguen ejecutándose sin problema.
- La **aplicación Flask** está diseñada para tolerar nodos caídos:
  muestra el nodo en rojo y carga los datos de los nodos que sí
  responden. Sin embargo, la información del nodo caído no está
  disponible — por ejemplo, si N2 está caído, no se pueden ver los
  datos clínicos de los pacientes.
- Esto no es una tolerancia a fallos completa (cada nodo no replica
  los datos de los demás), sino una **disponibilidad parcial** que
  es precisamente lo que se espera de una base de datos fragmentada
  vertical y horizontalmente.

---

## 2. Fragmentación horizontal — Algoritmo COM-MIN sobre CITA

### 2.1 ¿Por qué CITA?

La tabla `CITA` es la entidad más dinámica del sistema: se crean
constantemente (recepción), se consultan (médicos), se verifican
(farmacia) y se facturan (administración). Es la tabla con mayor
volumen de operaciones concurrentes, lo que la hace candidata ideal
para fragmentación horizontal.

### 2.2 Predicados definidos

Se definieron 7 predicados simples sobre atributos de `CITA`:

| Predicado | Expresión | Significado |
|-----------|-----------|-------------|
| p1 | `estatus = 'programada'` | Cita agendada, aún no ocurre |
| p2 | `estatus = 'completada'` | Cita que ya ocurrió |
| p3 | `estatus = 'cancelada'` | Cita que no ocurrió por cancelación |
| p4 | `fecha_cita >= 2026-01-01 AND fecha_cita <= 2026-06-30` | 1er semestre año en curso |
| p5 | `fecha_cita >= 2026-07-01 AND fecha_cita <= 2026-12-31` | 2do semestre año en curso |
| p6 | `fecha_cita >= 2025-01-01 AND fecha_cita <= 2025-06-30` | 1er semestre año anterior |
| p7 | `fecha_cita >= 2025-07-01 AND fecha_cita <= 2025-12-31` | 2do semestre año anterior |

### 2.3 Aplicación del algoritmo COM-MIN

**Paso 1 — Completitud**: Todo registro de `CITA` tiene un estatus
en `{programada, completada, cancelada}` y una fecha. La disyunción
de p1∨p2∨p3 cubre todos los estatus, y p4∨p5∨p6∨p7 cubre todas las
fechas relevantes. CITA_F5 (canceladas) no requiere restricción de
fecha precisamente porque una cancelación puede ocurrir en cualquier
momento — ese es el único fragmento sin CHECK de fecha.

**Paso 2 — Minimalidad**: Los predicados se agrupan por combinaciones
de estatus + rango de fecha que realmente son consultadas por las
aplicaciones. Esto produce exactamente 5 fragmentos:

| Fragmento | Predicado | Nodo | ¿Quién lo usa? |
|-----------|-----------|:----:|----------------|
| `CITA_F1` | p1 ∧ p4 | 1 | Recepción agenda citas del semestre actual |
| `CITA_F2` | p1 ∧ p5 | 2 | Médicos consultan citas futuras del semestre siguiente |
| `CITA_F3` | p2 ∧ p6 | 3 | Farmacia verifica citas completadas del semestre pasado |
| `CITA_F4` | p2 ∧ p7 | 4 | Administración factura citas completadas |
| `CITA_F5` | p3 | 5 | Reportes analiza cancelaciones |

### 2.4 Justificación del salto de año (2025 vs 2026)

El sistema está modelado en junio de 2026 (fecha actual del proyecto).
Por lo tanto:

- **2026** → año en curso (citas programadas, aún no ocurren)
- **2025** → año anterior (citas que ya ocurrieron = completadas)

Esto refleja el ciclo natural de una clínica real: las citas pasadas
se facturan y analizan, las futuras se gestionan. La fecha del sistema
es configurable y los fragmentos se ajustarían si el año cambiara.

### 2.5 Limitación de la fragmentación estática

Los fragmentos de CITA usan valores fijos de año (2025 para
completadas, 2026 para programadas). Esto significa que cuando
el calendario avance a 2027, las citas programadas de 2027 no
encajarían en ningún fragmento (los CHECK constraints las
rechazarían). En un sistema productivo, los rangos se actualizarían
periódicamente o se usaría fragmentación derivada con función en
vez de valores literales. Para fines del proyecto académico, los
rangos son suficientes y demuestran correctamente el concepto de
fragmentación horizontal con COM-MIN.

### 2.6 Verificación de completitud y disjunción

**Completitud**: Cualquier cita en el sistema cae en exactamente uno
de estos casos:
- Es programada → 2026 (F1 o F2)
- Es completada → 2025 (F3 o F4)
- Es cancelada → F5 (sin importar año)

**Disjunción**: Los fragmentos son mutuamente excluyentes porque cada
combinación de estatus + rango de fecha es única. Una cita no puede
ser programada y completada al mismo tiempo, ni estar en dos rangos
de fecha distintos. Esto se garantiza con CHECK constraints en cada
tabla.

---

## 3. Fragmentación vertical — Algoritmos MU, MFA, MAA, BEA, MAC sobre PACIENTE

### 3.1 ¿Por qué PACIENTE?

La tabla `PACIENTE` tiene 11 atributos con patrones de acceso muy
heterogéneos:

| Área | Atributos que consulta | Atributos que NO consulta |
|------|------------------------|---------------------------|
| Recepción | nombre, teléfono, email | fecha_nac, tipo_sangre |
| Médicos | fecha_nac, sexo, tipo_sangre, alergias | teléfono, email |
| Reportes | sexo, tipo_sangre, activo | nombre, teléfono, email |

Esta heterogeneidad justifica partir los atributos en fragmentos
especializados, de modo que cada nodo tenga solo los datos que
realmente necesita.

### 3.2 Matriz de Uso (MU)

Se definieron 5 consultas representativas (Q1-Q5) que capturan los
patrones de acceso más frecuentes:

| Consulta | Descripción | Frecuencia/semana |
|----------|-------------|:-----------------:|
| Q1 | Buscar paciente por nombre (recepción) | 200 |
| Q2 | Ver datos clínicos del paciente (médicos) | 150 |
| Q3 | Registrar nuevo paciente (recepción) | 50 |
| Q4 | Actualizar teléfono/email (recepción) | 30 |
| Q5 | Reporte demográfico (reportes) | 10 |

### 3.3 Matriz de Frecuencia de Acceso (MFA)

Cada consulta Q se multiplica por su frecuencia para obtener una
matriz ponderada que refleja el uso real del sistema.

### 3.4 Matriz de Afinidad entre Atributos (MAA)

Se calcula la afinidad entre cada par de atributos:

```
AA(ai, aj) = Σ(q) freq(q) × use(q, ai) × use(q, aj)
```

Donde `use(q, a)` = 1 si la consulta q accede al atributo a, 0 si no.

Los atributos con alta afinidad son aquellos que frecuentemente se
consultan juntos. Por ejemplo:
- `nombre` y `apellido_p` → alta afinidad (siempre se buscan juntos)
- `nombre` y `tipo_sangre` → baja afinidad (diferentes áreas los usan)

### 3.5 Bond Energy Algorithm (BEA)

BEA reorganiza las columnas de la matriz de afinidad para maximizar
la "energía de enlace", agrupando los atributos más afines de forma
contigua. El resultado produce 3 grupos naturales:

| Grupo | Atributos | Afinidad entre ellos |
|-------|-----------|:--------------------:|
| G1 | id_paciente, nombre, apellido_p, apellido_m, telefono, email, activo | Alta (consultados por recepción) |
| G2 | id_paciente, nombre, apellido_p, apellido_m, fecha_nac, sexo, tipo_sangre | Alta (consultados por médicos) |
| G3 | id_paciente, sexo, tipo_sangre, fecha_registro, activo | Alta (consultados por reportes) |

### 3.6 Matriz de Acceso a Columnas (MAC)

MAC verifica que:
1. Cada columna esté asignada a al menos un fragmento ✓
2. La llave primaria `id_paciente` esté presente en todos los
   fragmentos (necesario para reconstrucción) ✓

### 3.7 Fragmentos verticales resultantes

| Fragmento | Nodo | Atributos | Justificación |
|-----------|:----:|-----------|---------------|
| `PACIENTE_V1` | 1 | id, nombre, apellidos, teléfono, email, activo | Recepción necesita contactar pacientes |
| `PACIENTE_V2` | 2 | id, nombre, apellidos, fecha_nac, sexo, tipo_sangre | Médicos necesitan datos clínicos |
| `PACIENTE_V3` | 5 | id, sexo, tipo_sangre, fecha_registro, activo | Reportes necesita estadísticas |

**Reconstrucción**: Para obtener el paciente completo:
```sql
SELECT * FROM PACIENTE_V1
JOIN PACIENTE_V2 USING (id_paciente)
JOIN PACIENTE_V3 USING (id_paciente);
```

---

## 4. Asignación de fragmentos a nodos

### 4.1 Principio: localidad de referencia

Cada fragmento se asigna al nodo donde es accedido con mayor
frecuencia, minimizando transferencias por la red Hamachi.

### 4.2 Mapa completo de asignación

```
Nodo 1 — Recepción (Francisco)
├── ESPECIALIDAD    → Catálogo local (FK de MEDICO)
├── MEDICO          → Catálogo local (lo usa recepción al agendar)
├── PACIENTE_V1     → Fragmento vertical (contacto)
└── CITA_F1         → Fragmento horizontal (programadas 1er semestre)

Nodo 2 — Médicos (Axel)
├── PACIENTE_V2     → Fragmento vertical (clínico)
├── CITA_F2         → Fragmento horizontal (programadas 2do semestre)
├── EXPEDIENTE      → Tabla local (historial médico)
├── CONSULTA        → Tabla local (diagnósticos)
├── RECETA          → Tabla local (recetas)
└── DETALLE_RECETA  → Tabla local origen (detalle de recetas)

Nodo 3 — Farmacia (Elmer)
├── MEDICAMENTO     → Tabla local (inventario)
├── DETALLE_RECETA  → Réplica desde N2 (con dispensado extra)
└── CITA_F3         → Fragmento horizontal (completadas 1er semestre)

Nodo 4 — Administración (Jorge)
├── CITA_F4         → Fragmento horizontal (completadas 2do semestre)
├── FACTURA         → Tabla local (facturación)
└── PAGO            → Tabla local (pagos)

Nodo 5 — Reportes (Oscar)
├── PACIENTE_V3     → Fragmento vertical (estadístico)
├── CITA_F5         → Fragmento horizontal (canceladas)
├── v_cancelaciones_mes       → Vista
├── v_demografia_sangre       → Vista
├── v_demografia_sexo         → Vista
└── v_crecimiento_pacientes   → Vista
```

### 4.3 Justificación nodo por nodo

**Nodo 1 — Recepción**: Es la entrada del sistema. Recibe al paciente,
lo registra y le asigna una cita. Necesita `PACIENTE_V1` para datos
de contacto, `MEDICO` y `ESPECIALIDAD` para asignar doctores, y
`CITA_F1` para las citas del semestre en curso.

**Nodo 2 — Médicos**: Es el núcleo clínico. Cuando el médico atiende,
consulta el expediente (`EXPEDIENTE`), registra el diagnóstico
(`CONSULTA`), emite recetas (`RECETA` + `DETALLE_RECETA`) y revisa
citas futuras (`CITA_F2`). Este nodo concentra 6 tablas porque toda
la actividad clínica depende de él.

**Nodo 3 — Farmacia**: Recibe las recetas emitidas por los médicos
y las surte. Necesita `MEDICAMENTO` para conocer stock y precio,
`DETALLE_RECETA` (réplica) para saber qué surtir, y `CITA_F3` para
validar que la cita realmente ocurrió.

**Nodo 4 — Administración**: Genera facturas por las consultas
realizadas y registra pagos. Necesita `CITA_F4` para saber qué citas
facturar, `FACTURA` para los montos y `PAGO` para los cobros.

**Nodo 5 — Reportes**: No realiza operaciones diarias. Su función es
analítica: estudia cancelaciones (`CITA_F5`), demografía de pacientes
(`PACIENTE_V3`) y genera estadísticas mediante vistas.

---

## 5. Réplica de DETALLE_RECETA

### 5.1 ¿Por qué existe la réplica?

La tabla `DETALLE_RECETA` existe en dos nodos:

| Nodo | Rol | Columnas |
|:----:|-----|----------|
| 2 | Origen | `id_detalle, id_receta, id_medicamento, cantidad, duracion_dias` |
| 3 | Réplica | `id_detalle, id_receta, id_medicamento, cantidad, duracion_dias, **dispensado**` |

**Razón**: El médico (N2) emite la receta, pero la farmacia (N3) es
quien la surte. La farmacia necesita saber si ya se dispensó o no
cada medicamento, información que al médico no le interesa.

La columna `dispensado` solo existe en N3. No tendría sentido agregarla
al N2 porque los médicos no necesitan saber el estado de dispensación
de cada receta que emitieron.

### 5.2 ¿Es una réplica exacta?

No exacta. N3 tiene una columna extra (`dispensado`). La réplica es
unidireccional: N2 escribe, N3 lee. En un sistema productivo, la
sincronización podría hacerse mediante eventos programados o triggers.

---

## 6. FKs lógicas (distribuidas)

En un sistema centralizado, las FKs garantizan integridad referencial.
En un sistema distribuido como SGCM, algunas FKs cruzan entre nodos
y no pueden ser constraints físicos de MySQL.

### 6.1 Tabla de FKs lógicas

| FK | Desde | Hasta | ¿Por qué es lógica? |
|----|-------|-------|---------------------|
| `CONSULTA.id_cita → CITA` | N2 | N1-N5 | `CITA` está fragmentada en 5 nodos distintos |
| `FACTURA.id_consulta → CONSULTA` | N4 | N2 | `CONSULTA` está solo en N2, `FACTURA` está en N4 |
| `DETALLE_RECETA.id_medicamento → MEDICAMENTO` | N2 | N3 | `MEDICAMENTO` está en N3, el detalle de receta en N2 |
| `EXPEDIENTE.id_paciente → PACIENTE` | N2 | N1, N2, N5 | `PACIENTE` está fragmentado en 3 nodos |

### 6.2 ¿Cómo se mantiene la integridad?

La **aplicación Flask** es la responsable de mantener la integridad
referencial. Por ejemplo, cuando se crea una cita desde la app, esta
se encarga de insertar en el fragmento correcto según el estatus y
la fecha, asegurando que los IDs sean consistentes.

### 6.3 FKs locales (reales)

Las FKs que están dentro del mismo nodo SÍ son constraints reales de
MySQL:

| Nodo | FK real |
|:----:|---------|
| 1 | `MEDICO.id_especialidad → ESPECIALIDAD` |
| 1 | `CITA_F1.id_paciente → PACIENTE_V1` |
| 1 | `CITA_F1.id_medico → MEDICO` |
| 2 | `EXPEDIENTE.id_paciente → PACIENTE_V2` |
| 2 | `RECETA.id_consulta → CONSULTA` |
| 2 | `DETALLE_RECETA.id_receta → RECETA` |
| 3 | `DETALLE_RECETA.id_medicamento → MEDICAMENTO` |
| 4 | `PAGO.id_factura → FACTURA` |

---

## 7. Optimización de consultas — Alternativa 3

### 7.1 El problema

Una consulta como "expediente clínico del paciente" involucra 5 tablas
con JOINs. Sin optimización, el motor de base de datos podría generar
productos cartesianos enormes antes de filtrar.

### 7.2 Las 3 alternativas comparadas

**Alternativa 1 — Sin optimización** (orden de izquierda a derecha):
Se realiza el producto cartesiano completo antes de aplicar la
selección. Costo estimado: ~7,750,000 B (7.5 MB).

**Alternativa 2 — Selección temprana** (pushdown de σ):
Se aplica `WHERE id_paciente = X` antes de cualquier JOIN, reduciendo
drásticamente las filas intermedias. Costo: ~25,570 B (25 KB).

**Alternativa 3 — Selección + Proyección temprana** (ÓPTIMA):
Además de la selección temprana, se proyectan solo los atributos
necesarios en cada nivel intermedio. Costo: ~4,450 B (4.3 KB).

### 7.3 ¿Por qué es la óptima?

La Alternativa 3 aplica 4 reglas de equivalencia del álgebra relacional:

1. **Conmutatividad del JOIN**: reordenar para aplicar el JOIN más
   selectivo primero
2. **Asociatividad**: agrupar JOINs para minimizar tamaño intermedio
3. **Pushdown de selección** (σ): filtrar lo antes posible
4. **Pushdown de proyección** (π): solo proyectar atributos necesarios

### 7.4 Implementación en las queries

Cada query de nodo en `consultas_nodos.sql` y `query_nodoX.sql` sigue
la Alternativa 3. Por ejemplo, Nodo 2 usa una subquery que primero
selecciona solo el paciente y proyecta solo las columnas necesarias
antes de los JOINs:

```sql
FROM (
    SELECT id_paciente, nombre, apellido_p, fecha_nac, tipo_sangre
    FROM PACIENTE_V2
    WHERE id_paciente = 1
) p   -- ← selección + proyección temprana
JOIN EXPEDIENTE ...
```

---

## 8. Resumen visual de conceptos

### Fragmentación
```
          ┌─────────────────────────────────────────────┐
          │              TABLA LÓGICA                    │
          │                                              │
          │  ┌────────────────────────────────────────┐  │
          │  │  PACIENTE (11 atributos)               │  │
          │  └──────┬──────────┬──────────┬───────────┘  │
          │         │ V1 (N1)  │ V2 (N2)  │ V3 (N5)     │
          │         │ contacto  │ clínico   │ estadístico │
          │         └──────────┴──────────┴─────────────┘  │
          │                                                │
          │  ┌────────────────────────────────────────┐  │
          │  │  CITA (5 fragmentos horizontales)      │  │
          │  │  ┌─────┬─────┬─────┬─────┬─────┐      │  │
          │  │  │ F1  │ F2  │ F3  │ F4  │ F5  │      │  │
          │  │  │ N1  │ N2  │ N3  │ N4  │ N5  │      │  │
          │  │  └─────┴─────┴─────┴─────┴─────┘      │  │
          │  └────────────────────────────────────────┘  │
          └─────────────────────────────────────────────┘
```

### Red Hamachi
```
                   ┌──────────┐
                   │  App     │
                   │  Flask   │
                   │ :5050    │
                   └────┬─────┘
                        │ VPN Hamachi
        ┌───────────────┼───────────────┐
        │               │               │
   ┌────▼────┐    ┌────▼────┐    ┌────▼────┐
   │ N1:3306 │    │ N2:3306 │    │ N3:3306 │
   │ Fran    │    │ Axel    │    │ Elmer   │
   └─────────┘    └─────────┘    └─────────┘
        │               │               │
   ┌────▼────┐    ┌────▼────┐
   │ N4:3306 │    │ N5:3306 │
   │ Jorge   │    │ Oscar   │
   └─────────┘    └─────────┘
```

---

## 9. Glosario de términos

| Término | Definición |
|---------|------------|
| **Fragmentación horizontal** | Partir una tabla por filas según una condición (ej: estatus = 'programada') |
| **Fragmentación vertical** | Partir una tabla por columnas según afinidad de acceso |
| **COM-MIN** | Algoritmo que produce el mínimo número de fragmentos horizontales completos y disjuntos |
| **BEA** (Bond Energy Algorithm) | Algoritmo que agrupa atributos por afinidad para fragmentación vertical |
| **Réplica** | Copia de una tabla en otro nodo con fines operativos |
| **FK lógica** | Referencia entre nodos que no puede ser constraint físico de MySQL |
| **Localidad de referencia** | Principio de asignar datos al nodo que más los usa |
| **Pushdown** | Técnica de optimización que aplica selección/proyección lo antes posible en el árbol de la consulta |
| **Hamachi** | Software VPN que permite conectar computadoras como si estuvieran en la misma red local |
| **Alternativa 3** | Estrategia de optimización que combina selección temprana + proyección temprana |
