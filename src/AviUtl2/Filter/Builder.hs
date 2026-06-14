{-# LANGUAGE ForeignFunctionInterface #-}
{-# LANGUAGE ScopedTypeVariables #-}

module AviUtl2.Filter.Builder
  ( FilterCapability(..)
  , FilterPlugin(..)
  , defaultFilterPlugin
  , newFilterPluginTable
  , staticFilterPluginTable
  , FilterItem
  , filterItemPointer
  , TrackItem
  , TrackGroupItem
  , CheckItem
  , CheckSectionItem
  , ColorItem
  , SelectItem
  , FileItem
  , GroupItem
  , ButtonItem
  , StringItem
  , TextItem
  , FolderItem
  , SeparatorItem
  , DataItem
  , FilterTrackSpec(..)
  , defaultFilterTrack
  , newTrackItem
  , staticTrackItem
  , trackFilterItem
  , readTrackValue
  , readTrackInt
  , newTrackGroupItem
  , staticTrackGroupItem
  , trackGroupFilterItem
  , newCheckItem
  , staticCheckItem
  , checkFilterItem
  , readCheckValue
  , newCheckSectionItem
  , staticCheckSectionItem
  , checkSectionFilterItem
  , readCheckSectionValue
  , newColorItem
  , staticColorItem
  , colorFilterItem
  , readColorCode
  , rgbColorCode
  , newSelectItem
  , staticSelectItem
  , selectFilterItem
  , readSelectValue
  , newFileItem
  , staticFileItem
  , fileFilterItem
  , readFileValue
  , newGroupItem
  , staticGroupItem
  , groupFilterItem
  , newButtonItem
  , staticButtonItem
  , buttonFilterItem
  , newStringItem
  , staticStringItem
  , stringFilterItem
  , readStringValue
  , newTextItem
  , staticTextItem
  , textFilterItem
  , readTextValue
  , newFolderItem
  , staticFolderItem
  , folderFilterItem
  , readFolderValue
  , newSeparatorItem
  , staticSeparatorItem
  , separatorFilterItem
  , newDataItem
  , staticDataItem
  , dataFilterItem
  , readDataValue
  , writeDataValue
  , newWideString
  , staticWideString
  , withPixelBuffer
  , fillPixelBuffer
  , setImagePixels
  ) where

import Control.Exception (bracket)
import Control.Monad (when)
import Data.Bits ((.|.), shiftL)
import Data.Proxy (Proxy(..))
import Data.Word (Word8)
import Foreign.C.String (newCWString)
import Foreign.C.Types (CBool(..), CInt)
import Foreign.Marshal.Alloc (malloc, mallocBytes)
import qualified Foreign.Marshal.Alloc as Alloc
import Foreign.Marshal.Array (mallocArray, newArray)
import Foreign.Ptr (FunPtr, Ptr, castPtr, nullFunPtr, nullPtr, plusPtr)
import Foreign.Storable (Storable(..), peek, poke, pokeElemOff)
import System.IO.Unsafe (unsafePerformIO)

import AviUtl2.Edit (EDIT_SECTION)
import AviUtl2.Filter
  ( FILTER_ITEM_BUTTON(..)
  , FILTER_ITEM_CHECK(..)
  , FILTER_ITEM_CHECK_SECTION(..)
  , FILTER_ITEM_COLOR(..)
  , FILTER_ITEM_COLOR_VALUE(..)
  , FILTER_ITEM_DATA_HEADER(..)
  , FILTER_ITEM_FILE(..)
  , FILTER_ITEM_FOLDER(..)
  , FILTER_ITEM_GROUP(..)
  , FILTER_ITEM_SELECT(..)
  , FILTER_ITEM_SELECT_ITEM(..)
  , FILTER_ITEM_SEPARATOR(..)
  , FILTER_ITEM_STRING(..)
  , FILTER_ITEM_TEXT(..)
  , FILTER_ITEM_TRACK(..)
  , FILTER_ITEM_TRACK_GROUP(..)
  , FILTER_PLUGIN_TABLE(..)
  , FILTER_PROC_AUDIO
  , FILTER_PROC_VIDEO
  , filterItemDataSize
  , filterItemDataValueOffset
  , filterItemTypeData
  , filterFlagAudio
  , filterFlagFilter
  , filterFlagInput
  , filterFlagVideo
  , setImageData
  )
import AviUtl2.Types (BOOL_, LPCWSTR, PIXEL_RGBA, boolFromBOOL, boolToBOOL)

data FilterCapability
  = FilterVideo
  | FilterAudio
  | FilterInput
  | FilterObject
  deriving (Eq, Show)

data FilterPlugin = FilterPlugin
  { filterPluginName :: String
  , filterPluginLabel :: Maybe String
  , filterPluginInformation :: String
  , filterPluginCapabilities :: [FilterCapability]
  , filterPluginItems :: [FilterItem]
  , filterPluginVideoProc :: Maybe (Ptr FILTER_PROC_VIDEO -> IO Bool)
  , filterPluginAudioProc :: Maybe (Ptr FILTER_PROC_AUDIO -> IO Bool)
  }

defaultFilterPlugin :: FilterPlugin
defaultFilterPlugin = FilterPlugin
  { filterPluginName = ""
  , filterPluginLabel = Nothing
  , filterPluginInformation = ""
  , filterPluginCapabilities = []
  , filterPluginItems = []
  , filterPluginVideoProc = Nothing
  , filterPluginAudioProc = Nothing
  }

newtype FilterItem = FilterItem (Ptr ())
newtype TrackItem = TrackItem (Ptr FILTER_ITEM_TRACK)
newtype TrackGroupItem = TrackGroupItem (Ptr FILTER_ITEM_TRACK_GROUP)
newtype CheckItem = CheckItem (Ptr FILTER_ITEM_CHECK)
newtype CheckSectionItem = CheckSectionItem (Ptr FILTER_ITEM_CHECK_SECTION)
newtype ColorItem = ColorItem (Ptr FILTER_ITEM_COLOR)
newtype SelectItem = SelectItem (Ptr FILTER_ITEM_SELECT)
newtype FileItem = FileItem (Ptr FILTER_ITEM_FILE)
newtype GroupItem = GroupItem (Ptr FILTER_ITEM_GROUP)
newtype ButtonItem = ButtonItem (Ptr FILTER_ITEM_BUTTON)
newtype StringItem = StringItem (Ptr FILTER_ITEM_STRING)
newtype TextItem = TextItem (Ptr FILTER_ITEM_TEXT)
newtype FolderItem = FolderItem (Ptr FILTER_ITEM_FOLDER)
newtype SeparatorItem = SeparatorItem (Ptr FILTER_ITEM_SEPARATOR)
newtype DataItem a = DataItem (Ptr FILTER_ITEM_DATA_HEADER)

data FilterTrackSpec = FilterTrackSpec
  { filterTrackName :: String
  , filterTrackValue :: Double
  , filterTrackMin :: Double
  , filterTrackMax :: Double
  , filterTrackStep :: Double
  , filterTrackZeroDisplay :: Maybe String
  , filterTrackSliderRatio :: Double
  } deriving (Eq, Show)

defaultFilterTrack :: String -> Double -> FilterTrackSpec
defaultFilterTrack name value = FilterTrackSpec
  { filterTrackName = name
  , filterTrackValue = value
  , filterTrackMin = 0
  , filterTrackMax = 100
  , filterTrackStep = 1
  , filterTrackZeroDisplay = Nothing
  , filterTrackSliderRatio = 1
  }

newTrackItem :: FilterTrackSpec -> IO TrackItem
newTrackItem spec = do
  itemType <- newCWString "track2"
  itemName <- newCWString (filterTrackName spec)
  zeroDisplay <- traverse newCWString (filterTrackZeroDisplay spec)
  ptr <- malloc
  poke ptr FILTER_ITEM_TRACK
    { fitType = itemType
    , fitName = itemName
    , fitValue = realToFrac (filterTrackValue spec)
    , fitS = realToFrac (filterTrackMin spec)
    , fitE = realToFrac (filterTrackMax spec)
    , fitStep = realToFrac (filterTrackStep spec)
    , fitZeroDisplay = maybe nullPtr id zeroDisplay
    , fitSliderRatio = realToFrac (filterTrackSliderRatio spec)
    }
  pure (TrackItem ptr)

staticTrackItem :: FilterTrackSpec -> TrackItem
staticTrackItem spec = unsafePerformIO (newTrackItem spec)
{-# NOINLINE staticTrackItem #-}

trackFilterItem :: TrackItem -> FilterItem
trackFilterItem (TrackItem ptr) = FilterItem (castPtr ptr)

readTrackValue :: TrackItem -> IO Double
readTrackValue (TrackItem ptr) =
  realToFrac . fitValue <$> peek ptr

readTrackInt :: TrackItem -> IO Int
readTrackInt item =
  round <$> readTrackValue item

newTrackGroupItem :: String -> [TrackItem] -> IO TrackGroupItem
newTrackGroupItem name tracks = do
  itemType <- newCWString "trackgroup"
  itemName <- newCWString name
  trackList <- newArray (map trackItemPtr tracks ++ [nullPtr])
  ptr <- malloc
  poke ptr FILTER_ITEM_TRACK_GROUP
    { fitgType = itemType
    , fitgName = itemName
    , fitgTracks = trackList
    }
  pure (TrackGroupItem ptr)

staticTrackGroupItem :: String -> [TrackItem] -> TrackGroupItem
staticTrackGroupItem name tracks = unsafePerformIO (newTrackGroupItem name tracks)
{-# NOINLINE staticTrackGroupItem #-}

trackGroupFilterItem :: TrackGroupItem -> FilterItem
trackGroupFilterItem (TrackGroupItem ptr) = FilterItem (castPtr ptr)

newCheckItem :: String -> Bool -> IO CheckItem
newCheckItem name value = do
  itemType <- newCWString "check"
  itemName <- newCWString name
  ptr <- malloc
  poke ptr FILTER_ITEM_CHECK
    { ficType = itemType
    , ficName = itemName
    , ficValue = boolToBOOL value
    }
  pure (CheckItem ptr)

staticCheckItem :: String -> Bool -> CheckItem
staticCheckItem name value = unsafePerformIO (newCheckItem name value)
{-# NOINLINE staticCheckItem #-}

checkFilterItem :: CheckItem -> FilterItem
checkFilterItem (CheckItem ptr) = FilterItem (castPtr ptr)

readCheckValue :: CheckItem -> IO Bool
readCheckValue (CheckItem ptr) =
  boolFromBOOL . ficValue <$> peek ptr

newCheckSectionItem :: String -> Bool -> Bool -> IO CheckSectionItem
newCheckSectionItem name value multiSection = do
  itemType <- newCWString "checksection2"
  itemName <- newCWString name
  ptr <- malloc
  poke ptr FILTER_ITEM_CHECK_SECTION
    { ficsType = itemType
    , ficsName = itemName
    , ficsValue = boolToBOOL value
    , ficsMultiSection = boolToBOOL multiSection
    }
  pure (CheckSectionItem ptr)

staticCheckSectionItem :: String -> Bool -> Bool -> CheckSectionItem
staticCheckSectionItem name value multiSection = unsafePerformIO (newCheckSectionItem name value multiSection)
{-# NOINLINE staticCheckSectionItem #-}

checkSectionFilterItem :: CheckSectionItem -> FilterItem
checkSectionFilterItem (CheckSectionItem ptr) = FilterItem (castPtr ptr)

readCheckSectionValue :: CheckSectionItem -> IO Bool
readCheckSectionValue (CheckSectionItem ptr) =
  boolFromBOOL . ficsValue <$> peek ptr

newColorItem :: String -> CInt -> IO ColorItem
newColorItem name code = do
  itemType <- newCWString "color"
  itemName <- newCWString name
  ptr <- malloc
  poke ptr FILTER_ITEM_COLOR
    { fiColType = itemType
    , fiColName = itemName
    , fiColValue = FILTER_ITEM_COLOR_VALUE code
    }
  pure (ColorItem ptr)

staticColorItem :: String -> CInt -> ColorItem
staticColorItem name code = unsafePerformIO (newColorItem name code)
{-# NOINLINE staticColorItem #-}

colorFilterItem :: ColorItem -> FilterItem
colorFilterItem (ColorItem ptr) = FilterItem (castPtr ptr)

readColorCode :: ColorItem -> IO CInt
readColorCode (ColorItem ptr) =
  ficvCode . fiColValue <$> peek ptr

rgbColorCode :: Word8 -> Word8 -> Word8 -> CInt
rgbColorCode r g b =
  fromIntegral b
    .|. (fromIntegral g `shiftL` 8)
    .|. (fromIntegral r `shiftL` 16)

newSelectItem :: String -> CInt -> [(String, CInt)] -> IO SelectItem
newSelectItem name value options = do
  itemType <- newCWString "select"
  itemName <- newCWString name
  optionItems <- traverse newSelectOption options
  optionList <- newArray (optionItems ++ [FILTER_ITEM_SELECT_ITEM nullPtr 0])
  ptr <- malloc
  poke ptr FILTER_ITEM_SELECT
    { fiselType = itemType
    , fiselName = itemName
    , fiselValue = value
    , fiselList = optionList
    }
  pure (SelectItem ptr)

staticSelectItem :: String -> CInt -> [(String, CInt)] -> SelectItem
staticSelectItem name value options = unsafePerformIO (newSelectItem name value options)
{-# NOINLINE staticSelectItem #-}

selectFilterItem :: SelectItem -> FilterItem
selectFilterItem (SelectItem ptr) = FilterItem (castPtr ptr)

readSelectValue :: SelectItem -> IO CInt
readSelectValue (SelectItem ptr) =
  fiselValue <$> peek ptr

newFileItem :: String -> String -> String -> IO FileItem
newFileItem name value filefilter = do
  itemType <- newCWString "file"
  itemName <- newCWString name
  itemValue <- newCWString value
  itemFilter <- newCWString filefilter
  ptr <- malloc
  poke ptr FILTER_ITEM_FILE
    { fifType = itemType
    , fifName = itemName
    , fifValue = itemValue
    , fifFilefilter = itemFilter
    }
  pure (FileItem ptr)

staticFileItem :: String -> String -> String -> FileItem
staticFileItem name value filefilter = unsafePerformIO (newFileItem name value filefilter)
{-# NOINLINE staticFileItem #-}

fileFilterItem :: FileItem -> FilterItem
fileFilterItem (FileItem ptr) = FilterItem (castPtr ptr)

readFileValue :: FileItem -> IO LPCWSTR
readFileValue (FileItem ptr) =
  fifValue <$> peek ptr

newGroupItem :: String -> Bool -> IO GroupItem
newGroupItem name defaultVisible = do
  itemType <- newCWString "group"
  itemName <- newCWString name
  ptr <- malloc
  poke ptr FILTER_ITEM_GROUP
    { figType = itemType
    , figName = itemName
    , figDefaultVisible = boolToBOOL defaultVisible
    }
  pure (GroupItem ptr)

staticGroupItem :: String -> Bool -> GroupItem
staticGroupItem name defaultVisible = unsafePerformIO (newGroupItem name defaultVisible)
{-# NOINLINE staticGroupItem #-}

groupFilterItem :: GroupItem -> FilterItem
groupFilterItem (GroupItem ptr) = FilterItem (castPtr ptr)

newButtonItem :: String -> (Ptr EDIT_SECTION -> IO ()) -> IO ButtonItem
newButtonItem name callback = do
  itemType <- newCWString "button"
  itemName <- newCWString name
  callbackPtr <- mkButtonCallback callback
  ptr <- malloc
  poke ptr FILTER_ITEM_BUTTON
    { fibType = itemType
    , fibName = itemName
    , fibCallback = callbackPtr
    }
  pure (ButtonItem ptr)

staticButtonItem :: String -> (Ptr EDIT_SECTION -> IO ()) -> ButtonItem
staticButtonItem name callback = unsafePerformIO (newButtonItem name callback)
{-# NOINLINE staticButtonItem #-}

buttonFilterItem :: ButtonItem -> FilterItem
buttonFilterItem (ButtonItem ptr) = FilterItem (castPtr ptr)

newStringItem :: String -> String -> IO StringItem
newStringItem name value = do
  itemType <- newCWString "string"
  itemName <- newCWString name
  itemValue <- newCWString value
  ptr <- malloc
  poke ptr FILTER_ITEM_STRING
    { fistrType = itemType
    , fistrName = itemName
    , fistrValue = itemValue
    }
  pure (StringItem ptr)

staticStringItem :: String -> String -> StringItem
staticStringItem name value = unsafePerformIO (newStringItem name value)
{-# NOINLINE staticStringItem #-}

stringFilterItem :: StringItem -> FilterItem
stringFilterItem (StringItem ptr) = FilterItem (castPtr ptr)

readStringValue :: StringItem -> IO LPCWSTR
readStringValue (StringItem ptr) =
  fistrValue <$> peek ptr

newTextItem :: String -> String -> IO TextItem
newTextItem name value = do
  itemType <- newCWString "text"
  itemName <- newCWString name
  itemValue <- newCWString value
  ptr <- malloc
  poke ptr FILTER_ITEM_TEXT
    { fitxtType = itemType
    , fitxtName = itemName
    , fitxtValue = itemValue
    }
  pure (TextItem ptr)

staticTextItem :: String -> String -> TextItem
staticTextItem name value = unsafePerformIO (newTextItem name value)
{-# NOINLINE staticTextItem #-}

textFilterItem :: TextItem -> FilterItem
textFilterItem (TextItem ptr) = FilterItem (castPtr ptr)

readTextValue :: TextItem -> IO LPCWSTR
readTextValue (TextItem ptr) =
  fitxtValue <$> peek ptr

newFolderItem :: String -> String -> IO FolderItem
newFolderItem name value = do
  itemType <- newCWString "folder"
  itemName <- newCWString name
  itemValue <- newCWString value
  ptr <- malloc
  poke ptr FILTER_ITEM_FOLDER
    { fifolType = itemType
    , fifolName = itemName
    , fifolValue = itemValue
    }
  pure (FolderItem ptr)

staticFolderItem :: String -> String -> FolderItem
staticFolderItem name value = unsafePerformIO (newFolderItem name value)
{-# NOINLINE staticFolderItem #-}

folderFilterItem :: FolderItem -> FilterItem
folderFilterItem (FolderItem ptr) = FilterItem (castPtr ptr)

readFolderValue :: FolderItem -> IO LPCWSTR
readFolderValue (FolderItem ptr) =
  fifolValue <$> peek ptr

newSeparatorItem :: String -> IO SeparatorItem
newSeparatorItem name = do
  itemType <- newCWString "separator"
  itemName <- newCWString name
  ptr <- malloc
  poke ptr FILTER_ITEM_SEPARATOR
    { fisepType = itemType
    , fisepName = itemName
    }
  pure (SeparatorItem ptr)

staticSeparatorItem :: String -> SeparatorItem
staticSeparatorItem name = unsafePerformIO (newSeparatorItem name)
{-# NOINLINE staticSeparatorItem #-}

separatorFilterItem :: SeparatorItem -> FilterItem
separatorFilterItem (SeparatorItem ptr) = FilterItem (castPtr ptr)

newDataItem :: forall a. Storable a => String -> a -> IO (DataItem a)
newDataItem name defaultValue = do
  let valueSize = sizeOf defaultValue
  when (valueSize > 1024) $
    ioError (userError "FILTER_ITEM_DATA default value must be 1024 bytes or less")
  itemName <- newCWString name
  let valueOffset = filterItemDataValueOffset (Proxy :: Proxy a)
      totalSize = filterItemDataSize (Proxy :: Proxy a)
  raw <- mallocBytes totalSize :: IO (Ptr ())
  let header = castPtr raw
      valuePtr = raw `plusPtr` valueOffset
  poke header FILTER_ITEM_DATA_HEADER
    { fidhType = filterItemTypeData
    , fidhName = itemName
    , fidhValue = valuePtr
    , fidhSize = fromIntegral valueSize
    }
  poke (castPtr valuePtr) defaultValue
  pure (DataItem header)

staticDataItem :: Storable a => String -> a -> DataItem a
staticDataItem name defaultValue = unsafePerformIO (newDataItem name defaultValue)
{-# NOINLINE staticDataItem #-}

dataFilterItem :: DataItem a -> FilterItem
dataFilterItem (DataItem ptr) = FilterItem (castPtr ptr)

readDataValue :: Storable a => DataItem a -> IO a
readDataValue (DataItem ptr) = do
  header <- peek ptr
  peek (castPtr (fidhValue header))

writeDataValue :: Storable a => DataItem a -> a -> IO ()
writeDataValue (DataItem ptr) value = do
  header <- peek ptr
  poke (castPtr (fidhValue header)) value

filterItemPointer :: FilterItem -> Ptr ()
filterItemPointer = filterItemPtr

trackItemPtr :: TrackItem -> Ptr FILTER_ITEM_TRACK
trackItemPtr (TrackItem ptr) = ptr

newSelectOption :: (String, CInt) -> IO FILTER_ITEM_SELECT_ITEM
newSelectOption (name, value) = do
  itemName <- newCWString name
  pure (FILTER_ITEM_SELECT_ITEM itemName value)

newWideString :: String -> IO LPCWSTR
newWideString = newCWString

staticWideString :: String -> LPCWSTR
staticWideString text = unsafePerformIO (newWideString text)
{-# NOINLINE staticWideString #-}

withPixelBuffer :: Int -> (Ptr PIXEL_RGBA -> IO a) -> IO a
withPixelBuffer pixelCount =
  bracket (mallocArray pixelCount) Alloc.free

fillPixelBuffer :: Ptr PIXEL_RGBA -> Int -> PIXEL_RGBA -> IO ()
fillPixelBuffer buf pixelCount pixel =
  mapM_ (\i -> pokeElemOff buf i pixel) [0 .. pixelCount - 1]

setImagePixels :: Ptr FILTER_PROC_VIDEO -> Int -> Int -> (Int -> PIXEL_RGBA) -> IO ()
setImagePixels video width height pixelAt =
  withPixelBuffer pixelCount $ \buf -> do
    mapM_ (\i -> pokeElemOff buf i (pixelAt i)) [0 .. pixelCount - 1]
    setImageData video buf (fromIntegral width) (fromIntegral height)
  where
    pixelCount = width * height

newFilterPluginTable :: FilterPlugin -> IO (Ptr FILTER_PLUGIN_TABLE)
newFilterPluginTable spec = do
  name <- newCWString (filterPluginName spec)
  label <- traverse newCWString (filterPluginLabel spec)
  information <- newCWString (filterPluginInformation spec)
  items <- newArray (map filterItemPtr (filterPluginItems spec) ++ [nullPtr])
  videoProc <- maybe (pure nullFunPtr) (mkFilterVideoProc . wrapBoolProc) (filterPluginVideoProc spec)
  audioProc <- maybe (pure nullFunPtr) (mkFilterAudioProc . wrapBoolProc) (filterPluginAudioProc spec)
  table <- malloc
  poke table FILTER_PLUGIN_TABLE
    { fptFlag = filterCapabilitiesFlag (filterPluginCapabilities spec)
    , fptName = name
    , fptLabel = maybe nullPtr id label
    , fptInformation = information
    , fptItems = items
    , fptFuncProcVideo = videoProc
    , fptFuncProcAudio = audioProc
    }
  pure table

staticFilterPluginTable :: FilterPlugin -> Ptr FILTER_PLUGIN_TABLE
staticFilterPluginTable spec = unsafePerformIO (newFilterPluginTable spec)
{-# NOINLINE staticFilterPluginTable #-}

filterItemPtr :: FilterItem -> Ptr ()
filterItemPtr (FilterItem ptr) = ptr

filterCapabilitiesFlag :: [FilterCapability] -> CInt
filterCapabilitiesFlag =
  foldr ((.|.) . filterCapabilityFlag) 0

filterCapabilityFlag :: FilterCapability -> CInt
filterCapabilityFlag FilterVideo = filterFlagVideo
filterCapabilityFlag FilterAudio = filterFlagAudio
filterCapabilityFlag FilterInput = filterFlagInput
filterCapabilityFlag FilterObject = filterFlagFilter

wrapBoolProc :: (a -> IO Bool) -> a -> IO BOOL_
wrapBoolProc proc value =
  boolToBOOL <$> proc value

foreign import ccall "wrapper"
  mkFilterVideoProc :: (Ptr FILTER_PROC_VIDEO -> IO BOOL_) -> IO (FunPtr (Ptr FILTER_PROC_VIDEO -> IO BOOL_))

foreign import ccall "wrapper"
  mkFilterAudioProc :: (Ptr FILTER_PROC_AUDIO -> IO BOOL_) -> IO (FunPtr (Ptr FILTER_PROC_AUDIO -> IO BOOL_))

foreign import ccall "wrapper"
  mkButtonCallback :: (Ptr EDIT_SECTION -> IO ()) -> IO (FunPtr (Ptr EDIT_SECTION -> IO ()))
