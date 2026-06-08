-- ============================================================
-- SGCM — CONSULTA ÓPTIMA NODO 1
-- Sistema de Gestión de Clínica Médica (SGCM)
-- Bases de Datos Distribuidas — UABC 2026
-- Profesora: Lissethe Guadalupe Lamadrid López
-- ============================================================
-- Nodo 1 — Recepción (Francisco)
-- Base de datos: sgcm_nodo1
-- Caso de uso: Listar todas las citas programadas de un paciente
--              específico con nombre del médico y especialidad.
--
-- Alternativa 3: selección + proyección temprana
-- ============================================================
-- INSTRUCCIONES:
-- 1. Conectar a MySQL (local o remoto)
-- 2. Copiar y pegar esta consulta
-- 3. Reemplazar el 1 en WHERE por el ID del paciente deseado
-- ============================================================

USE sgcm_nodo1;

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
