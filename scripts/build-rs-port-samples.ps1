param(
  [switch]$Deploy,
  [switch]$SkipBuild,
  [string]$AviUtl2Dir
)

$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$buildDir = Join-Path $repoRoot 'build'
$pluginDir = Join-Path $repoRoot 'plugin'
$licenseSourceDir = Join-Path $repoRoot 'licenses'
$pluginLicenseDir = Join-Path $pluginDir 'licenses'
$sdkIncludeDir = Join-Path $repoRoot 'external\aviutl2_sdk_mirror\include'
$pluginDeployDir = $null
$scriptDeployDir = $null

if (-not $AviUtl2Dir) {
  $localAviUtl2Dir = Join-Path $repoRoot '..\aviutl2beta50'
  if (Test-Path -LiteralPath (Join-Path $localAviUtl2Dir 'aviutl2.exe')) {
    $AviUtl2Dir = (Resolve-Path -LiteralPath $localAviUtl2Dir).Path
  }
}

if ($AviUtl2Dir) {
  $AviUtl2Dir = (Resolve-Path -LiteralPath $AviUtl2Dir).Path
  $pluginDeployDir = Join-Path $AviUtl2Dir 'data\Plugin'
  $scriptDeployDir = Join-Path $AviUtl2Dir 'data\Script'
} elseif ($Deploy) {
  throw 'Deploy requires -AviUtl2Dir or a sibling ..\aviutl2beta50\aviutl2.exe.'
}

$targets = @(
  @{
    Module = 'RandomColorFilter'
    OutputName = 'HsRandomColorFilter.auf2'
    Source = 'examples\RandomColorFilter.hs'
    Exports = @('RequiredVersion', 'InitializePlugin', 'UninitializePlugin', 'GetFilterPluginTable')
    DeployDir = $pluginDeployDir
  },
  @{
    Module = 'PixelRgbaByValueFilter'
    OutputName = 'HsPixelRgbaByValueFilter.auf2'
    Source = 'examples\PixelRgbaByValueFilter.hs'
    Exports = @('RequiredVersion', 'InitializePlugin', 'UninitializePlugin', 'GetFilterPluginTable')
    DeployDir = $pluginDeployDir
  },
  @{
    Module = 'ObjectLayerFrameSretFilter'
    OutputName = 'HsObjectLayerFrameSretFilter.auf2'
    Source = 'examples\ObjectLayerFrameSretFilter.hs'
    Exports = @('RequiredVersion', 'InitializePlugin', 'UninitializePlugin', 'GetFilterPluginTable')
    DeployDir = $pluginDeployDir
  },
  @{
    Module = 'UsernameModule'
    OutputName = 'HsUsernameModule.mod2'
    Source = 'examples\UsernameModule.hs'
    Exports = @('RequiredVersion', 'InitializePlugin', 'UninitializePlugin', 'GetScriptModuleTable')
    DeployDir = $scriptDeployDir
  },
  @{
    Module = 'PixelFormatTestInput'
    OutputName = 'HsPixelFormatTestInput.aui2'
    Source = 'examples\PixelFormatTestInput.hs'
    Exports = @('RequiredVersion', 'InitializePlugin', 'UninitializePlugin', 'GetInputPluginTable')
    DeployDir = $pluginDeployDir
  },
  @{
    Module = 'MetronomePlugin'
    OutputName = 'HsMetronomePlugin.aux2'
    Source = 'examples\MetronomePlugin.hs'
    Exports = @('RequiredVersion', 'InitializePlugin', 'UninitializePlugin', 'InitializeLogger', 'InitializeConfig', 'GetCommonPluginTable', 'RegisterPlugin')
    DeployDir = $pluginDeployDir
  }
)

function Read-U16([byte[]]$Bytes, [int]$Offset) {
  [BitConverter]::ToUInt16($Bytes, $Offset)
}

function Read-U32([byte[]]$Bytes, [int]$Offset) {
  [BitConverter]::ToUInt32($Bytes, $Offset)
}

function Read-ZString([byte[]]$Bytes, [int]$Offset) {
  $end = $Offset
  while ($end -lt $Bytes.Length -and $Bytes[$end] -ne 0) {
    $end++
  }
  [Text.Encoding]::ASCII.GetString($Bytes, $Offset, $end - $Offset)
}

