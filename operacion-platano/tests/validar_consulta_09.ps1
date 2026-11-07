$ErrorActionPreference = 'Stop'

$raiz = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$rutaConsultas = Join-Path $raiz 'database\03_queries.sql'
$rutaPrueba = Join-Path $PSScriptRoot 'consulta_09_regresion.sql'
$rutaEvidencia = Join-Path $raiz 'entregables\evidencias\11_regresion_consulta_09.txt'

$contenido = Get-Content -Raw -Encoding UTF8 $rutaConsultas
$plantilla = Get-Content -Raw -Encoding UTF8 $rutaPrueba

# Extraer la sentencia real entre los encabezados de consultas 9 y 10.
$patron = '(?im)^--[ \t]*Consulta[ \t]*0?9\b[^\r\n]*\r?\n(?<sql>[\s\S]*?)(?=^--[ \t]*Consulta[ \t]*0?10\b)'
$coincidencia = [regex]::Match($contenido, $patron)
if (-not $coincidencia.Success) {
    throw 'No se encontro el bloque de la consulta 9.'
}

$bloque = $coincidencia.Groups['sql'].Value
$inicio = [regex]::Match($bloque, '(?im)^[ \t]*SELECT\b')
if (-not $inicio.Success) {
    throw 'No se encontro una sentencia SELECT en la consulta 9.'
}

$bloqueSQL = $bloque.Substring($inicio.Index).Trim()
$sentencia = [regex]::Match($bloqueSQL, '(?is)\ASELECT\b[\s\S]*?;')
if (-not $sentencia.Success) {
    throw 'La consulta 9 no contiene una sentencia SELECT completa.'
}

$consulta = $sentencia.Value.TrimEnd(';').Trim()
if (-not $plantilla.Contains('__CONSULTA_09__')) {
    throw 'La plantilla no contiene el marcador esperado.'
}
$sqlPrueba = $plantilla.Replace('__CONSULTA_09__', $consulta)

# Archivo temporal UTF-8 sin BOM; ejecutar psql con ON_ERROR_STOP=1.
$temporal = Join-Path ([System.IO.Path]::GetTempPath()) (
    'platano_c09_' + [guid]::NewGuid().ToString('N') + '.sql'
)
$utf8 = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($temporal, $sqlPrueba, $utf8)

$codigoSalida = -1
Push-Location $raiz
try {
    $comando = 'docker compose exec -T db psql -X -v ON_ERROR_STOP=1 -U platano -d platano < "' +
        $temporal + '" > "' + $rutaEvidencia + '" 2>&1'
    & cmd.exe /d /c $comando
    $codigoSalida = $LASTEXITCODE
}
finally {
    Pop-Location
    Remove-Item -LiteralPath $temporal -ErrorAction SilentlyContinue
}

Get-Content -Encoding UTF8 $rutaEvidencia
if ($codigoSalida -ne 0) {
    throw 'La prueba de regresion de la consulta 9 fallo con codigo ' + $codigoSalida
}
Write-Host 'Regresion de consulta 09: correcta.'
