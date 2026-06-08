-- ============================================================
-- SGCM — CONSULTA ÓPTIMA NODO 3
-- Sistema de Gestión de Clínica Médica (SGCM)
-- Bases de Datos Distribuidas — UABC 2026
-- Profesora: Lissethe Guadalupe Lamadrid López
-- ============================================================
-- Nodo 3 — Farmacia (Elmer)
-- Base de datos: sgcm_nodo3
-- Caso de uso: Consultar todas las recetas con medicamentos
--              pendientes de dispensar.
--
-- Alternativa 3: selección + proyección temprana
-- ============================================================
-- INSTRUCCIONES:
-- 1. Conectar a MySQL (local o remoto)
-- 2. Copiar y pegar esta consulta
-- 3. El resultado muestra solo recetas NO dispensadas (dispensado = 0)
-- ============================================================

USE sgcm_nodo3;

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
