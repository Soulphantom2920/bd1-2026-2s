
$ErrorActionPreference = 'Stop'

$raiz = Split-Path -Parent $PSScriptRoot

$rutaConsultas = Join-Path $raiz 'database\03_queries.sql'
$rutaPrueba = Join-Path $PSScriptRoot 'consulta_02_regresion.sql'

$contenido = Get-Content -Raw -Encoding UTF8 $rutaConsultas

# Localizar los limites de la consulta 2.
$inicio = $contenido.IndexOf('-- Consulta 2:')
$fin = $contenido.IndexOf('-- Consulta 3:')

if ($inicio -lt 0 -or $fin -le $inicio) {
    throw 'No se encontraron los limites de la consulta 2.'
}

$seccion = $contenido.Substring($inicio, $fin - $inicio)

# Extraer la sentencia SELECT completa.
$coincidencia = [regex]::Match(
    $seccion,
    '(?ims)^\s*SELECT\b.*?;'
)

if (-not $coincidencia.Success) {
    throw 'No se encontro una sentencia SELECT en la consulta 2.'
}

# Insertar la consulta real en la prueba SQL.
$plantilla = Get-Content -Raw -Encoding UTF8 $rutaPrueba

$sqlPrueba = $plantilla.Replace(
    '__CONSULTA_02__',
    $coincidencia.Value.Trim()
)

# Ejecutar las pruebas mediante PostgreSQL en Docker.
Push-Location $raiz

try {
    $sqlPrueba | docker compose exec -T db `
        psql -X -v ON_ERROR_STOP=1 -U platano -d platano

    if ($LASTEXITCODE -ne 0) {
        throw 'La prueba de regresion fallo.'
    }
}
finally {
    Pop-Location
}
