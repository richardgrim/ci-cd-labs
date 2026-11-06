param(
    [Parameter(Mandatory=$true)][string]$ArtifactPath,
    [Parameter(Mandatory=$true)][ValidatePattern('^[0-9]+$')][string]$ReleaseId
)
$ErrorActionPreference = 'Stop'
function Invoke-Docker {
    param([string[]]$DockerArgs)
    $result = & docker @DockerArgs
    if ($LASTEXITCODE -ne 0) { throw "Docker fallo: $($DockerArgs -join ' ')" }
    return $result
}
function Assert-Healthy {
    for ($attempt = 0; $attempt -lt 30; $attempt++) {
        try {
            $response = Invoke-WebRequest -UseBasicParsing -Uri 'http://127.0.0.1:8080/health' -TimeoutSec 3
            if ($response.StatusCode -eq 200 -and $response.Content.Trim() -eq 'Server Healthy!') { return }
        } catch { }
        Start-Sleep -Seconds 2
    }
    throw 'La aplicacion no supero la comprobacion /health.'
}
if (-not (Test-Path -LiteralPath $ArtifactPath -PathType Leaf)) { throw 'No existe el JAR descargado.' }
Invoke-Docker -DockerArgs @('info','--format','{{.ServerVersion}}') | Write-Output
$compose = Join-Path $PSScriptRoot 'compose.yaml'
$newImage = "richardgrim-labs-webapi:release-$ReleaseId"
$oldEnvironment = $env:WEBAPI_IMAGE
$env:WEBAPI_IMAGE = $newImage
$previousImage = $null
$deployStarted = $false
try {
    $containerId = Invoke-Docker -DockerArgs @('compose','-f',$compose,'ps','-a','-q','webapi')
    if ($containerId) {
        $previousImage = (Invoke-Docker -DockerArgs @('inspect','--format','{{.Image}}',($containerId | Select-Object -First 1))).Trim()
    }
    $context = Join-Path ([System.IO.Path]::GetTempPath()) ('webapi-release-' + $ReleaseId + '-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $context | Out-Null
    Copy-Item -LiteralPath $ArtifactPath -Destination (Join-Path $context 'app.jar')
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'Dockerfile') -Destination $context
    Get-FileHash -LiteralPath (Join-Path $context 'app.jar') -Algorithm SHA256 | Format-List
    Invoke-Docker -DockerArgs @('build','--tag',$newImage,$context) | Write-Output
    $deployStarted = $true
    Invoke-Docker -DockerArgs @('compose','-f',$compose,'up','-d','--no-build','webapi') | Write-Output
    Assert-Healthy
    Write-Output "Despliegue verificado: $newImage"
} catch {
    $failure = $_
    if ($deployStarted -and $previousImage) {
        Write-Warning "El despliegue fallo; restaurando la imagen anterior $previousImage"
        $env:WEBAPI_IMAGE = $previousImage
        Invoke-Docker -DockerArgs @('compose','-f',$compose,'up','-d','--no-build','webapi') | Write-Output
        Assert-Healthy
        Write-Output 'Version anterior restaurada y verificada.'
    }
    throw $failure
} finally {
    $env:WEBAPI_IMAGE = $oldEnvironment
}
