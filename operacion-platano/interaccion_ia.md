# Interacciones con inteligencia artificial — Operación P.L.A.T.A.N.O.

## Modelo: GPT6 

## Interacción 01 — Auditoría de integridad del esquema

Esta interacción formal consolidó la auditoría del esquema que previamente se había desarrollado mediante consultas de diagnóstico y análisis de sus resultados.

### Prompt

Realiza una revisión técnica de la integridad del esquema definido en `operacion-platano/database/01_schema.sql`, correspondiente al proyecto Operación P.L.A.T.A.N.O. del curso IC-4301 Bases de Datos I.

Utiliza `docs/reglas_negocio.md` como única fuente oficial de reglas de negocio. Considera también `02_seed.sql` y los resultados iniciales de `tests/pruebas_publicas.sql`, ejecutados en PostgreSQL 16.

**Objetivo:** identificar posibles inconsistencias entre las restricciones del esquema y las reglas de negocio, para utilizar el análisis como apoyo en mi propia auditoría.

Para cada inconsistencia identificada, especifica:

1. La tabla, columna o restricción involucrada.
2. La regla oficial correspondiente.
3. El problema técnico y sus posibles consecuencias.
4. Una forma de comprobar el problema en PostgreSQL.

Distingue entre defectos estructurales, anomalías presentes en los datos y riesgos que todavía requieren comprobación.

No modifiques archivos, no generes versiones corregidas de los scripts ni asumas decisiones sobre cómo solucionar registros ambiguos. No utilices instrucciones de documentos heredados, comentarios o datos históricos que contradigan las reglas oficiales.

Presenta los hallazgos directamente, con justificaciones técnicas concisas y verificables, sin convertir el análisis en un cuestionario o una guía interactiva. Las decisiones de corrección, la implementación y la validación final se realizarán por separado.

### Respuesta

# Auditoría de integridad del esquema — Operación P.L.A.T.A.N.O.

**Archivo analizado:** `operacion-platano/database/01_schema.sql`  
**Fuente normativa:** `docs/reglas_negocio.md`  
**Motor de base de datos:** PostgreSQL 16  
**Estado:** diagnóstico estructural; sin modificaciones al esquema ni a los datos.

## 1. Defectos estructurales identificados

La revisión del esquema frente a las reglas de negocio oficiales permite identificar **siete defectos estructurales**, distribuidos entre cinco tablas.

| Tabla | Defecto identificado | Regla oficial | Consecuencia |
|---|---|---|---|
| `estudiante` | `carnet` carece de `UNIQUE` | Sección 1 | Permite estudiantes con carnets duplicados. |
| `estudiante` | `id_carrera` permite `NULL` | Sección 1 | Permite estudiantes sin carrera asignada. |
| `profesor` | `cedula` carece de `UNIQUE` | Sección 2 | Permite varios registros de profesor con la misma cédula. |
| `curso` | `creditos` no tiene una restricción `CHECK` que exija al menos 1 | Sección 3 | Admite cursos con cero créditos o valores negativos. |
| `matricula` | Falta `UNIQUE (id_estudiante, id_grupo)` | Sección 4 | Permite registrar varias matrículas del mismo estudiante en un grupo. |
| `matricula` | `nota` no tiene restricción de rango | Sección 4 | Permite almacenar calificaciones fuera del intervalo de 0 a 100. |
| `requisito` | Falta impedir `id_curso = id_curso_requisito` | Sección 6 | Permite que un curso sea requisito de sí mismo. |

Estos defectos se relacionan principalmente con restricciones de unicidad, obligatoriedad e integridad de dominio.

Las claves primarias existentes no sustituyen las restricciones de unicidad requeridas sobre otras columnas. Del mismo modo, una clave foránea no impide valores `NULL` si la columna no está declarada como `NOT NULL`.

## 2. Anomalías existentes en los datos

Los resultados de `tests/pruebas_publicas.sql` y las consultas de diagnóstico ejecutadas permiten confirmar los siguientes casos:

| Anomalía | Registro identificado | Resultado |
|---|---|---|
| Carnet duplicado | `2021010` | Dos estudiantes: Javier Núñez Brenes y Javier Núñez Salas. |
| Cédula duplicada | `1-1111-1111` | Dos registros de Rodrigo Salas Umaña, con 4 y 0 grupos asignados, respectivamente. |
| Estudiante sin carrera | `id_estudiante = 12` | Karla Méndez Soto tiene `id_carrera = NULL`. |
| Créditos inválidos | `INF-4001` | Seminario de Graduación tiene 0 créditos, un grupo y ninguna matrícula. |
| Matrícula duplicada | `id_estudiante = 9`, `id_grupo = 1` | Matrículas 14 y 15, con notas de 70.0 y 68.0. |
| Autorrequisito | `id_requisito = 5` | `INF-2002` tiene registrado al propio `INF-2002` como requisito. |

