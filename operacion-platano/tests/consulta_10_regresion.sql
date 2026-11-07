-- Regresion consulta 10: detalle de cursos aprobados y sus creditos.
BEGIN;

CREATE TEMP VIEW reporte_consulta_10 AS
__CONSULTA_10__;

SELECT 'datos_iniciales' AS escenario, * FROM reporte_consulta_10;

DO $$
BEGIN
    IF (SELECT COUNT(*) FROM reporte_consulta_10) <> 11
       OR (SELECT COALESCE(SUM(creditos), 0) FROM reporte_consulta_10) <> 40 THEN
        RAISE EXCEPTION 'Consulta 10: cantidad de cursos aprobados o creditos incorrecta';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM (VALUES
            ('2021001', 'Ana Morales Jiménez', 'INF-1001', 4),
            ('2021001', 'Ana Morales Jiménez', 'INF-2001', 4),
            ('2021003', 'Beatriz Solano Vargas', 'ADM-2001', 3),
            ('2021002', 'Carlos Jiménez Rojas', 'INF-1001', 4),
            ('2021002', 'Carlos Jiménez Rojas', 'INF-2002', 3),
            ('2021002', 'Carlos Jiménez Rojas', 'INF-2003', 3),
            ('2021005', 'Elena Castro Mora', 'INF-2002', 3),
            ('2021008', 'Hugo Araya Núñez', 'INF-1001', 4),
            ('2021009', 'Irene Lobo Salas', 'INF-1001', 4),
            ('2021010', 'Javier Núñez Brenes', 'INF-1002', 4),
            ('2021010', 'Javier Núñez Salas', 'INF-2001', 4)
        ) AS esperado(carnet, nombre, codigo, creditos)
        FULL OUTER JOIN reporte_consulta_10 obtenido
            ON obtenido.carnet = esperado.carnet
           AND obtenido.nombre = esperado.nombre
           AND obtenido.codigo = esperado.codigo
        WHERE esperado.carnet IS NULL OR obtenido.carnet IS NULL
           OR obtenido.creditos IS DISTINCT FROM esperado.creditos
    ) THEN
        RAISE EXCEPTION 'Consulta 10: detalle de aprobaciones inicial incorrecto';
    END IF;
END;
$$;

-- Un registro retirado con nota aprobatoria no otorga creditos.
UPDATE matricula SET nota = 99 WHERE id_estudiante = 4 AND id_grupo = 1;
DO $$
BEGIN
    IF (SELECT COUNT(*) FROM reporte_consulta_10) <> 11 THEN
        RAISE EXCEPTION 'Consulta 10: incluyo una matricula retirada';
    END IF;
END;
$$;

-- La materia pendiente de Ana se aprueba con 70, agregando solo ese curso.
UPDATE matricula SET nota = 70 WHERE id_estudiante = 1 AND id_grupo = 5;

DO $$
BEGIN
    IF (SELECT COUNT(*) FROM reporte_consulta_10) <> 12
       OR NOT EXISTS (
           SELECT 1 FROM reporte_consulta_10
           WHERE carnet = '2021001' AND nombre = 'Ana Morales Jiménez'
             AND codigo = 'INF-2003' AND creditos = 3
       ) THEN
        RAISE EXCEPTION 'Consulta 10: no contabiliza la aprobacion con nota 70';
    END IF;
END;
$$;

-- Aprobar el mismo curso en otro grupo no duplica la fila del detalle.
INSERT INTO matricula (id_estudiante, id_grupo, nota, estado)
VALUES (1, 6, 85, 'matriculado');

SELECT 'aprobacion_y_curso_repetido' AS escenario, * FROM reporte_consulta_10;

DO $$
BEGIN
    IF (SELECT COUNT(*) FROM reporte_consulta_10) <> 12
       OR (SELECT COUNT(*) FROM reporte_consulta_10
           WHERE carnet = '2021001' AND nombre = 'Ana Morales Jiménez'
             AND codigo = 'INF-2001') <> 1 THEN
        RAISE EXCEPTION 'Consulta 10: duplico creditos por el mismo curso aprobado';
    END IF;
END;
$$;

SELECT 'OK: consulta 10 supera las pruebas de regresion' AS resultado;
ROLLBACK;
