module AviUtl2.Plugin.Export
  ( PluginExportKind(..)
  , PluginExportOptions(..)
  , minimalPluginExportOptions
  , defaultPluginExportOptions
  , pluginExportNames
  , minimalPluginExportNames
  , defaultPluginExportNames
  , filterPluginExportNames
  , inputPluginExportNames
  , outputPluginExportNames
  , scriptModuleExportNames
  , commonPluginExportNames
  , pluginDefText
  , writePluginDefFile
  ) where

import Data.List (nub)

data PluginExportKind
  = ExportFilterPlugin
  | ExportInputPlugin
  | ExportOutputPlugin
  | ExportScriptModule
  | ExportCommonPlugin
  deriving (Eq, Show)

data PluginExportOptions = PluginExportOptions
  { exportRequiredVersion :: Bool
  , exportInitializePlugin :: Bool
  , exportUninitializePlugin :: Bool
  , exportInitializeLogger :: Bool
  , exportInitializeConfig :: Bool
  , exportInitializeCache :: Bool
  , exportCommonPluginTable :: Bool
  } deriving (Eq, Show)

minimalPluginExportOptions :: PluginExportOptions
minimalPluginExportOptions = PluginExportOptions
  { exportRequiredVersion = False
  , exportInitializePlugin = False
  , exportUninitializePlugin = False
  , exportInitializeLogger = False
  , exportInitializeConfig = False
  , exportInitializeCache = False
  , exportCommonPluginTable = False
  }

defaultPluginExportOptions :: PluginExportOptions
defaultPluginExportOptions = minimalPluginExportOptions
  { exportRequiredVersion = True
  , exportInitializePlugin = True
  , exportUninitializePlugin = True
  }

pluginExportNames :: PluginExportKind -> PluginExportOptions -> [String]
pluginExportNames kind options =
  nub (optionalLifecycleExports options ++ optionalServiceExports kind options ++ requiredPluginExports kind)

minimalPluginExportNames :: PluginExportKind -> [String]
minimalPluginExportNames kind =
  pluginExportNames kind minimalPluginExportOptions

defaultPluginExportNames :: PluginExportKind -> [String]
defaultPluginExportNames kind =
  pluginExportNames kind defaultPluginExportOptions

filterPluginExportNames :: [String]
filterPluginExportNames = defaultPluginExportNames ExportFilterPlugin

inputPluginExportNames :: [String]
inputPluginExportNames = defaultPluginExportNames ExportInputPlugin

outputPluginExportNames :: [String]
outputPluginExportNames = defaultPluginExportNames ExportOutputPlugin

scriptModuleExportNames :: [String]
scriptModuleExportNames = defaultPluginExportNames ExportScriptModule

commonPluginExportNames :: [String]
commonPluginExportNames =
  pluginExportNames ExportCommonPlugin defaultPluginExportOptions
    { exportInitializeLogger = True
    , exportInitializeConfig = True
    , exportCommonPluginTable = True
    }

pluginDefText :: [String] -> String
pluginDefText names =
  "EXPORTS\r\n" ++ concatMap (\name -> "  " ++ name ++ "\r\n") (nub names)

writePluginDefFile :: FilePath -> [String] -> IO ()
writePluginDefFile path names =
  writeFile path (pluginDefText names)

optionalLifecycleExports :: PluginExportOptions -> [String]
optionalLifecycleExports options =
  concat
    [ ["RequiredVersion" | exportRequiredVersion options]
    , ["InitializePlugin" | exportInitializePlugin options]
    , ["UninitializePlugin" | exportUninitializePlugin options]
    ]

optionalServiceExports :: PluginExportKind -> PluginExportOptions -> [String]
optionalServiceExports kind options =
  concat
    [ ["InitializeLogger" | exportInitializeLogger options]
    , ["InitializeConfig" | exportInitializeConfig options]
    , ["InitializeCache" | exportInitializeCache options]
    , ["GetCommonPluginTable" | kind == ExportCommonPlugin && exportCommonPluginTable options]
    ]

requiredPluginExports :: PluginExportKind -> [String]
requiredPluginExports ExportFilterPlugin = ["GetFilterPluginTable"]
requiredPluginExports ExportInputPlugin = ["GetInputPluginTable"]
requiredPluginExports ExportOutputPlugin = ["GetOutputPluginTable"]
requiredPluginExports ExportScriptModule = ["GetScriptModuleTable"]
requiredPluginExports ExportCommonPlugin = ["RegisterPlugin"]
