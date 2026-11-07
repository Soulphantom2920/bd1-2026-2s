-- Regresion consulta 05: matriculas historicas por curso, sin fusionar homonimos.
BEGIN;

CREATE TEMP VIEW reporte_consulta_05 AS
__CONSULTA_05__;

SELECT codigo, curso, total_matriculas FROM reporte_consulta_05;

DO $$
BEGIN
    IF (SELECT COUNT(*) FROM reporte_consulta_05) <> 6
       OR (SELECT COUNT(DISTINCT codigo) FROM reporte_consulta_05) <> 6 THEN
        RAISE EXCEPTION 'Consulta 05: cantidad o identidad de cursos incorrecta';
    END IF;

    -- La comparacion completa evita aceptar cursos fusionados u omitidos.
    IF EXISTS (
        SELECT 1
        FROM (VALUES
            ('INF-1001', 'Programación I', 7::bigint),
            ('INF-1002', 'Programación II', 2::bigint),
            ('INF-2001', 'Bases de Datos I', 3::bigint),
            ('INF-2002', 'Sistemas Operativos', 2::bigint),
            ('INF-2003', 'Redes de Computadoras', 2::bigint),
            ('ADM-2001', 'Bases de Datos I', 2::bigint)
        ) AS esperado(codigo, curso, total_matriculas)
        FULL OUTER JOIN reporte_consulta_05 AS obtenido USING (codigo)
        WHERE esperado.codigo IS NULL OR obtenido.codigo IS NULL
           OR obtenido.curso IS DISTINCT FROM esperado.curso
           OR obtenido.total_matriculas IS DISTINCT FROM esperado.total_matriculas
    ) THEN
        RAISE EXCEPTION 'Consulta 05: el detalle historico no coincide con los datos iniciales';
    END IF;

    -- Verificacion independiente por identidad del curso.
    IF EXISTS (
        SELECT 1
        FROM reporte_consulta_05 r
        JOIN curso cu ON cu.codigo = r.codigo
        WHERE r.total_matriculas IS DISTINCT FROM (
            SELECT COUNT(*)
            FROM grupo g JOIN matricula m ON m.id_grupo = g.id_grupo
            WHERE g.id_curso = cu.id_curso
        )
    ) THEN
        RAISE EXCEPTION 'Consulta 05: conteo historico incorrecto por id_curso';
    END IF;
END;
$$;

SELECT 'OK: consulta 05 supera las pruebas de regresion' AS resultado;
ROLLBACK;