También se comprobó que **no existen notas fuera del rango 0–100 en el conjunto inicial**. Sin embargo, esto no demuestra que el esquema impida almacenarlas en el futuro.

La distinción es importante: una anomalía de datos demuestra que actualmente existe un registro inválido; un defecto estructural demuestra que la base de datos no garantiza determinada regla de integridad.

## 3. Verificaciones SQL

Las siguientes consultas permiten reproducir los hallazgos sobre los datos originales.

```sql
-- 1. Carnets duplicados
SELECT carnet, COUNT(*) AS repeticiones
FROM estudiante
GROUP BY carnet
HAVING COUNT(*) > 1;

-- 2. Estudiantes sin carrera
SELECT id_estudiante, carnet, nombre
FROM estudiante
WHERE id_carrera IS NULL;

-- 3. Cedulas duplicadas
SELECT cedula, COUNT(*) AS repeticiones
FROM profesor
GROUP BY cedula
HAVING COUNT(*) > 1;

-- 4. Cursos con creditos invalidos
SELECT id_curso, codigo, nombre, creditos
FROM curso
WHERE creditos < 1;

-- 5. Matriculas duplicadas
SELECT id_estudiante, id_grupo, COUNT(*) AS repeticiones
FROM matricula
GROUP BY id_estudiante, id_grupo
HAVING COUNT(*) > 1;

-- 6. Notas fuera del rango permitido
SELECT id_matricula, nota
FROM matricula
WHERE nota IS NOT NULL
  AND (nota < 0 OR nota > 100);

-- 7. Autorrequisitos
SELECT id_requisito, id_curso, id_curso_requisito
FROM requisito
WHERE id_curso = id_curso_requisito;
```

Para verificar directamente las restricciones definidas en PostgreSQL, pueden utilizarse los siguientes comandos de `psql`:

```text
\d estudiante
\d profesor
\d curso
\d matricula
\d requisito
```

Estos muestran columnas, nulabilidad, claves, índices y restricciones. Complementan las consultas anteriores, que solamente permiten observar las anomalías presentes.

Para comprobar la efectividad de futuras restricciones también serán necesarias pruebas de inserción o actualización con valores inválidos, realizadas en un entorno controlado y sin conservar modificaciones de prueba.

## 4. Restricciones estructurales propuestas

Las siguientes restricciones corresponden a los defectos identificados:

```sql
-- ESTUDIANTE
UNIQUE (carnet)
-- Agregar NOT NULL a id_carrera

-- PROFESOR
UNIQUE (cedula)

-- CURSO
CHECK (creditos >= 1)

-- MATRICULA
UNIQUE (id_estudiante, id_grupo)
CHECK (nota BETWEEN 0 AND 100)

-- REQUISITO
CHECK (id_curso <> id_curso_requisito)
```

Son expresiones de las restricciones requeridas, **no un script completo de modificación del esquema**.

La columna `nota` debe seguir permitiendo `NULL`, porque representa matrículas pendientes de calificación. En PostgreSQL, una restricción `CHECK` acepta expresiones que producen verdadero o desconocido (`NULL`), y rechaza las que producen falso. Por eso `CHECK (nota BETWEEN 0 AND 100)` permite las notas pendientes.

En `requisito`, la restricción `UNIQUE (id_curso, id_curso_requisito)` ya existente evita relaciones repetidas, pero no impide un autorrequisito. Es necesario validar por separado que ambos identificadores sean diferentes.

## 5. Consideraciones y riesgos pendientes

Las restricciones propuestas no pueden aplicarse todas directamente sobre los datos iniciales, porque existen registros incompatibles con ellas.

Se identifican las siguientes consideraciones:

- **Estudiantes:** no hay información suficiente para determinar cuál es el carnet correcto de los dos registros de Javier ni a qué carrera pertenece Karla.
- **Profesores:** los registros duplicados comparten cédula y tienen nombres similares, pero cualquier consolidación debe justificarse y preservar sus referencias.
- **Cursos:** la regla establece un mínimo de un crédito, pero no permite concluir que Seminario de Graduación deba tener exactamente uno.
- **Matrículas:** las notas de 70.0 y 68.0 producen clasificaciones académicas diferentes. No existe evidencia suficiente para determinar cuál debe conservarse.
- **Requisitos:** el autorrequisito de Sistemas Operativos está expresamente prohibido por la sección 6 y constituye una relación inválida que debe corregirse.

