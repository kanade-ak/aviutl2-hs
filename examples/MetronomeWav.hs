module MetronomeWav
  ( SampleData(..)
  , sampleLength
  , getWavSample
  , clearSampleCache
  ) where

import Control.Exception (SomeException, try)
import Data.Bits ((.|.), shiftL)
import qualified Data.ByteString as BS
import Data.IORef (IORef, atomicModifyIORef', newIORef, readIORef, writeIORef)
import Data.List (find)
import Data.Word (Word16, Word32, Word8)
import GHC.Float (castWord32ToFloat)
import qualified Data.Vector as V
import System.FilePath (normalise)
import System.IO.Unsafe (unsafePerformIO)

data SampleData = SampleData
  { sampleLeft :: V.Vector Float
  , sampleRight :: V.Vector Float
  } deriving (Show)

data WavFormat = WavFormat
  { wavAudioFormat :: Int
  , wavChannels :: Int
  , wavSampleRate :: Int
  , wavBlockAlign :: Int
  , wavBitsPerSample :: Int
  } deriving (Show)

type CacheKey = (FilePath, Int)
type SampleCache = [(CacheKey, Maybe SampleData)]

sampleCacheRef :: IORef SampleCache
sampleCacheRef = unsafePerformIO (newIORef [])
{-# NOINLINE sampleCacheRef #-}

sampleLength :: SampleData -> Int
sampleLength sample =
  min (V.length (sampleLeft sample)) (V.length (sampleRight sample))

clearSampleCache :: IO ()
clearSampleCache = writeIORef sampleCacheRef []

getWavSample :: FilePath -> Int -> IO (Maybe SampleData)
getWavSample path targetRate = do
  let key = (normalise path, targetRate)
  cache <- readIORef sampleCacheRef
  case find ((== key) . fst) cache of
    Just (_, result) -> pure result
    Nothing -> do
      result <- loadWavSampleSafe path targetRate
      atomicModifyIORef' sampleCacheRef (\items -> ((key, result) : items, ()))
      pure result

loadWavSampleSafe :: FilePath -> Int -> IO (Maybe SampleData)
loadWavSampleSafe path targetRate = do
  result <- try (loadWavSample path targetRate) :: IO (Either SomeException SampleData)
  pure (either (const Nothing) Just result)

loadWavSample :: FilePath -> Int -> IO SampleData
loadWavSample path targetRate = do
  bytes <- BS.readFile path
  (fmt, waveData) <- parseWav bytes
  let (leftRaw, rightRaw) = decodeChannels fmt waveData
  pure SampleData
    { sampleLeft = resampleChannel leftRaw (wavSampleRate fmt) targetRate
    , sampleRight = resampleChannel rightRaw (wavSampleRate fmt) targetRate
    }

parseWav :: BS.ByteString -> IO (WavFormat, BS.ByteString)
parseWav bytes
  | BS.length bytes < 12 = ioError (userError "WAV file is too short")
  | sliceEq bytes 0 "RIFF" && sliceEq bytes 8 "WAVE" = go 12 Nothing Nothing
  | otherwise = ioError (userError "Invalid WAV header")
  where
    totalLength = BS.length bytes

    go offset maybeFmt maybeData
      | offset + 8 > totalLength =
          case (maybeFmt, maybeData) of
            (Just fmt, Just chunkData) -> pure (fmt, chunkData)
            _ -> ioError (userError "WAV file is missing fmt or data chunk")
      | otherwise = do
          let chunkId = BS.take 4 (BS.drop offset bytes)
              chunkSize = fromIntegral (readWord32LE bytes (offset + 4)) :: Int
              chunkStart = offset + 8
              chunkEnd = min totalLength (chunkStart + chunkSize)
              chunkData = BS.take (chunkEnd - chunkStart) (BS.drop chunkStart bytes)
              nextOffset = chunkStart + chunkSize + if odd chunkSize then 1 else 0
              nextFmt
                | chunkId == textBytes "fmt " = Just (parseFmt chunkData)
                | otherwise = maybeFmt
              nextData
                | chunkId == textBytes "data" = Just chunkData
                | otherwise = maybeData
          go nextOffset nextFmt nextData

parseFmt :: BS.ByteString -> WavFormat
parseFmt chunk
  | BS.length chunk < 16 = error "fmt chunk is too short"
  | otherwise =
      WavFormat
        { wavAudioFormat = fromIntegral (readWord16LE chunk 0)
        , wavChannels = fromIntegral (readWord16LE chunk 2)
        , wavSampleRate = fromIntegral (readWord32LE chunk 4)
        , wavBlockAlign = fromIntegral (readWord16LE chunk 12)
        , wavBitsPerSample = fromIntegral (readWord16LE chunk 14)
        }

decodeChannels :: WavFormat -> BS.ByteString -> (V.Vector Float, V.Vector Float)
decodeChannels fmt bytes
  | wavChannels fmt <= 0 || wavChannels fmt > 2 = error "Unsupported channel count"
  | wavBlockAlign fmt <= 0 = error "Invalid WAV block align"
  | otherwise =
      let frameCount = BS.length bytes `div` wavBlockAlign fmt
          leftValues = [decodeSample fmt bytes frame 0 | frame <- [0 .. frameCount - 1]]
          rightValues =
            if wavChannels fmt == 1
              then leftValues
              else [decodeSample fmt bytes frame 1 | frame <- [0 .. frameCount - 1]]
      in (V.fromList leftValues, V.fromList rightValues)

decodeSample :: WavFormat -> BS.ByteString -> Int -> Int -> Float
decodeSample fmt bytes frameIndex channelIndex =
  case (wavAudioFormat fmt, wavBitsPerSample fmt) of
    (1, 8) ->
      let value = fromIntegral (readWord8 bytes sampleOffset) :: Float
      in clampSample ((value - 128.0) / 127.0)
    (1, 16) ->
      clampSample (fromIntegral (readInt16LE bytes sampleOffset) / 32767.0)
    (1, 24) ->
      clampSample (fromIntegral (readInt24LE bytes sampleOffset) / 8388607.0)
    (1, 32) ->
      clampSample (fromIntegral (readInt32LE bytes sampleOffset) / 2147483647.0)
    (3, 32) ->
      clampSample (castWord32ToFloat (readWord32LE bytes sampleOffset))
    _ -> error "Unsupported WAV format"
  where
    bytesPerSample = wavBitsPerSample fmt `div` 8
    frameOffset = frameIndex * wavBlockAlign fmt
    sampleOffset = frameOffset + channelIndex * bytesPerSample

resampleChannel :: V.Vector Float -> Int -> Int -> V.Vector Float
resampleChannel samples inputRate outputRate
  | V.null samples = V.empty
  | inputRate <= 0 || outputRate <= 0 = samples
  | inputRate == outputRate = samples
  | otherwise =
      let inputLength = V.length samples
          outputLength =
            fromIntegral
              (((fromIntegral inputLength :: Integer) * fromIntegral outputRate
                + fromIntegral inputRate - 1) `div` fromIntegral inputRate)
      in V.generate outputLength (interpolateSample samples outputLength)

interpolateSample :: V.Vector Float -> Int -> Int -> Float
interpolateSample input outputLength index
  | V.length input == outputLength = input V.! index
  | otherwise =
      let inputLength = fromIntegral (V.length input) :: Double
          outputLength' = fromIntegral outputLength :: Double
          position = fromIntegral index * inputLength / outputLength'
          baseIndex = floor position
          fraction = realToFrac (position - fromIntegral baseIndex)
      in if baseIndex + 1 < V.length input
           then
             let a = input V.! baseIndex
                 b = input V.! (baseIndex + 1)
             in a * (1.0 - fraction) + b * fraction
           else if baseIndex < V.length input
             then input V.! baseIndex
             else 0.0

clampSample :: Float -> Float
clampSample value
  | value < (-1.0) = -1.0
  | value > 1.0 = 1.0
  | otherwise = value

sliceEq :: BS.ByteString -> Int -> String -> Bool
sliceEq bytes offset text =
  BS.take (length text) (BS.drop offset bytes) == textBytes text

textBytes :: String -> BS.ByteString
textBytes text = BS.pack (map (fromIntegral . fromEnum) text)

readWord8 :: BS.ByteString -> Int -> Word8
readWord8 bytes offset = BS.index bytes offset

readWord16LE :: BS.ByteString -> Int -> Word16
readWord16LE bytes offset =
  fromIntegral b0 .|. shiftL (fromIntegral b1) 8
  where
    b0 = readWord8 bytes offset
    b1 = readWord8 bytes (offset + 1)

readWord32LE :: BS.ByteString -> Int -> Word32
readWord32LE bytes offset =
  fromIntegral b0
    .|. shiftL (fromIntegral b1) 8
    .|. shiftL (fromIntegral b2) 16
    .|. shiftL (fromIntegral b3) 24
  where
    b0 = readWord8 bytes offset
    b1 = readWord8 bytes (offset + 1)
    b2 = readWord8 bytes (offset + 2)
    b3 = readWord8 bytes (offset + 3)

readInt16LE :: BS.ByteString -> Int -> Int
readInt16LE bytes offset =
  let value = fromIntegral (readWord16LE bytes offset) :: Int
  in if value >= 0x8000 then value - 0x10000 else value

readInt24LE :: BS.ByteString -> Int -> Int
readInt24LE bytes offset =
  let b0 = fromIntegral (readWord8 bytes offset) :: Int
      b1 = fromIntegral (readWord8 bytes (offset + 1)) :: Int
      b2 = fromIntegral (readWord8 bytes (offset + 2)) :: Int
      value = b0 .|. shiftL b1 8 .|. shiftL b2 16
  in if value >= 0x800000 then value - 0x1000000 else value

readInt32LE :: BS.ByteString -> Int -> Int
readInt32LE bytes offset =
  let value = fromIntegral (readWord32LE bytes offset) :: Integer
  in fromIntegral (if value >= 0x80000000 then value - 0x100000000 else value)
