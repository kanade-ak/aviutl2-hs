{-# LANGUAGE ScopedTypeVariables #-}
{-|
Module      : AviUtl2.Filter
Description : AviUtl2のフィルタプラグインと設定UI項目を定義するABIバインディングです。

このモジュールは @filter2.h@ 相当の薄いFFI定義です。ポインタや
バッファの寿命はAviUtl2 SDK側の規約に従って扱ってください。
-}
module AviUtl2.Filter
  ( FILTER_ITEM_TRACK(..)
  , FILTER_ITEM_TRACK_GROUP(..)
  , FILTER_ITEM_CHECK(..)
  , FILTER_ITEM_CHECK_SECTION(..)
  , FILTER_ITEM_COLOR(..)
  , FILTER_ITEM_COLOR_VALUE(..)
  , FILTER_ITEM_SELECT(..)
  , FILTER_ITEM_SELECT_ITEM(..)
  , FILTER_ITEM_FILE(..)
  , FILTER_ITEM_GROUP(..)
  , FILTER_ITEM_BUTTON(..)
  , FILTER_ITEM_STRING(..)
  , FILTER_ITEM_TEXT(..)
  , FILTER_ITEM_FOLDER(..)
  , FILTER_ITEM_SEPARATOR(..)
  , FILTER_ITEM_DATA_HEADER(..)
  , filterItemDataHeaderSize
  , filterItemDataValueOffset
  , filterItemDataSize
  , filterItemTypeData
  , VERTEX_COLOR(..)
  , VERTEX_COLOR_NORM(..)
  , VERTEX_TEXTURE(..)
  , VERTEX_TEXTURE_NORM(..)
  , VERTEX_TYPE
  , vertexTypeTriangleColor
  , vertexTypeTriangleColorNorm
  , vertexTypeTriangleTexture
  , vertexTypeTriangleTextureNorm
  , vertexTypeQuadColor
  , vertexTypeQuadColorNorm
  , vertexTypeQuadTexture
  , vertexTypeQuadTextureNorm
  , BLEND_MODE
  , blendModeNone
  , blendModeAdd
  , blendModeSub
  , blendModeMul
  , blendModeScreen
  , blendModeOverlay
  , blendModeLight
  , blendModeDark
  , blendModeBrightness
  , blendModeChroma
  , blendModeShadow
  , blendModeLightDark
  , blendModeDiff
  , BILLBOARD_MODE
  , billboardModeNone
  , billboardModeSide
  , billboardModeDirection
  , billboardModeCamera
  , SAMPLER_MODE
  , samplerModeClip
  , samplerModeClamp
  , samplerModeLoop
  , samplerModeMirror
  , samplerModeDot
  , BLEND_STATE_MODE
  , blendStateModeCopy
  , blendStateModeMask
  , blendStateModeDraw
  , blendStateModeAdd
  , INPUT_PIXEL_FORMAT
  , inputPixelFormatRgba
  , inputPixelFormatBgra
  , inputPixelFormatBgr
  , inputPixelFormatPa64
  , inputPixelFormatHf64
  , inputPixelFormatYuy2
  , inputPixelFormatYc48
  , OUTPUT_PIXEL_FORMAT
  , outputPixelFormatRgba
  , outputPixelFormatPa64
  , outputPixelFormatHf64
  , OBJECT_IMAGE_PARAM(..)
  , OBJECT_AUDIO_PARAM(..)
  , FILTER_PROC_VIDEO(..)
  , FILTER_PROC_AUDIO(..)
  , FILTER_PLUGIN_TABLE(..)
  , filterFlagVideo
  , filterFlagAudio
  , filterFlagInput
  , filterFlagFilter
  , getImageData
  , setImageData
  , getImageTexture2d
  , getFramebufferTexture2d
  , getOutputImageParam
  , getImageObject
  , drawImage
  , drawPoly
  , setDefaultAnchor
  , setBlendMode
  , setMaterialShine
  , setSamplerMode
  , setCullingState
  , setBillboardMode
  , createImageResource
  , getImageResourceTexture2d
  , copyImageResource
  , clearImageResource
  , drawImageToResource
  , drawPolyToResource
  , execPixelShaderFile
  , execComputeShaderFile
  , getBlendState
  , getSamplerState
  , execPixelShaderData
  , execComputeShaderData
  , getImageResourceSize
  , getImageResourceData
  , setImageResourceData
  , getSampleData
  , setSampleData
  , getOutputAudioParam
  , getAudioObject
  ) where

import Data.Bits ((.|.), shiftL)
import Data.Word (Word8, Word32)
import Foreign.C.String (newCWString)
import Foreign.C.Types (CBool(..), CDouble(..), CFloat(..), CInt(..))
import Foreign.Ptr (FunPtr, Ptr)
import Foreign.Storable (Storable(..))
import System.IO.Unsafe (unsafePerformIO)

import AviUtl2.Edit (EDIT_SECTION)
import AviUtl2.Types
  ( BOOL_
  , LPCWSTR
  , OBJECT_HANDLE
  , OBJECT_INFO
  , PIXEL_RGBA(..)
  , SCENE_INFO
  )

-- | トラックバー項目を表す構造体です。
data FILTER_ITEM_TRACK = FILTER_ITEM_TRACK
  { fitType        :: LPCWSTR
  , fitName        :: LPCWSTR
  , fitValue       :: CDouble
  , fitS           :: CDouble
  , fitE           :: CDouble
  , fitStep        :: CDouble
  , fitZeroDisplay :: LPCWSTR
  , fitSliderRatio :: CDouble
  } deriving (Show)

instance Storable FILTER_ITEM_TRACK where
  sizeOf _ = 64
  alignment _ = 8
  peek ptr = FILTER_ITEM_TRACK
    <$> peekByteOff ptr 0
    <*> peekByteOff ptr 8
    <*> peekByteOff ptr 16
    <*> peekByteOff ptr 24
    <*> peekByteOff ptr 32
    <*> peekByteOff ptr 40
    <*> peekByteOff ptr 48
    <*> peekByteOff ptr 56
  poke ptr v = do
    pokeByteOff ptr 0 (fitType v)
    pokeByteOff ptr 8 (fitName v)
    pokeByteOff ptr 16 (fitValue v)
    pokeByteOff ptr 24 (fitS v)
    pokeByteOff ptr 32 (fitE v)
    pokeByteOff ptr 40 (fitStep v)
    pokeByteOff ptr 48 (fitZeroDisplay v)
    pokeByteOff ptr 56 (fitSliderRatio v)

-- | 複数のトラックバーを1行にまとめるグループ項目です。
data FILTER_ITEM_TRACK_GROUP = FILTER_ITEM_TRACK_GROUP
  { fitgType   :: LPCWSTR
  , fitgName   :: LPCWSTR
  , fitgTracks :: Ptr (Ptr FILTER_ITEM_TRACK)
  } deriving (Show)

instance Storable FILTER_ITEM_TRACK_GROUP where
  sizeOf _ = 24
  alignment _ = 8
  peek ptr = FILTER_ITEM_TRACK_GROUP
    <$> peekByteOff ptr 0
    <*> peekByteOff ptr 8
    <*> peekByteOff ptr 16
  poke ptr v = do
    pokeByteOff ptr 0 (fitgType v)
    pokeByteOff ptr 8 (fitgName v)
    pokeByteOff ptr 16 (fitgTracks v)

-- | チェックボックス項目を表す構造体です。
data FILTER_ITEM_CHECK = FILTER_ITEM_CHECK
  { ficType  :: LPCWSTR
  , ficName  :: LPCWSTR
  , ficValue :: BOOL_
  } deriving (Show)

instance Storable FILTER_ITEM_CHECK where
  sizeOf _ = 24
  alignment _ = 8
  peek ptr = FILTER_ITEM_CHECK
    <$> peekByteOff ptr 0
    <*> peekByteOff ptr 8
    <*> peekByteOff ptr 16
  poke ptr v = do
    pokeByteOff ptr 0 (ficType v)
    pokeByteOff ptr 8 (ficName v)
    pokeByteOff ptr 16 (ficValue v)

-- | セクション毎チェックボックス項目を表す構造体です。
data FILTER_ITEM_CHECK_SECTION = FILTER_ITEM_CHECK_SECTION
  { ficsType         :: LPCWSTR
  , ficsName         :: LPCWSTR
  , ficsValue        :: BOOL_
  , ficsMultiSection :: BOOL_
  } deriving (Show)

instance Storable FILTER_ITEM_CHECK_SECTION where
  sizeOf _ = 24
  alignment _ = 8
  peek ptr = FILTER_ITEM_CHECK_SECTION
    <$> peekByteOff ptr 0
    <*> peekByteOff ptr 8
    <*> peekByteOff ptr 16
    <*> peekByteOff ptr 17
  poke ptr v = do
    pokeByteOff ptr 0 (ficsType v)
    pokeByteOff ptr 8 (ficsName v)
    pokeByteOff ptr 16 (ficsValue v)
    pokeByteOff ptr 17 (ficsMultiSection v)

-- | 色項目に格納される色コードです。
newtype FILTER_ITEM_COLOR_VALUE = FILTER_ITEM_COLOR_VALUE
  { ficvCode :: CInt
  } deriving (Show, Eq)

instance Storable FILTER_ITEM_COLOR_VALUE where
  sizeOf _ = 4
  alignment _ = 4
  peek ptr = FILTER_ITEM_COLOR_VALUE <$> peekByteOff ptr 0
  poke ptr v = pokeByteOff ptr 0 (ficvCode v)

-- | 色選択項目を表す構造体です。
data FILTER_ITEM_COLOR = FILTER_ITEM_COLOR
  { fiColType  :: LPCWSTR
  , fiColName  :: LPCWSTR
  , fiColValue :: FILTER_ITEM_COLOR_VALUE
  } deriving (Show)

instance Storable FILTER_ITEM_COLOR where
  sizeOf _ = 24
  alignment _ = 8
  peek ptr = FILTER_ITEM_COLOR
    <$> peekByteOff ptr 0
    <*> peekByteOff ptr 8
    <*> peekByteOff ptr 16
  poke ptr v = do
    pokeByteOff ptr 0 (fiColType v)
    pokeByteOff ptr 8 (fiColName v)
    pokeByteOff ptr 16 (fiColValue v)

-- | 選択リスト項目の1要素です。
data FILTER_ITEM_SELECT_ITEM = FILTER_ITEM_SELECT_ITEM
  { fisiName  :: LPCWSTR
  , fisiValue :: CInt
  } deriving (Show)

instance Storable FILTER_ITEM_SELECT_ITEM where
  sizeOf _ = 16
  alignment _ = 8
  peek ptr = FILTER_ITEM_SELECT_ITEM
    <$> peekByteOff ptr 0
    <*> peekByteOff ptr 8
  poke ptr v = do
    pokeByteOff ptr 0 (fisiName v)
    pokeByteOff ptr 8 (fisiValue v)

-- | 選択リスト項目を表す構造体です。
data FILTER_ITEM_SELECT = FILTER_ITEM_SELECT
  { fiselType  :: LPCWSTR
  , fiselName  :: LPCWSTR
  , fiselValue :: CInt
  , fiselList  :: Ptr FILTER_ITEM_SELECT_ITEM
  } deriving (Show)

instance Storable FILTER_ITEM_SELECT where
  sizeOf _ = 32
  alignment _ = 8
  peek ptr = FILTER_ITEM_SELECT
    <$> peekByteOff ptr 0
    <*> peekByteOff ptr 8
    <*> peekByteOff ptr 16
    <*> peekByteOff ptr 24
  poke ptr v = do
    pokeByteOff ptr 0 (fiselType v)
    pokeByteOff ptr 8 (fiselName v)
    pokeByteOff ptr 16 (fiselValue v)
    pokeByteOff ptr 24 (fiselList v)

-- | ファイル選択項目を表す構造体です。
data FILTER_ITEM_FILE = FILTER_ITEM_FILE
  { fifType       :: LPCWSTR
  , fifName       :: LPCWSTR
  , fifValue      :: LPCWSTR
  , fifFilefilter :: LPCWSTR
  } deriving (Show)

instance Storable FILTER_ITEM_FILE where
  sizeOf _ = 32
  alignment _ = 8
  peek ptr = FILTER_ITEM_FILE
    <$> peekByteOff ptr 0
    <*> peekByteOff ptr 8
    <*> peekByteOff ptr 16
    <*> peekByteOff ptr 24
  poke ptr v = do
    pokeByteOff ptr 0 (fifType v)
    pokeByteOff ptr 8 (fifName v)
    pokeByteOff ptr 16 (fifValue v)
    pokeByteOff ptr 24 (fifFilefilter v)

-- | 設定項目をグループ化するための項目です。
data FILTER_ITEM_GROUP = FILTER_ITEM_GROUP
  { figType           :: LPCWSTR
  , figName           :: LPCWSTR
  , figDefaultVisible :: BOOL_
  } deriving (Show)

instance Storable FILTER_ITEM_GROUP where
  sizeOf _ = 24
  alignment _ = 8
  peek ptr = FILTER_ITEM_GROUP
    <$> peekByteOff ptr 0
    <*> peekByteOff ptr 8
    <*> peekByteOff ptr 16
  poke ptr v = do
    pokeByteOff ptr 0 (figType v)
    pokeByteOff ptr 8 (figName v)
    pokeByteOff ptr 16 (figDefaultVisible v)

-- | ボタン項目を表す構造体です。
data FILTER_ITEM_BUTTON = FILTER_ITEM_BUTTON
  { fibType     :: LPCWSTR
  , fibName     :: LPCWSTR
  , fibCallback :: FunPtr (Ptr EDIT_SECTION -> IO ())
  } deriving (Show)

instance Storable FILTER_ITEM_BUTTON where
  sizeOf _ = 24
  alignment _ = 8
  peek ptr = FILTER_ITEM_BUTTON
    <$> peekByteOff ptr 0
    <*> peekByteOff ptr 8
    <*> peekByteOff ptr 16
  poke ptr v = do
    pokeByteOff ptr 0 (fibType v)
    pokeByteOff ptr 8 (fibName v)
    pokeByteOff ptr 16 (fibCallback v)

-- | 単一行の文字列入力項目を表す構造体です。
data FILTER_ITEM_STRING = FILTER_ITEM_STRING
  { fistrType  :: LPCWSTR
  , fistrName  :: LPCWSTR
  , fistrValue :: LPCWSTR
  } deriving (Show)

instance Storable FILTER_ITEM_STRING where
  sizeOf _ = 24
  alignment _ = 8
  peek ptr = FILTER_ITEM_STRING
    <$> peekByteOff ptr 0
    <*> peekByteOff ptr 8
    <*> peekByteOff ptr 16
  poke ptr v = do
    pokeByteOff ptr 0 (fistrType v)
    pokeByteOff ptr 8 (fistrName v)
    pokeByteOff ptr 16 (fistrValue v)

-- | 複数行テキスト入力項目を表す構造体です。
data FILTER_ITEM_TEXT = FILTER_ITEM_TEXT
  { fitxtType  :: LPCWSTR
  , fitxtName  :: LPCWSTR
  , fitxtValue :: LPCWSTR
  } deriving (Show)

instance Storable FILTER_ITEM_TEXT where
  sizeOf _ = 24
  alignment _ = 8
  peek ptr = FILTER_ITEM_TEXT
    <$> peekByteOff ptr 0
    <*> peekByteOff ptr 8
    <*> peekByteOff ptr 16
  poke ptr v = do
    pokeByteOff ptr 0 (fitxtType v)
    pokeByteOff ptr 8 (fitxtName v)
    pokeByteOff ptr 16 (fitxtValue v)

-- | フォルダ選択項目を表す構造体です。
data FILTER_ITEM_FOLDER = FILTER_ITEM_FOLDER
  { fifolType  :: LPCWSTR
  , fifolName  :: LPCWSTR
  , fifolValue :: LPCWSTR
  } deriving (Show)

instance Storable FILTER_ITEM_FOLDER where
  sizeOf _ = 24
  alignment _ = 8
  peek ptr = FILTER_ITEM_FOLDER
    <$> peekByteOff ptr 0
    <*> peekByteOff ptr 8
    <*> peekByteOff ptr 16
  poke ptr v = do
    pokeByteOff ptr 0 (fifolType v)
    pokeByteOff ptr 8 (fifolName v)
    pokeByteOff ptr 16 (fifolValue v)

-- | 設定UI上の区切り線を表す項目です。
data FILTER_ITEM_SEPARATOR = FILTER_ITEM_SEPARATOR
  { fisepType :: LPCWSTR
  , fisepName :: LPCWSTR
  } deriving (Show)

instance Storable FILTER_ITEM_SEPARATOR where
  sizeOf _ = 16
  alignment _ = 8
  peek ptr = FILTER_ITEM_SEPARATOR
    <$> peekByteOff ptr 0
    <*> peekByteOff ptr 8
  poke ptr v = do
    pokeByteOff ptr 0 (fisepType v)
    pokeByteOff ptr 8 (fisepName v)

-- | 汎用データ項目であることを示す型名文字列です。
filterItemTypeData :: LPCWSTR
filterItemTypeData = unsafePerformIO (newCWString "data")
{-# NOINLINE filterItemTypeData #-}

-- | 汎用データ項目のヘッダー部分です。
data FILTER_ITEM_DATA_HEADER = FILTER_ITEM_DATA_HEADER
  { fidhType  :: LPCWSTR
  , fidhName  :: LPCWSTR
  , fidhValue :: Ptr ()
  , fidhSize  :: CInt
  }

instance Storable FILTER_ITEM_DATA_HEADER where
  sizeOf _ = 32
  alignment _ = 8
  peek ptr = FILTER_ITEM_DATA_HEADER
    <$> peekByteOff ptr 0
    <*> peekByteOff ptr 8
    <*> peekByteOff ptr 16
    <*> peekByteOff ptr 24
  poke ptr v = do
    pokeByteOff ptr 0 (fidhType v)
    pokeByteOff ptr 8 (fidhName v)
    pokeByteOff ptr 16 (fidhValue v)
    pokeByteOff ptr 24 (fidhSize v)

filterItemDataHeaderSize :: Int
filterItemDataHeaderSize = 28

filterItemDataValueOffset :: forall a proxy. Storable a => proxy a -> Int
filterItemDataValueOffset _ = alignUp filterItemDataHeaderSize (alignment (undefined :: a))

filterItemDataSize :: forall a proxy. Storable a => proxy a -> Int
filterItemDataSize proxy =
  let valueAlign = alignmentValue proxy
      valueSize = sizeOf (undefined :: a)
      structAlign = max 8 valueAlign
      totalSize = filterItemDataValueOffset proxy + valueSize
  in alignUp totalSize structAlign

alignmentValue :: forall a proxy. Storable a => proxy a -> Int
alignmentValue _ = alignment (undefined :: a)

alignUp :: Int -> Int -> Int
alignUp value align =
  ((value + align - 1) `div` align) * align

data VERTEX_COLOR = VERTEX_COLOR
  { vcX :: CFloat, vcY :: CFloat, vcZ :: CFloat
  , vcR :: CFloat, vcG :: CFloat, vcB :: CFloat, vcA :: CFloat
  } deriving (Show)

instance Storable VERTEX_COLOR where
  sizeOf _ = 28
  alignment _ = 4
  peek ptr = VERTEX_COLOR
    <$> peekByteOff ptr 0 <*> peekByteOff ptr 4 <*> peekByteOff ptr 8
    <*> peekByteOff ptr 12 <*> peekByteOff ptr 16 <*> peekByteOff ptr 20 <*> peekByteOff ptr 24
  poke ptr v = do
    pokeByteOff ptr 0 (vcX v); pokeByteOff ptr 4 (vcY v); pokeByteOff ptr 8 (vcZ v)
    pokeByteOff ptr 12 (vcR v); pokeByteOff ptr 16 (vcG v); pokeByteOff ptr 20 (vcB v); pokeByteOff ptr 24 (vcA v)

data VERTEX_COLOR_NORM = VERTEX_COLOR_NORM
  { vcnX :: CFloat, vcnY :: CFloat, vcnZ :: CFloat
  , vcnR :: CFloat, vcnG :: CFloat, vcnB :: CFloat, vcnA :: CFloat
  , vcnVx :: CFloat, vcnVy :: CFloat, vcnVz :: CFloat
  } deriving (Show)

instance Storable VERTEX_COLOR_NORM where
  sizeOf _ = 40
  alignment _ = 4
  peek ptr = VERTEX_COLOR_NORM
    <$> peekByteOff ptr 0 <*> peekByteOff ptr 4 <*> peekByteOff ptr 8
    <*> peekByteOff ptr 12 <*> peekByteOff ptr 16 <*> peekByteOff ptr 20 <*> peekByteOff ptr 24
    <*> peekByteOff ptr 28 <*> peekByteOff ptr 32 <*> peekByteOff ptr 36
  poke ptr v = do
    pokeByteOff ptr 0 (vcnX v); pokeByteOff ptr 4 (vcnY v); pokeByteOff ptr 8 (vcnZ v)
    pokeByteOff ptr 12 (vcnR v); pokeByteOff ptr 16 (vcnG v); pokeByteOff ptr 20 (vcnB v); pokeByteOff ptr 24 (vcnA v)
    pokeByteOff ptr 28 (vcnVx v); pokeByteOff ptr 32 (vcnVy v); pokeByteOff ptr 36 (vcnVz v)

data VERTEX_TEXTURE = VERTEX_TEXTURE
  { vtX :: CFloat, vtY :: CFloat, vtZ :: CFloat
  , vtU :: CFloat, vtV :: CFloat, vtA :: CFloat
  } deriving (Show)

instance Storable VERTEX_TEXTURE where
  sizeOf _ = 24
  alignment _ = 4
  peek ptr = VERTEX_TEXTURE
    <$> peekByteOff ptr 0 <*> peekByteOff ptr 4 <*> peekByteOff ptr 8
    <*> peekByteOff ptr 12 <*> peekByteOff ptr 16 <*> peekByteOff ptr 20
  poke ptr v = do
    pokeByteOff ptr 0 (vtX v); pokeByteOff ptr 4 (vtY v); pokeByteOff ptr 8 (vtZ v)
    pokeByteOff ptr 12 (vtU v); pokeByteOff ptr 16 (vtV v); pokeByteOff ptr 20 (vtA v)

data VERTEX_TEXTURE_NORM = VERTEX_TEXTURE_NORM
  { vtnX :: CFloat, vtnY :: CFloat, vtnZ :: CFloat
  , vtnU :: CFloat, vtnV :: CFloat, vtnA :: CFloat
  , vtnVx :: CFloat, vtnVy :: CFloat, vtnVz :: CFloat
  } deriving (Show)

instance Storable VERTEX_TEXTURE_NORM where
  sizeOf _ = 36
  alignment _ = 4
  peek ptr = VERTEX_TEXTURE_NORM
    <$> peekByteOff ptr 0 <*> peekByteOff ptr 4 <*> peekByteOff ptr 8
    <*> peekByteOff ptr 12 <*> peekByteOff ptr 16 <*> peekByteOff ptr 20
    <*> peekByteOff ptr 24 <*> peekByteOff ptr 28 <*> peekByteOff ptr 32
  poke ptr v = do
    pokeByteOff ptr 0 (vtnX v); pokeByteOff ptr 4 (vtnY v); pokeByteOff ptr 8 (vtnZ v)
    pokeByteOff ptr 12 (vtnU v); pokeByteOff ptr 16 (vtnV v); pokeByteOff ptr 20 (vtnA v)
    pokeByteOff ptr 24 (vtnVx v); pokeByteOff ptr 28 (vtnVy v); pokeByteOff ptr 32 (vtnVz v)

type VERTEX_TYPE = CInt
vertexTypeTriangleColor, vertexTypeTriangleColorNorm, vertexTypeTriangleTexture, vertexTypeTriangleTextureNorm :: VERTEX_TYPE
vertexTypeQuadColor, vertexTypeQuadColorNorm, vertexTypeQuadTexture, vertexTypeQuadTextureNorm :: VERTEX_TYPE
vertexTypeTriangleColor = 1
vertexTypeTriangleColorNorm = 2
vertexTypeTriangleTexture = 3
vertexTypeTriangleTextureNorm = 4
vertexTypeQuadColor = 5
vertexTypeQuadColorNorm = 6
vertexTypeQuadTexture = 7
vertexTypeQuadTextureNorm = 8

type BLEND_MODE = CInt
blendModeNone, blendModeAdd, blendModeSub, blendModeMul, blendModeScreen, blendModeOverlay :: BLEND_MODE
blendModeLight, blendModeDark, blendModeBrightness, blendModeChroma, blendModeShadow, blendModeLightDark, blendModeDiff :: BLEND_MODE
blendModeNone = 0
blendModeAdd = 1
blendModeSub = 2
blendModeMul = 3
blendModeScreen = 4
blendModeOverlay = 5
blendModeLight = 6
blendModeDark = 7
blendModeBrightness = 8
blendModeChroma = 9
blendModeShadow = 10
blendModeLightDark = 11
blendModeDiff = 12

type BILLBOARD_MODE = CInt
billboardModeNone, billboardModeSide, billboardModeDirection, billboardModeCamera :: BILLBOARD_MODE
billboardModeNone = 0
billboardModeSide = 1
billboardModeDirection = 2
billboardModeCamera = 3

type SAMPLER_MODE = CInt
samplerModeClip, samplerModeClamp, samplerModeLoop, samplerModeMirror, samplerModeDot :: SAMPLER_MODE
samplerModeClip = 0
samplerModeClamp = 1
samplerModeLoop = 2
samplerModeMirror = 3
samplerModeDot = 4

type BLEND_STATE_MODE = CInt
blendStateModeCopy, blendStateModeMask, blendStateModeDraw, blendStateModeAdd :: BLEND_STATE_MODE
blendStateModeCopy = 0
blendStateModeMask = 1
blendStateModeDraw = 2
blendStateModeAdd = 3

type INPUT_PIXEL_FORMAT = CInt
inputPixelFormatRgba, inputPixelFormatBgra, inputPixelFormatBgr, inputPixelFormatPa64 :: INPUT_PIXEL_FORMAT
inputPixelFormatHf64, inputPixelFormatYuy2, inputPixelFormatYc48 :: INPUT_PIXEL_FORMAT
inputPixelFormatRgba = 28
inputPixelFormatBgra = 87
inputPixelFormatBgr = 88
inputPixelFormatPa64 = 11
inputPixelFormatHf64 = 10
inputPixelFormatYuy2 = 107
inputPixelFormatYc48 = 13

type OUTPUT_PIXEL_FORMAT = CInt
outputPixelFormatRgba, outputPixelFormatPa64, outputPixelFormatHf64 :: OUTPUT_PIXEL_FORMAT
outputPixelFormatRgba = 28
outputPixelFormatPa64 = 11
outputPixelFormatHf64 = 10

data OBJECT_IMAGE_PARAM = OBJECT_IMAGE_PARAM
  { oipX :: CFloat, oipY :: CFloat, oipZ :: CFloat
  , oipRx :: CFloat, oipRy :: CFloat, oipRz :: CFloat
  , oipSx :: CFloat, oipSy :: CFloat, oipSz :: CFloat
  , oipCx :: CFloat, oipCy :: CFloat, oipCz :: CFloat
  , oipAlpha :: CFloat
  } deriving (Show)

instance Storable OBJECT_IMAGE_PARAM where
  sizeOf _ = 52
  alignment _ = 4
  peek ptr = OBJECT_IMAGE_PARAM
    <$> peekByteOff ptr 0 <*> peekByteOff ptr 4 <*> peekByteOff ptr 8
    <*> peekByteOff ptr 12 <*> peekByteOff ptr 16 <*> peekByteOff ptr 20
    <*> peekByteOff ptr 24 <*> peekByteOff ptr 28 <*> peekByteOff ptr 32
    <*> peekByteOff ptr 36 <*> peekByteOff ptr 40 <*> peekByteOff ptr 44
    <*> peekByteOff ptr 48
  poke ptr v = do
    pokeByteOff ptr 0 (oipX v); pokeByteOff ptr 4 (oipY v); pokeByteOff ptr 8 (oipZ v)
    pokeByteOff ptr 12 (oipRx v); pokeByteOff ptr 16 (oipRy v); pokeByteOff ptr 20 (oipRz v)
    pokeByteOff ptr 24 (oipSx v); pokeByteOff ptr 28 (oipSy v); pokeByteOff ptr 32 (oipSz v)
    pokeByteOff ptr 36 (oipCx v); pokeByteOff ptr 40 (oipCy v); pokeByteOff ptr 44 (oipCz v)
    pokeByteOff ptr 48 (oipAlpha v)

data OBJECT_AUDIO_PARAM = OBJECT_AUDIO_PARAM
  { oapVolL :: CFloat
  , oapVolR :: CFloat
  } deriving (Show)

instance Storable OBJECT_AUDIO_PARAM where
  sizeOf _ = 8
  alignment _ = 4
  peek ptr = OBJECT_AUDIO_PARAM <$> peekByteOff ptr 0 <*> peekByteOff ptr 4
  poke ptr v = do
    pokeByteOff ptr 0 (oapVolL v)
    pokeByteOff ptr 4 (oapVolR v)

-- | 映像フィルタ処理中に渡される文脈構造体です。
data FILTER_PROC_VIDEO = FILTER_PROC_VIDEO
  { fpvScene                      :: Ptr SCENE_INFO
  , fpvObject                     :: Ptr OBJECT_INFO
  , fpvGetImageData               :: FunPtr (Ptr PIXEL_RGBA -> IO ())
  , fpvSetImageData               :: FunPtr (Ptr PIXEL_RGBA -> CInt -> CInt -> IO ())
  , fpvGetImageTexture2d          :: FunPtr (IO (Ptr ()))
  , fpvGetFramebufferTexture2d    :: FunPtr (IO (Ptr ()))
  , fpvEdit                       :: Ptr EDIT_SECTION
  , fpvParam                      :: Ptr OBJECT_IMAGE_PARAM
  , fpvGetOutputImageParam        :: FunPtr (OBJECT_HANDLE -> CDouble -> Ptr OBJECT_IMAGE_PARAM -> CInt -> IO BOOL_)
  , fpvGetImageObject             :: FunPtr (CInt -> CDouble -> IO OBJECT_HANDLE)
  , fpvDrawImage                  :: FunPtr (LPCWSTR -> CFloat -> CFloat -> CFloat -> CFloat -> CFloat -> CFloat -> CFloat -> CFloat -> CFloat -> CFloat -> IO BOOL_)
  , fpvDrawPoly                   :: FunPtr (VERTEX_TYPE -> Ptr () -> CInt -> LPCWSTR -> IO BOOL_)
  , fpvSetDefaultAnchor           :: FunPtr (CInt -> CInt -> IO ())
  , fpvSetBlendMode               :: FunPtr (BLEND_MODE -> IO ())
  , fpvSetMaterialShine           :: FunPtr (CFloat -> IO ())
  , fpvSetSamplerMode             :: FunPtr (SAMPLER_MODE -> IO ())
  , fpvSetCullingState            :: FunPtr (BOOL_ -> IO ())
  , fpvSetBillboardMode           :: FunPtr (BILLBOARD_MODE -> IO ())
  , fpvCreateImageResource        :: FunPtr (LPCWSTR -> Ptr PIXEL_RGBA -> CInt -> CInt -> IO ())
  , fpvGetImageResourceTexture2d  :: FunPtr (LPCWSTR -> IO (Ptr ()))
  , fpvCopyImageResource          :: FunPtr (LPCWSTR -> LPCWSTR -> IO BOOL_)
  , fpvClearImageResource         :: FunPtr (LPCWSTR -> Word32 -> IO BOOL_)
  , fpvDrawImageToResource        :: FunPtr (LPCWSTR -> LPCWSTR -> CFloat -> CFloat -> CFloat -> CFloat -> CFloat -> CFloat -> CFloat -> CFloat -> CFloat -> CFloat -> IO BOOL_)
  , fpvDrawPolyToResource         :: FunPtr (LPCWSTR -> VERTEX_TYPE -> Ptr () -> CInt -> LPCWSTR -> IO BOOL_)
  , fpvExecPixelShaderFile        :: FunPtr (LPCWSTR -> LPCWSTR -> Ptr LPCWSTR -> CInt -> Ptr () -> CInt -> Ptr () -> Ptr () -> IO BOOL_)
  , fpvExecComputeShaderFile      :: FunPtr (LPCWSTR -> Ptr LPCWSTR -> CInt -> Ptr LPCWSTR -> CInt -> Ptr () -> CInt -> CInt -> CInt -> CInt -> Ptr () -> IO BOOL_)
  , fpvGetBlendState              :: FunPtr (BLEND_STATE_MODE -> IO (Ptr ()))
  , fpvGetSamplerState            :: FunPtr (SAMPLER_MODE -> IO (Ptr ()))
  , fpvExecPixelShaderData        :: FunPtr (Ptr Word8 -> CInt -> LPCWSTR -> Ptr LPCWSTR -> CInt -> Ptr () -> CInt -> Ptr () -> Ptr () -> IO BOOL_)
  , fpvExecComputeShaderData      :: FunPtr (Ptr Word8 -> CInt -> Ptr LPCWSTR -> CInt -> Ptr LPCWSTR -> CInt -> Ptr () -> CInt -> CInt -> CInt -> CInt -> Ptr () -> IO BOOL_)
  , fpvGetImageResourceSize       :: FunPtr (LPCWSTR -> Ptr CInt -> Ptr CInt -> IO BOOL_)
  , fpvGetImageResourceData       :: FunPtr (LPCWSTR -> Ptr () -> CInt -> CInt -> CInt -> OUTPUT_PIXEL_FORMAT -> IO BOOL_)
  , fpvSetImageResourceData       :: FunPtr (LPCWSTR -> Ptr () -> CInt -> CInt -> CInt -> INPUT_PIXEL_FORMAT -> IO BOOL_)
  }

instance Storable FILTER_PROC_VIDEO where
  sizeOf _ = 264
  alignment _ = 8
  peek ptr = FILTER_PROC_VIDEO
    <$> peekByteOff ptr 0 <*> peekByteOff ptr 8 <*> peekByteOff ptr 16 <*> peekByteOff ptr 24
    <*> peekByteOff ptr 32 <*> peekByteOff ptr 40 <*> peekByteOff ptr 48 <*> peekByteOff ptr 56
    <*> peekByteOff ptr 64 <*> peekByteOff ptr 72 <*> peekByteOff ptr 80 <*> peekByteOff ptr 88
    <*> peekByteOff ptr 96 <*> peekByteOff ptr 104 <*> peekByteOff ptr 112 <*> peekByteOff ptr 120
    <*> peekByteOff ptr 128 <*> peekByteOff ptr 136 <*> peekByteOff ptr 144 <*> peekByteOff ptr 152
    <*> peekByteOff ptr 160 <*> peekByteOff ptr 168 <*> peekByteOff ptr 176 <*> peekByteOff ptr 184
    <*> peekByteOff ptr 192 <*> peekByteOff ptr 200 <*> peekByteOff ptr 208 <*> peekByteOff ptr 216
    <*> peekByteOff ptr 224 <*> peekByteOff ptr 232 <*> peekByteOff ptr 240 <*> peekByteOff ptr 248
    <*> peekByteOff ptr 256
  poke ptr v = do
    pokeByteOff ptr 0 (fpvScene v); pokeByteOff ptr 8 (fpvObject v)
    pokeByteOff ptr 16 (fpvGetImageData v); pokeByteOff ptr 24 (fpvSetImageData v)
    pokeByteOff ptr 32 (fpvGetImageTexture2d v); pokeByteOff ptr 40 (fpvGetFramebufferTexture2d v)
    pokeByteOff ptr 48 (fpvEdit v); pokeByteOff ptr 56 (fpvParam v)
    pokeByteOff ptr 64 (fpvGetOutputImageParam v); pokeByteOff ptr 72 (fpvGetImageObject v)
    pokeByteOff ptr 80 (fpvDrawImage v); pokeByteOff ptr 88 (fpvDrawPoly v)
    pokeByteOff ptr 96 (fpvSetDefaultAnchor v); pokeByteOff ptr 104 (fpvSetBlendMode v)
    pokeByteOff ptr 112 (fpvSetMaterialShine v); pokeByteOff ptr 120 (fpvSetSamplerMode v)
    pokeByteOff ptr 128 (fpvSetCullingState v); pokeByteOff ptr 136 (fpvSetBillboardMode v)
    pokeByteOff ptr 144 (fpvCreateImageResource v); pokeByteOff ptr 152 (fpvGetImageResourceTexture2d v)
    pokeByteOff ptr 160 (fpvCopyImageResource v); pokeByteOff ptr 168 (fpvClearImageResource v)
    pokeByteOff ptr 176 (fpvDrawImageToResource v); pokeByteOff ptr 184 (fpvDrawPolyToResource v)
    pokeByteOff ptr 192 (fpvExecPixelShaderFile v); pokeByteOff ptr 200 (fpvExecComputeShaderFile v)
    pokeByteOff ptr 208 (fpvGetBlendState v); pokeByteOff ptr 216 (fpvGetSamplerState v)
    pokeByteOff ptr 224 (fpvExecPixelShaderData v); pokeByteOff ptr 232 (fpvExecComputeShaderData v)
    pokeByteOff ptr 240 (fpvGetImageResourceSize v); pokeByteOff ptr 248 (fpvGetImageResourceData v)
    pokeByteOff ptr 256 (fpvSetImageResourceData v)

-- | 音声フィルタ処理中に渡される文脈構造体です。
data FILTER_PROC_AUDIO = FILTER_PROC_AUDIO
  { fpaScene               :: Ptr SCENE_INFO
  , fpaObject              :: Ptr OBJECT_INFO
  , fpaGetSampleData       :: FunPtr (Ptr CFloat -> CInt -> IO ())
  , fpaSetSampleData       :: FunPtr (Ptr CFloat -> CInt -> IO ())
  , fpaEdit                :: Ptr EDIT_SECTION
  , fpaParam               :: Ptr OBJECT_AUDIO_PARAM
  , fpaGetOutputAudioParam :: FunPtr (OBJECT_HANDLE -> CDouble -> Ptr OBJECT_AUDIO_PARAM -> CInt -> IO BOOL_)
  , fpaGetAudioObject      :: FunPtr (CInt -> CDouble -> IO OBJECT_HANDLE)
  }

instance Storable FILTER_PROC_AUDIO where
  sizeOf _ = 64
  alignment _ = 8
  peek ptr = FILTER_PROC_AUDIO
    <$> peekByteOff ptr 0 <*> peekByteOff ptr 8 <*> peekByteOff ptr 16 <*> peekByteOff ptr 24
    <*> peekByteOff ptr 32 <*> peekByteOff ptr 40 <*> peekByteOff ptr 48 <*> peekByteOff ptr 56
  poke ptr v = do
    pokeByteOff ptr 0 (fpaScene v); pokeByteOff ptr 8 (fpaObject v)
    pokeByteOff ptr 16 (fpaGetSampleData v); pokeByteOff ptr 24 (fpaSetSampleData v)
    pokeByteOff ptr 32 (fpaEdit v); pokeByteOff ptr 40 (fpaParam v)
    pokeByteOff ptr 48 (fpaGetOutputAudioParam v); pokeByteOff ptr 56 (fpaGetAudioObject v)

-- | フィルタプラグイン登録用の関数テーブルです。
data FILTER_PLUGIN_TABLE = FILTER_PLUGIN_TABLE
  { fptFlag           :: CInt
  , fptName           :: LPCWSTR
  , fptLabel          :: LPCWSTR
  , fptInformation    :: LPCWSTR
  , fptItems          :: Ptr (Ptr ())
  , fptFuncProcVideo  :: FunPtr (Ptr FILTER_PROC_VIDEO -> IO BOOL_)
  , fptFuncProcAudio  :: FunPtr (Ptr FILTER_PROC_AUDIO -> IO BOOL_)
  } deriving (Show)

filterFlagVideo, filterFlagAudio, filterFlagInput, filterFlagFilter :: CInt
filterFlagVideo = 1
filterFlagAudio = 2
filterFlagInput = 4
filterFlagFilter = 8

instance Storable FILTER_PLUGIN_TABLE where
  sizeOf _ = 56
  alignment _ = 8
  peek ptr = FILTER_PLUGIN_TABLE
    <$> peekByteOff ptr 0 <*> peekByteOff ptr 8 <*> peekByteOff ptr 16 <*> peekByteOff ptr 24
    <*> peekByteOff ptr 32 <*> peekByteOff ptr 40 <*> peekByteOff ptr 48
  poke ptr v = do
    pokeByteOff ptr 0 (fptFlag v)
    pokeByteOff ptr 8 (fptName v)
    pokeByteOff ptr 16 (fptLabel v)
    pokeByteOff ptr 24 (fptInformation v)
    pokeByteOff ptr 32 (fptItems v)
    pokeByteOff ptr 40 (fptFuncProcVideo v)
    pokeByteOff ptr 48 (fptFuncProcAudio v)

foreign import ccall "dynamic"
  mkGetImageData :: FunPtr (Ptr PIXEL_RGBA -> IO ()) -> Ptr PIXEL_RGBA -> IO ()
foreign import ccall "dynamic"
  mkSetImageData :: FunPtr (Ptr PIXEL_RGBA -> CInt -> CInt -> IO ()) -> Ptr PIXEL_RGBA -> CInt -> CInt -> IO ()
foreign import ccall "dynamic"
  mkGetImageTexture2d :: FunPtr (IO (Ptr ())) -> IO (Ptr ())
foreign import ccall "dynamic"
  mkGetFramebufferTexture2d :: FunPtr (IO (Ptr ())) -> IO (Ptr ())
foreign import ccall "dynamic"
  mkGetOutputImageParam :: FunPtr (OBJECT_HANDLE -> CDouble -> Ptr OBJECT_IMAGE_PARAM -> CInt -> IO BOOL_) -> OBJECT_HANDLE -> CDouble -> Ptr OBJECT_IMAGE_PARAM -> CInt -> IO BOOL_
foreign import ccall "dynamic"
  mkGetImageObject :: FunPtr (CInt -> CDouble -> IO OBJECT_HANDLE) -> CInt -> CDouble -> IO OBJECT_HANDLE
foreign import ccall "dynamic"
  mkDrawImage :: FunPtr (LPCWSTR -> CFloat -> CFloat -> CFloat -> CFloat -> CFloat -> CFloat -> CFloat -> CFloat -> CFloat -> CFloat -> IO BOOL_) -> LPCWSTR -> CFloat -> CFloat -> CFloat -> CFloat -> CFloat -> CFloat -> CFloat -> CFloat -> CFloat -> CFloat -> IO BOOL_
foreign import ccall "dynamic"
  mkDrawPoly :: FunPtr (VERTEX_TYPE -> Ptr () -> CInt -> LPCWSTR -> IO BOOL_) -> VERTEX_TYPE -> Ptr () -> CInt -> LPCWSTR -> IO BOOL_
foreign import ccall "dynamic"
  mkSetDefaultAnchor :: FunPtr (CInt -> CInt -> IO ()) -> CInt -> CInt -> IO ()
foreign import ccall "dynamic"
  mkSetBlendMode :: FunPtr (BLEND_MODE -> IO ()) -> BLEND_MODE -> IO ()
foreign import ccall "dynamic"
  mkSetMaterialShine :: FunPtr (CFloat -> IO ()) -> CFloat -> IO ()
foreign import ccall "dynamic"
  mkSetSamplerMode :: FunPtr (SAMPLER_MODE -> IO ()) -> SAMPLER_MODE -> IO ()
foreign import ccall "dynamic"
  mkSetCullingState :: FunPtr (BOOL_ -> IO ()) -> BOOL_ -> IO ()
foreign import ccall "dynamic"
  mkSetBillboardMode :: FunPtr (BILLBOARD_MODE -> IO ()) -> BILLBOARD_MODE -> IO ()
foreign import ccall "dynamic"
  mkCreateImageResource :: FunPtr (LPCWSTR -> Ptr PIXEL_RGBA -> CInt -> CInt -> IO ()) -> LPCWSTR -> Ptr PIXEL_RGBA -> CInt -> CInt -> IO ()
foreign import ccall "dynamic"
  mkGetImageResourceTexture2d :: FunPtr (LPCWSTR -> IO (Ptr ())) -> LPCWSTR -> IO (Ptr ())
foreign import ccall "dynamic"
  mkCopyImageResource :: FunPtr (LPCWSTR -> LPCWSTR -> IO BOOL_) -> LPCWSTR -> LPCWSTR -> IO BOOL_
foreign import ccall "dynamic"
  mkClearImageResource :: FunPtr (LPCWSTR -> Word32 -> IO BOOL_) -> LPCWSTR -> Word32 -> IO BOOL_
foreign import ccall "dynamic"
  mkDrawImageToResource :: FunPtr (LPCWSTR -> LPCWSTR -> CFloat -> CFloat -> CFloat -> CFloat -> CFloat -> CFloat -> CFloat -> CFloat -> CFloat -> CFloat -> IO BOOL_) -> LPCWSTR -> LPCWSTR -> CFloat -> CFloat -> CFloat -> CFloat -> CFloat -> CFloat -> CFloat -> CFloat -> CFloat -> CFloat -> IO BOOL_
foreign import ccall "dynamic"
  mkDrawPolyToResource :: FunPtr (LPCWSTR -> VERTEX_TYPE -> Ptr () -> CInt -> LPCWSTR -> IO BOOL_) -> LPCWSTR -> VERTEX_TYPE -> Ptr () -> CInt -> LPCWSTR -> IO BOOL_
foreign import ccall "dynamic"
  mkExecPixelShaderFile :: FunPtr (LPCWSTR -> LPCWSTR -> Ptr LPCWSTR -> CInt -> Ptr () -> CInt -> Ptr () -> Ptr () -> IO BOOL_) -> LPCWSTR -> LPCWSTR -> Ptr LPCWSTR -> CInt -> Ptr () -> CInt -> Ptr () -> Ptr () -> IO BOOL_
foreign import ccall "dynamic"
  mkExecComputeShaderFile :: FunPtr (LPCWSTR -> Ptr LPCWSTR -> CInt -> Ptr LPCWSTR -> CInt -> Ptr () -> CInt -> CInt -> CInt -> CInt -> Ptr () -> IO BOOL_) -> LPCWSTR -> Ptr LPCWSTR -> CInt -> Ptr LPCWSTR -> CInt -> Ptr () -> CInt -> CInt -> CInt -> CInt -> Ptr () -> IO BOOL_
foreign import ccall "dynamic"
  mkGetBlendState :: FunPtr (BLEND_STATE_MODE -> IO (Ptr ())) -> BLEND_STATE_MODE -> IO (Ptr ())
foreign import ccall "dynamic"
  mkGetSamplerState :: FunPtr (SAMPLER_MODE -> IO (Ptr ())) -> SAMPLER_MODE -> IO (Ptr ())
foreign import ccall "dynamic"
  mkExecPixelShaderData :: FunPtr (Ptr Word8 -> CInt -> LPCWSTR -> Ptr LPCWSTR -> CInt -> Ptr () -> CInt -> Ptr () -> Ptr () -> IO BOOL_) -> Ptr Word8 -> CInt -> LPCWSTR -> Ptr LPCWSTR -> CInt -> Ptr () -> CInt -> Ptr () -> Ptr () -> IO BOOL_
foreign import ccall "dynamic"
  mkExecComputeShaderData :: FunPtr (Ptr Word8 -> CInt -> Ptr LPCWSTR -> CInt -> Ptr LPCWSTR -> CInt -> Ptr () -> CInt -> CInt -> CInt -> CInt -> Ptr () -> IO BOOL_) -> Ptr Word8 -> CInt -> Ptr LPCWSTR -> CInt -> Ptr LPCWSTR -> CInt -> Ptr () -> CInt -> CInt -> CInt -> CInt -> Ptr () -> IO BOOL_
foreign import ccall "dynamic"
  mkGetImageResourceSize :: FunPtr (LPCWSTR -> Ptr CInt -> Ptr CInt -> IO BOOL_) -> LPCWSTR -> Ptr CInt -> Ptr CInt -> IO BOOL_
foreign import ccall "dynamic"
  mkGetImageResourceData :: FunPtr (LPCWSTR -> Ptr () -> CInt -> CInt -> CInt -> OUTPUT_PIXEL_FORMAT -> IO BOOL_) -> LPCWSTR -> Ptr () -> CInt -> CInt -> CInt -> OUTPUT_PIXEL_FORMAT -> IO BOOL_
foreign import ccall "dynamic"
  mkSetImageResourceData :: FunPtr (LPCWSTR -> Ptr () -> CInt -> CInt -> CInt -> INPUT_PIXEL_FORMAT -> IO BOOL_) -> LPCWSTR -> Ptr () -> CInt -> CInt -> CInt -> INPUT_PIXEL_FORMAT -> IO BOOL_
foreign import ccall "dynamic"
  mkGetSampleData :: FunPtr (Ptr CFloat -> CInt -> IO ()) -> Ptr CFloat -> CInt -> IO ()
foreign import ccall "dynamic"
  mkSetSampleData :: FunPtr (Ptr CFloat -> CInt -> IO ()) -> Ptr CFloat -> CInt -> IO ()
foreign import ccall "dynamic"
  mkGetOutputAudioParam :: FunPtr (OBJECT_HANDLE -> CDouble -> Ptr OBJECT_AUDIO_PARAM -> CInt -> IO BOOL_) -> OBJECT_HANDLE -> CDouble -> Ptr OBJECT_AUDIO_PARAM -> CInt -> IO BOOL_
foreign import ccall "dynamic"
  mkGetAudioObject :: FunPtr (CInt -> CDouble -> IO OBJECT_HANDLE) -> CInt -> CDouble -> IO OBJECT_HANDLE

getImageData :: Ptr FILTER_PROC_VIDEO -> Ptr PIXEL_RGBA -> IO ()
getImageData ptr buf = peek ptr >>= \v -> mkGetImageData (fpvGetImageData v) buf

setImageData :: Ptr FILTER_PROC_VIDEO -> Ptr PIXEL_RGBA -> CInt -> CInt -> IO ()
setImageData ptr buf w h = peek ptr >>= \v -> mkSetImageData (fpvSetImageData v) buf w h

getImageTexture2d :: Ptr FILTER_PROC_VIDEO -> IO (Ptr ())
getImageTexture2d ptr = peek ptr >>= \v -> mkGetImageTexture2d (fpvGetImageTexture2d v)

getFramebufferTexture2d :: Ptr FILTER_PROC_VIDEO -> IO (Ptr ())
getFramebufferTexture2d ptr = peek ptr >>= \v -> mkGetFramebufferTexture2d (fpvGetFramebufferTexture2d v)

getOutputImageParam :: Ptr FILTER_PROC_VIDEO -> OBJECT_HANDLE -> CDouble -> Ptr OBJECT_IMAGE_PARAM -> CInt -> IO BOOL_
getOutputImageParam ptr obj offset out size = peek ptr >>= \v -> mkGetOutputImageParam (fpvGetOutputImageParam v) obj offset out size

getImageObject :: Ptr FILTER_PROC_VIDEO -> CInt -> CDouble -> IO OBJECT_HANDLE
getImageObject ptr layer offset = peek ptr >>= \v -> mkGetImageObject (fpvGetImageObject v) layer offset

drawImage :: Ptr FILTER_PROC_VIDEO -> LPCWSTR -> CFloat -> CFloat -> CFloat -> CFloat -> CFloat -> CFloat -> CFloat -> CFloat -> CFloat -> CFloat -> IO BOOL_
drawImage ptr resource x y z rx ry rz sx sy sz alpha =
  peek ptr >>= \v -> mkDrawImage (fpvDrawImage v) resource x y z rx ry rz sx sy sz alpha

drawPoly :: Ptr FILTER_PROC_VIDEO -> VERTEX_TYPE -> Ptr () -> CInt -> LPCWSTR -> IO BOOL_
drawPoly ptr vertexType vertices vertexNum resource =
  peek ptr >>= \v -> mkDrawPoly (fpvDrawPoly v) vertexType vertices vertexNum resource

setDefaultAnchor :: Ptr FILTER_PROC_VIDEO -> CInt -> CInt -> IO ()
setDefaultAnchor ptr w h = peek ptr >>= \v -> mkSetDefaultAnchor (fpvSetDefaultAnchor v) w h

setBlendMode :: Ptr FILTER_PROC_VIDEO -> BLEND_MODE -> IO ()
setBlendMode ptr mode = peek ptr >>= \v -> mkSetBlendMode (fpvSetBlendMode v) mode

setMaterialShine :: Ptr FILTER_PROC_VIDEO -> CFloat -> IO ()
setMaterialShine ptr shine = peek ptr >>= \v -> mkSetMaterialShine (fpvSetMaterialShine v) shine

setSamplerMode :: Ptr FILTER_PROC_VIDEO -> SAMPLER_MODE -> IO ()
setSamplerMode ptr mode = peek ptr >>= \v -> mkSetSamplerMode (fpvSetSamplerMode v) mode

setCullingState :: Ptr FILTER_PROC_VIDEO -> BOOL_ -> IO ()
setCullingState ptr culling = peek ptr >>= \v -> mkSetCullingState (fpvSetCullingState v) culling

setBillboardMode :: Ptr FILTER_PROC_VIDEO -> BILLBOARD_MODE -> IO ()
setBillboardMode ptr mode = peek ptr >>= \v -> mkSetBillboardMode (fpvSetBillboardMode v) mode

createImageResource :: Ptr FILTER_PROC_VIDEO -> LPCWSTR -> Ptr PIXEL_RGBA -> CInt -> CInt -> IO ()
createImageResource ptr resource buf w h =
  peek ptr >>= \v -> mkCreateImageResource (fpvCreateImageResource v) resource buf w h

getImageResourceTexture2d :: Ptr FILTER_PROC_VIDEO -> LPCWSTR -> IO (Ptr ())
getImageResourceTexture2d ptr resource =
  peek ptr >>= \v -> mkGetImageResourceTexture2d (fpvGetImageResourceTexture2d v) resource

copyImageResource :: Ptr FILTER_PROC_VIDEO -> LPCWSTR -> LPCWSTR -> IO BOOL_
copyImageResource ptr dst src = peek ptr >>= \v -> mkCopyImageResource (fpvCopyImageResource v) dst src

clearImageResource :: Ptr FILTER_PROC_VIDEO -> LPCWSTR -> PIXEL_RGBA -> IO BOOL_
clearImageResource ptr resource color =
  peek ptr >>= \v -> mkClearImageResource (fpvClearImageResource v) resource (packPixelRGBA color)

-- Windows x86_64 passes a four-byte C struct by value as one integer register.
packPixelRGBA :: PIXEL_RGBA -> Word32
packPixelRGBA (PIXEL_RGBA r g b a) =
  fromIntegral r
    .|. (fromIntegral g `shiftL` 8)
    .|. (fromIntegral b `shiftL` 16)
    .|. (fromIntegral a `shiftL` 24)

drawImageToResource :: Ptr FILTER_PROC_VIDEO -> LPCWSTR -> LPCWSTR -> CFloat -> CFloat -> CFloat -> CFloat -> CFloat -> CFloat -> CFloat -> CFloat -> CFloat -> CFloat -> IO BOOL_
drawImageToResource ptr dst src x y z rx ry rz sx sy sz alpha =
  peek ptr >>= \v -> mkDrawImageToResource (fpvDrawImageToResource v) dst src x y z rx ry rz sx sy sz alpha

drawPolyToResource :: Ptr FILTER_PROC_VIDEO -> LPCWSTR -> VERTEX_TYPE -> Ptr () -> CInt -> LPCWSTR -> IO BOOL_
drawPolyToResource ptr dst vertexType vertices vertexNum src =
  peek ptr >>= \v -> mkDrawPolyToResource (fpvDrawPolyToResource v) dst vertexType vertices vertexNum src

execPixelShaderFile :: Ptr FILTER_PROC_VIDEO -> LPCWSTR -> LPCWSTR -> Ptr LPCWSTR -> CInt -> Ptr () -> CInt -> Ptr () -> Ptr () -> IO BOOL_
execPixelShaderFile ptr cso target resources resourceNum constant constantSize blend sampler =
  peek ptr >>= \v -> mkExecPixelShaderFile (fpvExecPixelShaderFile v) cso target resources resourceNum constant constantSize blend sampler

execComputeShaderFile :: Ptr FILTER_PROC_VIDEO -> LPCWSTR -> Ptr LPCWSTR -> CInt -> Ptr LPCWSTR -> CInt -> Ptr () -> CInt -> CInt -> CInt -> CInt -> Ptr () -> IO BOOL_
execComputeShaderFile ptr cso targets targetNum resources resourceNum constant constantSize countX countY countZ sampler =
  peek ptr >>= \v -> mkExecComputeShaderFile (fpvExecComputeShaderFile v) cso targets targetNum resources resourceNum constant constantSize countX countY countZ sampler

getBlendState :: Ptr FILTER_PROC_VIDEO -> BLEND_STATE_MODE -> IO (Ptr ())
getBlendState ptr mode = peek ptr >>= \v -> mkGetBlendState (fpvGetBlendState v) mode

getSamplerState :: Ptr FILTER_PROC_VIDEO -> SAMPLER_MODE -> IO (Ptr ())
getSamplerState ptr mode = peek ptr >>= \v -> mkGetSamplerState (fpvGetSamplerState v) mode

execPixelShaderData :: Ptr FILTER_PROC_VIDEO -> Ptr Word8 -> CInt -> LPCWSTR -> Ptr LPCWSTR -> CInt -> Ptr () -> CInt -> Ptr () -> Ptr () -> IO BOOL_
execPixelShaderData ptr dat size target resources resourceNum constant constantSize blend sampler =
  peek ptr >>= \v -> mkExecPixelShaderData (fpvExecPixelShaderData v) dat size target resources resourceNum constant constantSize blend sampler

execComputeShaderData :: Ptr FILTER_PROC_VIDEO -> Ptr Word8 -> CInt -> Ptr LPCWSTR -> CInt -> Ptr LPCWSTR -> CInt -> Ptr () -> CInt -> CInt -> CInt -> CInt -> Ptr () -> IO BOOL_
execComputeShaderData ptr dat size targets targetNum resources resourceNum constant constantSize countX countY countZ sampler =
  peek ptr >>= \v -> mkExecComputeShaderData (fpvExecComputeShaderData v) dat size targets targetNum resources resourceNum constant constantSize countX countY countZ sampler

getImageResourceSize :: Ptr FILTER_PROC_VIDEO -> LPCWSTR -> Ptr CInt -> Ptr CInt -> IO BOOL_
getImageResourceSize ptr resource w h =
  peek ptr >>= \v -> mkGetImageResourceSize (fpvGetImageResourceSize v) resource w h

getImageResourceData :: Ptr FILTER_PROC_VIDEO -> LPCWSTR -> Ptr () -> CInt -> CInt -> CInt -> OUTPUT_PIXEL_FORMAT -> IO BOOL_
getImageResourceData ptr resource buf w h pitch format =
  peek ptr >>= \v -> mkGetImageResourceData (fpvGetImageResourceData v) resource buf w h pitch format

setImageResourceData :: Ptr FILTER_PROC_VIDEO -> LPCWSTR -> Ptr () -> CInt -> CInt -> CInt -> INPUT_PIXEL_FORMAT -> IO BOOL_
setImageResourceData ptr resource buf w h pitch format =
  peek ptr >>= \v -> mkSetImageResourceData (fpvSetImageResourceData v) resource buf w h pitch format

getSampleData :: Ptr FILTER_PROC_AUDIO -> Ptr CFloat -> CInt -> IO ()
getSampleData ptr buf ch = peek ptr >>= \a -> mkGetSampleData (fpaGetSampleData a) buf ch

setSampleData :: Ptr FILTER_PROC_AUDIO -> Ptr CFloat -> CInt -> IO ()
setSampleData ptr buf ch = peek ptr >>= \a -> mkSetSampleData (fpaSetSampleData a) buf ch

getOutputAudioParam :: Ptr FILTER_PROC_AUDIO -> OBJECT_HANDLE -> CDouble -> Ptr OBJECT_AUDIO_PARAM -> CInt -> IO BOOL_
getOutputAudioParam ptr obj offset out size =
  peek ptr >>= \a -> mkGetOutputAudioParam (fpaGetOutputAudioParam a) obj offset out size

getAudioObject :: Ptr FILTER_PROC_AUDIO -> CInt -> CDouble -> IO OBJECT_HANDLE
getAudioObject ptr layer offset = peek ptr >>= \a -> mkGetAudioObject (fpaGetAudioObject a) layer offset
