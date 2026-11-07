-- Regresion consulta 09: elegibilidad requiere TODOS los cursos previos aprobados.
BEGIN;

CREATE TEMP VIEW reporte_consulta_09 AS
__CONSULTA_09__;

SELECT 'datos_iniciales' AS escenario, * FROM reporte_consulta_09;

DO $$
BEGIN
    IF (SELECT COUNT(*) FROM reporte_consulta_09) <> 1
       OR NOT EXISTS (
           SELECT 1 FROM reporte_consulta_09
           WHERE carnet = '2021002' AND nombre = 'Carlos Jiménez Rojas'
       ) THEN
        RAISE EXCEPTION 'Consulta 09: con los datos iniciales solo Carlos cumple ambos requisitos';
    END IF;
END;
$$;

-- Elena aprobo Sistemas Operativos, pero Programacion I retirada no habilita.
INSERT INTO matricula (id_estudiante, id_grupo, nota, estado)
VALUES (5, 1, 90, 'retirado');

DO $$
BEGIN
    IF (SELECT COUNT(*) FROM reporte_consulta_09) <> 1 THEN
        RAISE EXCEPTION 'Consulta 09: una matricula retirada no satisface requisitos';
    END IF;
END;
$$;

-- Aun matriculada, 69.9 no satisface el requisito.
UPDATE matricula SET estado = 'matriculado', nota = 69.9
WHERE id_estudiante = 5 AND id_grupo = 1;

DO $$
BEGIN
    IF (SELECT COUNT(*) FROM reporte_consulta_09) <> 1 THEN
        RAISE EXCEPTION 'Consulta 09: nota 69.9 no satisface requisitos';
    END IF;
END;
$$;

-- Nota 70 exacta satisface el segundo requisito y habilita a Elena.
UPDATE matricula SET nota = 70 WHERE id_estudiante = 5 AND id_grupo = 1;
SELECT 'ambos_requisitos_cumplidos' AS escenario, * FROM reporte_consulta_09;

DO $$
BEGIN
    IF (SELECT COUNT(*) FROM reporte_consulta_09) <> 2
       OR NOT EXISTS (
           SELECT 1 FROM reporte_consulta_09
           WHERE carnet = '2021005' AND nombre = 'Elena Castro Mora'
       )
       OR NOT EXISTS (
           SELECT 1 FROM reporte_consulta_09
           WHERE carnet = '2021002' AND nombre = 'Carlos Jiménez Rojas'
       ) THEN
        RAISE EXCEPTION 'Consulta 09: falla al comprobar simultaneamente todos los requisitos';
    END IF;
END;
$$;

SELECT 'OK: consulta 09 supera las pruebas de regresion' AS resultado;
ROLLBACK;
