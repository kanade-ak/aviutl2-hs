{-# LANGUAGE ForeignFunctionInterface #-}
module SingleImageOutput where

import Codec.Picture
  ( DynamicImage(..)
  , Image(..)
  , PixelRGBA8
  , PixelRGBA16(..)
  , convertRGBA8
  , generateImage
  , saveBmpImage
  , saveGifImage
  , saveJpgImage
  , savePngImage
  , saveTiffImage
  )
import Codec.Picture.Saving (imageToRadiance, imageToTga)
import Control.Concurrent.MVar (MVar, modifyMVar, newMVar)
import Control.Exception (SomeException, try)
import Control.Monad (when)
import qualified Data.ByteString as BS
import qualified Data.ByteString.Lazy as LBS
import Data.Bits ((.&.), shiftR)
import Data.Char (toLower)
import qualified Data.Vector.Storable as VS
import Data.Word (Word16, Word8)
import Foreign.C.String (peekCWString, withCString, withCWString)
import Foreign.C.Types (CBool(..), CInt(..), CSize(..), CULong(..))
import Foreign.Marshal.Alloc (alloca, malloc)
import Foreign.Marshal.Array (peekArray)
import Foreign.Ptr (FunPtr, Ptr, castPtr, nullFunPtr, nullPtr)
import Foreign.Storable (peek, poke)
import System.Directory (createDirectoryIfMissing, doesFileExist, getTemporaryDirectory)
import System.FilePath (takeDirectory, takeExtension)
import System.IO.Unsafe (unsafePerformIO)
import AviUtl2.Output
  ( OUTPUT_INFO(..)
  , OUTPUT_PLUGIN_TABLE(..)
  , oiGetVideo
  , outputFlagImage
  )
import AviUtl2.Types (BOOL_, DWORD, LPCWSTR)
import PluginSupport (newWideString, requiredVersion)

foreign import ccall "wrapper"
  mkOutput :: (Ptr OUTPUT_INFO -> IO BOOL_) -> IO (FunPtr (Ptr OUTPUT_INFO -> IO BOOL_))

foreign import ccall "wrapper"
  mkConfigText :: IO LPCWSTR -> IO (FunPtr (IO LPCWSTR))

foreign import ccall "dynamic"
  mkWebPEncodeLosslessRGBA :: FunPtr (Ptr Word8 -> CInt -> CInt -> CInt -> Ptr (Ptr Word8) -> IO CSize) -> Ptr Word8 -> CInt -> CInt -> CInt -> Ptr (Ptr Word8) -> IO CSize

foreign import ccall "dynamic"
  mkWebPFree :: FunPtr (Ptr a -> IO ()) -> Ptr a -> IO ()

foreign import ccall unsafe "windows.h LoadLibraryW"
  cLoadLibraryW :: LPCWSTR -> IO (Ptr ())

foreign import ccall unsafe "windows.h GetProcAddress"
  cGetProcAddress :: Ptr () -> Ptr Word8 -> IO (FunPtr a)

foreign import ccall unsafe "embedded_libwebp_7_dll_ptr"
  cEmbeddedWebpPtr :: IO (Ptr Word8)

foreign import ccall unsafe "embedded_libwebp_7_dll_len"
  cEmbeddedWebpLen :: IO CSize

foreign import ccall unsafe "embedded_libsharpyuv_0_dll_ptr"
  cEmbeddedSharpyuvPtr :: IO (Ptr Word8)

foreign import ccall unsafe "embedded_libsharpyuv_0_dll_len"
  cEmbeddedSharpyuvLen :: IO CSize

foreign export ccall "RequiredVersion"
  requiredVersionExport :: IO DWORD

foreign export ccall "InitializePlugin"
  initializePlugin :: DWORD -> IO BOOL_

foreign export ccall "UninitializePlugin"
  uninitializePlugin :: IO ()

foreign export ccall "GetOutputPluginTable"
  getOutputPluginTable :: IO (Ptr OUTPUT_PLUGIN_TABLE)

pluginName, pluginFilter, pluginInfo, configText :: LPCWSTR
pluginName = unsafePerformIO (newWideString "Rusty Single Image Output")
pluginFilter = unsafePerformIO (newWideString "WebP Image (*.webp)\0*.webp\0PNG Image (*.png)\0*.png\0JPEG Image (*.jpg;*.jpeg)\0*.jpg;*.jpeg\0All Image Formats (*.*)\0*.*\0")
pluginInfo = unsafePerformIO (newWideString "Single Image Output for AviUtl2, powered by JuicyPixels, written in Haskell / https://github.com/sevenc-nanashi/aviutl2-rs/tree/main/examples/image-rs-single-output")
configText = unsafePerformIO (newWideString "No settings")
{-# NOINLINE pluginName #-}
{-# NOINLINE pluginFilter #-}
{-# NOINLINE pluginInfo #-}
{-# NOINLINE configText #-}

outputPtr :: FunPtr (Ptr OUTPUT_INFO -> IO BOOL_)
outputPtr = unsafePerformIO (mkOutput outputSingleImage)
{-# NOINLINE outputPtr #-}

configTextPtr :: FunPtr (IO LPCWSTR)
configTextPtr = unsafePerformIO (mkConfigText (pure configText))
{-# NOINLINE configTextPtr #-}

outputPluginTablePtr :: Ptr OUTPUT_PLUGIN_TABLE
outputPluginTablePtr = unsafePerformIO $ do
  ptr <- malloc
  poke ptr OUTPUT_PLUGIN_TABLE
    { optFlag = outputFlagImage
    , optName = pluginName
    , optFilefilter = pluginFilter
    , optInformation = pluginInfo
    , optFuncOutput = outputPtr
    , optFuncConfig = nullFunPtr
    , optFuncGetConfigText = configTextPtr
    }
  pure ptr
{-# NOINLINE outputPluginTablePtr #-}

data WebpApi = WebpApi
  { webpEncodeLosslessRGBA :: Ptr Word8 -> CInt -> CInt -> CInt -> Ptr (Ptr Word8) -> IO CSize
  , webpFree :: Ptr () -> IO ()
  }

embeddedWebpDll :: BS.ByteString
embeddedWebpDll = unsafePerformIO $ do
  ptr <- cEmbeddedWebpPtr
  len <- cEmbeddedWebpLen
  BS.packCStringLen (castPtr ptr, fromIntegral len)
{-# NOINLINE embeddedWebpDll #-}

embeddedSharpyuvDll :: BS.ByteString
embeddedSharpyuvDll = unsafePerformIO $ do
  ptr <- cEmbeddedSharpyuvPtr
  len <- cEmbeddedSharpyuvLen
  BS.packCStringLen (castPtr ptr, fromIntegral len)
{-# NOINLINE embeddedSharpyuvDll #-}

webpApiVar :: MVar (Maybe WebpApi)
webpApiVar = unsafePerformIO (newMVar Nothing)
{-# NOINLINE webpApiVar #-}

requiredVersionExport :: IO DWORD
requiredVersionExport = pure requiredVersion

initializePlugin :: DWORD -> IO BOOL_
initializePlugin _ = pure 1

uninitializePlugin :: IO ()
uninitializePlugin = pure ()

getOutputPluginTable :: IO (Ptr OUTPUT_PLUGIN_TABLE)
getOutputPluginTable = pure outputPluginTablePtr

outputSingleImage :: Ptr OUTPUT_INFO -> IO BOOL_
outputSingleImage infoPtr = do
  result <- (try $ do
    info <- peek infoPtr
    let width = fromIntegral (outInfoWidth info) :: Int
        height = fromIntegral (outInfoHeight info) :: Int
    when (width <= 0 || height <= 0) $
      ioError (userError "invalid image size")

    path <- peekCWString (outInfoSavefile info)
    createDirectoryIfMissing True (takeDirectory path)

    frameImage <- loadHf64Frame infoPtr info width height
    saveImage path frameImage) :: IO (Either SomeException ())
  case result of
    Left _ -> pure 0
    Right () -> pure 1

loadHf64Frame :: Ptr OUTPUT_INFO -> OUTPUT_INFO -> Int -> Int -> IO DynamicImage
loadHf64Frame infoPtr _ width height = do
  buffer <- oiGetVideo infoPtr 0 biHf64
  when (buffer == nullPtr) $
    ioError (userError "failed to get HF64 image buffer")

  rawWords <- peekArray (width * height * 4) (castPtr buffer :: Ptr Word16)
  let pixels = VS.fromListN (width * height * 4) rawWords
      image = generateImage (pixelAt pixels width) width height
  pure (ImageRGBA16 image)

saveImage :: FilePath -> DynamicImage -> IO ()
saveImage path image =
  case map toLower (takeExtension path) of
    ".webp" -> saveWebpImage path rgba8
    ".png" -> savePngWithFallback path image rgba8Image
    ".jpg" -> saveJpgImage 75 path rgba8
    ".jpeg" -> saveJpgImage 75 path rgba8
    ".bmp" -> saveBmpImage path rgba8
    ".gif" ->
      case saveGifImage path rgba8 of
        Left err -> ioError (userError err)
        Right action -> action
    ".tif" -> saveTiffImage path image
    ".tiff" -> saveTiffImage path image
    ".tga" -> LBS.writeFile path (imageToTga rgba8)
    ".hdr" -> LBS.writeFile path (imageToRadiance image)
    ext -> ioError (userError ("unsupported output extension: " ++ ext))
  where
    rgba8Image = convertRGBA8 image
    rgba8 = ImageRGBA8 rgba8Image

savePngWithFallback :: FilePath -> DynamicImage -> Image PixelRGBA8 -> IO ()
savePngWithFallback path image rgba8Image = do
  result <- try (savePngImage path image) :: IO (Either SomeException ())
  case result of
    Left _ -> savePngImage path (ImageRGBA8 rgba8Image)
    Right () -> pure ()

saveWebpImage :: FilePath -> DynamicImage -> IO ()
saveWebpImage path (ImageRGBA8 image) = do
  encoded <- encodeLosslessWebp image
  BS.writeFile path encoded
saveWebpImage _ _ =
  ioError (userError "unexpected non-RGBA8 image for WebP encoding")

encodeLosslessWebp :: Image PixelRGBA8 -> IO BS.ByteString
encodeLosslessWebp image = do
  api <- getWebpApi
  VS.unsafeWith (imageData image) $ \inputPtr ->
    alloca $ \outputPtrPtr -> do
      let width = fromIntegral (imageWidth image)
          height = fromIntegral (imageHeight image)
          stride = fromIntegral (imageWidth image * 4)
      encodedSize <- webpEncodeLosslessRGBA api inputPtr width height stride outputPtrPtr
      outputPtr <- peek outputPtrPtr
      when (encodedSize == 0 || outputPtr == nullPtr) $
        ioError (userError "failed to encode WebP image")
      encoded <- BS.packCStringLen (castPtr outputPtr, fromIntegral encodedSize)
      webpFree api (castPtr outputPtr)
      pure encoded

getWebpApi :: IO WebpApi
getWebpApi =
  modifyMVar webpApiVar $ \cached ->
    case cached of
      Just api -> pure (cached, api)
      Nothing -> do
        api <- loadWebpApi
        pure (Just api, api)

loadWebpApi :: IO WebpApi
loadWebpApi = do
  runtimeDir <- ensureEmbeddedDlls
  sharpyuvHandle <- loadLibraryOrFail (runtimeDir <> "\\libsharpyuv-0.dll")
  _ <- pure sharpyuvHandle
  webpHandle <- loadLibraryOrFail (runtimeDir <> "\\libwebp-7.dll")
  encodePtr <- getProcAddressOrFail webpHandle "WebPEncodeLosslessRGBA"
  freePtr <- getProcAddressOrFail webpHandle "WebPFree"
  pure WebpApi
    { webpEncodeLosslessRGBA = mkWebPEncodeLosslessRGBA encodePtr
    , webpFree = mkWebPFree freePtr
    }

ensureEmbeddedDlls :: IO FilePath
ensureEmbeddedDlls = do
  tempDir <- getTemporaryDirectory
  let runtimeDir = tempDir <> "\\aviutl2-hs-single-image-output"
  createDirectoryIfMissing True runtimeDir
  writeDllIfMissing (runtimeDir <> "\\libsharpyuv-0.dll") embeddedSharpyuvDll
  writeDllIfMissing (runtimeDir <> "\\libwebp-7.dll") embeddedWebpDll
  pure runtimeDir

writeDllIfMissing :: FilePath -> BS.ByteString -> IO ()
writeDllIfMissing path content = do
  exists <- doesFileExist path
  when (not exists) $
    BS.writeFile path content

loadLibraryOrFail :: FilePath -> IO (Ptr ())
loadLibraryOrFail path =
  withCWString path $ \widePath -> do
    handle <- cLoadLibraryW widePath
    when (handle == nullPtr) $
      ioError (userError ("failed to load embedded runtime: " ++ path))
    pure handle

getProcAddressOrFail :: Ptr () -> String -> IO (FunPtr a)
getProcAddressOrFail handle symbol =
  withCString symbol $ \symbolPtr -> do
    ptr <- cGetProcAddress handle (castPtr symbolPtr)
    when (ptr == nullFunPtr) $
      ioError (userError ("failed to resolve symbol: " ++ symbol))
    pure ptr

pixelAt :: VS.Vector Word16 -> Int -> Int -> Int -> PixelRGBA16
pixelAt pixels width x y =
  let base = ((y * width) + x) * 4
  in PixelRGBA16
       (halfBitsToWord16 (pixels VS.! (base + 0)))
       (halfBitsToWord16 (pixels VS.! (base + 1)))
       (halfBitsToWord16 (pixels VS.! (base + 2)))
       (halfBitsToWord16 (pixels VS.! (base + 3)))

halfBitsToWord16 :: Word16 -> Word16
halfBitsToWord16 bits =
  round (clampUnit (halfBitsToDouble bits) * 65535.0)

halfBitsToDouble :: Word16 -> Double
halfBitsToDouble word
  | exponent == 0 =
      if mantissa == 0
        then signedZero
        else sign * (fromIntegral mantissa / 1024.0) * (2 ^^ (-14 :: Int))
  | exponent == 31 =
      if mantissa == 0
        then sign * (1 / 0)
        else 0 / 0
  | otherwise =
      sign * (1.0 + fromIntegral mantissa / 1024.0) * (2 ** fromIntegral (exponent - 15))
  where
    exponent = fromIntegral ((word `shiftR` 10) .&. 0x1F) :: Int
    mantissa = fromIntegral (word .&. 0x03FF) :: Int
    sign = if word .&. 0x8000 == 0 then 1.0 else -1.0
    signedZero = if sign > 0 then 0.0 else -0.0

clampUnit :: Double -> Double
clampUnit value
  | isNaN value = 0
  | value <= 0 = 0
  | value >= 1 = 1
  | otherwise = value

biHf64 :: DWORD
biHf64 = fourCC 'H' 'F' '6' '4'

fourCC :: Char -> Char -> Char -> Char -> DWORD
fourCC a b c d =
  fromIntegral
    ( fromEnum a
    + shift 8 b
    + shift 16 c
    + shift 24 d
    )
  where
    shift bits ch = fromEnum ch * (2 ^ bits)
