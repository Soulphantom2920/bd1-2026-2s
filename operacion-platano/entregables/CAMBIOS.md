# Registro de cambios — Operación P.L.A.T.A.N.O.

## Consulta 2 — Catálogo de cursos por carrera

**Archivo modificado:** `database/03_queries.sql`  
**Referencia:** `docs/reglas_negocio.md`, sección 3.  
**Estado:** Implementada y validada funcionalmente.

### Problema identificado

La consulta original utilizaba uniones internas (`INNER JOIN`) entre las tablas `curso`, `grupo` y `matricula`, lo que excluía del catálogo aquellos cursos sin grupos o sin matrículas registradas.

En el conjunto de datos inicial, la consulta devolvía 6 de los 8 cursos existentes. Los cursos omitidos eran:

- `IND-1001`: no tenía grupos asociados.
- `INF-4001`: tenía un grupo asociado, pero ninguna matrícula.

Adicionalmente, el reporte no incluía la cantidad de grupos, aunque su encabezado indicaba que debía proporcionar esa información.

### Causa raíz

Las uniones internas exigían la existencia de registros relacionados en todas las tablas involucradas. Esta condición era inadecuada para un catálogo que debía incluir cursos independientemente de su actividad académica.

El reporte también carecía de una agregación para contabilizar grupos.

### Corrección implementada

Se sustituyeron por `LEFT JOIN` las uniones de `curso` con `grupo` y de `grupo` con `matricula`, conservando los cursos sin registros asociados.

Se incorporó `COUNT(DISTINCT g.id_grupo)` para calcular la cantidad de grupos sin duplicarlos por cada matrícula relacionada.

Se mantuvo `COUNT(m.id_matricula)` para contabilizar los registros de matrícula existentes y se incluyeron los identificadores de las entidades correspondientes en la agrupación.

La unión entre `carrera` y `curso` se mantuvo como `INNER JOIN`, debido a que todo curso debe pertenecer a una carrera.

### Verificación y resultados

La consulta corregida se ejecutó sobre PostgreSQL 16 utilizando los datos originales.

Resultados obtenidos:

- 8 cursos incluidos en el catálogo.
- 8 grupos contabilizados.
- 18 registros de matrícula contabilizados.
- `IND-1001`: 0 grupos y 0 matrículas.
- `INF-4001`: 1 grupo y 0 matrículas.
- Los cursos `ADM-2001` e `INF-2001`, ambos denominados «Bases de Datos I», permanecieron separados.

También se ejecutaron las otras once consultas del archivo sin errores SQL.

### Prueba de regresión

Se incorporó una prueba automatizada que ejecuta la consulta 2 desde el archivo original y contrasta sus resultados con las tablas de la base de datos.

**Archivos de prueba:**
- `tests/validar_consulta_02.ps1`
- `tests/consulta_02_regresion.sql`

**Evidencias:**
- `entregables/evidencias/02_consultas_originales.txt`
- `entregables/evidencias/03_consultas_tras_correccion_2.txt`
- `entregables/evidencias/04_regresion_consulta_02.txt`

### Alcance y limitaciones

El reporte contabiliza registros históricos de matrícula, no estudiantes únicos. Incluye las matrículas retiradas y los registros duplicados que todavía existen en el conjunto de datos.

Este criterio conserva la semántica de «matrículas totales» del reporte original. La depuración de registros duplicados se abordará independientemente durante la corrección de los datos y las restricciones del esquema.

La inclusión de cursos sin actividad responde al propósito declarado del catálogo. La sección 3 de las reglas oficiales establece la identificación individual de los cursos, pero no define explícitamente el formato de este reporte.