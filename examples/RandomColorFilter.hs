{-# LANGUAGE ForeignFunctionInterface #-}
module RandomColorFilter where

import Data.Bits ((.&.), shiftR, xor)
import Data.Int (Int64)
import Data.Word (Word8, Word64)
import Foreign.C.Types (CBool(..), CULong(..))
import Foreign.Marshal.Alloc (free, malloc)
import Foreign.Marshal.Array (mallocArray, newArray)
import Foreign.Ptr (FunPtr, Ptr, castPtr, nullFunPtr, nullPtr)
import Foreign.Storable (peek, poke, pokeElemOff)
import System.IO.Unsafe (unsafePerformIO)
import AviUtl2.Filter
  ( FILTER_ITEM_TRACK(..)
  , FILTER_PLUGIN_TABLE(..)
  , FILTER_PROC_VIDEO(..)
  , filterFlagInput
  , filterFlagVideo
  , setImageData
  )
import AviUtl2.Types (BOOL_, DWORD, LPCWSTR, OBJECT_INFO(..), PIXEL_RGBA(..))
import PluginSupport (newWideString, requiredVersion)

foreign import ccall "wrapper"
  mkFuncProcVideo :: (Ptr FILTER_PROC_VIDEO -> IO BOOL_) -> IO (FunPtr (Ptr FILTER_PROC_VIDEO -> IO BOOL_))

foreign export ccall "RequiredVersion"
  requiredVersionExport :: IO DWORD

foreign export ccall "InitializePlugin"
  initializePlugin :: DWORD -> IO BOOL_

foreign export ccall "UninitializePlugin"
  uninitializePlugin :: IO ()

foreign export ccall "GetFilterPluginTable"
  getFilterPluginTable :: IO (Ptr FILTER_PLUGIN_TABLE)

pluginName, pluginLabel, pluginInfo, itemTypeTrack, itemNameWidth, itemNameHeight :: LPCWSTR
pluginName = unsafePerformIO (newWideString "Rusty Random Color Filter (hs)")
pluginLabel = unsafePerformIO (newWideString "Random Color")
pluginInfo = unsafePerformIO (newWideString "aviutl2-rs random-color-filter port for Haskell")
itemTypeTrack = unsafePerformIO (newWideString "track")
itemNameWidth = unsafePerformIO (newWideString "Width")
itemNameHeight = unsafePerformIO (newWideString "Height")
{-# NOINLINE pluginName #-}
{-# NOINLINE pluginLabel #-}
{-# NOINLINE pluginInfo #-}
{-# NOINLINE itemTypeTrack #-}
{-# NOINLINE itemNameWidth #-}
{-# NOINLINE itemNameHeight #-}

widthPtr, heightPtr :: Ptr FILTER_ITEM_TRACK
widthPtr = unsafePerformIO $ do
  ptr <- malloc
  poke ptr (FILTER_ITEM_TRACK itemTypeTrack itemNameWidth 640.0 1.0 4096.0 1.0)
  pure ptr
{-# NOINLINE widthPtr #-}

heightPtr = unsafePerformIO $ do
  ptr <- malloc
  poke ptr (FILTER_ITEM_TRACK itemTypeTrack itemNameHeight 640.0 1.0 4096.0 1.0)
  pure ptr
{-# NOINLINE heightPtr #-}

itemsPtr :: Ptr (Ptr ())
itemsPtr = unsafePerformIO $ newArray
  [ castPtr widthPtr
  , castPtr heightPtr
  , nullPtr
  ]
{-# NOINLINE itemsPtr #-}

videoProcPtr :: FunPtr (Ptr FILTER_PROC_VIDEO -> IO BOOL_)
videoProcPtr = unsafePerformIO (mkFuncProcVideo funcProcVideo)
{-# NOINLINE videoProcPtr #-}

filterPluginTablePtr :: Ptr FILTER_PLUGIN_TABLE
filterPluginTablePtr = unsafePerformIO $ do
  ptr <- malloc
  poke ptr FILTER_PLUGIN_TABLE
    { fptFlag = filterFlagVideo + filterFlagInput
    , fptName = pluginName
    , fptLabel = pluginLabel
    , fptInformation = pluginInfo
    , fptItems = itemsPtr
    , fptFuncProcVideo = videoProcPtr
    , fptFuncProcAudio = nullFunPtr
    }
  pure ptr
{-# NOINLINE filterPluginTablePtr #-}

requiredVersionExport :: IO DWORD
requiredVersionExport = pure requiredVersion

initializePlugin :: DWORD -> IO BOOL_
initializePlugin _ = pure 1

uninitializePlugin :: IO ()
uninitializePlugin = pure ()

getFilterPluginTable :: IO (Ptr FILTER_PLUGIN_TABLE)
getFilterPluginTable = pure filterPluginTablePtr

funcProcVideo :: Ptr FILTER_PROC_VIDEO -> IO BOOL_
funcProcVideo video = do
  proc <- peek video
  objectInfo <- peek (fpvObject proc)
  width <- round . fitValue <$> peek widthPtr
  height <- round . fitValue <$> peek heightPtr
  if width <= 0 || height <= 0
    then pure 0
    else do
      let (r, g, b) = hashColor (oiEffectId objectInfo)
          pixelCount = width * height
      buf <- mallocArray pixelCount
      mapM_ (\i -> pokeElemOff buf i (PIXEL_RGBA r g b 255)) [0 .. pixelCount - 1]
      setImageData video buf (fromIntegral width) (fromIntegral height)
      free buf
      pure 1

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
