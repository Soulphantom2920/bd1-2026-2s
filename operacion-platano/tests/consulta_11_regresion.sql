-- Regresion consulta 11: grupos actuales por identidad de profesor.
BEGIN;

CREATE TEMP VIEW reporte_consulta_11 AS
__CONSULTA_11__;

SELECT 'datos_iniciales' AS escenario, * FROM reporte_consulta_11;

DO $$
BEGIN
    IF (SELECT COUNT(*) FROM reporte_consulta_11) <> 4
       OR (SELECT SUM(cantidad_grupos) FROM reporte_consulta_11) <> 6 THEN
        RAISE EXCEPTION 'Consulta 11: profesores o grupos iniciales incorrectos';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM (VALUES
            (1, 'Rodrigo Salas Umaña', 3::bigint),
            (2, 'Mónica Vega Chaves', 1::bigint),
            (3, 'Esteban Brenes Quirós', 2::bigint),
            (4, 'Rodrigo A. Salas Umaña', 0::bigint)
        ) AS esperado(id_profesor, profesor, cantidad_grupos)
        FULL OUTER JOIN reporte_consulta_11 obtenido USING (id_profesor)
        WHERE esperado.id_profesor IS NULL OR obtenido.id_profesor IS NULL
           OR obtenido.profesor IS DISTINCT FROM esperado.profesor
           OR obtenido.cantidad_grupos IS DISTINCT FROM esperado.cantidad_grupos
    ) THEN
        RAISE EXCEPTION 'Consulta 11: conteo inicial por profesor incorrecto';
    END IF;
END;
$$;

-- Un profesor adicional con el mismo nombre no debe fusionarse con el original.
INSERT INTO profesor (cedula, nombre, id_carrera)
VALUES ('PRUEBA-11', 'Rodrigo Salas Umaña', 1);

-- El grupo 8 estaba sin profesor; se asigna temporalmente al homonimo.
UPDATE grupo
SET id_profesor = (SELECT id_profesor FROM profesor WHERE cedula = 'PRUEBA-11')
WHERE id_grupo = 8;

SELECT 'profesores_homonimos' AS escenario, * FROM reporte_consulta_11;

DO $$
BEGIN
    IF (SELECT COUNT(*) FROM reporte_consulta_11) <> 5
       OR (SELECT SUM(cantidad_grupos) FROM reporte_consulta_11) <> 7
       OR (SELECT COUNT(*) FROM reporte_consulta_11
           WHERE profesor = 'Rodrigo Salas Umaña') <> 2
       OR NOT EXISTS (
           SELECT 1 FROM reporte_consulta_11
           WHERE id_profesor = 1 AND cantidad_grupos = 3
       )
       OR NOT EXISTS (
           SELECT 1 FROM reporte_consulta_11
           WHERE id_profesor = (SELECT id_profesor FROM profesor WHERE cedula = 'PRUEBA-11')
             AND cantidad_grupos = 1
       )
       OR NOT EXISTS (
           SELECT 1 FROM reporte_consulta_11
           WHERE id_profesor = 4 AND cantidad_grupos = 0
       ) THEN
        RAISE EXCEPTION 'Consulta 11: fusion de profesores homonimos o filtro de ciclo incorrecto';
    END IF;
END;
$$;

SELECT 'OK: consulta 11 supera las pruebas de regresion' AS resultado;
ROLLBACK;
