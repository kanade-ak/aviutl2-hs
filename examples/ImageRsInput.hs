{-# LANGUAGE ForeignFunctionInterface #-}
module ImageRsInput where

import Control.Exception (SomeException, bracket, try)
import Data.ByteString (ByteString)
import qualified Data.ByteString as BS
import Data.Char (toLower)
import Data.Word (Word16)
import Foreign.C.String (peekCWString)
import Foreign.C.Types (CBool(..), CDouble(..), CInt(..), CULong(..))
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
import Foreign.Storable (Storable(..), peek, peekElemOff, poke, pokeByteOff)
import System.Directory (doesFileExist, findExecutable, getTemporaryDirectory, removeFile)
import System.Exit (ExitCode(..))
import System.FilePath (takeExtension)
import System.IO (hClose, openBinaryTempFile)
import System.IO.Unsafe (unsafePerformIO)
import System.Process (proc, readCreateProcessWithExitCode)
import AviUtl2.Input
  ( INPUT_HANDLE
  , INPUT_INFO(..)
  , INPUT_PLUGIN_TABLE(..)
  , inputFlagTimeToFrame
  , inputFlagVideo
  , inputPluginFlagVideo
  )
import AviUtl2.Types (BOOL_, DWORD, LPCWSTR)
import PluginSupport (newWideString, requiredVersion)

foreign import ccall "wrapper"
  mkOpen :: (LPCWSTR -> IO INPUT_HANDLE) -> IO (FunPtr (LPCWSTR -> IO INPUT_HANDLE))

foreign import ccall "wrapper"
  mkClose :: (INPUT_HANDLE -> IO BOOL_) -> IO (FunPtr (INPUT_HANDLE -> IO BOOL_))

foreign import ccall "wrapper"
  mkInfoGet :: (INPUT_HANDLE -> Ptr INPUT_INFO -> IO BOOL_) -> IO (FunPtr (INPUT_HANDLE -> Ptr INPUT_INFO -> IO BOOL_))

foreign import ccall "wrapper"
  mkReadVideo :: (INPUT_HANDLE -> CInt -> Ptr () -> IO CInt) -> IO (FunPtr (INPUT_HANDLE -> CInt -> Ptr () -> IO CInt))

foreign import ccall "wrapper"
  mkTimeToFrame :: (INPUT_HANDLE -> CDouble -> IO CInt) -> IO (FunPtr (INPUT_HANDLE -> CDouble -> IO CInt))

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

data Backend
  = BackendMagickStatic
  | BackendMagickAnimation
  | BackendFfmpegAnimation
  deriving (Eq, Show)

data FrameTiming = FrameTiming
  { ftStart :: Double
  , ftDuration :: Double
  } deriving (Eq, Show)

data HandleState = HandleState
  { hsFilePath :: FilePath
  , hsWidth :: Int
  , hsHeight :: Int
  , hsFormatPtr :: Ptr BITMAPINFOHEADER
  , hsFrameTimings :: [FrameTiming]
  , hsBackend :: Backend
  } deriving (Eq, Show)

pluginName, pluginFilter, pluginInfo :: LPCWSTR
pluginName = unsafePerformIO (newWideString "Rusty Image Input (hs)")
pluginFilter = unsafePerformIO (newWideString "Image Files (*.webp;*.png;*.apng;*.jpg;*.jpeg;*.bmp;*.tiff;*.gif;*.hdr;*.jxl)\0*.webp;*.png;*.apng;*.jpg;*.jpeg;*.bmp;*.tiff;*.gif;*.hdr;*.jxl\0")
pluginInfo = unsafePerformIO (newWideString "image-rs-input compatible sample for AviUtl2, powered by ImageMagick/FFmpeg, written in Haskell")
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

timeToFramePtr :: FunPtr (INPUT_HANDLE -> CDouble -> IO CInt)
timeToFramePtr = unsafePerformIO (mkTimeToFrame timeToFrameInput)
{-# NOINLINE timeToFramePtr #-}

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
    , iptFuncTimeToFrame = timeToFramePtr
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
      result <- (try $ do
        path <- peekCWString file
        spec <- probeInput path
        formatPtr <- malloc
        poke formatPtr (mkBitmapInfoHeader (hsWidth spec) (hsHeight spec))
        stable <- newStablePtr spec { hsFormatPtr = formatPtr }
        pure (castStablePtrToPtr stable)) :: IO (Either SomeException INPUT_HANDLE)
      case result of
        Left _ -> pure nullPtr
        Right handle -> pure handle

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
      result <- (try $ do
        state <- deRefStablePtr (castPtrToStablePtr handle :: StablePtr HandleState)
        let frameCount = length (hsFrameTimings state)
            totalDuration = animationLength (hsFrameTimings state)
            avgFpsMilli =
              if frameCount <= 1 || totalDuration <= 0
                then 1000
                else max 1 (round ((fromIntegral frameCount / totalDuration) * 1000.0))
            flags =
              inputFlagVideo +
              if frameCount > 1 then inputFlagTimeToFrame else 0
        poke infoPtr INPUT_INFO
          { iiFlag = flags
          , iiRate = fromIntegral avgFpsMilli
          , iiScale = 1000
          , iiN = fromIntegral frameCount
          , iiFormat = castPtr (hsFormatPtr state)
          , iiFormatSize = fromIntegral (sizeOf (undefined :: BITMAPINFOHEADER))
          , iiAudioN = 0
          , iiAudioFormat = nullPtr
          , iiAudioFormatSize = 0
          }) :: IO (Either SomeException ())
      pure $ case result of
        Left _ -> 0
        Right () -> 1

readVideoInput :: INPUT_HANDLE -> CInt -> Ptr () -> IO CInt
readVideoInput handle frame buf
  | handle == nullPtr || buf == nullPtr = pure 0
  | frame < 0 = pure 0
  | otherwise = do
      result <- (try $ do
        state <- deRefStablePtr (castPtrToStablePtr handle :: StablePtr HandleState)
        let frameIndex = fromIntegral frame
            frameCount = length (hsFrameTimings state)
        if frameIndex >= frameCount
          then pure 0
          else do
            raw <- decodeFrameBytes state frameIndex
            let expectedSize = hsWidth state * hsHeight state * 8
            if BS.length raw /= expectedSize
              then pure 0
              else do
                writePremultipliedPa64 buf raw
                pure (fromIntegral expectedSize)) :: IO (Either SomeException CInt)
      case result of
        Left _ -> pure 0
        Right sizeRead -> pure sizeRead

timeToFrameInput :: INPUT_HANDLE -> CDouble -> IO CInt
timeToFrameInput handle time
  | handle == nullPtr = pure 0
  | otherwise = do
      result <- (try $ do
        state <- deRefStablePtr (castPtrToStablePtr handle :: StablePtr HandleState)
        let timings = hsFrameTimings state
        pure $
          if length timings <= 1
            then 0
            else fromIntegral (frameIndexAtTime timings (realToFrac time))) :: IO (Either SomeException CInt)
      case result of
        Left _ -> pure 0
        Right frameIndex -> pure frameIndex

probeInput :: FilePath -> IO HandleState
probeInput path = do
  let ext = map toLower (takeExtension path)
  case ext of
    ".gif" -> do
      frames <- probeFfmpegAnimation path
      if length frames > 1
        then mkHandle path BackendFfmpegAnimation frames
        else mkStaticHandle path
    ".png" -> do
      frames <- probeFfmpegAnimation path
      if length frames > 1
        then mkHandle path BackendFfmpegAnimation frames
        else mkStaticHandle path
    ".apng" -> do
      frames <- probeFfmpegAnimation path
      if null frames
        then mkStaticHandle path
        else mkHandle path BackendFfmpegAnimation frames
    ".webp" -> do
      frames <- probeMagickAnimation path
      if length frames > 1
        then mkHandle path BackendMagickAnimation frames
        else mkStaticHandle path
    _ -> mkStaticHandle path

mkStaticHandle :: FilePath -> IO HandleState
mkStaticHandle path = do
  (width, height) <- probeMagickStatic path
  pure HandleState
    { hsFilePath = path
    , hsWidth = width
    , hsHeight = height
    , hsFormatPtr = nullPtr
    , hsFrameTimings = [FrameTiming 0 0]
    , hsBackend = BackendMagickStatic
    }

mkHandle :: FilePath -> Backend -> [FrameTiming] -> IO HandleState
mkHandle path backend frames = do
  (resolvedWidth, resolvedHeight) <-
    case backend of
      BackendFfmpegAnimation -> probeFfmpegDimensions path
      BackendMagickAnimation -> probeMagickStatic path
      BackendMagickStatic -> probeMagickStatic path
  pure HandleState
    { hsFilePath = path
    , hsWidth = resolvedWidth
    , hsHeight = resolvedHeight
    , hsFormatPtr = nullPtr
    , hsFrameTimings = frames
    , hsBackend = backend
    }

probeMagickStatic :: FilePath -> IO (Int, Int)
probeMagickStatic path = do
  output <- runTextCommand "magick" ["identify", "-format", "%w %h", path]
  case words output of
    [wText, hText] -> pure (read wText, read hText)
    _ -> fail "failed to parse magick identify output"

probeMagickAnimation :: FilePath -> IO [FrameTiming]
probeMagickAnimation path = do
  output <- runTextCommand "magick" [path, "-coalesce", "-format", "%w %h %T\n", "info:"]
  pure (parseMagickTimings output)

probeFfmpegAnimation :: FilePath -> IO [FrameTiming]
probeFfmpegAnimation path = do
  output <- runTextCommand "ffprobe"
    [ "-v", "error"
    , "-select_streams", "v:0"
    , "-show_entries", "packet=pts_time,duration_time"
    , "-of", "csv=p=0"
    , path
    ]
  pure (parsePacketTimings output)

probeFfmpegDimensions :: FilePath -> IO (Int, Int)
probeFfmpegDimensions path = do
  output <- runTextCommand "ffprobe"
    [ "-v", "error"
    , "-select_streams", "v:0"
    , "-show_entries", "stream=width,height"
    , "-of", "csv=p=0:s=x"
    , path
    ]
  case break (== 'x') (trim output) of
    (wText, 'x':hText) -> pure (read wText, read hText)
    _ -> fail "failed to parse ffprobe dimensions"

decodeFrameBytes :: HandleState -> Int -> IO ByteString
decodeFrameBytes state frameIndex =
  case hsBackend state of
    BackendMagickStatic ->
      decodeWithMagickStatic (hsFilePath state)
    BackendMagickAnimation ->
      decodeWithMagickAnimation (hsFilePath state) frameIndex
    BackendFfmpegAnimation ->
      decodeWithFfmpegAnimation (hsFilePath state) frameIndex

decodeWithMagickStatic :: FilePath -> IO ByteString
decodeWithMagickStatic path =
  withTempBinaryFile "image-rs-input-static" $ \tmpPath -> do
    runUnitCommand "magick"
      [ path
      , "-alpha", "on"
      , "-depth", "16"
      , "rgba:" ++ tmpPath
      ]
    BS.readFile tmpPath

decodeWithMagickAnimation :: FilePath -> Int -> IO ByteString
decodeWithMagickAnimation path frameIndex =
  withTempBinaryFile "image-rs-input-anim" $ \tmpPath -> do
    let preDelete =
          if frameIndex <= 0
            then []
            else ["-delete", "0-" ++ show (frameIndex - 1)]
    runUnitCommand "magick" $
      [path, "-coalesce"] ++
      preDelete ++
      [ "-delete", "1--1"
      , "-alpha", "on"
      , "-depth", "16"
      , "rgba:" ++ tmpPath
      ]
    BS.readFile tmpPath

decodeWithFfmpegAnimation :: FilePath -> Int -> IO ByteString
decodeWithFfmpegAnimation path frameIndex =
  withTempBinaryFile "image-rs-input-ffmpeg" $ \tmpPath -> do
    runUnitCommand "ffmpeg"
      [ "-v", "error"
      , "-i", path
      , "-f", "rawvideo"
      , "-pix_fmt", "rgba64le"
      , "-frames:v", "1"
      , "-vf", "select=eq(n\\," ++ show frameIndex ++ ")"
      , "-y", tmpPath
      ]
    BS.readFile tmpPath

runTextCommand :: FilePath -> [String] -> IO String
runTextCommand exe args = do
  resolved <- requireExecutable exe
  (exitCode, stdoutText, stderrText) <- readCreateProcessWithExitCode (proc resolved args) ""
  case exitCode of
    ExitSuccess -> pure stdoutText
    ExitFailure _ -> fail (nonEmpty stderrText stdoutText)

runUnitCommand :: FilePath -> [String] -> IO ()
runUnitCommand exe args = do
  resolved <- requireExecutable exe
  (exitCode, stdoutText, stderrText) <- readCreateProcessWithExitCode (proc resolved args) ""
  case exitCode of
    ExitSuccess -> pure ()
    ExitFailure _ -> fail (nonEmpty stderrText stdoutText)

requireExecutable :: FilePath -> IO FilePath
requireExecutable exe = do
  found <- findExecutable exe
  case found of
    Just path -> pure path
    Nothing -> do
      fallback <- findFallbackExecutable exe
      case fallback of
        Just path -> pure path
        Nothing -> fail ("missing executable: " ++ exe)

findFallbackExecutable :: FilePath -> IO (Maybe FilePath)
findFallbackExecutable exe = firstExistingFile (fallbackCandidates exe)

fallbackCandidates :: FilePath -> [FilePath]
fallbackCandidates "magick" =
  [ "C:\\Program Files\\ImageMagick-7.1.2-Q16-HDRI\\magick.exe"
  ]
fallbackCandidates "ffmpeg" =
  [ "C:\\ffmpeg\\bin\\ffmpeg.exe"
  ]
fallbackCandidates "ffprobe" =
  [ "C:\\ffmpeg\\bin\\ffprobe.exe"
  ]
fallbackCandidates _ = []

firstExistingFile :: [FilePath] -> IO (Maybe FilePath)
firstExistingFile [] = pure Nothing
firstExistingFile (candidate : rest) = do
  exists <- doesFileExist candidate
  if exists
    then pure (Just candidate)
    else firstExistingFile rest

withTempBinaryFile :: String -> (FilePath -> IO a) -> IO a
withTempBinaryFile pattern action = do
  tempDir <- getTemporaryDirectory
  bracket
    (do
      (tmpPath, tmpHandle) <- openBinaryTempFile tempDir pattern
      hClose tmpHandle
      pure tmpPath)
    cleanupTemp
    action
  where
    cleanupTemp tmpPath = do
      _ <- try (removeFile tmpPath) :: IO (Either SomeException ())
      pure ()

parseMagickTimings :: String -> [FrameTiming]
parseMagickTimings output =
  zipWith FrameTiming starts delays
  where
    delays =
      [ read delayText / 100.0
      | line <- lines output
      , case words line of
          [_wText, _hText, _delayText] -> True
          _ -> False
      , let [_wText, _hText, delayText] = words line
      ]
    starts = scanl (+) 0 delays

parsePacketTimings :: String -> [FrameTiming]
parsePacketTimings output =
  foldr step [] (filter (not . null) (lines output))
  where
    step line acc =
      case splitOnce ',' line of
        Just (ptsText, durationText) ->
          FrameTiming (read ptsText) (read durationText) : acc
        Nothing -> acc

animationLength :: [FrameTiming] -> Double
animationLength [] = 0
animationLength [FrameTiming start duration] = start + duration
animationLength timings =
  let FrameTiming start duration = last timings
  in start + duration

frameIndexAtTime :: [FrameTiming] -> Double -> Int
frameIndexAtTime [] _ = 0
frameIndexAtTime [_] _ = 0
frameIndexAtTime timings timeSeconds =
  let total = animationLength timings
      wrapped
        | total <= 0 = 0
        | otherwise = timeSeconds - fromIntegral (floor (timeSeconds / total) :: Int) * total
  in go 0 timings wrapped
  where
    go idx [FrameTiming _ _] _ = idx
    go idx (FrameTiming start _ : next@(FrameTiming nextStart _ : _)) t
      | t >= start && t < nextStart = idx
      | otherwise = go (idx + 1) next t
    go _ [] _ = 0

mkBitmapInfoHeader :: Int -> Int -> BITMAPINFOHEADER
mkBitmapInfoHeader width height =
  BITMAPINFOHEADER
    { bihSize = 40
    , bihWidth = fromIntegral width
    , bihHeight = fromIntegral height
    , bihPlanes = 1
    , bihBitCount = 64
    , bihCompression = fourCC 'P' 'A' '6' '4'
    , bihSizeImage = fromIntegral (width * height * 8)
    , bihXPelsPerMeter = 0
    , bihYPelsPerMeter = 0
    , bihClrUsed = 0
    , bihClrImportant = 0
    }

writePremultipliedPa64 :: Ptr () -> ByteString -> IO ()
writePremultipliedPa64 dst raw =
  BS.useAsCString raw $ \src -> do
    let pixelCount = BS.length raw `div` 8
        srcPtr = castPtr src :: Ptr Word16
        go pixelIndex
          | pixelIndex >= pixelCount = pure ()
          | otherwise = do
              let wordIndex = pixelIndex * 4
                  byteIndex = pixelIndex * 8
              r <- peekElemOff srcPtr (wordIndex + 0)
              g <- peekElemOff srcPtr (wordIndex + 1)
              b <- peekElemOff srcPtr (wordIndex + 2)
              a <- peekElemOff srcPtr (wordIndex + 3)
              let alpha = fromIntegral a :: Integer
                  scale channel = fromIntegral ((fromIntegral channel * alpha) `div` 65535) :: Word16
              pokeByteOff dst (byteIndex + 0) (scale r)
              pokeByteOff dst (byteIndex + 2) (scale g)
              pokeByteOff dst (byteIndex + 4) (scale b)
              pokeByteOff dst (byteIndex + 6) a
              go (pixelIndex + 1)
    go 0

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

trim :: String -> String
trim = reverse . dropWhile (`elem` "\r\n\t ") . reverse . dropWhile (`elem` "\r\n\t ")

splitOnce :: Char -> String -> Maybe (String, String)
splitOnce needle text =
  case break (== needle) text of
    (lhs, _ : rhs) -> Just (lhs, rhs)
    _ -> Nothing

nonEmpty :: String -> String -> String
nonEmpty first second =
  case trim first of
    "" ->
      case trim second of
        "" -> "external command failed"
        value -> value
    value -> value