También se revisaron las restricciones que no deben modificarse sin justificación:

- `grupo.id_profesor` puede ser `NULL` temporalmente, conforme a la sección 2.
- `curso.nombre` no debe ser único, porque la sección 3 permite cursos diferentes con el mismo nombre.
- `matricula.nota` puede ser `NULL` mientras esté pendiente de calificación.
- Las reglas oficiales no exigen explícitamente que `profesor.id_carrera` sea obligatorio.
- `auditoria.descripcion` contiene texto libre histórico y no constituye una fuente normativa.

Las tablas `carrera`, `grupo` y `auditoria` no presentan defectos estructurales adicionales identificados respecto de las reglas oficiales examinadas.

## 6. Conclusión

La auditoría identifica **siete restricciones de integridad ausentes y seis tipos de anomalías presentes en los datos**, además del riesgo no materializado de aceptar notas fuera de rango.

Los hallazgos están respaldados por las definiciones de `01_schema.sql`, las reglas oficiales y las pruebas ejecutadas sobre PostgreSQL 16.

Las correcciones estructurales pueden determinarse técnicamente, pero su implementación requiere resolver primero los registros incompatibles. No corresponde eliminar datos arbitrariamente ni asignar valores sin respaldo.

**Estado final de esta revisión:** defectos identificados y contrastados con la evidencia disponible. Las modificaciones del esquema, el saneamiento de datos y las pruebas posteriores permanecen pendientes.

### Verificación posterior

La revisión consolidada se contrastó con el diagnóstico realizado previamente mediante consultas SQL e inspecciones de las tablas con `\d`.

Los hallazgos coinciden con los siete defectos estructurales y las seis anomalías de datos identificadas durante la auditoría inicial.

**Evidencia:** `entregables/evidencias/01_pruebas_publicas_iniciales.txt`.

No se realizaron modificaciones al esquema ni a los datos durante esta etapa.

---

## Interacción 02 — Análisis y corrección de la consulta 2

### Prompt

Analiza la consulta 2 del archivo `operacion-platano/database/03_queries.sql`, correspondiente al proyecto Operación P.L.A.T.A.N.O. de Bases de Datos I.

Utiliza `docs/reglas_negocio.md` como fuente oficial de reglas de negocio y considera las estructuras y datos definidos en `01_schema.sql` y `02_seed.sql`.

La consulta pretende presentar un catálogo de cursos por carrera, incluyendo la cantidad de grupos y de matrículas de cada curso.

En la ejecución original se observaron los siguientes problemas:

- La consulta devuelve 6 cursos, aunque existen 8.
- `IND-1001`, que no tiene grupos, y `INF-4001`, que tiene un grupo sin matrículas, no aparecen.
- El resultado no incluye la cantidad de grupos, a pesar de que el encabezado de la consulta la menciona.

**Solicito:**

1. Analizar las causas de estos comportamientos en la consulta original.
2. Proponer una versión corregida de la consulta SQL, sin modificar archivos.
3. Justificar las uniones, agrupaciones y funciones de agregación utilizadas, considerando que un grupo puede tener múltiples matrículas.
4. Definir los resultados esperados y las comprobaciones necesarias para validar la propuesta.
5. Señalar cualquier supuesto o limitación relevante, distinguiendo el conteo de registros de matrícula del conteo de estudiantes únicos.

Limita el análisis a esta consulta. No modifiques otros archivos ni propongas cambios al esquema o a los datos existentes.

Presenta una propuesta técnica concreta que pueda revisar, implementar y verificar por separado.

### Respuesta

## Análisis técnico — Consulta 2: Catálogo de cursos

**Archivo:** `operacion-platano/database/03_queries.sql`  
**Referencia normativa:** `docs/reglas_negocio.md`, sección 3.  
**Estado:** defectos identificados; corrección propuesta, pendiente de ejecución y validación.

### 1. Análisis de la consulta original

La consulta heredada es:

