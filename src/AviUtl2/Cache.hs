{-|
Module      : AviUtl2.Cache
Description : AviUtl2のキャッシュ関連APIです。

@cache2.h@ のキャッシュ取得関数は C++ の非自明な値戻り型
(@CACHE_IMAGE@ / @CACHE_AUDIO@ / @CACHE_FILE_IMAGE@) を返します。
Haskell FFI からは直接扱えないため、最小C++ shimが値戻りオブジェクトを
保持し、Haskell側には明示的に解放するビューだけを渡します。
-}
module AviUtl2.Cache
  ( CACHE_IMAGE(..)
  , CACHE_AUDIO(..)
  , CACHE_FILE_IMAGE(..)
  , VIDEO_INFO(..)
  , AUDIO_INFO(..)
  , CACHE_HANDLE(..)
  , getImageCache
  , createImageCache
  , releaseImageCache
  , getAudioCache
  , createAudioCache
  , releaseAudioCache
  , deprecatedGetImageFileCache
  , getVideoFileInfo
  , getAudioFileInfo
  , getImageFileCache
  , getVideoFileCache
  , getVideoFileCacheByTime
  , releaseFileImageCache
  , getAudioFileData
  ) where

import Data.Int (Int64)
import Foreign.C.Types (CBool(..), CDouble(..), CFloat(..), CInt(..))
import Foreign.Ptr (FunPtr, Ptr)
import Foreign.Storable (Storable(..))

import AviUtl2.Filter (INPUT_PIXEL_FORMAT)
import AviUtl2.Types (BOOL_, LPCWSTR, PIXEL_RGBA)

-- | C++ shim が保持する @CACHE_IMAGE@ のビューです。
--
-- 'ciHandle' は解放用の不透明ハンドルです。取得に成功した値は
-- 'releaseImageCache' で解放してください。
data CACHE_IMAGE = CACHE_IMAGE
  { ciHandle :: Ptr ()
  , ciBuffer :: Ptr PIXEL_RGBA
  , ciWidth  :: CInt
  , ciHeight :: CInt
  } deriving (Show)

instance Storable CACHE_IMAGE where
  sizeOf _ = 24
  alignment _ = 8
  peek ptr = CACHE_IMAGE
    <$> peekByteOff ptr 0
    <*> peekByteOff ptr 8
    <*> peekByteOff ptr 16
    <*> peekByteOff ptr 20
  poke ptr v = do
    pokeByteOff ptr 0 (ciHandle v)
    pokeByteOff ptr 8 (ciBuffer v)
    pokeByteOff ptr 16 (ciWidth v)
    pokeByteOff ptr 20 (ciHeight v)

-- | C++ shim が保持する @CACHE_AUDIO@ のビューです。
data CACHE_AUDIO = CACHE_AUDIO
  { caHandle     :: Ptr ()
  , caBuffer0    :: Ptr CFloat
  , caBuffer1    :: Ptr CFloat
  , caSampleNum  :: CInt
  , caChannelNum :: CInt
  } deriving (Show)

instance Storable CACHE_AUDIO where
  sizeOf _ = 32
  alignment _ = 8
  peek ptr = CACHE_AUDIO
    <$> peekByteOff ptr 0
    <*> peekByteOff ptr 8
    <*> peekByteOff ptr 16
    <*> peekByteOff ptr 24
    <*> peekByteOff ptr 28
  poke ptr v = do
    pokeByteOff ptr 0 (caHandle v)
    pokeByteOff ptr 8 (caBuffer0 v)
    pokeByteOff ptr 16 (caBuffer1 v)
    pokeByteOff ptr 24 (caSampleNum v)
    pokeByteOff ptr 28 (caChannelNum v)

-- | C++ shim が保持する @CACHE_FILE_IMAGE@ のビューです。
data CACHE_FILE_IMAGE = CACHE_FILE_IMAGE
  { cfiHandle :: Ptr ()
  , cfiBuffer :: Ptr ()
  , cfiWidth  :: CInt
  , cfiHeight :: CInt
  , cfiPitch  :: CInt
  , cfiFormat :: INPUT_PIXEL_FORMAT
  } deriving (Show)

instance Storable CACHE_FILE_IMAGE where
  sizeOf _ = 32
  alignment _ = 8
  peek ptr = CACHE_FILE_IMAGE
    <$> peekByteOff ptr 0
    <*> peekByteOff ptr 8
    <*> peekByteOff ptr 16
    <*> peekByteOff ptr 20
    <*> peekByteOff ptr 24
    <*> peekByteOff ptr 28
  poke ptr v = do
    pokeByteOff ptr 0 (cfiHandle v)
    pokeByteOff ptr 8 (cfiBuffer v)
    pokeByteOff ptr 16 (cfiWidth v)
    pokeByteOff ptr 20 (cfiHeight v)
    pokeByteOff ptr 24 (cfiPitch v)
    pokeByteOff ptr 28 (cfiFormat v)

