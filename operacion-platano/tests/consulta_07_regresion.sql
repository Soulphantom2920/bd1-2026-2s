-- Regresion consulta 07: aprobados INF-2001 con nota >= 70 y no retirados.
BEGIN;

CREATE TEMP VIEW reporte_consulta_07 AS
__CONSULTA_07__;

SELECT 'datos_iniciales' AS escenario, * FROM reporte_consulta_07;

DO $$
BEGIN
    IF (SELECT COUNT(*) FROM reporte_consulta_07) <> 2
       OR NOT EXISTS (
           SELECT 1 FROM reporte_consulta_07
           WHERE carnet = '2021001' AND nombre = 'Ana Morales Jiménez' AND nota = 70
       )
       OR NOT EXISTS (
           SELECT 1 FROM reporte_consulta_07
           WHERE carnet = '2021010' AND nombre = 'Javier Núñez Salas' AND nota = 90
       ) THEN
        RAISE EXCEPTION 'Consulta 07: aprobados iniciales incorrectos';
    END IF;
END;
$$;

-- Pasar 69.9 a 70 debe incorporar a Elena (nota exacta aprobatoria).
UPDATE matricula SET nota = 70 WHERE id_estudiante = 5 AND id_grupo = 3;
-- Un retiro con nota aprobatoria NO debe aparecer.
INSERT INTO matricula (id_estudiante, id_grupo, nota, estado)
VALUES (6, 3, 98, 'retirado');

SELECT 'umbral_y_retiro' AS escenario, * FROM reporte_consulta_07;

DO $$
BEGIN
    IF (SELECT COUNT(*) FROM reporte_consulta_07) <> 3
       OR NOT EXISTS (
           SELECT 1 FROM reporte_consulta_07
           WHERE carnet = '2021005' AND nombre = 'Elena Castro Mora' AND nota = 70
       )
       OR EXISTS (
           SELECT 1 FROM reporte_consulta_07 WHERE carnet = '2021006'
       )
       OR EXISTS (
           SELECT 1 FROM reporte_consulta_07 WHERE carnet IN ('2021003', '2021007')
       ) THEN
        RAISE EXCEPTION 'Consulta 07: falla el umbral, el estado o la separacion de cursos homonimos';
    END IF;
END;
$$;

SELECT 'OK: consulta 07 supera las pruebas de regresion' AS resultado;
ROLLBACK;