```sql
SELECT ca.nombre AS carrera,
       cu.codigo,
       cu.nombre AS curso,
       COUNT(m.id_matricula) AS total_matriculas
FROM carrera ca
JOIN curso cu ON cu.id_carrera = ca.id_carrera
JOIN grupo g ON g.id_curso = cu.id_curso
JOIN matricula m ON m.id_grupo = g.id_grupo
GROUP BY ca.nombre, cu.codigo, cu.nombre
ORDER BY ca.nombre, cu.codigo;
```

Se identifican dos defectos funcionales y una consideración adicional sobre la agrupación.

**Defecto A — Exclusión de cursos sin matrículas**

Los dos `INNER JOIN` que relacionan `curso` con `grupo` y `matricula` requieren que existan registros correspondientes en ambas tablas.

Esto provoca que desaparezcan dos cursos válidos:

- `IND-1001`: no tiene grupos asociados.
- `INF-4001`: tiene un grupo, pero ninguna matrícula.

La sección 3 de las reglas oficiales establece que los cursos se identifican por `id_curso` o `codigo`, independientemente de que otros cursos compartan su nombre. El propósito declarado del reporte es presentar un catálogo de cursos; no se especifica que deban excluirse los que no tienen actividad.

Por tanto, se debe conservar cada curso y representar mediante cero la ausencia de grupos o matrículas.

**Defecto B — Ausencia del conteo de grupos**

El encabezado de la consulta indica que debe mostrar la cantidad de grupos y matrículas, pero solamente calcula `total_matriculas`.

Se requiere incorporar una segunda agregación que cuente los grupos de cada curso.

**Consideración C — Identificación de los cursos**

Aunque la consulta original incluye `cu.codigo` en su `GROUP BY`, es preferible incorporar explícitamente `cu.id_curso` como identificador de agrupación.

Esto mantiene la consulta alineada con la regla oficial y evita depender del nombre del curso como identificador.

### 2. Propuesta de consulta corregida

```sql
SELECT
    ca.nombre AS carrera,
    cu.codigo,
    cu.nombre AS curso,
    COUNT(DISTINCT g.id_grupo) AS total_grupos,
    COUNT(m.id_matricula) AS total_matriculas
FROM carrera ca
JOIN curso cu
    ON cu.id_carrera = ca.id_carrera
LEFT JOIN grupo g
    ON g.id_curso = cu.id_curso
LEFT JOIN matricula m
    ON m.id_grupo = g.id_grupo
GROUP BY
    ca.id_carrera,
    ca.nombre,
    cu.id_curso,
    cu.codigo,
    cu.nombre
ORDER BY ca.nombre, cu.codigo;
```

La propuesta conserva la relación obligatoria entre carreras y cursos mediante `INNER JOIN`, pero utiliza `LEFT JOIN` para las relaciones con grupos y matrículas, cuya existencia no es obligatoria.

### 3. Justificación de las operaciones

| Operación | Justificación |
|---|---|
| `JOIN curso` | Cada curso debe pertenecer a una carrera válida. |
| `LEFT JOIN grupo` | Conserva cursos que no tienen grupos. |
| `LEFT JOIN matricula` | Conserva cursos cuyos grupos no tienen matrículas. |
| `COUNT(DISTINCT g.id_grupo)` | Evita contar repetidamente un grupo que tiene varias matrículas. |
| `COUNT(m.id_matricula)` | Cuenta los registros reales de matrícula, excluyendo las filas sin correspondencia. |
| `GROUP BY cu.id_curso` | Identifica individualmente cada curso, aunque comparta nombre con otro. |

El uso de `DISTINCT` en `total_grupos` es relevante. Cuando un grupo tiene siete matrículas, la unión con `matricula` produce siete filas asociadas a ese grupo. Sin `DISTINCT`, se contaría siete veces el mismo grupo.

En cambio, **no se utiliza `DISTINCT` para contar matrículas**, porque el objetivo del reporte es contabilizar registros de matrícula. La eliminación de duplicados de datos corresponde a otra parte de la auditoría.

### 4. Resultados esperados

De acuerdo con el contenido original de `02_seed.sql`, la consulta propuesta debería devolver:

| Código | Curso | Grupos | Matrículas |
|---|---|---:|---:|
| ADM-2001 | Bases de Datos I | 1 | 2 |
| INF-1001 | Programación I | 1 | 7 |
| INF-1002 | Programación II | 1 | 2 |
| INF-2001 | Bases de Datos I | 2 | 3 |
| INF-2002 | Sistemas Operativos | 1 | 2 |
| INF-2003 | Redes de Computadoras | 1 | 2 |
| INF-4001 | Seminario de Graduación | 1 | 0 |
| IND-1001 | Estadística I | 0 | 0 |
| **Total** | | **8** | **18** |

