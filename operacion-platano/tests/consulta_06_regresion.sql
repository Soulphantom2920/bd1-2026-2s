-- Regresion consulta 06: pendientes, evaluadas, aprobados y tasa.
BEGIN;

CREATE TEMP VIEW reporte_consulta_06 AS
__CONSULTA_06__;

SELECT 'datos_iniciales' AS escenario, * FROM reporte_consulta_06;

DO $$
BEGIN
    IF (SELECT COUNT(*) FROM reporte_consulta_06) <> 1
       OR NOT EXISTS (
           SELECT 1 FROM reporte_consulta_06
           WHERE pendientes = 1 AND total_evaluadas = 16
             AND aprobados = 11 AND tasa_aprobacion = 68.8
       ) THEN
        RAISE EXCEPTION 'Consulta 06: valores iniciales incorrectos';
    END IF;
END;
$$;

-- Nota cero cuenta como evaluada, no como aprobada.
UPDATE matricula SET nota = 0 WHERE id_estudiante = 12 AND id_grupo = 1;
-- Una nota aprobatoria en estado retirado se excluye por completo.
UPDATE matricula SET nota = 99 WHERE id_estudiante = 4 AND id_grupo = 1;

SELECT 'nota_cero_y_retirado' AS escenario, * FROM reporte_consulta_06;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM reporte_consulta_06
        WHERE pendientes = 1 AND total_evaluadas = 16
          AND aprobados = 11 AND tasa_aprobacion = 68.8
    ) THEN
        RAISE EXCEPTION 'Consulta 06: nota cero o retirado alteraron indebidamente los conteos';
    END IF;
END;
$$;

-- Caso limite: ninguna matricula activa tiene nota; la tasa debe ser NULL.
UPDATE matricula SET nota = NULL WHERE estado = 'matriculado';
SELECT 'todas_pendientes' AS escenario, * FROM reporte_consulta_06;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM reporte_consulta_06
        WHERE pendientes = 17 AND total_evaluadas = 0
          AND aprobados = 0 AND tasa_aprobacion IS NULL
    ) THEN
        RAISE EXCEPTION 'Consulta 06: denominador cero o pendientes incorrectos';
    END IF;
END;
$$;

SELECT 'OK: consulta 06 supera las pruebas de regresion' AS resultado;
ROLLBACK;