data VIDEO_INFO = VIDEO_INFO
  { viTotalTime :: CDouble
  , viFrameNum  :: CInt
  , viTrackNum  :: CInt
  , viWidth     :: CInt
  , viHeight    :: CInt
  , viRate      :: CInt
  , viScale     :: CInt
  } deriving (Show)

instance Storable VIDEO_INFO where
  sizeOf _ = 32
  alignment _ = 8
  peek ptr = VIDEO_INFO
    <$> peekByteOff ptr 0
    <*> peekByteOff ptr 8
    <*> peekByteOff ptr 12
    <*> peekByteOff ptr 16
    <*> peekByteOff ptr 20
    <*> peekByteOff ptr 24
    <*> peekByteOff ptr 28
  poke ptr v = do
    pokeByteOff ptr 0 (viTotalTime v)
    pokeByteOff ptr 8 (viFrameNum v)
    pokeByteOff ptr 12 (viTrackNum v)
    pokeByteOff ptr 16 (viWidth v)
    pokeByteOff ptr 20 (viHeight v)
    pokeByteOff ptr 24 (viRate v)
    pokeByteOff ptr 28 (viScale v)

data AUDIO_INFO = AUDIO_INFO
  { aiTotalTime :: CDouble
  , aiSampleNum :: Int64
  , aiTrackNum  :: CInt
  , aiRate      :: CInt
  , aiChannel   :: CInt
  } deriving (Show)

instance Storable AUDIO_INFO where
  sizeOf _ = 32
  alignment _ = 8
  peek ptr = AUDIO_INFO
    <$> peekByteOff ptr 0
    <*> peekByteOff ptr 8
    <*> peekByteOff ptr 16
    <*> peekByteOff ptr 20
    <*> peekByteOff ptr 24
  poke ptr v = do
    pokeByteOff ptr 0 (aiTotalTime v)
    pokeByteOff ptr 8 (aiSampleNum v)
    pokeByteOff ptr 16 (aiTrackNum v)
    pokeByteOff ptr 20 (aiRate v)
    pokeByteOff ptr 24 (aiChannel v)

data CACHE_HANDLE = CACHE_HANDLE
  { chGetImageCache               :: FunPtr ()
  , chCreateImageCache            :: FunPtr ()
  , chGetAudioCache               :: FunPtr ()
  , chCreateAudioCache            :: FunPtr ()
  , chDeprecatedGetImageFileCache :: FunPtr ()
  , chGetVideoFileInfo            :: FunPtr (LPCWSTR -> Ptr VIDEO_INFO -> CInt -> IO BOOL_)
  , chGetAudioFileInfo            :: FunPtr (LPCWSTR -> Ptr AUDIO_INFO -> CInt -> IO BOOL_)
  , chGetImageFileCache           :: FunPtr ()
  , chGetVideoFileCache           :: FunPtr ()
  , chGetVideoFileCacheByTime     :: FunPtr ()
  , chGetAudioFileData            :: FunPtr (LPCWSTR -> CInt -> Int64 -> CInt -> Ptr CFloat -> Ptr CFloat -> IO CInt)
  }

instance Storable CACHE_HANDLE where
  sizeOf _ = 88
  alignment _ = 8
  peek ptr = CACHE_HANDLE
    <$> peekByteOff ptr 0
    <*> peekByteOff ptr 8
    <*> peekByteOff ptr 16
    <*> peekByteOff ptr 24
    <*> peekByteOff ptr 32
    <*> peekByteOff ptr 40
    <*> peekByteOff ptr 48
    <*> peekByteOff ptr 56
    <*> peekByteOff ptr 64
    <*> peekByteOff ptr 72
    <*> peekByteOff ptr 80
  poke ptr v = do
    pokeByteOff ptr 0 (chGetImageCache v)
    pokeByteOff ptr 8 (chCreateImageCache v)
    pokeByteOff ptr 16 (chGetAudioCache v)
    pokeByteOff ptr 24 (chCreateAudioCache v)
    pokeByteOff ptr 32 (chDeprecatedGetImageFileCache v)
    pokeByteOff ptr 40 (chGetVideoFileInfo v)
    pokeByteOff ptr 48 (chGetAudioFileInfo v)
    pokeByteOff ptr 56 (chGetImageFileCache v)
    pokeByteOff ptr 64 (chGetVideoFileCache v)
    pokeByteOff ptr 72 (chGetVideoFileCacheByTime v)
    pokeByteOff ptr 80 (chGetAudioFileData v)