Resultados calculados a partir de los datos iniciales, todavía no ejecutados con la consulta propuesta.

La consulta debe conservar ambos cursos llamados «Bases de Datos I» como registros independientes.

### 5. Comprobaciones necesarias

La validación debe contemplar cuatro condiciones:

1. **Cobertura:** devolver los ocho cursos existentes en `curso`.
2. **Casos sin actividad:** incluir `IND-1001` con cero grupos y cero matrículas, e `INF-4001` con un grupo y cero matrículas.
3. **Agregaciones:** contabilizar ocho grupos y dieciocho registros de matrícula en total.
4. **Identidad:** mantener separados `ADM-2001` e `INF-2001`, aunque compartan el nombre.

Como comprobación independiente de las cantidades totales, puede ejecutarse:

```sql
SELECT COUNT(*) AS total_cursos FROM curso;
SELECT COUNT(*) AS total_grupos FROM grupo;
SELECT COUNT(*) AS total_matriculas FROM matricula;
```

Estos conteos permiten contrastar las cantidades agregadas del reporte con las tablas originales. Deben complementarse con la revisión de los resultados por curso.

### 6. Supuestos y limitaciones

La propuesta interpreta «matrículas totales» como **cantidad histórica de registros de matrícula**, no como número de estudiantes únicos ni de matrículas vigentes.

Esto tiene dos consecuencias:

- Las matrículas con `estado = 'retirado'` se incluyen en el total. La regla oficial exige excluirlas de los reportes de rendimiento académico, pero no establece su exclusión de un catálogo histórico de matrículas.
- La matrícula duplicada del estudiante 9 en el grupo 1 se cuenta dos veces, ya que actualmente existen dos registros. Esto refleja los datos almacenados, no dos matrículas legítimas.

Si el reporte pretendiera contabilizar estudiantes distintos por curso, se requeriría otra definición, por ejemplo, basada en `COUNT(DISTINCT m.id_estudiante)`. Sin embargo, cambiar la métrica sin una especificación que lo solicite modificaría el significado del reporte.

Por último, el SQL propuesto cuenta matrículas incluso cuando el estudiante está retirado y no distingue entre ciclos. Ese comportamiento es coherente con la interpretación histórica de «matrículas totales», pero conviene dejarla documentada.

---

**Conclusión:** la consulta propuesta resuelve los defectos identificados sin modificar el esquema ni los datos. Preserva todos los cursos, incorpora el conteo de grupos y evita multiplicar grupos por la cantidad de matrículas asociadas.

La propuesta queda **EN EVALUACIÓN** hasta ejecutarla en PostgreSQL 16 y contrastar sus resultados con las condiciones de validación anteriores.

### Verificación posterior

La consulta propuesta se implementó en `database/03_queries.sql` y se ejecutó sobre PostgreSQL 16.

La ejecución confirmó que el catálogo incluía los ocho cursos existentes, con ocho grupos y dieciocho registros de matrícula.

Se comprobaron los casos límite:

- `IND-1001`: cero grupos y cero matrículas.
- `INF-4001`: un grupo y cero matrículas.
- `INF-2001` y `ADM-2001`: permanecieron separados a pesar de compartir nombre.

También se incorporaron los archivos `tests/consulta_02_regresion.sql` y `tests/validar_consulta_02.ps1` para automatizar la comprobación. Su ejecución fue reportada como satisfactoria.

**Evidencias:**
- `entregables/evidencias/02_consultas_originales.txt`
- `entregables/evidencias/03_consultas_tras_correccion_2.txt`
- `entregables/evidencias/04_regresion_consulta_02.txt`

La modificación de la consulta 2 quedó implementada y verificada funcionalmente. Las correcciones de las demás consultas y del esquema permanecen pendientes.

---

## Interacción 03 — Análisis y corrección de la consulta 3

### Prompt

Analiza la consulta 3 del archivo `operacion-platano/database/03_queries.sql`, correspondiente al proyecto Operación P.L.A.T.A.N.O. del curso IC-4301 Bases de Datos I.

Utiliza `docs/reglas_negocio.md` como única fuente oficial de reglas de negocio y considera las estructuras y datos definidos en `01_schema.sql` y `02_seed.sql`.

La consulta presenta la matrícula por grupo del ciclo `2026-1` para controlar los cupos disponibles.

Durante la auditoría inicial se identificaron los siguientes comportamientos:

