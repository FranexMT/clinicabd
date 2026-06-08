-- ============================================================
-- SGCM — CONSULTAS ÓPTIMAS POR NODO
-- Sistema de Gestión de Clínica Médica
-- Bases de Datos Distribuidas — UABC 2026
-- Alternativa 3: selección + proyección temprana
-- ============================================================
-- Para ejecutar: conectar al nodo correspondiente y correr
-- la consulta. Reemplazar WHERE id = X con el ID deseado.
-- ============================================================

-- ════════════════════════════════════════════════════════════
-- NODO 1 — Recepción (Francisco)
-- Base: sgcm_nodo1
-- Caso: Citas programadas de un paciente con médico y especialidad
-- ════════════════════════════════════════════════════════════

SELECT
    c.id_cita,
    c.fecha_cita,
    c.hora_cita,
    c.motivo,
    CONCAT(m.nombre, ' ', m.apellido_p) AS medico,
    e.nombre                            AS especialidad
FROM CITA_F1 c
JOIN MEDICO       m ON c.id_medico   = m.id_medico
JOIN ESPECIALIDAD e ON m.id_especialidad = e.id_especialidad
WHERE c.id_paciente = 1     -- cambiar por el ID del paciente
ORDER BY c.fecha_cita, c.hora_cita;


-- ════════════════════════════════════════════════════════════
-- NODO 2 — Médicos (Axel)
-- Base: sgcm_nodo2
-- Caso: Expediente clínico completo de un paciente
-- ════════════════════════════════════════════════════════════

SELECT
    p.id_paciente,
    CONCAT(p.nombre, ' ', p.apellido_p) AS paciente,
    p.fecha_nac,
    p.tipo_sangre,
    exp.alergias,
    exp.antecedentes,
    con.id_consulta,
    con.fecha_consulta,
    con.diagnostico,
    rec.id_receta,
    rec.indicaciones
FROM (
    SELECT id_paciente, nombre, apellido_p, fecha_nac, tipo_sangre
    FROM PACIENTE_V2
    WHERE id_paciente = 1               -- cambiar por el ID del paciente
) p
JOIN EXPEDIENTE  exp ON exp.id_paciente  = p.id_paciente
JOIN CONSULTA    con ON con.id_consulta IS NOT NULL
JOIN RECETA      rec ON rec.id_consulta  = con.id_consulta
ORDER BY con.fecha_consulta DESC;


-- ════════════════════════════════════════════════════════════
-- NODO 3 — Farmacia (Elmer)
-- Base: sgcm_nodo3
-- Caso: Recetas pendientes de dispensar con costo total
-- ════════════════════════════════════════════════════════════

SELECT
    dr.id_receta,
    m.nombre        AS medicamento,
    m.presentacion,
    m.precio,
    dr.cantidad,
    dr.duracion_dias,
    dr.cantidad * m.precio AS costo_total
FROM DETALLE_RECETA dr
JOIN MEDICAMENTO    m  ON m.id_medicamento = dr.id_medicamento
WHERE dr.dispensado = 0
ORDER BY dr.id_receta;


-- ════════════════════════════════════════════════════════════
-- NODO 4 — Administración (Jorge)
-- Base: sgcm_nodo4
-- Caso: Facturas pendientes de pago con días de vencimiento
-- ════════════════════════════════════════════════════════════

SELECT
    f.id_factura,
    f.fecha_emision,
    c.id_paciente,
    f.subtotal,
    f.iva,
    f.total,
    f.estatus_pago,
    DATEDIFF(CURDATE(), f.fecha_emision) AS dias_vencida
FROM (
    SELECT id_factura, id_consulta, fecha_emision, subtotal, iva, total, estatus_pago
    FROM FACTURA
    WHERE estatus_pago = 'pendiente'
) f
JOIN CITA_F4 c ON c.id_cita = f.id_consulta
ORDER BY dias_vencida DESC, f.total DESC;


-- ════════════════════════════════════════════════════════════
-- NODO 5 — Reportes (Oscar)
-- Base: sgcm_nodo5
-- Caso: Análisis de ausentismo — top pacientes con más cancelaciones
-- ════════════════════════════════════════════════════════════

SELECT
    id_paciente,
    COUNT(*) AS num_cancelaciones,
    MIN(fecha_cita) AS primera_cancelacion,
    MAX(fecha_cita) AS ultima_cancelacion
FROM CITA_F5
GROUP BY id_paciente
ORDER BY num_cancelaciones DESC
LIMIT 10;