function Get-PEImports([string]$Path) {
  $bytes = [System.IO.File]::ReadAllBytes($Path)
  if ($bytes.Length -lt 0x40 -or (Read-U16 $bytes 0) -ne 0x5a4d) {
    throw "not a PE file: $Path"
  }

  $pe = [int](Read-U32 $bytes 0x3c)
  if ($pe + 24 -ge $bytes.Length -or (Read-U32 $bytes $pe) -ne 0x00004550) {
    throw "invalid PE header: $Path"
  }

  $sectionCount = [int](Read-U16 $bytes ($pe + 6))
  $optionalHeaderSize = [int](Read-U16 $bytes ($pe + 20))
  $optionalHeader = $pe + 24
  $magic = Read-U16 $bytes $optionalHeader
  $dataDirectory = if ($magic -eq 0x20b) { $optionalHeader + 112 } else { $optionalHeader + 96 }
  $importRva = Read-U32 $bytes ($dataDirectory + 8)
  if ($importRva -eq 0) {
    return @()
  }

  $sectionTable = $optionalHeader + $optionalHeaderSize
  $sections = @()
  for ($i = 0; $i -lt $sectionCount; $i++) {
    $section = $sectionTable + 40 * $i
    $virtualSize = Read-U32 $bytes ($section + 8)
    $virtualAddress = Read-U32 $bytes ($section + 12)
    $rawSize = Read-U32 $bytes ($section + 16)
    $rawPointer = Read-U32 $bytes ($section + 20)
    $sections += [pscustomobject]@{
      VirtualAddress = $virtualAddress
      VirtualSize = $virtualSize
      RawSize = $rawSize
      RawPointer = $rawPointer
    }
  }

  function Convert-RvaToOffset([uint32]$Rva) {
    foreach ($section in $sections) {
      $span = [Math]::Max([uint32]$section.VirtualSize, [uint32]$section.RawSize)
      if ($Rva -ge [uint32]$section.VirtualAddress -and
          $Rva -lt ([uint32]$section.VirtualAddress + $span)) {
        return [int]([uint32]$section.RawPointer + ($Rva - [uint32]$section.VirtualAddress))
      }
    }
    [int]$Rva
  }

  $imports = @()
  $descriptor = Convert-RvaToOffset $importRva
  while ($descriptor -gt 0 -and $descriptor + 20 -le $bytes.Length) {
    $originalFirstThunk = Read-U32 $bytes $descriptor
    $timeDateStamp = Read-U32 $bytes ($descriptor + 4)
    $forwarderChain = Read-U32 $bytes ($descriptor + 8)
    $nameRva = Read-U32 $bytes ($descriptor + 12)
    $firstThunk = Read-U32 $bytes ($descriptor + 16)
    if (($originalFirstThunk -bor $timeDateStamp -bor $forwarderChain -bor $nameRva -bor $firstThunk) -eq 0) {
      break
    }

    $imports += Read-ZString $bytes (Convert-RvaToOffset $nameRva)
    $descriptor += 20
  }

  $imports | Sort-Object -Unique
}

function Test-SystemDll([string]$Name) {
  $lower = $Name.ToLowerInvariant()
  if ($lower.StartsWith('api-ms-win-') -or $lower.StartsWith('ext-ms-win-')) {
    return $true
  }

  $systemDlls = @(
    'advapi32.dll',
    'bcrypt.dll',
    'cfgmgr32.dll',
    'comdlg32.dll',
    'crypt32.dll',
    'dbghelp.dll',
    'gdi32.dll',
    'imm32.dll',
    'kernel32.dll',
    'msvcrt.dll',
    'ntdll.dll',
    'ole32.dll',
    'oleaut32.dll',
    'rpcrt4.dll',
    'secur32.dll',
    'setupapi.dll',
    'shell32.dll',
    'shlwapi.dll',
    'user32.dll',
    'version.dll',
    'winmm.dll',
    'ws2_32.dll',
    'wsock32.dll'
  )

  $systemDlls -contains $lower
}

function Get-RuntimeSearchDirs {
  $ghcLibDir = (& cabal exec -- ghc --print-libdir | Select-Object -Last 1).Trim()
  if (-not $ghcLibDir) {
    throw 'could not determine GHC libdir'
  }

  $ghcRoot = Split-Path -Parent $ghcLibDir
  $dirs = @(
    (Join-Path $ghcRoot 'mingw\bin')
  )

  foreach ($dir in ($env:PATH -split ';')) {
    if ($dir -and (Test-Path -LiteralPath $dir)) {
      $dirs += (Resolve-Path -LiteralPath $dir).Path
    }
  }

  $dirs | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -Unique
}