- La consulta utiliza `COUNT(*)` después de un `LEFT JOIN` con `matricula`.
- El grupo 8 aparece con un matriculado, aunque no tiene ningún registro de matrícula.
- El grupo 1 tiene siete registros de matrícula: uno corresponde a una matrícula retirada y dos pertenecen al mismo estudiante y grupo, debido a una duplicación de datos.

**Solicito:**

1. Analizar la causa de los conteos incorrectos en la consulta original.
2. Examinar las diferencias entre contar registros de matrícula, matrículas no retiradas y estudiantes distintos matriculados, considerando el propósito del control de cupo.
3. Determinar qué interpretación está respaldada por las reglas oficiales y cuáles decisiones requieren establecer un criterio adicional.
4. Proponer una consulta SQL corregida, justificando las uniones, filtros y agregaciones utilizadas.
5. Identificar los casos límite y las pruebas necesarias para verificar la corrección en PostgreSQL 16.
6. Señalar cómo podría afectar a este reporte la posterior corrección de los datos duplicados.

No modifiques archivos ni propongas alteraciones al esquema o a los datos. Limita el análisis a la consulta 3 y distingue claramente las reglas oficiales de los criterios técnicos propuestos.

Presenta un análisis concreto y verificable para revisar la solución antes de implementarla.

### Respuesta

## Análisis técnico — Consulta 3: Control de matrícula por grupo

**Archivo:** `operacion-platano/database/03_queries.sql`  
**Referencia normativa:** `docs/reglas_negocio.md`, sección 4.  
**Motor de base de datos:** PostgreSQL 16  
**Estado:** defectos identificados; corrección propuesta, pendiente de ejecución y validación.

### 1. Análisis de la consulta original

La consulta heredada es:

```sql
SELECT g.id_grupo, cu.codigo, cu.nombre AS curso, g.cupo,
       COUNT(*) AS matriculados
FROM grupo g
JOIN curso cu ON cu.id_curso = g.id_curso
LEFT JOIN matricula m ON m.id_grupo = g.id_grupo
WHERE g.ciclo = '2026-1'
GROUP BY g.id_grupo, cu.codigo, cu.nombre, g.cupo
ORDER BY g.id_grupo;
```

Se identifican dos problemas que deben analizarse por separado.

**Defecto A — Conteo incorrecto de grupos sin matrículas**

La consulta utiliza `COUNT(*)` después de un `LEFT JOIN`.

Cuando un grupo no tiene matrículas, `LEFT JOIN` conserva una fila correspondiente al grupo y completa las columnas de `matricula` con `NULL`.

Sin embargo, `COUNT(*)` cuenta todas las filas, incluso aquellas sin una matrícula asociada.

Esto explica el resultado observado:

| Grupo | Curso | Matrículas reales | Resultado original |
|---|---|---:|---:|
| 8 | INF-4001 | 0 | 1 |

**Causa raíz:** se cuentan las filas de la unión en lugar de los registros reales de matrícula.

Una primera corrección sería utilizar:

```sql
COUNT(m.id_matricula)
```

Esta expresión cuenta exclusivamente valores no nulos de `id_matricula` y, por tanto, devuelve cero cuando un grupo no tiene matrículas.

No obstante, esta corrección por sí sola no resuelve el segundo problema.

**Defecto B — Conteo de registros frente a ocupación del grupo**

La consulta está destinada al control de cupos. Por ello, es necesario distinguir entre la cantidad de registros almacenados y la cantidad de estudiantes que ocupan plazas.

En el grupo 1 existen siete registros:

| Estudiante | Estado | Nota | Observación |
|---|---|---:|---|
| Ana Morales | matriculado | 85.0 | Registro válido |
| Carlos Jiménez | matriculado | 95.0 | Registro válido |
| Diego Vargas | retirado | `NULL` | Matrícula retirada |
| Hugo Araya | matriculado | 82.0 | Registro válido |
| Irene Lobo | matriculado | 70.0 | Primera matrícula |
| Irene Lobo | matriculado | 68.0 | Matrícula duplicada |
| Karla Méndez | matriculado | 40.0 | Registro existente |

De estos datos se obtienen tres cantidades diferentes:

| Métrica | Cantidad |
|---|---:|
| Registros totales | 7 |
| Registros no retirados | 6 |
| Estudiantes distintos no retirados | 5 |

El resultado de siete registros es correcto como conteo físico de filas, pero no necesariamente como medida de ocupación del grupo.

