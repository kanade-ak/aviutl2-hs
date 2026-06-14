{-# LANGUAGE ForeignFunctionInterface #-}

module ObjectLayerFrameSretFilter where

import AviUtl2.Plugin
  ( BOOL_
  , DWORD
  , FILTER_PLUGIN_TABLE
  , FILTER_PROC_VIDEO(..)
  , FilterCapability(..)
  , FilterPlugin(..)
  , OBJECT_INFO(..)
  , OBJECT_LAYER_FRAME(..)
  , PIXEL_RGBA(..)
  , defaultFilterPlugin
  , findObject
  , getObjectLayerFrame
  , setImagePixels
  , staticFilterPluginTable
  )
import Foreign.C.Types (CBool(..), CULong(..))
import Foreign.Ptr (Ptr, nullPtr)
import Foreign.Storable (peek)
import PluginSupport (requiredVersion)

foreign export ccall "RequiredVersion"
  requiredVersionExport :: IO DWORD

foreign export ccall "InitializePlugin"
  initializePlugin :: DWORD -> IO BOOL_

foreign export ccall "UninitializePlugin"
  uninitializePlugin :: IO ()

foreign export ccall "GetFilterPluginTable"
  getFilterPluginTable :: IO (Ptr FILTER_PLUGIN_TABLE)

filterPluginTablePtr :: Ptr FILTER_PLUGIN_TABLE
filterPluginTablePtr = staticFilterPluginTable defaultFilterPlugin
  { filterPluginName = "OBJECT_LAYER_FRAME sret ABI test (hs)"
  , filterPluginLabel = Just "OBJECT_LAYER_FRAME ABI Test"
  , filterPluginInformation = "Verifies get_object_layer_frame hidden sret calls from Haskell"
  , filterPluginCapabilities = [FilterVideo, FilterInput]
  , filterPluginVideoProc = Just funcProcVideo
  }
{-# NOINLINE filterPluginTablePtr #-}

requiredVersionExport :: IO DWORD
requiredVersionExport = pure requiredVersion

initializePlugin :: DWORD -> IO BOOL_
initializePlugin _ = pure 1

uninitializePlugin :: IO ()
uninitializePlugin = pure ()

getFilterPluginTable :: IO (Ptr FILTER_PLUGIN_TABLE)
getFilterPluginTable = pure filterPluginTablePtr

funcProcVideo :: Ptr FILTER_PROC_VIDEO -> IO Bool
funcProcVideo video = do
  proc <- peek video
  objectInfo <- peek (fpvObject proc)
  object <- findObject (fpvEdit proc) (oiLayer objectInfo) (oiFrameStart objectInfo)
  success <-
    if object == nullPtr
      then pure False
      else do
        layerFrame <- getObjectLayerFrame (fpvEdit proc) object
        pure (matchesObjectInfo objectInfo layerFrame)
  writeResult video (resultPixel success)
  pure True

matchesObjectInfo :: OBJECT_INFO -> OBJECT_LAYER_FRAME -> Bool
matchesObjectInfo objectInfo layerFrame =
  olfLayer layerFrame == oiLayer objectInfo
    && olfStart layerFrame == oiFrameStart objectInfo
    && olfEnd layerFrame == oiFrameEnd objectInfo

resultPixel :: Bool -> PIXEL_RGBA
resultPixel True = PIXEL_RGBA 0x00 0xDD 0x66 0xFF
resultPixel False = PIXEL_RGBA 0xEE 0x22 0x33 0xFF

writeResult :: Ptr FILTER_PROC_VIDEO -> PIXEL_RGBA -> IO ()
writeResult video pixel =
  setImagePixels video 32 32 (const pixel)