foreign import ccall unsafe "hs_aviutl2_cache_get_image_cache"
  getImageCache :: Ptr CACHE_HANDLE -> Ptr () -> LPCWSTR -> Ptr CACHE_IMAGE -> IO BOOL_

foreign import ccall unsafe "hs_aviutl2_cache_create_image_cache"
  createImageCache :: Ptr CACHE_HANDLE -> Ptr () -> LPCWSTR -> CInt -> CInt -> Ptr CACHE_IMAGE -> IO BOOL_

foreign import ccall unsafe "hs_aviutl2_cache_release_image"
  releaseImageCache :: Ptr CACHE_IMAGE -> IO ()

foreign import ccall unsafe "hs_aviutl2_cache_get_audio_cache"
  getAudioCache :: Ptr CACHE_HANDLE -> Ptr () -> LPCWSTR -> Ptr CACHE_AUDIO -> IO BOOL_

foreign import ccall unsafe "hs_aviutl2_cache_create_audio_cache"
  createAudioCache :: Ptr CACHE_HANDLE -> Ptr () -> LPCWSTR -> CInt -> CInt -> Ptr CACHE_AUDIO -> IO BOOL_

foreign import ccall unsafe "hs_aviutl2_cache_release_audio"
  releaseAudioCache :: Ptr CACHE_AUDIO -> IO ()

foreign import ccall unsafe "hs_aviutl2_cache_deprecated_get_image_file_cache"
  deprecatedGetImageFileCache :: Ptr CACHE_HANDLE -> LPCWSTR -> Ptr CACHE_IMAGE -> IO BOOL_

foreign import ccall unsafe "hs_aviutl2_cache_get_image_file_cache"
  getImageFileCache :: Ptr CACHE_HANDLE -> LPCWSTR -> Ptr CACHE_FILE_IMAGE -> IO BOOL_

foreign import ccall unsafe "hs_aviutl2_cache_get_video_file_cache"
  getVideoFileCache :: Ptr CACHE_HANDLE -> LPCWSTR -> CInt -> CInt -> Ptr CACHE_FILE_IMAGE -> IO BOOL_

foreign import ccall unsafe "hs_aviutl2_cache_get_video_file_cache_by_time"
  getVideoFileCacheByTime :: Ptr CACHE_HANDLE -> LPCWSTR -> CInt -> CDouble -> Ptr CACHE_FILE_IMAGE -> IO BOOL_

foreign import ccall unsafe "hs_aviutl2_cache_release_file_image"
  releaseFileImageCache :: Ptr CACHE_FILE_IMAGE -> IO ()

foreign import ccall "dynamic"
  mkGetVideoFileInfo :: FunPtr (LPCWSTR -> Ptr VIDEO_INFO -> CInt -> IO BOOL_) -> LPCWSTR -> Ptr VIDEO_INFO -> CInt -> IO BOOL_

foreign import ccall "dynamic"
  mkGetAudioFileInfo :: FunPtr (LPCWSTR -> Ptr AUDIO_INFO -> CInt -> IO BOOL_) -> LPCWSTR -> Ptr AUDIO_INFO -> CInt -> IO BOOL_

foreign import ccall "dynamic"
  mkGetAudioFileData :: FunPtr (LPCWSTR -> CInt -> Int64 -> CInt -> Ptr CFloat -> Ptr CFloat -> IO CInt) -> LPCWSTR -> CInt -> Int64 -> CInt -> Ptr CFloat -> Ptr CFloat -> IO CInt

getVideoFileInfo :: Ptr CACHE_HANDLE -> LPCWSTR -> Ptr VIDEO_INFO -> CInt -> IO BOOL_
getVideoFileInfo ptr file info infoSize = do
  h <- peek ptr
  mkGetVideoFileInfo (chGetVideoFileInfo h) file info infoSize

getAudioFileInfo :: Ptr CACHE_HANDLE -> LPCWSTR -> Ptr AUDIO_INFO -> CInt -> IO BOOL_
getAudioFileInfo ptr file info infoSize = do
  h <- peek ptr
  mkGetAudioFileInfo (chGetAudioFileInfo h) file info infoSize

getAudioFileData :: Ptr CACHE_HANDLE -> LPCWSTR -> CInt -> Int64 -> CInt -> Ptr CFloat -> Ptr CFloat -> IO CInt
getAudioFileData ptr file track sampleIndex sampleNum buffer0 buffer1 = do
  h <- peek ptr
  mkGetAudioFileData (chGetAudioFileData h) file track sampleIndex sampleNum buffer0 buffer1
