$ErrorActionPreference = "Stop"

$RegistryPush = "192.168.3.159:30500"
$RegistryPull = "localhost:30500"
$Repository = "teampass"
$Version = "3.1.7.5"
$Tag = "latest"
$ImagePush = "$RegistryPush/$Repository`:$Tag"
$ImagePull = "$RegistryPull/$Repository`:$Tag"
$BuilderName = "teampass-builder"
$EntrypointPath = Join-Path $PSScriptRoot "..\_upstream\docker\docker-entrypoint.sh"

function Remove-RegistryImage {
  param(
    [string]$Registry,
    [string]$Repo,
    [string]$TagName
  )

  $manifestUrl = "http://$Registry/v2/$Repo/manifests/$TagName"
  try {
    $response = Invoke-WebRequest -Uri $manifestUrl -Method Head -Headers @{ Accept = "application/vnd.docker.distribution.manifest.v2+json" } -UseBasicParsing -ErrorAction Stop
    $digest = $response.Headers['Docker-Content-Digest']
    if ($null -ne $digest -and $digest -ne '') {
      Write-Host "Deleting existing registry image $Registry/$Repo@$digest"
      Invoke-WebRequest -Uri "http://$Registry/v2/$Repo/manifests/$digest" -Method Delete -UseBasicParsing -ErrorAction Stop
      Write-Host "Deleted existing image digest: $digest"
    }
  }
  catch {
    Write-Host ('No existing image to delete at ' + $Registry + '/' + $Repo + ':' + $TagName + ' or registry delete not available. Continuing...')
  }
}

Write-Host "Preparing to build and push $ImagePush..."
Remove-RegistryImage -Registry $RegistryPush -Repo $Repository -TagName $Tag

$entrypointContent = [System.IO.File]::ReadAllText($EntrypointPath)
$entrypointContent = $entrypointContent -replace "`r`n", "`n"
[System.IO.File]::WriteAllText($EntrypointPath, $entrypointContent, [System.Text.UTF8Encoding]::new($false))

docker buildx inspect $BuilderName *> $null
if ($LASTEXITCODE -ne 0) {
  docker buildx create --name $BuilderName --use | Out-Null
} else {
  docker buildx use $BuilderName
}

docker buildx inspect --bootstrap | Out-Null

$BuildContextPath = Join-Path $PSScriptRoot "..\_upstream"
$buildArgs = @(
  "buildx", "build",
  "--platform", "linux/arm64",
  "--tag", $ImagePush,
  "--build-arg", "TEAMPASS_VERSION=$Version",
  "--output", "type=image,name=$ImagePush,push=true,registry.insecure=true",
  $BuildContextPath
)

docker @buildArgs

if ($LASTEXITCODE -ne 0) {
  throw "docker buildx build failed"
}

Write-Host "Image published for push as: $ImagePush"
Write-Host "Cluster image reference remains: $ImagePull"
