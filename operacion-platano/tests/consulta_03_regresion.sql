
BEGIN;

-- La sentencia real se inserta desde validar_consulta_03.ps1.
CREATE TEMP VIEW reporte_consulta_03 AS
__CONSULTA_03__;

DO $$
DECLARE
    diferencias INTEGER;
BEGIN
    -- Comparar los resultados completos contra los datos iniciales.
    SELECT COUNT(*)
    INTO diferencias
    FROM (
        VALUES
            (1, 'INF-1001', 30, 5),
            (2, 'INF-1002', 25, 2),
            (3, 'INF-2001', 30, 3),
            (4, 'INF-2002', 20, 2),
            (5, 'INF-2003', 20, 2),
            (7, 'ADM-2001', 25, 2),
            (8, 'INF-4001', 15, 0)
    ) AS esperado(id_grupo, codigo, cupo, matriculados)
    FULL OUTER JOIN reporte_consulta_03 AS obtenido
        USING (id_grupo)
    WHERE obtenido.id_grupo IS NULL
       OR esperado.id_grupo IS NULL
       OR obtenido.codigo IS DISTINCT FROM esperado.codigo
       OR obtenido.cupo IS DISTINCT FROM esperado.cupo
       OR obtenido.matriculados IS DISTINCT FROM esperado.matriculados;

    IF diferencias <> 0 THEN
        RAISE EXCEPTION
            'Consulta 03: % grupos tienen resultados incorrectos',
            diferencias;
    END IF;

    -- Comprobar los totales del reporte.
    IF (
        SELECT COALESCE(SUM(matriculados), 0)
        FROM reporte_consulta_03
    ) <> 16 THEN
        RAISE EXCEPTION
            'Consulta 03: total de matriculados incorrecto';
    END IF;

    IF (
        SELECT COALESCE(SUM(cupo), 0)
        FROM reporte_consulta_03
    ) <> 165 THEN
        RAISE EXCEPTION
            'Consulta 03: total de cupos incorrecto';
    END IF;

    -- Comparar cada grupo contra un conteo independiente.
    IF EXISTS (
        SELECT 1
        FROM reporte_consulta_03 AS r
        WHERE r.matriculados IS DISTINCT FROM (
            SELECT COUNT(DISTINCT m.id_estudiante)
            FROM matricula AS m
            WHERE m.id_grupo = r.id_grupo
              AND m.estado = 'matriculado'
        )
    ) THEN
        RAISE EXCEPTION
            'Consulta 03: conteo de ocupacion inconsistente';
    END IF;
END;
$$;

SELECT 'OK: consulta 03 supera las pruebas de regresion'
    AS resultado;

ROLLBACK;
