
-- Prueba de regresion: consulta 2, catalogo de cursos.
-- Utiliza la consulta real extraida de 03_queries.sql.

BEGIN;

CREATE TEMP VIEW catalogo_consulta_02 AS
__CONSULTA_02__

DO $$
BEGIN
    -- Cada curso debe aparecer exactamente una vez.
    IF (SELECT COUNT(*) FROM catalogo_consulta_02)
       <> (SELECT COUNT(*) FROM curso) THEN
        RAISE EXCEPTION 'Cantidad incorrecta de cursos';
    END IF;

    IF EXISTS (
        SELECT codigo
        FROM catalogo_consulta_02
        GROUP BY codigo
        HAVING COUNT(*) > 1
    ) THEN
        RAISE EXCEPTION 'El catalogo contiene cursos repetidos';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM curso c
        LEFT JOIN catalogo_consulta_02 v
            ON v.codigo = c.codigo
        WHERE v.codigo IS NULL
    ) THEN
        RAISE EXCEPTION 'Faltan cursos en el catalogo';
    END IF;

    -- Verificar nombres y carreras.
    IF EXISTS (
        SELECT 1
        FROM curso c
        JOIN carrera ca ON ca.id_carrera = c.id_carrera
        JOIN catalogo_consulta_02 v ON v.codigo = c.codigo
        WHERE v.carrera IS DISTINCT FROM ca.nombre
           OR v.curso IS DISTINCT FROM c.nombre
    ) THEN
        RAISE EXCEPTION 'Datos incorrectos de curso o carrera';
    END IF;

    -- Comparar los conteos con calculos independientes.
    IF EXISTS (
        SELECT 1
        FROM curso c
        JOIN catalogo_consulta_02 v ON v.codigo = c.codigo
        WHERE v.total_grupos <> (
            SELECT COUNT(*)
            FROM grupo g
            WHERE g.id_curso = c.id_curso
        )
        OR v.total_matriculas <> (
            SELECT COUNT(*)
            FROM grupo g
            JOIN matricula m ON m.id_grupo = g.id_grupo
            WHERE g.id_curso = c.id_curso
        )
    ) THEN
        RAISE EXCEPTION 'Conteo incorrecto de grupos o matriculas';
    END IF;

    -- Casos limite del conjunto de datos original.
    IF NOT EXISTS (
        SELECT 1
        FROM catalogo_consulta_02
        WHERE codigo = 'IND-1001'
          AND total_grupos = 0
          AND total_matriculas = 0
    ) THEN
        RAISE EXCEPTION 'Fallo: curso sin grupos';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM catalogo_consulta_02
        WHERE codigo = 'INF-4001'
          AND total_grupos = 1
          AND total_matriculas = 0
    ) THEN
        RAISE EXCEPTION 'Fallo: grupo sin matriculas';
    END IF;
END;
$$;

SELECT 'OK: pruebas de consulta 2 superadas' AS resultado;

ROLLBACK;
