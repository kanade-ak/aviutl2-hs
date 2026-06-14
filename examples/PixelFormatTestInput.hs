{-# LANGUAGE ForeignFunctionInterface #-}
module PixelFormatTestInput where

import Data.Char (toLower)
import Data.Int (Int16)
import Data.Word (Word8, Word16)
import Foreign.C.String (peekCWString)
import Foreign.C.Types (CBool(..), CInt(..), CULong(..))
import Foreign.Marshal.Alloc (free, malloc)
import Foreign.Ptr (FunPtr, Ptr, castPtr, nullFunPtr, nullPtr)
import Foreign.StablePtr
  ( StablePtr
  , castPtrToStablePtr
  , castStablePtrToPtr
  , deRefStablePtr
  , freeStablePtr
  , newStablePtr
  )
import Foreign.Storable (Storable(..), poke)
import System.FilePath (takeExtension)
import System.IO.Unsafe (unsafePerformIO)
import AviUtl2.Types (BOOL_, DWORD, HINSTANCE, HWND, LPCWSTR)
import AviUtl2.Input
  ( INPUT_HANDLE
  , INPUT_INFO(..)
  , INPUT_PLUGIN_TABLE(..)
  , inputFlagVideo
  , inputPluginFlagVideo
  )
import PluginSupport (newWideString, requiredVersion)

foreign import ccall "wrapper"
  mkOpen :: (LPCWSTR -> IO INPUT_HANDLE) -> IO (FunPtr (LPCWSTR -> IO INPUT_HANDLE))

foreign import ccall "wrapper"
  mkClose :: (INPUT_HANDLE -> IO BOOL_) -> IO (FunPtr (INPUT_HANDLE -> IO BOOL_))

foreign import ccall "wrapper"
  mkInfoGet :: (INPUT_HANDLE -> Ptr INPUT_INFO -> IO BOOL_) -> IO (FunPtr (INPUT_HANDLE -> Ptr INPUT_INFO -> IO BOOL_))

foreign import ccall "wrapper"
  mkReadVideo :: (INPUT_HANDLE -> CInt -> Ptr () -> IO CInt) -> IO (FunPtr (INPUT_HANDLE -> CInt -> Ptr () -> IO CInt))

foreign export ccall "RequiredVersion"
  requiredVersionExport :: IO DWORD

foreign export ccall "InitializePlugin"
  initializePlugin :: DWORD -> IO BOOL_

foreign export ccall "UninitializePlugin"
  uninitializePlugin :: IO ()

foreign export ccall "GetInputPluginTable"
  getInputPluginTable :: IO (Ptr INPUT_PLUGIN_TABLE)

type WORD = Word16

data BITMAPINFOHEADER = BITMAPINFOHEADER
  { bihSize          :: DWORD
  , bihWidth         :: CInt
  , bihHeight        :: CInt
  , bihPlanes        :: WORD
  , bihBitCount      :: WORD
  , bihCompression   :: DWORD
  , bihSizeImage     :: DWORD
  , bihXPelsPerMeter :: CInt
  , bihYPelsPerMeter :: CInt
  , bihClrUsed       :: DWORD
  , bihClrImportant  :: DWORD
  }

instance Storable BITMAPINFOHEADER where
  sizeOf _ = 40
  alignment _ = 4
  peek ptr = BITMAPINFOHEADER
    <$> peekByteOff ptr 0
    <*> peekByteOff ptr 4
    <*> peekByteOff ptr 8
    <*> peekByteOff ptr 12
    <*> peekByteOff ptr 14
    <*> peekByteOff ptr 16
    <*> peekByteOff ptr 20
    <*> peekByteOff ptr 24
    <*> peekByteOff ptr 28
    <*> peekByteOff ptr 32
    <*> peekByteOff ptr 36
  poke ptr v = do
    pokeByteOff ptr 0 (bihSize v)
    pokeByteOff ptr 4 (bihWidth v)
    pokeByteOff ptr 8 (bihHeight v)
    pokeByteOff ptr 12 (bihPlanes v)
    pokeByteOff ptr 14 (bihBitCount v)
    pokeByteOff ptr 16 (bihCompression v)
    pokeByteOff ptr 20 (bihSizeImage v)
    pokeByteOff ptr 24 (bihXPelsPerMeter v)
    pokeByteOff ptr 28 (bihYPelsPerMeter v)
    pokeByteOff ptr 32 (bihClrUsed v)
    pokeByteOff ptr 36 (bihClrImportant v)

data PixelFormat
  = PixelBgr
  | PixelBgra
  | PixelYuy2
  | PixelPa64
  | PixelHf64
  | PixelYc48

data HandleState = HandleState
  { hsFormat    :: PixelFormat
  , hsWidth     :: Int
  , hsHeight    :: Int
  , hsFormatPtr :: Ptr BITMAPINFOHEADER
  }

pluginName, pluginFilter, pluginInfo :: LPCWSTR
pluginName = unsafePerformIO (newWideString "Rusty Pixel Format Tester Input (hs)")
pluginFilter = unsafePerformIO (newWideString "Pixel Formats (*.bgra;*.bgr;*.yuy2;*.pa64;*.hf64;*.yc48)\0*.bgra;*.bgr;*.yuy2;*.pa64;*.hf64;*.yc48\0")
pluginInfo = unsafePerformIO (newWideString "aviutl2-rs pixel-format-test-input port for Haskell")
{-# NOINLINE pluginName #-}
{-# NOINLINE pluginFilter #-}
{-# NOINLINE pluginInfo #-}

openPtr :: FunPtr (LPCWSTR -> IO INPUT_HANDLE)
openPtr = unsafePerformIO (mkOpen openInput)
{-# NOINLINE openPtr #-}

closePtr :: FunPtr (INPUT_HANDLE -> IO BOOL_)
closePtr = unsafePerformIO (mkClose closeInput)
{-# NOINLINE closePtr #-}

infoGetPtr :: FunPtr (INPUT_HANDLE -> Ptr INPUT_INFO -> IO BOOL_)
infoGetPtr = unsafePerformIO (mkInfoGet infoGetInput)
{-# NOINLINE infoGetPtr #-}

readVideoPtr :: FunPtr (INPUT_HANDLE -> CInt -> Ptr () -> IO CInt)
readVideoPtr = unsafePerformIO (mkReadVideo readVideoInput)
{-# NOINLINE readVideoPtr #-}

inputPluginTablePtr :: Ptr INPUT_PLUGIN_TABLE
inputPluginTablePtr = unsafePerformIO $ do
  ptr <- malloc
  poke ptr INPUT_PLUGIN_TABLE
    { iptFlag = inputPluginFlagVideo
    , iptName = pluginName
    , iptFilefilter = pluginFilter
    , iptInformation = pluginInfo
    , iptFuncOpen = openPtr
    , iptFuncClose = closePtr
    , iptFuncInfoGet = infoGetPtr
    , iptFuncReadVideo = readVideoPtr
    , iptFuncReadAudio = nullFunPtr
    , iptFuncConfig = nullFunPtr
    , iptFuncSetTrack = nullFunPtr
    , iptFuncTimeToFrame = nullFunPtr
    }
  pure ptr
{-# NOINLINE inputPluginTablePtr #-}

requiredVersionExport :: IO DWORD
requiredVersionExport = pure requiredVersion

initializePlugin :: DWORD -> IO BOOL_
initializePlugin _ = pure 1

uninitializePlugin :: IO ()
uninitializePlugin = pure ()

getInputPluginTable :: IO (Ptr INPUT_PLUGIN_TABLE)
getInputPluginTable = pure inputPluginTablePtr

openInput :: LPCWSTR -> IO INPUT_HANDLE
openInput file
  | file == nullPtr = pure nullPtr
  | otherwise = do
      path <- peekCWString file
      case parsePixelFormat path of
        Nothing -> pure nullPtr
        Just format_ -> do
          formatPtr <- malloc
          poke formatPtr (mkBitmapInfoHeader format_ 256 256)
          stable <- newStablePtr HandleState
            { hsFormat = format_
            , hsWidth = 256
            , hsHeight = 256
            , hsFormatPtr = formatPtr
            }
          pure (castStablePtrToPtr stable)

closeInput :: INPUT_HANDLE -> IO BOOL_
closeInput handle
  | handle == nullPtr = pure 0
  | otherwise = do
      let stable = castPtrToStablePtr handle :: StablePtr HandleState
      state <- deRefStablePtr stable
      free (hsFormatPtr state)
      freeStablePtr stable
      pure 1

infoGetInput :: INPUT_HANDLE -> Ptr INPUT_INFO -> IO BOOL_
infoGetInput handle infoPtr
  | handle == nullPtr || infoPtr == nullPtr = pure 0
  | otherwise = do
      state <- deRefStablePtr (castPtrToStablePtr handle :: StablePtr HandleState)
      poke infoPtr INPUT_INFO
        { iiFlag = inputFlagVideo
        , iiRate = 30
        , iiScale = 1
        , iiN = 1
        , iiFormat = castPtr (hsFormatPtr state)
        , iiFormatSize = fromIntegral (sizeOf (undefined :: BITMAPINFOHEADER))
        , iiAudioN = 0
        , iiAudioFormat = nullPtr
        , iiAudioFormatSize = 0
        }
      pure 1

readVideoInput :: INPUT_HANDLE -> CInt -> Ptr () -> IO CInt
readVideoInput handle frame buf
  | handle == nullPtr || buf == nullPtr = pure 0
  | frame /= 0 = pure 0
  | otherwise = do
      state <- deRefStablePtr (castPtrToStablePtr handle :: StablePtr HandleState)
      writePattern state buf
      pure (fromIntegral (imageSize (hsFormat state) (hsWidth state) (hsHeight state)))

parsePixelFormat :: FilePath -> Maybe PixelFormat
parsePixelFormat path =
  case map toLower (dropWhile (== '.') (takeExtension path)) of
    "bgr"  -> Just PixelBgr
    "bgra" -> Just PixelBgra
    "yuy2" -> Just PixelYuy2
    "pa64" -> Just PixelPa64
    "hf64" -> Just PixelHf64
    "yc48" -> Just PixelYc48
    _      -> Nothing

mkBitmapInfoHeader :: PixelFormat -> Int -> Int -> BITMAPINFOHEADER
mkBitmapInfoHeader format_ width height =
  BITMAPINFOHEADER
    { bihSize = 40
    , bihWidth = fromIntegral width
    , bihHeight = fromIntegral height
    , bihPlanes = 1
    , bihBitCount = fromIntegral (bytesPerPixel format_ * 8)
    , bihCompression = compressionCode format_
    , bihSizeImage = fromIntegral (imageSize format_ width height)
    , bihXPelsPerMeter = 0
    , bihYPelsPerMeter = 0
    , bihClrUsed = 0
    , bihClrImportant = 0
    }

bytesPerPixel :: PixelFormat -> Int
bytesPerPixel PixelBgr = 3
bytesPerPixel PixelBgra = 4
bytesPerPixel PixelYuy2 = 2
bytesPerPixel PixelPa64 = 8
bytesPerPixel PixelHf64 = 8
bytesPerPixel PixelYc48 = 6

imageSize :: PixelFormat -> Int -> Int -> Int
imageSize format_ width height = width * height * bytesPerPixel format_

compressionCode :: PixelFormat -> DWORD
compressionCode PixelBgr = 0
compressionCode PixelBgra = 0
compressionCode PixelYuy2 = fourCC 'Y' 'U' 'Y' '2'
compressionCode PixelPa64 = fourCC 'P' 'A' '6' '4'
compressionCode PixelHf64 = fourCC 'H' 'F' '6' '4'
compressionCode PixelYc48 = fourCC 'Y' 'C' '4' '8'

fourCC :: Char -> Char -> Char -> Char -> DWORD
fourCC a b c d =
  fromIntegral
    ( fromEnum a
    + shift 8 b
    + shift 16 c
    + shift 24 d
    )
  where
    shift bits ch = fromEnum ch `shiftLInt` bits

shiftLInt :: Int -> Int -> Int
shiftLInt value bits = value * (2 ^ bits)

writePattern :: HandleState -> Ptr () -> IO ()
writePattern state buf =
  case hsFormat state of
    PixelBgra -> writeBgra buf (hsWidth state) (hsHeight state)
    PixelBgr  -> writeBgr buf (hsWidth state) (hsHeight state)
    PixelYuy2 -> writeYuy2 buf (hsWidth state) (hsHeight state)
    PixelPa64 -> writePa64 buf (hsWidth state) (hsHeight state)
    PixelHf64 -> writeHf64 buf (hsWidth state) (hsHeight state)
    PixelYc48 -> writeYc48 buf (hsWidth state) (hsHeight state)

writeBgra :: Ptr () -> Int -> Int -> IO ()
writeBgra buf width height =
  mapM_ (\(index, value) -> pokeByteOff buf index value) $
    concatMap row [0 .. height - 1]
  where
    row y = concatMap (pixel y) [0 .. width - 1]
    pixel y x =
      let base = (y * width + x) * 4
      in [ (base + 0, fromIntegral x :: Word8)
         , (base + 1, fromIntegral y :: Word8)
         , (base + 2, gradByte x y width height)
         , (base + 3, 255 :: Word8)
         ]

writeBgr :: Ptr () -> Int -> Int -> IO ()
writeBgr buf width height =
  mapM_ (\(index, value) -> pokeByteOff buf index value) $
    concatMap row [0 .. height - 1]
  where
    row y = concatMap (pixel y) [0 .. width - 1]
    pixel y x =
      let base = (y * width + x) * 3
      in [ (base + 0, fromIntegral x :: Word8)
         , (base + 1, fromIntegral y :: Word8)
         , (base + 2, gradByte x y width height)
         ]

writeYuy2 :: Ptr () -> Int -> Int -> IO ()
writeYuy2 buf width height =
  mapM_ writePair
    [ (x, y) | y <- [0 .. height - 1], x <- [0,2 .. width - 2] ]
  where
    writePair (x, y) = do
      let base = (y * width + x) * 2
          y0 = gradByte x y width height
          y1 = gradByte (x + 1) y width height
          u = scaleByte x width
          v = scaleByte y height
      pokeByteOff buf (base + 0) y0
      pokeByteOff buf (base + 1) u
      pokeByteOff buf (base + 2) y1
      pokeByteOff buf (base + 3) v

writePa64 :: Ptr () -> Int -> Int -> IO ()
writePa64 buf width height =
  mapM_ writePixel [ (x, y) | y <- [0 .. height - 1], x <- [0 .. width - 1] ]
  where
    writePixel (x, y) = do
      let base = (y * width + x) * 8
      pokeByteOff buf (base + 0) (scaleWord16 x width :: Word16)
      pokeByteOff buf (base + 2) (scaleWord16 y height :: Word16)
      pokeByteOff buf (base + 4) (gradWord16 x y width height :: Word16)
      pokeByteOff buf (base + 6) (65535 :: Word16)

writeHf64 :: Ptr () -> Int -> Int -> IO ()
writeHf64 buf width height =
  mapM_ writePixel [ (x, y) | y <- [0 .. height - 1], x <- [0 .. width - 1] ]
  where
    writePixel (x, y) = do
      let base = (y * width + x) * 8
      pokeByteOff buf (base + 0) (floatToHalfWord (scaleUnit x width) :: Word16)
      pokeByteOff buf (base + 2) (floatToHalfWord (scaleUnit y height) :: Word16)
      pokeByteOff buf (base + 4) (floatToHalfWord (gradUnit x y width height) :: Word16)
      pokeByteOff buf (base + 6) (floatToHalfWord 1.0 :: Word16)

writeYc48 :: Ptr () -> Int -> Int -> IO ()
writeYc48 buf width height =
  mapM_ writePixel [ (x, y) | y <- [0 .. height - 1], x <- [0 .. width - 1] ]
  where
    writePixel (x, y) = do
      let base = (y * width + x) * 6
      pokeByteOff buf (base + 0) (fromIntegral (round (gradUnit x y width height * 4096.0)) :: Int16)
      pokeByteOff buf (base + 2) (fromIntegral (round (scaleUnit x width * 4096.0 - 2048.0)) :: Int16)
      pokeByteOff buf (base + 4) (fromIntegral (round (scaleUnit y height * 4096.0 - 2048.0)) :: Int16)

gradByte :: Int -> Int -> Int -> Int -> Word8
gradByte x y width height = fromIntegral (round (gradUnit x y width height * 255.0))

gradWord16 :: Int -> Int -> Int -> Int -> Word16
gradWord16 x y width height = fromIntegral (round (gradUnit x y width height * 65535.0))

scaleByte :: Int -> Int -> Word8
scaleByte value total = fromIntegral (round (scaleUnit value total * 255.0))

scaleWord16 :: Int -> Int -> Word16
scaleWord16 value total = fromIntegral (round (scaleUnit value total * 65535.0))

scaleUnit :: Int -> Int -> Double
scaleUnit value total
  | total <= 0 = 0
  | otherwise = fromIntegral value / fromIntegral total

gradUnit :: Int -> Int -> Int -> Int -> Double
gradUnit x y width height
  | width + height <= 0 = 0
  | otherwise = fromIntegral (x + y) / fromIntegral (width + height)

floatToHalfWord :: Double -> Word16
floatToHalfWord x
  | x <= 0 = 0
  | x >= 65504 = 0x7BFF
  | otherwise =
      let exponent0 = floor (logBase 2 x) :: Int
          mantissa0 = x / (2 ** fromIntegral exponent0)
          mantissaBits0 = round ((mantissa0 - 1.0) * 1024.0) :: Int
          (exponent, mantissaBits) =
            if mantissaBits0 >= 1024
              then (exponent0 + 1, 0)
              else (exponent0, mantissaBits0)
          exponentBits = exponent + 15
      in fromIntegral ((exponentBits `shiftLInt` 10) + mantissaBits)