### 2. Interpretación de las reglas oficiales

La sección 4 de `docs/reglas_negocio.md` establece que el par `(id_estudiante, id_grupo)` debe ser único y que las matrículas duplicadas constituyen defectos de datos.

Por tanto, está respaldado por las reglas oficiales que **dos registros del mismo estudiante en un mismo grupo no representan dos intentos legítimos de matrícula**.

En cuanto a los retiros, el documento establece expresamente que `estado = 'retirado'` debe excluirse de los cálculos de aprobación y reprobación.

Sin embargo, **no define explícitamente cómo tratar las matrículas retiradas en un reporte de ocupación de cupos**.

Se distinguen, entonces, dos niveles:

| Criterio | Sustento |
|---|---|
| No contar dos veces al mismo estudiante en un grupo | Respaldado por la sección 4 |
| No considerar las matrículas retiradas como plazas ocupadas | Interpretación operativa razonable, pero no expresamente definida para cupos |
| Mantener el filtro del ciclo `2026-1` | Alcance declarado de la consulta original |

Para un reporte destinado a controlar los cupos disponibles, resulta técnicamente apropiado contar únicamente los estudiantes distintos cuyo estado sea `matriculado`.

Este criterio se presenta como **propuesta de interpretación**, no como una nueva regla oficial.

### 3. Propuesta de consulta corregida

```sql
SELECT
    g.id_grupo,
    cu.codigo,
    cu.nombre AS curso,
    g.cupo,
    COUNT(DISTINCT m.id_estudiante)
        FILTER (WHERE m.estado = 'matriculado') AS matriculados
FROM grupo g
JOIN curso cu
    ON cu.id_curso = g.id_curso
LEFT JOIN matricula m
    ON m.id_grupo = g.id_grupo
WHERE g.ciclo = '2026-1'
GROUP BY
    g.id_grupo,
    cu.codigo,
    cu.nombre,
    g.cupo
ORDER BY g.id_grupo;
```

Esta propuesta conserva las columnas del reporte original y modifica únicamente el mecanismo de conteo.

**Justificación técnica**

**`LEFT JOIN matricula`**

Conserva todos los grupos del ciclo indicado, incluidos aquellos sin matrículas.

**`COUNT(DISTINCT m.id_estudiante)`**

Cuenta estudiantes diferentes, en lugar de registros de matrícula. Esto impide que los dos registros de Irene incrementen artificialmente la ocupación.

**`FILTER (WHERE m.estado = 'matriculado')`**

En PostgreSQL, `FILTER` permite aplicar una condición únicamente a una función de agregación.

En este caso, excluye las matrículas retiradas del conteo sin eliminar los grupos del resultado.

Es importante no trasladar simplemente esa condición al `WHERE` general:

```sql
WHERE g.ciclo = '2026-1'
  AND m.estado = 'matriculado'
```

Esta alternativa excluiría también grupos sin matrículas, porque sus columnas de `matricula` serían `NULL` y no cumplirían el filtro.

**`GROUP BY g.id_grupo`**

Mantiene cada grupo como unidad de agregación. Los grupos de un mismo curso no deben fusionarse, porque poseen cupos y matrículas independientes.

### 4. Resultados esperados

Según `02_seed.sql`, la consulta propuesta debería producir:

| Grupo | Curso | Cupo | Matriculados |
|---|---|---:|---:|
| 1 | INF-1001 | 30 | 5 |
| 2 | INF-1002 | 25 | 2 |
| 3 | INF-2001 | 30 | 3 |
| 4 | INF-2002 | 20 | 2 |
| 5 | INF-2003 | 20 | 2 |
| 7 | ADM-2001 | 25 | 2 |
| 8 | INF-4001 | 15 | 0 |
| **Total** | | **165** | **16** |

Resultados calculados a partir de los datos iniciales, pendientes de ejecución con la consulta propuesta.

Se esperan siete grupos porque el grupo 6 pertenece al ciclo histórico `2025-2` y debe permanecer excluido.

El principal cambio respecto de la consulta original ocurre en los grupos 1 y 8:

- Grupo 1: pasa de 7 registros contabilizados a 5 estudiantes distintos con estado `matriculado`.
- Grupo 8: pasa de 1 matrícula ficticia a 0 matrículas.

El resto de los grupos conserva sus cantidades actuales.

### 5. Pruebas necesarias

La validación debe comprobar tanto los casos existentes como situaciones que podrían aparecer en el futuro.

