{-# LANGUAGE ForeignFunctionInterface #-}
{-# LANGUAGE ScopedTypeVariables #-}

module MetronomePlugin where

import AviUtl2.Config (CONFIG_HANDLE)
import AviUtl2.Edit
  ( EDIT_HANDLE
  , EDIT_SECTION
  , callEditSection
  , getEditInfo
  , getEditInfoFromHandle
  , setGridBpm
  )
import AviUtl2.Filter
  ( FILTER_ITEM_FILE(..)
  , FILTER_ITEM_TRACK(..)
  , FILTER_PLUGIN_TABLE(..)
  , FILTER_PROC_AUDIO(..)
  , filterFlagAudio
  , filterFlagInput
  , setSampleData
  )
import AviUtl2.Host
  ( HOST_APP_TABLE
  , createEditHandle
  , registerClearCacheHandler
  , registerFilterPlugin
  , registerWindowClient
  )
import AviUtl2.Logger (LOG_HANDLE, logInfo, logWarn)
import AviUtl2.Plugin (BOOL_, COMMON_PLUGIN_TABLE(..), DWORD, EDIT_INFO(..), LPCWSTR, HWND, boolFromBOOL)
import AviUtl2.Types (SCENE_INFO(..), OBJECT_INFO(..))
import Data.Bits ((.&.), (.|.))
import Data.Char (isSpace)
import Data.Int (Int64)
import Data.IORef (IORef, atomicModifyIORef', newIORef, readIORef, writeIORef)
import Data.List (dropWhileEnd)
import Foreign.C.String (peekCWString, withCWString)
import Foreign.C.Types (CBool(..), CFloat(..), CInt(..), CUInt(..), CULong(..), CUShort(..))
import Foreign.Marshal.Alloc (alloca, malloc)
import Foreign.Marshal.Array (allocaArray, newArray)
import Foreign.Ptr
  ( FunPtr
  , IntPtr(..)
  , Ptr
  , WordPtr(..)
  , castPtr
  , freeHaskellFunPtr
  , intPtrToPtr
  , nullFunPtr
  , nullPtr
  , wordPtrToPtr
  )
import Foreign.Storable (Storable(..))
import Numeric (showFFloat)
import PluginSupport (newWideString, requiredVersion)
import GHC.Clock (getMonotonicTimeNSec)
import System.IO.Unsafe (unsafePerformIO)

import qualified Data.Vector as V

import MetronomeWav (SampleData(..), clearSampleCache, getWavSample, sampleLength)

type WPARAM = WordPtr
type LPARAM = IntPtr
type LRESULT = IntPtr
type HBRUSH = Ptr ()
type HCURSOR = Ptr ()
type HICON = Ptr ()
type HMENU = Ptr ()
type UINT = CUInt
type WINDOW_STYLE = DWORD
type WINDOW_EX_STYLE = DWORD
type ATOM = CUShort

data WNDCLASSEXW = WNDCLASSEXW
  { wcxCbSize :: CUInt
  , wcxStyle :: CUInt
  , wcxWndProc :: FunPtr (HWND -> UINT -> WPARAM -> LPARAM -> IO LRESULT)
  , wcxClsExtra :: CInt
  , wcxWndExtra :: CInt
  , wcxInstance :: Ptr ()
  , wcxIcon :: HICON
  , wcxCursor :: HCURSOR
  , wcxBackground :: HBRUSH
  , wcxMenuName :: LPCWSTR
  , wcxClassName :: LPCWSTR
  , wcxIconSmall :: HICON
  }

instance Storable WNDCLASSEXW where
  sizeOf _ = 80
  alignment _ = 8
  peek ptr = WNDCLASSEXW
    <$> peekByteOff ptr 0
    <*> peekByteOff ptr 4
    <*> peekByteOff ptr 8
    <*> peekByteOff ptr 16
    <*> peekByteOff ptr 20
    <*> peekByteOff ptr 24
    <*> peekByteOff ptr 32
    <*> peekByteOff ptr 40
    <*> peekByteOff ptr 48
    <*> peekByteOff ptr 56
    <*> peekByteOff ptr 64
    <*> peekByteOff ptr 72
  poke ptr value = do
    pokeByteOff ptr 0 (wcxCbSize value)
    pokeByteOff ptr 4 (wcxStyle value)
    pokeByteOff ptr 8 (wcxWndProc value)
    pokeByteOff ptr 16 (wcxClsExtra value)
    pokeByteOff ptr 20 (wcxWndExtra value)
    pokeByteOff ptr 24 (wcxInstance value)
    pokeByteOff ptr 32 (wcxIcon value)
    pokeByteOff ptr 40 (wcxCursor value)
    pokeByteOff ptr 48 (wcxBackground value)
    pokeByteOff ptr 56 (wcxMenuName value)
    pokeByteOff ptr 64 (wcxClassName value)
    pokeByteOff ptr 72 (wcxIconSmall value)

data TapState = TapState
  { tsLastTap :: Maybe Double
  , tsIntervals :: [Double]
  , tsBpm :: Maybe Double
  }

data ApplyMode = ApplyFromOrigin | ApplyFromCurrent deriving (Eq)

maxTapIntervalSeconds :: Double
maxTapIntervalSeconds = 3.0

maxTapIntervals :: Int
maxTapIntervals = 8

pluginWindowClassName, pluginWindowTitle, commonPluginName, commonPluginInfo :: LPCWSTR
pluginWindowClassName = unsafePerformIO (newWideString "AviUtl2HsMetronomeWindow")
pluginWindowTitle = unsafePerformIO (newWideString "Rusty Metronome Plugin (hs)")
commonPluginName = unsafePerformIO (newWideString "Rusty Metronome Plugin (hs)")
commonPluginInfo = unsafePerformIO (newWideString "Metronome for AviUtl2, written in Haskell / provides a BPM tap window and metronome filter")
{-# NOINLINE pluginWindowClassName #-}
{-# NOINLINE pluginWindowTitle #-}
{-# NOINLINE commonPluginName #-}
{-# NOINLINE commonPluginInfo #-}

filterPluginName, filterPluginInfo :: LPCWSTR
filterPluginName = unsafePerformIO (newWideString "Rusty Metronome Filter (hs)")
filterPluginInfo = unsafePerformIO (newWideString "Metronome effect for AviUtl2, written in Haskell")
{-# NOINLINE filterPluginName #-}
{-# NOINLINE filterPluginInfo #-}

itemTypeTrack, itemTypeFile :: LPCWSTR
itemTypeTrack = unsafePerformIO (newWideString "track")
itemTypeFile = unsafePerformIO (newWideString "file")
{-# NOINLINE itemTypeTrack #-}
{-# NOINLINE itemTypeFile #-}

itemNameVolume, itemNameFrequencyA, itemNameFrequencyB, itemNameClickMs, itemNameSampleA, itemNameSampleB, itemFileFilterWav :: LPCWSTR
itemNameVolume = unsafePerformIO (newWideString "音量")
itemNameFrequencyA = unsafePerformIO (newWideString "周波数A(Hz)")
itemNameFrequencyB = unsafePerformIO (newWideString "周波数B(Hz)")
itemNameClickMs = unsafePerformIO (newWideString "長さ(ms)")
itemNameSampleA = unsafePerformIO (newWideString "音源A")
itemNameSampleB = unsafePerformIO (newWideString "音源B")
itemFileFilterWav = unsafePerformIO (newWideString "WAVファイル (*.wav)\0*.wav\0")
{-# NOINLINE itemNameVolume #-}
{-# NOINLINE itemNameFrequencyA #-}
{-# NOINLINE itemNameFrequencyB #-}
{-# NOINLINE itemNameClickMs #-}
{-# NOINLINE itemNameSampleA #-}
{-# NOINLINE itemNameSampleB #-}
{-# NOINLINE itemFileFilterWav #-}

emptyWideString :: LPCWSTR
emptyWideString = unsafePerformIO (newWideString "")
{-# NOINLINE emptyWideString #-}

buttonTapLabel, buttonResetLabel, buttonGetBpmLabel, buttonApplyOriginLabel, buttonApplyCurrentLabel, labelBpmText :: LPCWSTR
buttonTapLabel = unsafePerformIO (newWideString "Tap")
buttonResetLabel = unsafePerformIO (newWideString "Reset")
buttonGetBpmLabel = unsafePerformIO (newWideString "BPM取得")
buttonApplyOriginLabel = unsafePerformIO (newWideString "0:00を基準に反映")
buttonApplyCurrentLabel = unsafePerformIO (newWideString "現在位置を基準に反映")
labelBpmText = unsafePerformIO (newWideString "BPM")
{-# NOINLINE buttonTapLabel #-}
{-# NOINLINE buttonResetLabel #-}
{-# NOINLINE buttonGetBpmLabel #-}
{-# NOINLINE buttonApplyOriginLabel #-}
{-# NOINLINE buttonApplyCurrentLabel #-}
{-# NOINLINE labelBpmText #-}

volumeItemPtr, frequencyAItemPtr, frequencyBItemPtr, clickMsItemPtr :: Ptr FILTER_ITEM_TRACK
volumeItemPtr = unsafePerformIO $ do
  ptr <- malloc
  poke ptr (FILTER_ITEM_TRACK itemTypeTrack itemNameVolume 0.8 0.0 1.0 0.01)
  pure ptr
{-# NOINLINE volumeItemPtr #-}

frequencyAItemPtr = unsafePerformIO $ do
  ptr <- malloc
  poke ptr (FILTER_ITEM_TRACK itemTypeTrack itemNameFrequencyA 1000.0 200.0 2000.0 1.0)
  pure ptr
{-# NOINLINE frequencyAItemPtr #-}

frequencyBItemPtr = unsafePerformIO $ do
  ptr <- malloc
  poke ptr (FILTER_ITEM_TRACK itemTypeTrack itemNameFrequencyB 800.0 200.0 2000.0 1.0)
  pure ptr
{-# NOINLINE frequencyBItemPtr #-}

clickMsItemPtr = unsafePerformIO $ do
  ptr <- malloc
  poke ptr (FILTER_ITEM_TRACK itemTypeTrack itemNameClickMs 30.0 5.0 200.0 1.0)
  pure ptr
{-# NOINLINE clickMsItemPtr #-}

sampleAItemPtr, sampleBItemPtr :: Ptr FILTER_ITEM_FILE
sampleAItemPtr = unsafePerformIO $ do
  ptr <- malloc
  poke ptr (FILTER_ITEM_FILE itemTypeFile itemNameSampleA emptyWideString itemFileFilterWav)
  pure ptr
{-# NOINLINE sampleAItemPtr #-}

sampleBItemPtr = unsafePerformIO $ do
  ptr <- malloc
  poke ptr (FILTER_ITEM_FILE itemTypeFile itemNameSampleB emptyWideString itemFileFilterWav)
  pure ptr
{-# NOINLINE sampleBItemPtr #-}

filterItemsPtr :: Ptr (Ptr ())
filterItemsPtr = unsafePerformIO $ newArray
  [ castPtr volumeItemPtr
  , castPtr frequencyAItemPtr
  , castPtr frequencyBItemPtr
  , castPtr clickMsItemPtr
  , castPtr sampleAItemPtr
  , castPtr sampleBItemPtr
  , nullPtr
  ]
{-# NOINLINE filterItemsPtr #-}

commonPluginTablePtr :: Ptr COMMON_PLUGIN_TABLE
commonPluginTablePtr = unsafePerformIO $ do
  ptr <- malloc
  poke ptr (COMMON_PLUGIN_TABLE commonPluginName commonPluginInfo)
  pure ptr
{-# NOINLINE commonPluginTablePtr #-}

tapStateRef :: IORef TapState
tapStateRef = unsafePerformIO (newIORef (TapState Nothing [] Nothing))
{-# NOINLINE tapStateRef #-}

bpmCacheRef :: IORef (Maybe (Double, Int, Double))
bpmCacheRef = unsafePerformIO (newIORef Nothing)
{-# NOINLINE bpmCacheRef #-}

editHandleRef :: IORef EDIT_HANDLE
editHandleRef = unsafePerformIO (newIORef nullPtr)
{-# NOINLINE editHandleRef #-}

loggerHandleRef :: IORef (Ptr LOG_HANDLE)
loggerHandleRef = unsafePerformIO (newIORef nullPtr)
{-# NOINLINE loggerHandleRef #-}

configHandleRef :: IORef (Ptr CONFIG_HANDLE)
configHandleRef = unsafePerformIO (newIORef nullPtr)
{-# NOINLINE configHandleRef #-}

bpmEditRef, hostWindowRef :: IORef HWND
bpmEditRef = unsafePerformIO (newIORef nullPtr)
hostWindowRef = unsafePerformIO (newIORef nullPtr)
{-# NOINLINE bpmEditRef #-}
{-# NOINLINE hostWindowRef #-}

foreign import ccall "wrapper"
  mkWindowProc :: (HWND -> UINT -> WPARAM -> LPARAM -> IO LRESULT) -> IO (FunPtr (HWND -> UINT -> WPARAM -> LPARAM -> IO LRESULT))

foreign import ccall "wrapper"
  mkAudioProc :: (Ptr FILTER_PROC_AUDIO -> IO BOOL_) -> IO (FunPtr (Ptr FILTER_PROC_AUDIO -> IO BOOL_))

foreign import ccall "wrapper"
  mkEditSectionProc :: (Ptr EDIT_SECTION -> IO ()) -> IO (FunPtr (Ptr EDIT_SECTION -> IO ()))

windowProcPtr :: FunPtr (HWND -> UINT -> WPARAM -> LPARAM -> IO LRESULT)
windowProcPtr = unsafePerformIO (mkWindowProc metronomeWindowProc)
{-# NOINLINE windowProcPtr #-}

audioProcPtr :: FunPtr (Ptr FILTER_PROC_AUDIO -> IO BOOL_)
audioProcPtr = unsafePerformIO (mkAudioProc processMetronomeAudio)
{-# NOINLINE audioProcPtr #-}

clearCacheCallbackPtr :: FunPtr (Ptr EDIT_SECTION -> IO ())
clearCacheCallbackPtr = unsafePerformIO (mkEditSectionProc (\_ -> clearSampleCache))
{-# NOINLINE clearCacheCallbackPtr #-}

filterPluginTablePtr :: Ptr FILTER_PLUGIN_TABLE
filterPluginTablePtr = unsafePerformIO $ do
  ptr <- malloc
  poke ptr FILTER_PLUGIN_TABLE
    { fptFlag = filterFlagAudio + filterFlagInput
    , fptName = filterPluginName
    , fptLabel = nullPtr
    , fptInformation = filterPluginInfo
    , fptItems = filterItemsPtr
    , fptFuncProcVideo = nullFunPtr
    , fptFuncProcAudio = audioProcPtr
    }
  pure ptr
{-# NOINLINE filterPluginTablePtr #-}

foreign import ccall unsafe "windows.h RegisterClassExW"
  cRegisterClassExW :: Ptr WNDCLASSEXW -> IO ATOM

foreign import ccall safe "windows.h CreateWindowExW"
  cCreateWindowExW
    :: WINDOW_EX_STYLE
    -> LPCWSTR
    -> LPCWSTR
    -> WINDOW_STYLE
    -> CInt
    -> CInt
    -> CInt
    -> CInt
    -> HWND
    -> HMENU
    -> Ptr ()
    -> Ptr ()
    -> IO HWND

foreign import ccall safe "windows.h DefWindowProcW"
  cDefWindowProcW :: HWND -> UINT -> WPARAM -> LPARAM -> IO LRESULT

foreign import ccall unsafe "windows.h GetModuleHandleW"
  cGetModuleHandleW :: LPCWSTR -> IO (Ptr ())

foreign import ccall unsafe "windows.h LoadCursorW"
  cLoadCursorW :: Ptr () -> LPCWSTR -> IO HCURSOR

foreign import ccall safe "windows.h SetWindowTextW"
  cSetWindowTextW :: HWND -> LPCWSTR -> IO CBool

foreign import ccall safe "windows.h GetWindowTextLengthW"
  cGetWindowTextLengthW :: HWND -> IO CInt

foreign import ccall safe "windows.h GetWindowTextW"
  cGetWindowTextW :: HWND -> LPCWSTR -> CInt -> IO CInt

foreign export ccall "RequiredVersion"
  requiredVersionExport :: IO DWORD

foreign export ccall "InitializePlugin"
  initializePlugin :: DWORD -> IO BOOL_

foreign export ccall "UninitializePlugin"
  uninitializePlugin :: IO ()

foreign export ccall "InitializeLogger"
  initializeLogger :: Ptr LOG_HANDLE -> IO ()

foreign export ccall "InitializeConfig"
  initializeConfig :: Ptr CONFIG_HANDLE -> IO ()

foreign export ccall "GetCommonPluginTable"
  getCommonPluginTable :: IO (Ptr COMMON_PLUGIN_TABLE)

foreign export ccall "RegisterPlugin"
  registerPlugin :: Ptr HOST_APP_TABLE -> IO ()

requiredVersionExport :: IO DWORD
requiredVersionExport = pure requiredVersion

initializePlugin :: DWORD -> IO BOOL_
initializePlugin _ = do
  writeIORef bpmCacheRef Nothing
  pure 1

uninitializePlugin :: IO ()
uninitializePlugin = do
  clearSampleCache
  writeIORef tapStateRef (TapState Nothing [] Nothing)
  writeIORef bpmCacheRef Nothing

initializeLogger :: Ptr LOG_HANDLE -> IO ()
initializeLogger handle = writeIORef loggerHandleRef handle

initializeConfig :: Ptr CONFIG_HANDLE -> IO ()
initializeConfig handle = writeIORef configHandleRef handle

getCommonPluginTable :: IO (Ptr COMMON_PLUGIN_TABLE)
getCommonPluginTable = pure commonPluginTablePtr

registerPlugin :: Ptr HOST_APP_TABLE -> IO ()
registerPlugin host = do
  registerFilterPlugin host filterPluginTablePtr
  registerClearCacheHandler host clearCacheCallbackPtr
  hwnd <- createPluginWindow
  writeIORef hostWindowRef hwnd
  registerWindowClient host pluginWindowTitle hwnd
  editHandle <- createEditHandle host
  writeIORef editHandleRef editHandle
  updateBpmEditFromState
  logInfoText "Registered Haskell metronome plugin"

createPluginWindow :: IO HWND
createPluginWindow = do
  moduleHandle <- cGetModuleHandleW nullPtr
  ensureWindowClassRegistered moduleHandle
  hwnd <- cCreateWindowExW
    0
    pluginWindowClassName
    pluginWindowTitle
    wsPopup
    0
    0
    360
    150
    nullPtr
    nullPtr
    moduleHandle
    nullPtr
  if hwnd == nullPtr
    then ioError (userError "failed to create metronome plugin window")
    else do
      _ <- createChildControl hwnd staticClassName labelBpmText (wsChild .|. wsVisible) 12 14 40 24 0
      editControl <- createChildControl hwnd editClassName emptyWideString editStyle 56 10 110 26 controlIdBpmEdit
      _ <- createChildControl hwnd buttonClassName buttonTapLabel buttonStyle 180 10 72 26 controlIdTap
      _ <- createChildControl hwnd buttonClassName buttonResetLabel buttonStyle 264 10 72 26 controlIdReset
      _ <- createChildControl hwnd buttonClassName buttonGetBpmLabel buttonStyle 12 48 100 26 controlIdGetBpm
      _ <- createChildControl hwnd buttonClassName buttonApplyOriginLabel buttonStyle 12 86 156 26 controlIdApplyOrigin
      _ <- createChildControl hwnd buttonClassName buttonApplyCurrentLabel buttonStyle 180 86 156 26 controlIdApplyCurrent
      writeIORef bpmEditRef editControl
      pure hwnd

ensureWindowClassRegistered :: Ptr () -> IO ()
ensureWindowClassRegistered moduleHandle =
  alloca $ \classPtr -> do
    cursor <- cLoadCursorW nullPtr (intPtrToPtr 32512)
    poke classPtr WNDCLASSEXW
      { wcxCbSize = fromIntegral (sizeOf (undefined :: WNDCLASSEXW))
      , wcxStyle = 0
      , wcxWndProc = windowProcPtr
      , wcxClsExtra = 0
      , wcxWndExtra = 0
      , wcxInstance = moduleHandle
      , wcxIcon = nullPtr
      , wcxCursor = cursor
      , wcxBackground = wordPtrToPtr 6
      , wcxMenuName = nullPtr
      , wcxClassName = pluginWindowClassName
      , wcxIconSmall = nullPtr
      }
    _ <- cRegisterClassExW classPtr
    pure ()

createChildControl :: HWND -> LPCWSTR -> LPCWSTR -> WINDOW_STYLE -> CInt -> CInt -> CInt -> CInt -> IntPtr -> IO HWND
createChildControl parent className text style x y w h controlId = do
  moduleHandle <- cGetModuleHandleW nullPtr
  cCreateWindowExW
    0
    className
    text
    style
    x
    y
    w
    h
    parent
    (intPtrToPtr controlId)
    moduleHandle
    nullPtr

metronomeWindowProc :: HWND -> UINT -> WPARAM -> LPARAM -> IO LRESULT
metronomeWindowProc hwnd msg wparam lparam
  | msg == wmCommand = do
      handleCommand (lowWord wparam)
      pure 0
  | otherwise = cDefWindowProcW hwnd msg wparam lparam

handleCommand :: Int -> IO ()
handleCommand commandId
  | commandId == fromIntegral controlIdTap = do
      registerTap
      updateBpmEditFromState
  | commandId == fromIntegral controlIdReset = do
      resetTapState
      updateBpmEditFromState
  | commandId == fromIntegral controlIdGetBpm = do
      loadBpmFromProject
      updateBpmEditFromState
  | commandId == fromIntegral controlIdApplyOrigin = applyBpm ApplyFromOrigin
  | commandId == fromIntegral controlIdApplyCurrent = applyBpm ApplyFromCurrent
  | otherwise = pure ()

registerTap :: IO ()
registerTap = do
  now <- getMonotonicSeconds
  atomicModifyIORef' tapStateRef $ \state ->
    let tooOld = maybe True (\previous -> now - previous > maxTapIntervalSeconds) (tsLastTap state)
        baseState =
          if tooOld
            then TapState Nothing [] Nothing
            else state
        nextIntervals =
          case tsLastTap baseState of
            Just previous -> keepLatest maxTapIntervals (tsIntervals baseState ++ [now - previous])
            Nothing -> []
        nextBpm =
          if null nextIntervals
            then tsBpm baseState
            else Just (60.0 / (sum nextIntervals / fromIntegral (length nextIntervals)))
        nextState =
          baseState
            { tsLastTap = Just now
            , tsIntervals = nextIntervals
            , tsBpm = nextBpm
            }
    in (nextState, ())
resetTapState :: IO ()
resetTapState = writeIORef tapStateRef (TapState Nothing [] Nothing)

loadBpmFromProject :: IO ()
loadBpmFromProject = do
  editHandle <- readIORef editHandleRef
  if editHandle == nullPtr
    then pure ()
    else do
      maybeInfo <- readCurrentEditInfoViaSection editHandle
      case maybeInfo of
        Nothing -> logWarnText "Failed to get BPM from current edit section"
        Just info -> do
          let bpm = realToFrac (eiGridBpmTempo info) :: Double
              beat = fromIntegral (eiGridBpmBeat info)
              offset = realToFrac (eiGridBpmOffset info)
          atomicModifyIORef' tapStateRef (\state -> (state { tsBpm = if bpm > 0 then Just bpm else Nothing }, ()))
          writeIORef bpmCacheRef (if bpm > 0 && beat > 0 then Just (bpm, beat, offset) else Nothing)

applyBpm :: ApplyMode -> IO ()
applyBpm mode = do
  maybeBpm <- readBpmFromEdit
  case maybeBpm of
    Nothing -> logWarnText "BPM value is empty or invalid"
    Just bpm -> do
      editHandle <- readIORef editHandleRef
      if editHandle == nullPtr
        then pure ()
        else do
          callback <- mkEditSectionProc $ \editPtr -> do
            infoBefore <- getEditInfo editPtr
            let offsetSeconds =
                  case mode of
                    ApplyFromOrigin -> 0.0
                    ApplyFromCurrent ->
                      let rate = fromIntegral (eiRate infoBefore) :: Double
                          scale = fromIntegral (eiScale infoBefore) :: Double
                      in if rate <= 0 || scale <= 0
                           then 0.0
                           else fromIntegral (eiFrame infoBefore) / (rate / scale)
            setGridBpm editPtr (realToFrac bpm) 4 (realToFrac offsetSeconds)
          result <- callEditSection editHandle callback
          freeHaskellFunPtr callback
          if boolFromBOOL result
            then do
              verifiedInfo <- readCurrentEditInfoViaSection editHandle
              case verifiedInfo of
                Just info ->
                  do
                    let verifiedBpm = realToFrac (eiGridBpmTempo info)
                        verifiedBeat = fromIntegral (eiGridBpmBeat info)
                        verifiedOffset = realToFrac (eiGridBpmOffset info)
                    atomicModifyIORef' tapStateRef (\state -> (state { tsBpm = Just verifiedBpm }, ()))
                    writeIORef bpmCacheRef (if verifiedBpm > 0 && verifiedBeat > 0 then Just (verifiedBpm, verifiedBeat, verifiedOffset) else Nothing)
                Nothing ->
                  do
                    atomicModifyIORef' tapStateRef (\state -> (state { tsBpm = Just bpm }, ()))
                    writeIORef bpmCacheRef (Just (bpm, 4, if mode == ApplyFromOrigin then 0.0 else 0.0))
              updateBpmEditFromState
            else logWarnText "Failed to apply BPM to host"

readCurrentEditInfo :: EDIT_HANDLE -> IO EDIT_INFO
readCurrentEditInfo editHandle =
  alloca $ \infoPtr -> do
    getEditInfoFromHandle editHandle infoPtr (fromIntegral (sizeOf (undefined :: EDIT_INFO)))
    peek infoPtr

readCurrentEditInfoViaSection :: EDIT_HANDLE -> IO (Maybe EDIT_INFO)
readCurrentEditInfoViaSection editHandle = do
  infoRef <- newIORef Nothing
  callback <- mkEditSectionProc $ \editPtr -> do
    info <- getEditInfo editPtr
    writeIORef infoRef (Just info)
  result <- callEditSection editHandle callback
  freeHaskellFunPtr callback
  if boolFromBOOL result
    then readIORef infoRef
    else pure Nothing

refreshHostBpmCache :: IO ()
refreshHostBpmCache = do
  editHandle <- readIORef editHandleRef
  if editHandle == nullPtr
    then writeIORef bpmCacheRef Nothing
    else do
      maybeInfo <- readCurrentEditInfoViaSection editHandle
      case maybeInfo of
        Nothing -> pure ()
        Just info -> do
          let bpm = realToFrac (eiGridBpmTempo info)
              beat = fromIntegral (eiGridBpmBeat info)
              offset = realToFrac (eiGridBpmOffset info)
          writeIORef bpmCacheRef (if bpm > 0 && beat > 0 then Just (bpm, beat, offset) else Nothing)

readBpmFromEdit :: IO (Maybe Double)
readBpmFromEdit = do
  editControl <- readIORef bpmEditRef
  if editControl == nullPtr
    then tsBpm <$> readIORef tapStateRef
    else do
      rawText <- getWindowTextSafe editControl
      let trimmed = trim rawText
      if null trimmed
        then tsBpm <$> readIORef tapStateRef
        else case reads trimmed of
          [(value, "")] | value > 0 -> pure (Just value)
          _ -> pure Nothing

updateBpmEditFromState :: IO ()
updateBpmEditFromState = do
  editControl <- readIORef bpmEditRef
  state <- readIORef tapStateRef
  if editControl == nullPtr
    then pure ()
    else do
      let text = maybe "" (\value -> showFFloat (Just 2) value "") (tsBpm state)
      withCWString text (cSetWindowTextW editControl)
      pure ()

getWindowTextSafe :: HWND -> IO String
getWindowTextSafe hwnd = do
  length_ <- cGetWindowTextLengthW hwnd
  allocaArray (fromIntegral length_ + 1) $ \buffer -> do
    _ <- cGetWindowTextW hwnd buffer (length_ + 1)
    peekCWString buffer

processMetronomeAudio :: Ptr FILTER_PROC_AUDIO -> IO BOOL_
processMetronomeAudio audioPtr = do
  audio <- peek audioPtr
  bpmInfo <- getCurrentBpmInfo
  case bpmInfo of
    Nothing -> pure 1
    Just (bpm, beatCount, bpmOffset) ->
      if bpm <= 0 || beatCount <= 0
        then pure 1
        else do
          volume <- realToFrac . fitValue <$> peek volumeItemPtr
          frequencyA <- realToFrac . fitValue <$> peek frequencyAItemPtr
          frequencyB <- realToFrac . fitValue <$> peek frequencyBItemPtr
          clickMs <- realToFrac . fitValue <$> peek clickMsItemPtr
          let scenePtr = fpaScene audio
              objectPtr = fpaObject audio
          if scenePtr == nullPtr || objectPtr == nullPtr
            then pure 1
            else do
              sampleRate <- peekSceneSampleRate scenePtr
              sampleNum <- peekObjectSampleNum objectPtr
              currentSampleStart <- peekObjectSampleIndex objectPtr
              if sampleRate <= 0 || sampleNum <= 0 || sampleNum > 1048576
                then pure 1
                else do
                  let clickLengthSamples = max 1 (round ((clickMs / 1000.0) * fromIntegral sampleRate) :: Int)
                  allocaArray sampleNum $ \leftPtr ->
                    allocaArray sampleNum $ \rightPtr -> do
                      fillSamples leftPtr rightPtr sampleNum currentSampleStart sampleRate bpm bpmOffset beatCount clickLengthSamples volume frequencyA frequencyB Nothing Nothing
                      setSampleData audioPtr leftPtr 0
                      setSampleData audioPtr rightPtr 1
                  pure 1

fillSamples
  :: Ptr CFloat
  -> Ptr CFloat
  -> Int
  -> Int
  -> Int
  -> Double
  -> Double
  -> Int
  -> Int
  -> Float
  -> Float
  -> Float
  -> Maybe SampleData
  -> Maybe SampleData
  -> IO ()
fillSamples leftPtr rightPtr sampleNum currentSampleStart sampleRate bpm bpmOffset beatCount clickLengthSamples volume frequencyA frequencyB sampleA sampleB =
  mapM_ writeSample [0 .. sampleNum - 1]
  where
    writeSample index = do
      let currentSample = currentSampleStart + index
          (lastBeatSample, beatNumber) = getLastBeatSampleIndex sampleRate bpm bpmOffset currentSample
          usePrimary = beatNumber `mod` beatCount == 0
          sampleOffset = max 0 (currentSample - lastBeatSample)
          selectedSample = if usePrimary then sampleA else sampleB
          (leftValue, rightValue) =
            case selectedSample of
              Just sample ->
                let offsetIndex = fromIntegral sampleOffset
                in if offsetIndex < sampleLength sample
                     then
                       ( clampAudioSample (sampleLeft sample V.! offsetIndex * volume)
                       , clampAudioSample (sampleRight sample V.! offsetIndex * volume)
                       )
                     else (0.0, 0.0)
              Nothing ->
                if sampleOffset < fromIntegral clickLengthSamples
                  then
                    let timeSeconds = fromIntegral sampleOffset / fromIntegral sampleRate
                        frequency = if usePrimary then frequencyA else frequencyB
                        amplitude = (1.0 - fromIntegral sampleOffset / fromIntegral clickLengthSamples) * volume
                        tone = sin (2.0 * pi * frequency * timeSeconds) * amplitude * 0.5
                        sampleValue = clampAudioSample tone
                    in (sampleValue, sampleValue)
                  else (0.0, 0.0)
      pokeElemOff leftPtr index (realToFrac leftValue)
      pokeElemOff rightPtr index (realToFrac rightValue)

getCurrentBpmInfo :: IO (Maybe (Double, Int, Double))
getCurrentBpmInfo = readIORef bpmCacheRef

peekSceneSampleRate :: Ptr SCENE_INFO -> IO Int
peekSceneSampleRate ptr = fromIntegral <$> (peekByteOff ptr 16 :: IO CInt)

peekObjectSampleIndex :: Ptr OBJECT_INFO -> IO Int
peekObjectSampleIndex ptr = fromIntegral <$> (peekByteOff ptr 40 :: IO Int64)

peekObjectSampleNum :: Ptr OBJECT_INFO -> IO Int
peekObjectSampleNum ptr = fromIntegral <$> (peekByteOff ptr 56 :: IO CInt)

getLastBeatSampleIndex :: Int -> Double -> Double -> Int -> (Int, Int)
getLastBeatSampleIndex sampleRate bpm bpmOffset currentSampleIndex =
  let samplesPerBeat = (60.0 / bpm) * fromIntegral sampleRate
      offsetSamples = bpmOffset * fromIntegral sampleRate
      adjustedIndex = fromIntegral currentSampleIndex - offsetSamples
      beatIndex = floor (adjustedIndex / samplesPerBeat)
      lastBeatSample = round (fromIntegral beatIndex * samplesPerBeat + offsetSamples)
  in (lastBeatSample, beatIndex)

clampAudioSample :: Float -> Float
clampAudioSample value
  | value < (-1.0) = -1.0
  | value > 1.0 = 1.0
  | otherwise = value

logInfoText :: String -> IO ()
logInfoText message = do
  logger <- readIORef loggerHandleRef
  if logger == nullPtr
    then pure ()
    else withCWString message (logInfo logger)

logWarnText :: String -> IO ()
logWarnText message = do
  logger <- readIORef loggerHandleRef
  if logger == nullPtr
    then pure ()
    else withCWString message (logWarn logger)

getMonotonicSeconds :: IO Double
getMonotonicSeconds = (/ 1000000000.0) . fromIntegral <$> getMonotonicTimeNSec

keepLatest :: Int -> [a] -> [a]
keepLatest maxItems xs =
  drop (max 0 (length xs - maxItems)) xs

trim :: String -> String
trim = dropWhile isSpace . dropWhileEnd isSpace

lowWord :: WPARAM -> Int
lowWord value = fromIntegral (value .&. 0xFFFF)

controlIdBpmEdit, controlIdTap, controlIdReset, controlIdGetBpm, controlIdApplyOrigin, controlIdApplyCurrent :: IntPtr
controlIdBpmEdit = 1001
controlIdTap = 1002
controlIdReset = 1003
controlIdGetBpm = 1004
controlIdApplyOrigin = 1005
controlIdApplyCurrent = 1006

wmCommand :: UINT
wmCommand = 0x0111

wsPopup, wsChild, wsVisible, wsBorder, wsTabStop, esAutoHScroll, esRight, bsPushButton :: WINDOW_STYLE
wsPopup = 0x80000000
wsChild = 0x40000000
wsVisible = 0x10000000
wsBorder = 0x00800000
wsTabStop = 0x00010000
esAutoHScroll = 0x0080
esRight = 0x0002
bsPushButton = 0x00000000

buttonStyle, editStyle :: WINDOW_STYLE
buttonStyle = wsChild .|. wsVisible .|. wsTabStop .|. bsPushButton
editStyle = wsChild .|. wsVisible .|. wsBorder .|. wsTabStop .|. esAutoHScroll .|. esRight

buttonClassName, editClassName, staticClassName :: LPCWSTR
buttonClassName = unsafePerformIO (newWideString "BUTTON")
editClassName = unsafePerformIO (newWideString "EDIT")
staticClassName = unsafePerformIO (newWideString "STATIC")
{-# NOINLINE buttonClassName #-}
{-# NOINLINE editClassName #-}
{-# NOINLINE staticClassName #-}
