-- Regresion de la consulta 4: matriculas historicas y del ciclo 2026-1.
-- La consulta evaluada se extrae directamente de database/03_queries.sql.
BEGIN;

CREATE TEMP VIEW reporte_consulta_04 AS
__CONSULTA_04__;

-- Escenario inicial del conjunto 02_seed.sql.
SELECT 'datos_iniciales' AS escenario,
       codigo, nombre, matriculas, matriculas_ciclo_actual
FROM reporte_consulta_04;

DO $$
BEGIN
    IF (SELECT COUNT(*) FROM reporte_consulta_04) <> 1
       OR NOT EXISTS (
           SELECT 1
           FROM reporte_consulta_04
           WHERE codigo = 'INF-2001'
             AND nombre = 'Bases de Datos I'
             AND matriculas = 3
             AND matriculas_ciclo_actual = 3
       ) THEN
        RAISE EXCEPTION
            'Consulta 04: resultado inicial incorrecto; se esperaba INF-2001 con 3 matriculas historicas y 3 actuales';
    END IF;
END;
$$;

-- Caso limite: el grupo 6 corresponde al ciclo historico 2025-2.
-- La insercion es temporal y se revierte al finalizar esta prueba.
INSERT INTO matricula (id_estudiante, id_grupo, nota, estado)
VALUES (6, 6, 80.0, 'matriculado');

SELECT 'matricula_historica_temporal' AS escenario,
       codigo, nombre, matriculas, matriculas_ciclo_actual
FROM reporte_consulta_04;

DO $$
BEGIN
    IF (SELECT COUNT(*) FROM reporte_consulta_04) <> 1
       OR NOT EXISTS (
           SELECT 1
           FROM reporte_consulta_04
           WHERE codigo = 'INF-2001'
             AND nombre = 'Bases de Datos I'
             AND matriculas = 4
             AND matriculas_ciclo_actual = 3
       ) THEN
        RAISE EXCEPTION
            'Consulta 04: una matricula de 2025-2 debe aumentar el historico a 4, sin alterar las 3 actuales';
    END IF;
END;
$$;

SELECT 'OK: consulta 04 supera las pruebas de regresion'
    AS resultado;

ROLLBACK;