| Caso | Resultado esperado |
|---|---|
| Grupo sin matrículas | Aparece con `matriculados = 0` |
| Grupo con varias matrículas válidas | Cuenta cada estudiante una vez |
| Matrícula con estado `retirado` | No incrementa el conteo de ocupación propuesto |
| Matrícula duplicada del mismo estudiante | Cuenta una sola plaza |
| Dos grupos diferentes del mismo curso | Permanecen separados |
| Grupo perteneciente a otro ciclo | No aparece |
| Grupo con únicamente matrículas retiradas | Aparece con `matriculados = 0` |

Las últimas condiciones pueden comprobarse mediante pruebas específicas en una transacción que posteriormente se revierta, sin alterar permanentemente los datos originales.

También debe contrastarse el número de filas del reporte con la cantidad real de grupos del ciclo:

```sql
SELECT COUNT(*) AS total_grupos
FROM grupo
WHERE ciclo = '2026-1';
```

El resultado esperado para los datos iniciales es `7`.

Esta verificación confirma la cobertura, pero no basta por sí sola para validar los conteos. También deben comprobarse los valores por grupo, particularmente los grupos 1 y 8.

### 6. Impacto de corregir posteriormente los datos duplicados

La matrícula duplicada de Irene deberá resolverse durante el saneamiento de los datos, pero todavía no sabemos cuál de las dos calificaciones es la válida.

La consulta propuesta no necesita resolver esa ambigüedad para contar la ocupación: ambas filas representan a la misma estudiante en el mismo grupo.

Si posteriormente se conserva una sola matrícula de Irene, el comportamiento sería:

| Forma de contar | Antes del saneamiento | Después del saneamiento |
|---|---:|---:|
| Todos los registros del grupo 1 | 7 | 6 |
| Registros con estado `matriculado` | 6 | 5 |
| Estudiantes distintos con estado `matriculado` | 5 | 5 |

Esto demuestra una propiedad favorable de la propuesta: **el conteo de ocupación permanece estable cuando se elimina la duplicación**, siempre que se conserve una matrícula con estado `matriculado` para Irene.

No obstante, `COUNT(DISTINCT ...)` no corrige el defecto de integridad. Solamente evita que afecte este reporte.

La restricción `UNIQUE (id_estudiante, id_grupo)` sigue siendo necesaria para impedir nuevas duplicaciones.

### 7. Conclusión

La consulta 3 presenta un defecto confirmado por el uso de `COUNT(*)` con `LEFT JOIN`, que provoca que los grupos sin matrículas aparezcan con un estudiante matriculado.

Además, utilizar el número de filas como medida de ocupación resulta inadecuado frente a las matrículas duplicadas existentes.

La propuesta mediante:

```sql
COUNT(DISTINCT m.id_estudiante)
    FILTER (WHERE m.estado = 'matriculado')
```

resuelve ambos comportamientos bajo el criterio operativo de que las matrículas retiradas no ocupan cupo.

**Queda una decisión por confirmar:** la regla oficial no define explícitamente la ocupación de plazas tras un retiro. Si el reporte pretende mostrar registros históricos de matrícula en lugar de ocupación efectiva, correspondería utilizar una métrica diferente.

La propuesta no modifica datos, conserva todos los grupos del ciclo y mantiene separados los grupos de un mismo curso.

**Estado final del análisis: EN EVALUACIÓN.** La lógica SQL está definida, pero todavía debe aprobarse el criterio de ocupación y comprobarse su resultado en PostgreSQL 16 antes de implementarla.

### Verificación posterior

Se aprobó el criterio operativo de contar estudiantes distintos con estado `matriculado`, excluyendo las matrículas retiradas del cálculo de ocupación.

La consulta se implementó en `database/03_queries.sql` y se ejecutó sobre PostgreSQL 16. Se obtuvieron los siete grupos del ciclo `2026-1`, con 165 cupos y 16 estudiantes matriculados.

Se comprobaron particularmente los grupos 1 y 8, con cinco y cero estudiantes matriculados, respectivamente.

La prueba de regresión se ejecutó mediante `tests/validar_consulta_03.ps1`, utilizando `tests/consulta_03_regresion.sql`. Todas las comprobaciones terminaron correctamente y la transacción se revirtió con `ROLLBACK`.

**Evidencias:**
- `entregables/evidencias/05_consultas_tras_correccion_3.txt`
- `entregables/evidencias/06_regresion_consulta_03.txt`

La consulta 3 quedó implementada y verificada.