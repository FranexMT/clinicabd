-- ============================================================
-- SGCM — CONSULTA ÓPTIMA NODO 5
-- Sistema de Gestión de Clínica Médica (SGCM)
-- Bases de Datos Distribuidas — UABC 2026
-- Profesora: Lissethe Guadalupe Lamadrid López
-- ============================================================
-- Nodo 5 — Reportes (Oscar)
-- Base de datos: sgcm_nodo5
-- Caso de uso: Analizar los pacientes que más cancelan citas
--              (ausentismo).
--
-- Alternativa 3: selección + proyección temprana
-- ============================================================
-- INSTRUCCIONES:
-- 1. Conectar a MySQL (local o remoto)
-- 2. Copiar y pegar esta consulta
-- 3. Muestra top 10 pacientes con más cancelaciones
-- ============================================================

USE sgcm_nodo5;

SELECT
    id_paciente,
    COUNT(*) AS num_cancelaciones,
    MIN(fecha_cita) AS primera_cancelacion,
    MAX(fecha_cita) AS ultima_cancelacion
FROM CITA_F5
GROUP BY id_paciente
ORDER BY num_cancelaciones DESC
LIMIT 10;