function Find-RuntimeDll([string]$Name, [string[]]$SearchDirs) {
  foreach ($dir in $SearchDirs) {
    $candidate = Join-Path $dir $Name
    if (Test-Path -LiteralPath $candidate) {
      return (Resolve-Path -LiteralPath $candidate).Path
    }
  }
  $null
}

function Resolve-RuntimeDependencies([string[]]$RootPaths, [string[]]$SearchDirs) {
  $resolved = @{}
  $queue = New-Object System.Collections.Generic.Queue[string]
  foreach ($path in $RootPaths) {
    $queue.Enqueue((Resolve-Path -LiteralPath $path).Path)
  }

  while ($queue.Count -gt 0) {
    $path = $queue.Dequeue()
    foreach ($import in (Get-PEImports $path)) {
      if (Test-SystemDll $import) {
        continue
      }

      $key = $import.ToLowerInvariant()
      if ($resolved.ContainsKey($key)) {
        continue
      }

      $dllPath = Find-RuntimeDll $import $SearchDirs
      if (-not $dllPath) {
        throw "runtime DLL not found: $import (imported by $path)"
      }

      $resolved[$key] = $dllPath
      $queue.Enqueue($dllPath)
    }
  }

  $resolved.Values | Sort-Object -Unique
}

function Assert-NoRuntimeDependencies([string[]]$RootPaths, [string[]]$SearchDirs) {
  $runtimeDependencies = Resolve-RuntimeDependencies $RootPaths $SearchDirs
  if ($runtimeDependencies.Count -gt 0) {
    $names = $runtimeDependencies | ForEach-Object { Split-Path -Leaf $_ } | Sort-Object -Unique
    throw ("non-system runtime DLL imports remain; link them statically: " + ($names -join ', '))
  }
}

Set-Location $repoRoot
New-Item -ItemType Directory -Force $buildDir | Out-Null
New-Item -ItemType Directory -Force $pluginDir | Out-Null

if (-not (Test-Path -LiteralPath (Join-Path $sdkIncludeDir 'aviutl2_sdk\plugin2.h'))) {
  throw 'AviUtl2 SDK submodule is missing. Run: git submodule update --init --recursive'
}

if (-not (Test-Path -LiteralPath $licenseSourceDir)) {
  throw "licenses directory not found: $licenseSourceDir"
}

foreach ($fileName in @($targets | ForEach-Object { $_.OutputName })) {
  $path = Join-Path $pluginDir $fileName
  if (Test-Path -LiteralPath $path) {
    Remove-Item -LiteralPath $path -Force
  }
}

if (Test-Path -LiteralPath $pluginLicenseDir) {
  Remove-Item -LiteralPath $pluginLicenseDir -Recurse -Force
}

$builtOutputPaths = @()

if (-not $SkipBuild) {
  cabal build
  if ($LASTEXITCODE -ne 0) {
    throw 'cabal build failed'
  }
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
    "-I$sdkIncludeDir"
    '-optcxx-std=c++17'
    '-odir'
    $objDir
    '-hidir'
    $objDir
    '-stubdir'
    $objDir
    '-o'
    $outputPath
    $target.Source
    'cbits\aviutl2_haskell_sdk_shim.cpp'
    $defPath
    '-optl-static'
    '-optl-static-libgcc'
    '-optl-Wl,-Bstatic'
    '-optl-lc++'
    '-optl-lc++abi'
    '-optl-lunwind'
    '-optl-Wl,-Bdynamic'
  )

  cabal exec -- ghc @ghcArgs
  if ($LASTEXITCODE -ne 0) {
    throw "ghc failed for $($target.Module)"
  }

  Copy-Item -LiteralPath $outputPath -Destination (Join-Path $pluginDir $target.OutputName) -Force
  $builtOutputPaths += $outputPath

  if ($Deploy) {
    New-Item -ItemType Directory -Force $target.DeployDir | Out-Null
    Copy-Item -LiteralPath $outputPath -Destination (Join-Path $target.DeployDir $target.OutputName) -Force
  }
}

$runtimeSearchDirs = Get-RuntimeSearchDirs
Assert-NoRuntimeDependencies $builtOutputPaths $runtimeSearchDirs

Copy-Item -LiteralPath $licenseSourceDir -Destination $pluginLicenseDir -Recurse -Force

Write-Host "Distribution files were written to $pluginDir"
Write-Host "Non-system runtime dependencies were linked into the plugin DLLs"
if ($Deploy) {
  Write-Host "Plugins were also copied to $pluginDeployDir and $scriptDeployDir"
}
