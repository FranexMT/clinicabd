-- ============================================================
-- SGCM — CONSULTA ÓPTIMA NODO 4
-- Sistema de Gestión de Clínica Médica (SGCM)
-- Bases de Datos Distribuidas — UABC 2026
-- ============================================================
-- Nodo 4 — Administración (Jorge)
-- Base de datos: sgcm_nodo4
-- Caso de uso: Generar estado de cuenta de facturas pendientes
--              de pago con datos del paciente.
--
-- Alternativa 3: selección + proyección temprana
-- ============================================================
-- INSTRUCCIONES:
-- 1. Conectar a MySQL (local o remoto)
-- 2. Copiar y pegar esta consulta
-- 3. Muestra solo facturas con estatus 'pendiente'
-- ============================================================

USE sgcm_nodo4;

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
