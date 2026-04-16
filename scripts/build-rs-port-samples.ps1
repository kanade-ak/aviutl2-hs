param(
  [switch]$Deploy,
  [switch]$SkipBuild
)

$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$buildDir = Join-Path $repoRoot 'build'
$pluginDir = Join-Path $repoRoot 'plugin'
$licenseSourceDir = Join-Path $repoRoot 'licenses'
$pluginLicenseDir = Join-Path $pluginDir 'licenses'
$pluginDeployDir = 'C:\ProgramData\aviutl2\Plugin'
$scriptDeployDir = 'C:\ProgramData\aviutl2\Script'
$libzPath = 'A:\ghcup\msys64\mingw64\lib\libz.a'

$targets = @(
  @{
    Module = 'RandomColorFilter'
    OutputName = 'RsRandomColorFilter.auf2'
    Source = 'examples\RandomColorFilter.hs'
    Exports = @('RequiredVersion', 'InitializePlugin', 'UninitializePlugin', 'GetFilterPluginTable')
    DeployDir = $pluginDeployDir
  },
  @{
    Module = 'UsernameModule'
    OutputName = 'RsUsernameModule.mod2'
    Source = 'examples\UsernameModule.hs'
    Exports = @('RequiredVersion', 'InitializePlugin', 'UninitializePlugin', 'GetScriptModuleTable')
    DeployDir = $scriptDeployDir
  },
  @{
    Module = 'SingleImageOutput'
    OutputName = 'RsSingleImageOutput.auo2'
    Source = 'examples\SingleImageOutput.hs'
    Exports = @('RequiredVersion', 'InitializePlugin', 'UninitializePlugin', 'GetOutputPluginTable')
    DeployDir = $pluginDeployDir
  },
  @{
    Module = 'PixelFormatTestInput'
    OutputName = 'RsPixelFormatTestInput.aui2'
    Source = 'examples\PixelFormatTestInput.hs'
    Exports = @('RequiredVersion', 'InitializePlugin', 'UninitializePlugin', 'GetInputPluginTable')
    DeployDir = $pluginDeployDir
  },
  @{
    Module = 'MetronomePlugin'
    OutputName = 'RsMetronomePlugin.aux2'
    Source = 'examples\MetronomePlugin.hs'
    Exports = @('RequiredVersion', 'InitializePlugin', 'UninitializePlugin', 'InitializeLogger', 'InitializeConfig', 'GetCommonPluginTable', 'RegisterPlugin')
    DeployDir = $pluginDeployDir
  }
)

$runtimeAssets = @(
  Join-Path $repoRoot 'vendor\webp\libsharpyuv-0.dll'
  Join-Path $repoRoot 'vendor\webp\libwebp-7.dll'
  Join-Path $repoRoot 'vendor\webp\zlib1.dll'
)

Set-Location $repoRoot
New-Item -ItemType Directory -Force $buildDir | Out-Null
New-Item -ItemType Directory -Force $pluginDir | Out-Null

if (-not (Test-Path -LiteralPath $licenseSourceDir)) {
  throw "licenses directory not found: $licenseSourceDir"
}

$managedPluginFiles = @($targets | ForEach-Object { $_.OutputName }) +
  @($runtimeAssets | ForEach-Object { Split-Path $_ -Leaf })
foreach ($fileName in $managedPluginFiles) {
  $path = Join-Path $pluginDir $fileName
  if (Test-Path -LiteralPath $path) {
    Remove-Item -LiteralPath $path -Force
  }
}

if (Test-Path -LiteralPath $pluginLicenseDir) {
  Remove-Item -LiteralPath $pluginLicenseDir -Recurse -Force
}

if (-not $SkipBuild) {
  cabal build
  if ($LASTEXITCODE -ne 0) {
    throw 'cabal build failed'
  }
}

if (-not (Test-Path -LiteralPath $libzPath)) {
  throw "libz.a not found: $libzPath"
}

foreach ($target in $targets) {
  $objDir = Join-Path $buildDir ($target.Module + '_obj')
  $defPath = Join-Path $buildDir ($target.Module + '.def')
  $outputPath = Join-Path $buildDir $target.OutputName

  New-Item -ItemType Directory -Force $objDir | Out-Null
  $defText = "EXPORTS`r`n  " + ($target.Exports -join "`r`n  ") + "`r`n"
  Set-Content -Path $defPath -Value $defText -Encoding ASCII

  $ghcArgs = @(
    '--make'
    '-shared'
    '-threaded'
    '-no-hs-main'
    '-isrc'
    '-iexamples'
    '-odir'
    $objDir
    '-hidir'
    $objDir
    '-o'
    $outputPath
    $target.Source
    'cbits\hs_dllmain.c'
    'cbits\aviutl2_shims.c'
    $defPath
  )

  if ($target.Module -eq 'SingleImageOutput') {
    $ghcArgs += @(
      'cbits\embedded_webp.c'
      'cbits\static_runtime_compat.c'
      $libzPath
    )
  }

  cabal exec -- ghc @ghcArgs
  if ($LASTEXITCODE -ne 0) {
    throw "ghc failed for $($target.Module)"
  }

  Copy-Item -LiteralPath $outputPath -Destination (Join-Path $pluginDir $target.OutputName) -Force

  if ($Deploy) {
    New-Item -ItemType Directory -Force $target.DeployDir | Out-Null
    Copy-Item -LiteralPath $outputPath -Destination (Join-Path $target.DeployDir $target.OutputName) -Force
  }
}

foreach ($asset in $runtimeAssets) {
  if (-not (Test-Path -LiteralPath $asset)) {
    throw "runtime asset not found: $asset"
  }

  $assetName = Split-Path $asset -Leaf
  Copy-Item -LiteralPath $asset -Destination (Join-Path $pluginDir $assetName) -Force

  if ($Deploy) {
    New-Item -ItemType Directory -Force $pluginDeployDir | Out-Null
    Copy-Item -LiteralPath $asset -Destination (Join-Path $pluginDeployDir $assetName) -Force
  }
}

Copy-Item -LiteralPath $licenseSourceDir -Destination $pluginLicenseDir -Recurse -Force

if ($Deploy) {
  $deployLicenseDir = Join-Path $pluginDeployDir 'licenses'
  if (Test-Path -LiteralPath $deployLicenseDir) {
    Remove-Item -LiteralPath $deployLicenseDir -Recurse -Force
  }
  New-Item -ItemType Directory -Force $pluginDeployDir | Out-Null
  Copy-Item -LiteralPath $licenseSourceDir -Destination $deployLicenseDir -Recurse -Force
}

Write-Host "Distribution files were written to $pluginDir"
if ($Deploy) {
  Write-Host "Plugins were also copied to $pluginDeployDir and $scriptDeployDir"
}
