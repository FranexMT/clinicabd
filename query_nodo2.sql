-- ============================================================
-- SGCM — CONSULTA ÓPTIMA NODO 2
-- Sistema de Gestión de Clínica Médica (SGCM)
-- Bases de Datos Distribuidas — UABC 2026
-- Profesora: Lissethe Guadalupe Lamadrid López
-- ============================================================
-- Nodo 2 — Médicos (Axel)
-- Base de datos: sgcm_nodo2
-- Caso de uso: Obtener el expediente clínico completo de un
--              paciente: datos personales, diagnósticos y recetas.
--
-- Alternativa 3: selección + proyección temprana
-- ============================================================
-- INSTRUCCIONES:
-- 1. Conectar a MySQL (local o remoto)
-- 2. Copiar y pegar esta consulta
-- 3. Reemplazar el 1 en WHERE por el ID del paciente deseado
-- ============================================================

USE sgcm_nodo2;

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
