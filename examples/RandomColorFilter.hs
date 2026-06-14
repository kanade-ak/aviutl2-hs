{-# LANGUAGE ForeignFunctionInterface #-}

module RandomColorFilter where

import AviUtl2.Plugin
  ( BOOL_
  , DWORD
  , FILTER_PLUGIN_TABLE
  , FILTER_PROC_VIDEO(..)
  , FilterCapability(..)
  , FilterPlugin(..)
  , FilterTrackSpec(..)
  , OBJECT_INFO(..)
  , PIXEL_RGBA(..)
  , TrackItem
  , defaultFilterPlugin
  , defaultFilterTrack
  , readTrackInt
  , setImagePixels
  , staticFilterPluginTable
  , staticTrackItem
  , trackFilterItem
  )
import Data.Bits ((.&.), shiftR, xor)
import Data.Int (Int64)
import Data.Word (Word8, Word64)
import Foreign.C.Types (CBool(..), CULong(..))
import Foreign.Ptr (Ptr)
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

widthTrack, heightTrack :: TrackItem
widthTrack = staticTrackItem (track "Width")
heightTrack = staticTrackItem (track "Height")
{-# NOINLINE widthTrack #-}
{-# NOINLINE heightTrack #-}

filterPluginTablePtr :: Ptr FILTER_PLUGIN_TABLE
filterPluginTablePtr = staticFilterPluginTable defaultFilterPlugin
  { filterPluginName = "Rusty Random Color Filter (hs)"
  , filterPluginLabel = Just "Random Color"
  , filterPluginInformation = "aviutl2-rs random-color-filter port for Haskell"
  , filterPluginCapabilities = [FilterVideo, FilterInput]
  , filterPluginItems =
      [ trackFilterItem widthTrack
      , trackFilterItem heightTrack
      ]
  , filterPluginVideoProc = Just funcProcVideo
  }
{-# NOINLINE filterPluginTablePtr #-}

track :: String -> FilterTrackSpec
track name = (defaultFilterTrack name 640.0)
  { filterTrackMin = 1.0
  , filterTrackMax = 4096.0
  }

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
  width <- readTrackInt widthTrack
  height <- readTrackInt heightTrack
  if width <= 0 || height <= 0
    then pure False
    else do
      let (r, g, b) = hashColor (oiEffectId objectInfo)
      setImagePixels video width height (const (PIXEL_RGBA r g b 255))
      pure True

hashColor :: Int64 -> (Word8, Word8, Word8)
hashColor effectId =
  let mixed = mix64 (fromIntegral effectId + 0x9E3779B97F4A7C15)
  in (byteAt mixed 0, byteAt mixed 8, byteAt mixed 16)

mix64 :: Word64 -> Word64
mix64 x0 =
  let x1 = (x0 `xor` (x0 `shiftR` 33)) * 0xFF51AFD7ED558CCD
      x2 = (x1 `xor` (x1 `shiftR` 33)) * 0xC4CEB9FE1A85EC53
  in x2 `xor` (x2 `shiftR` 33)

byteAt :: Word64 -> Int -> Word8
byteAt value bits = fromIntegral ((value `shiftR` bits) .&. 0xFF)
