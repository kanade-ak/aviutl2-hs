{-# LANGUAGE ForeignFunctionInterface #-}

module PixelRgbaByValueFilter where

import AviUtl2.Plugin
  ( BOOL_
  , DWORD
  , FILTER_PLUGIN_TABLE
  , FILTER_PROC_VIDEO
  , FilterCapability(..)
  , FilterPlugin(..)
  , LPCWSTR
  , PIXEL_RGBA(..)
  , boolFromBOOL
  , clearImageResource
  , createImageResource
  , defaultFilterPlugin
  , getImageResourceData
  , outputPixelFormatRgba
  , setImagePixels
  , staticFilterPluginTable
  , staticWideString
  , withPixelBuffer
  )
import Foreign.C.Types (CBool(..), CULong(..))
import Foreign.Marshal.Array (peekArray)
import Foreign.Ptr (Ptr, castPtr, nullPtr)
import PluginSupport (requiredVersion)

foreign export ccall "RequiredVersion"
  requiredVersionExport :: IO DWORD

foreign export ccall "InitializePlugin"
  initializePlugin :: DWORD -> IO BOOL_

foreign export ccall "UninitializePlugin"
  uninitializePlugin :: IO ()

foreign export ccall "GetFilterPluginTable"
  getFilterPluginTable :: IO (Ptr FILTER_PLUGIN_TABLE)

testResource :: LPCWSTR
testResource = staticWideString "resource:hs-pixel-rgba-by-value-test"
{-# NOINLINE testResource #-}

filterPluginTablePtr :: Ptr FILTER_PLUGIN_TABLE
filterPluginTablePtr = staticFilterPluginTable defaultFilterPlugin
  { filterPluginName = "PIXEL_RGBA by-value ABI test (hs)"
  , filterPluginLabel = Just "PIXEL_RGBA ABI Test"
  , filterPluginInformation = "Verifies clear_image_resource PIXEL_RGBA by-value calls from Haskell"
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
  let width = 32
      height = 32
      pixelCount = width * height
      testColor = PIXEL_RGBA 0x12 0x34 0x56 0xA5
  success <- withPixelBuffer pixelCount $ \buf -> do
    createImageResource video testResource nullPtr (fromIntegral width) (fromIntegral height)
    okClear <- clearImageResource video testResource testColor
    okRead <- getImageResourceData
      video
      testResource
      (castPtr buf)
      (fromIntegral width)
      (fromIntegral height)
      (fromIntegral (width * 4))
      outputPixelFormatRgba
    pixels <- peekArray pixelCount buf
    pure (boolFromBOOL okClear && boolFromBOOL okRead && all (== testColor) pixels)
  setImagePixels video width height (const (resultPixel success))
  pure True

resultPixel :: Bool -> PIXEL_RGBA
resultPixel True = PIXEL_RGBA 0x00 0xDD 0x66 0xFF
resultPixel False = PIXEL_RGBA 0xEE 0x22 0x33 0xFF
