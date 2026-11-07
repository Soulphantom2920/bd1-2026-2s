
$ErrorActionPreference = 'Stop'

$raiz = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

$rutaConsultas = Join-Path $raiz 'database\03_queries.sql'
$rutaPrueba = Join-Path $PSScriptRoot 'consulta_03_regresion.sql'
$rutaEvidencia = Join-Path $raiz 'entregables\evidencias\06_regresion_consulta_03.txt'

$contenido = Get-Content -Raw -Encoding UTF8 $rutaConsultas
$plantilla = Get-Content -Raw -Encoding UTF8 $rutaPrueba

# Localizar el bloque entre las consultas 3 y 4.
$patron = '(?im)^--[ \t]*Consulta[ \t]*0?3\b[^\r\n]*\r?\n(?<sql>[\s\S]*?)(?=^--[ \t]*Consulta[ \t]*0?4\b)'

$coincidencia = [regex]::Match($contenido, $patron)

if (-not $coincidencia.Success) {
    throw 'No se encontro el bloque de la consulta 3.'
}

$bloque = $coincidencia.Groups['sql'].Value

# Omitir comentarios y lineas vacias anteriores al SELECT.
$inicio = [regex]::Match($bloque, '(?im)^[ \t]*SELECT\b')

if (-not $inicio.Success) {
    throw 'No se encontro una sentencia SELECT en la consulta 3.'
}

$bloqueSQL = $bloque.Substring($inicio.Index).Trim()

# Extraer solamente la sentencia SELECT hasta su primer punto y coma.
$sentencia = [regex]::Match(
    $bloqueSQL,
    '(?is)\ASELECT\b[\s\S]*?;'
)

if (-not $sentencia.Success) {
    throw 'La consulta 3 no contiene una sentencia SELECT completa.'
}

# Eliminar el punto y coma porque la plantilla ya lo incluye.
$consulta = $sentencia.Value.TrimEnd(';').Trim()

if (-not $plantilla.Contains('__CONSULTA_03__')) {
    throw 'La plantilla no contiene el marcador esperado.'
}

$sqlPrueba = $plantilla.Replace('__CONSULTA_03__', $consulta)

# Crear un archivo SQL temporal en UTF-8 sin BOM.
$temporal = Join-Path ([System.IO.Path]::GetTempPath()) (
    'platano_c03_' + [guid]::NewGuid().ToString('N') + '.sql'
)

$utf8 = New-Object System.Text.UTF8Encoding($false)

[System.IO.File]::WriteAllText(
    $temporal,
    $sqlPrueba,
    $utf8
)

$codigoSalida = -1

Push-Location $raiz

try {
    # Ejecutar PostgreSQL y redirigir los bytes directamente.
    # Se evita Tee-Object para conservar la codificacion UTF-8.
    $comando = 'docker compose exec -T db psql -X -v ON_ERROR_STOP=1 -U platano -d platano < "' +
        $temporal + '" > "' + $rutaEvidencia + '" 2>&1'

    & cmd.exe /d /c $comando

    $codigoSalida = $LASTEXITCODE
}
finally {
    Pop-Location

    Remove-Item -LiteralPath $temporal -ErrorAction SilentlyContinue
}

# Mostrar el resultado de la prueba.
Get-Content -Encoding UTF8 $rutaEvidencia

if ($codigoSalida -ne 0) {
    throw "La prueba de regresion fallo con codigo $codigoSalida."
}

Write-Host 'Regresion de consulta 03: correcta.'
