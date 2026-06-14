{-|
Module      : AviUtl2.Edit
Description : AviUtl2の編集ハンドル、編集セクション、プロジェクト保存領域を扱うAPIです。

このモジュールは @plugin2.h@ の編集関連構造体をHaskell FFI向けに
移した低水準バインディングです。
-}
module AviUtl2.Edit
  ( EDIT_SECTION(..)
  , EDIT_HANDLE_STRUCT(..)
  , EDIT_HANDLE
  , PROJECT_FILE(..)
  , EFFECT_ITEM_TYPE
  , effectItemTypeInteger
  , effectItemTypeNumber
  , effectItemTypeCheck
  , effectItemTypeText
  , effectItemTypeString
  , effectItemTypeFile
  , effectItemTypeColor
  , effectItemTypeSelect
  , effectItemTypeScene
  , effectItemTypeRange
  , effectItemTypeCombo
  , effectItemTypeMask
  , effectItemTypeFont
  , effectItemTypeFigure
  , effectItemTypeData
  , effectItemTypeFolder
  , callEditSection
  , callEditSectionParam
  , callReadSection
  , callReadSectionParam
  , getEditInfoFromHandle
  , getEditInfo
  , restartHostApp
  , enumEffectName
  , enumEffectItem
  , enumModuleInfo
  , renderingSceneVideo
  , renderingSceneAudio
  , waitRenderingTask
  , enumFontName
  , enumPaletteName
  , getHostAppWindow
  , getEditState
  , createObjectFromAlias
  , findObject
  , countObjectEffect
  , getObjectLayerFrame
  , getObjectAlias
  , getObjectItemValue
  , setObjectItemValue
  , moveObject
  , deleteObject
  , getFocusObject
  , setFocusObject
  , getProjectFile
  , getSelectedObject
  , getSelectedObjectNum
  , getMouseLayerFrame
  , posToLayerFrame
  , isSupportMediaFile
  , getMediaInfo
  , createObjectFromMediaFile
  , createObject
  , setCursorLayerFrame
  , setDisplayLayerFrame
  , setSelectRange
  , setGridBpm
  , getObjectName
  , setObjectName
  , getLayerName
  , setLayerName
  , getSceneName
  , setSceneName
  , setSceneSize
  , setSceneFrameRate
  , setSceneSampleRate
  , getLayerEnable
  , setLayerEnable
  , getLayerLock
  , setLayerLock
  , getObjectSectionNum
  , getFocusObjectSection
  , getObjectSectionFrame
  , getObjectTrackValue
  , getObjectCheckValue
  , getObjectTrackInfo
  , getPaletteName
  , getPaletteInfo
  , pfGetParamString
  , pfSetParamString
  , pfGetParamBinary
  , pfSetParamBinary
  , pfClearParams
  , pfGetProjectFilePath
  ) where

import Foreign.C.Types (CBool(..), CDouble(..), CFloat(..), CInt(..))
import Foreign.Marshal.Alloc (alloca)
import Foreign.Ptr (FunPtr, Ptr)
import Foreign.Storable (Storable(..))

import AviUtl2.Types
  ( BOOL_
  , EDIT_INFO
  , HWND
  , LPCSTR
  , LPCWSTR
  , MEDIA_INFO
  , MODULE_INFO
  , OBJECT_HANDLE
  , OBJECT_LAYER_FRAME
  , PALETTE_INFO
  , TRACK_INFO
  )

type EFFECT_ITEM_TYPE = CInt

effectItemTypeInteger, effectItemTypeNumber, effectItemTypeCheck, effectItemTypeText :: EFFECT_ITEM_TYPE
effectItemTypeString, effectItemTypeFile, effectItemTypeColor, effectItemTypeSelect :: EFFECT_ITEM_TYPE
effectItemTypeScene, effectItemTypeRange, effectItemTypeCombo, effectItemTypeMask :: EFFECT_ITEM_TYPE
effectItemTypeFont, effectItemTypeFigure, effectItemTypeData, effectItemTypeFolder :: EFFECT_ITEM_TYPE
effectItemTypeInteger = 1
effectItemTypeNumber = 2
effectItemTypeCheck = 3
effectItemTypeText = 4
effectItemTypeString = 5
effectItemTypeFile = 6
effectItemTypeColor = 7
effectItemTypeSelect = 8
effectItemTypeScene = 9
effectItemTypeRange = 10
effectItemTypeCombo = 11
effectItemTypeMask = 12
effectItemTypeFont = 13
effectItemTypeFigure = 14
effectItemTypeData = 15
effectItemTypeFolder = 16

data EDIT_HANDLE_STRUCT = EDIT_HANDLE_STRUCT
  { ehsCallEditSection        :: FunPtr (FunPtr (Ptr EDIT_SECTION -> IO ()) -> IO BOOL_)
  , ehsCallEditSectionParam   :: FunPtr (Ptr () -> FunPtr (Ptr () -> Ptr EDIT_SECTION -> IO ()) -> IO BOOL_)
  , ehsGetEditInfo            :: FunPtr (Ptr EDIT_INFO -> CInt -> IO ())
  , ehsRestartHostApp         :: FunPtr (IO ())
  , ehsEnumEffectName         :: FunPtr (Ptr () -> FunPtr (Ptr () -> LPCWSTR -> CInt -> CInt -> IO ()) -> IO ())
  , ehsEnumModuleInfo         :: FunPtr (Ptr () -> FunPtr (Ptr () -> Ptr MODULE_INFO -> IO ()) -> IO ())
  , ehsGetHostAppWindow       :: FunPtr (IO HWND)
  , ehsGetEditState           :: FunPtr (IO CInt)
  , ehsCallReadSection        :: FunPtr (FunPtr (Ptr EDIT_SECTION -> IO ()) -> IO BOOL_)
  , ehsCallReadSectionParam   :: FunPtr (Ptr () -> FunPtr (Ptr () -> Ptr EDIT_SECTION -> IO ()) -> IO BOOL_)
  , ehsEnumEffectItem         :: FunPtr (LPCWSTR -> Ptr () -> FunPtr (Ptr () -> LPCWSTR -> CInt -> IO ()) -> IO BOOL_)
  , ehsRenderingSceneVideo    :: FunPtr (CInt -> Ptr () -> FunPtr (Ptr () -> CInt -> Ptr () -> CInt -> CInt -> CInt -> IO ()) -> IO BOOL_)
  , ehsRenderingSceneAudio    :: FunPtr (CInt -> Ptr () -> FunPtr (Ptr () -> CInt -> Ptr CFloat -> Ptr CFloat -> CInt -> IO ()) -> IO BOOL_)
  , ehsWaitRenderingTask      :: FunPtr (IO ())
  , ehsEnumFontName           :: FunPtr (Ptr () -> FunPtr (Ptr () -> LPCWSTR -> IO ()) -> IO ())
  , ehsEnumPaletteName        :: FunPtr (Ptr () -> FunPtr (Ptr () -> LPCWSTR -> IO ()) -> IO ())
  }

type EDIT_HANDLE = Ptr EDIT_HANDLE_STRUCT

instance Storable EDIT_HANDLE_STRUCT where
  sizeOf _ = 128
  alignment _ = 8
  peek ptr = EDIT_HANDLE_STRUCT
    <$> peekByteOff ptr 0 <*> peekByteOff ptr 8 <*> peekByteOff ptr 16 <*> peekByteOff ptr 24
    <*> peekByteOff ptr 32 <*> peekByteOff ptr 40 <*> peekByteOff ptr 48 <*> peekByteOff ptr 56
    <*> peekByteOff ptr 64 <*> peekByteOff ptr 72 <*> peekByteOff ptr 80 <*> peekByteOff ptr 88
    <*> peekByteOff ptr 96 <*> peekByteOff ptr 104 <*> peekByteOff ptr 112 <*> peekByteOff ptr 120
  poke ptr v = do
    pokeByteOff ptr 0 (ehsCallEditSection v)
    pokeByteOff ptr 8 (ehsCallEditSectionParam v)
    pokeByteOff ptr 16 (ehsGetEditInfo v)
    pokeByteOff ptr 24 (ehsRestartHostApp v)
    pokeByteOff ptr 32 (ehsEnumEffectName v)
    pokeByteOff ptr 40 (ehsEnumModuleInfo v)
    pokeByteOff ptr 48 (ehsGetHostAppWindow v)
    pokeByteOff ptr 56 (ehsGetEditState v)
    pokeByteOff ptr 64 (ehsCallReadSection v)
    pokeByteOff ptr 72 (ehsCallReadSectionParam v)
    pokeByteOff ptr 80 (ehsEnumEffectItem v)
    pokeByteOff ptr 88 (ehsRenderingSceneVideo v)
    pokeByteOff ptr 96 (ehsRenderingSceneAudio v)
    pokeByteOff ptr 104 (ehsWaitRenderingTask v)
    pokeByteOff ptr 112 (ehsEnumFontName v)
    pokeByteOff ptr 120 (ehsEnumPaletteName v)

data PROJECT_FILE = PROJECT_FILE
  { pfFuncGetParamString     :: FunPtr (LPCSTR -> IO LPCSTR)
  , pfFuncSetParamString     :: FunPtr (LPCSTR -> LPCSTR -> IO ())
  , pfFuncGetParamBinary     :: FunPtr (LPCSTR -> Ptr () -> CInt -> IO BOOL_)
  , pfFuncSetParamBinary     :: FunPtr (LPCSTR -> Ptr () -> CInt -> IO ())
  , pfFuncClearParams        :: FunPtr (IO ())
  , pfFuncGetProjectFilePath :: FunPtr (IO LPCWSTR)
  }

instance Storable PROJECT_FILE where
  sizeOf _ = 48
  alignment _ = 8
  peek ptr = PROJECT_FILE
    <$> peekByteOff ptr 0 <*> peekByteOff ptr 8 <*> peekByteOff ptr 16
    <*> peekByteOff ptr 24 <*> peekByteOff ptr 32 <*> peekByteOff ptr 40
  poke ptr v = do
    pokeByteOff ptr 0 (pfFuncGetParamString v)
    pokeByteOff ptr 8 (pfFuncSetParamString v)
    pokeByteOff ptr 16 (pfFuncGetParamBinary v)
    pokeByteOff ptr 24 (pfFuncSetParamBinary v)
    pokeByteOff ptr 32 (pfFuncClearParams v)
    pokeByteOff ptr 40 (pfFuncGetProjectFilePath v)

data EDIT_SECTION = EDIT_SECTION
  { esInfo                      :: Ptr EDIT_INFO
  , esCreateObjectFromAlias     :: FunPtr (LPCSTR -> CInt -> CInt -> CInt -> IO OBJECT_HANDLE)
  , esFindObject                :: FunPtr (CInt -> CInt -> IO OBJECT_HANDLE)
  , esCountObjectEffect         :: FunPtr (OBJECT_HANDLE -> LPCWSTR -> IO CInt)
  , esGetObjectLayerFrame       :: FunPtr (Ptr OBJECT_LAYER_FRAME -> OBJECT_HANDLE -> IO ())
  , esGetObjectAlias            :: FunPtr (OBJECT_HANDLE -> IO LPCSTR)
  , esGetObjectItemValue        :: FunPtr (OBJECT_HANDLE -> LPCWSTR -> LPCWSTR -> IO LPCSTR)
  , esSetObjectItemValue        :: FunPtr (OBJECT_HANDLE -> LPCWSTR -> LPCWSTR -> LPCSTR -> IO BOOL_)
  , esMoveObject                :: FunPtr (OBJECT_HANDLE -> CInt -> CInt -> IO BOOL_)
  , esDeleteObject              :: FunPtr (OBJECT_HANDLE -> IO ())
  , esGetFocusObject            :: FunPtr (IO OBJECT_HANDLE)
  , esSetFocusObject            :: FunPtr (OBJECT_HANDLE -> IO ())
  , esGetProjectFile            :: FunPtr (EDIT_HANDLE -> IO (Ptr PROJECT_FILE))
  , esGetSelectedObject         :: FunPtr (CInt -> IO OBJECT_HANDLE)
  , esGetSelectedObjectNum      :: FunPtr (IO CInt)
  , esGetMouseLayerFrame        :: FunPtr (Ptr CInt -> Ptr CInt -> IO BOOL_)
  , esPosToLayerFrame           :: FunPtr (CInt -> CInt -> Ptr CInt -> Ptr CInt -> IO BOOL_)
  , esIsSupportMediaFile        :: FunPtr (LPCWSTR -> BOOL_ -> IO BOOL_)
  , esGetMediaInfo              :: FunPtr (LPCWSTR -> Ptr MEDIA_INFO -> CInt -> IO BOOL_)
  , esCreateObjectFromMediaFile :: FunPtr (LPCWSTR -> CInt -> CInt -> CInt -> IO OBJECT_HANDLE)
  , esCreateObject              :: FunPtr (LPCWSTR -> CInt -> CInt -> CInt -> IO OBJECT_HANDLE)
  , esSetCursorLayerFrame       :: FunPtr (CInt -> CInt -> IO ())
  , esSetDisplayLayerFrame      :: FunPtr (CInt -> CInt -> IO ())
  , esSetSelectRange            :: FunPtr (CInt -> CInt -> IO ())
  , esSetGridBpm                :: FunPtr (CFloat -> CInt -> CFloat -> IO ())
  , esGetObjectName             :: FunPtr (OBJECT_HANDLE -> IO LPCWSTR)
  , esSetObjectName             :: FunPtr (OBJECT_HANDLE -> LPCWSTR -> IO ())
  , esGetLayerName              :: FunPtr (CInt -> IO LPCWSTR)
  , esSetLayerName              :: FunPtr (CInt -> LPCWSTR -> IO ())
  , esGetSceneName              :: FunPtr (IO LPCWSTR)
  , esSetSceneName              :: FunPtr (LPCWSTR -> IO ())
  , esSetSceneSize              :: FunPtr (CInt -> CInt -> IO ())
  , esSetSceneFrameRate         :: FunPtr (CInt -> CInt -> IO ())
  , esSetSceneSampleRate        :: FunPtr (CInt -> IO ())
  , esGetLayerEnable            :: FunPtr (CInt -> IO BOOL_)
  , esSetLayerEnable            :: FunPtr (CInt -> BOOL_ -> IO ())
  , esGetLayerLock              :: FunPtr (CInt -> IO BOOL_)
  , esSetLayerLock              :: FunPtr (CInt -> BOOL_ -> IO ())
  , esGetObjectSectionNum       :: FunPtr (OBJECT_HANDLE -> IO CInt)
  , esGetFocusObjectSection     :: FunPtr (IO CInt)
  , esGetObjectSectionFrame     :: FunPtr (OBJECT_HANDLE -> CInt -> IO CInt)
  , esGetObjectTrackValue       :: FunPtr (OBJECT_HANDLE -> LPCWSTR -> LPCWSTR -> CDouble -> Ptr CDouble -> IO BOOL_)
  , esGetObjectCheckValue       :: FunPtr (OBJECT_HANDLE -> LPCWSTR -> LPCWSTR -> CInt -> Ptr BOOL_ -> IO BOOL_)
  , esGetObjectTrackInfo        :: FunPtr (OBJECT_HANDLE -> LPCWSTR -> LPCWSTR -> Ptr TRACK_INFO -> CInt -> IO BOOL_)
  , esGetPaletteName            :: FunPtr (IO LPCWSTR)
  , esGetPaletteInfo            :: FunPtr (LPCWSTR -> Ptr PALETTE_INFO -> CInt -> IO BOOL_)
  }

instance Storable EDIT_SECTION where
  sizeOf _ = 368
  alignment _ = 8
  peek ptr = EDIT_SECTION
    <$> peekByteOff ptr 0 <*> peekByteOff ptr 8 <*> peekByteOff ptr 16 <*> peekByteOff ptr 24
    <*> peekByteOff ptr 32 <*> peekByteOff ptr 40 <*> peekByteOff ptr 48 <*> peekByteOff ptr 56
    <*> peekByteOff ptr 64 <*> peekByteOff ptr 72 <*> peekByteOff ptr 80 <*> peekByteOff ptr 88
    <*> peekByteOff ptr 96 <*> peekByteOff ptr 104 <*> peekByteOff ptr 112 <*> peekByteOff ptr 120
    <*> peekByteOff ptr 128 <*> peekByteOff ptr 136 <*> peekByteOff ptr 144 <*> peekByteOff ptr 152
    <*> peekByteOff ptr 160 <*> peekByteOff ptr 168 <*> peekByteOff ptr 176 <*> peekByteOff ptr 184
    <*> peekByteOff ptr 192 <*> peekByteOff ptr 200 <*> peekByteOff ptr 208 <*> peekByteOff ptr 216
    <*> peekByteOff ptr 224 <*> peekByteOff ptr 232 <*> peekByteOff ptr 240 <*> peekByteOff ptr 248
    <*> peekByteOff ptr 256 <*> peekByteOff ptr 264 <*> peekByteOff ptr 272 <*> peekByteOff ptr 280
    <*> peekByteOff ptr 288 <*> peekByteOff ptr 296 <*> peekByteOff ptr 304 <*> peekByteOff ptr 312
    <*> peekByteOff ptr 320 <*> peekByteOff ptr 328 <*> peekByteOff ptr 336 <*> peekByteOff ptr 344
    <*> peekByteOff ptr 352 <*> peekByteOff ptr 360
  poke ptr v = do
    pokeByteOff ptr 0 (esInfo v)
    pokeByteOff ptr 8 (esCreateObjectFromAlias v)
    pokeByteOff ptr 16 (esFindObject v)
    pokeByteOff ptr 24 (esCountObjectEffect v)
    pokeByteOff ptr 32 (esGetObjectLayerFrame v)
    pokeByteOff ptr 40 (esGetObjectAlias v)
    pokeByteOff ptr 48 (esGetObjectItemValue v)
    pokeByteOff ptr 56 (esSetObjectItemValue v)
    pokeByteOff ptr 64 (esMoveObject v)
    pokeByteOff ptr 72 (esDeleteObject v)
    pokeByteOff ptr 80 (esGetFocusObject v)
    pokeByteOff ptr 88 (esSetFocusObject v)
    pokeByteOff ptr 96 (esGetProjectFile v)
    pokeByteOff ptr 104 (esGetSelectedObject v)
    pokeByteOff ptr 112 (esGetSelectedObjectNum v)
    pokeByteOff ptr 120 (esGetMouseLayerFrame v)
    pokeByteOff ptr 128 (esPosToLayerFrame v)
    pokeByteOff ptr 136 (esIsSupportMediaFile v)
    pokeByteOff ptr 144 (esGetMediaInfo v)
    pokeByteOff ptr 152 (esCreateObjectFromMediaFile v)
    pokeByteOff ptr 160 (esCreateObject v)
    pokeByteOff ptr 168 (esSetCursorLayerFrame v)
    pokeByteOff ptr 176 (esSetDisplayLayerFrame v)
    pokeByteOff ptr 184 (esSetSelectRange v)
    pokeByteOff ptr 192 (esSetGridBpm v)
    pokeByteOff ptr 200 (esGetObjectName v)
    pokeByteOff ptr 208 (esSetObjectName v)
    pokeByteOff ptr 216 (esGetLayerName v)
    pokeByteOff ptr 224 (esSetLayerName v)
    pokeByteOff ptr 232 (esGetSceneName v)
    pokeByteOff ptr 240 (esSetSceneName v)
    pokeByteOff ptr 248 (esSetSceneSize v)
    pokeByteOff ptr 256 (esSetSceneFrameRate v)
    pokeByteOff ptr 264 (esSetSceneSampleRate v)
    pokeByteOff ptr 272 (esGetLayerEnable v)
    pokeByteOff ptr 280 (esSetLayerEnable v)
    pokeByteOff ptr 288 (esGetLayerLock v)
    pokeByteOff ptr 296 (esSetLayerLock v)
    pokeByteOff ptr 304 (esGetObjectSectionNum v)
    pokeByteOff ptr 312 (esGetFocusObjectSection v)
    pokeByteOff ptr 320 (esGetObjectSectionFrame v)
    pokeByteOff ptr 328 (esGetObjectTrackValue v)
    pokeByteOff ptr 336 (esGetObjectCheckValue v)
    pokeByteOff ptr 344 (esGetObjectTrackInfo v)
    pokeByteOff ptr 352 (esGetPaletteName v)
    pokeByteOff ptr 360 (esGetPaletteInfo v)

foreign import ccall safe "dynamic"
  mkCallEditSection :: FunPtr (FunPtr (Ptr EDIT_SECTION -> IO ()) -> IO BOOL_) -> FunPtr (Ptr EDIT_SECTION -> IO ()) -> IO BOOL_
foreign import ccall safe "dynamic"
  mkCallEditSectionParam :: FunPtr (Ptr () -> FunPtr (Ptr () -> Ptr EDIT_SECTION -> IO ()) -> IO BOOL_) -> Ptr () -> FunPtr (Ptr () -> Ptr EDIT_SECTION -> IO ()) -> IO BOOL_
foreign import ccall safe "dynamic"
  mkCallReadSection :: FunPtr (FunPtr (Ptr EDIT_SECTION -> IO ()) -> IO BOOL_) -> FunPtr (Ptr EDIT_SECTION -> IO ()) -> IO BOOL_
foreign import ccall safe "dynamic"
  mkCallReadSectionParam :: FunPtr (Ptr () -> FunPtr (Ptr () -> Ptr EDIT_SECTION -> IO ()) -> IO BOOL_) -> Ptr () -> FunPtr (Ptr () -> Ptr EDIT_SECTION -> IO ()) -> IO BOOL_
foreign import ccall "dynamic"
  mkGetEditInfo :: FunPtr (Ptr EDIT_INFO -> CInt -> IO ()) -> Ptr EDIT_INFO -> CInt -> IO ()
foreign import ccall "dynamic"
  mkRestartHostApp :: FunPtr (IO ()) -> IO ()
foreign import ccall safe "dynamic"
  mkEnumEffectName :: FunPtr (Ptr () -> FunPtr (Ptr () -> LPCWSTR -> CInt -> CInt -> IO ()) -> IO ()) -> Ptr () -> FunPtr (Ptr () -> LPCWSTR -> CInt -> CInt -> IO ()) -> IO ()
foreign import ccall safe "dynamic"
  mkEnumEffectItem :: FunPtr (LPCWSTR -> Ptr () -> FunPtr (Ptr () -> LPCWSTR -> CInt -> IO ()) -> IO BOOL_) -> LPCWSTR -> Ptr () -> FunPtr (Ptr () -> LPCWSTR -> CInt -> IO ()) -> IO BOOL_
foreign import ccall safe "dynamic"
  mkEnumModuleInfo :: FunPtr (Ptr () -> FunPtr (Ptr () -> Ptr MODULE_INFO -> IO ()) -> IO ()) -> Ptr () -> FunPtr (Ptr () -> Ptr MODULE_INFO -> IO ()) -> IO ()
foreign import ccall "dynamic"
  mkRenderingSceneVideo :: FunPtr (CInt -> Ptr () -> FunPtr (Ptr () -> CInt -> Ptr () -> CInt -> CInt -> CInt -> IO ()) -> IO BOOL_) -> CInt -> Ptr () -> FunPtr (Ptr () -> CInt -> Ptr () -> CInt -> CInt -> CInt -> IO ()) -> IO BOOL_
foreign import ccall "dynamic"
  mkRenderingSceneAudio :: FunPtr (CInt -> Ptr () -> FunPtr (Ptr () -> CInt -> Ptr CFloat -> Ptr CFloat -> CInt -> IO ()) -> IO BOOL_) -> CInt -> Ptr () -> FunPtr (Ptr () -> CInt -> Ptr CFloat -> Ptr CFloat -> CInt -> IO ()) -> IO BOOL_
foreign import ccall "dynamic"
  mkWaitRenderingTask :: FunPtr (IO ()) -> IO ()
foreign import ccall safe "dynamic"
  mkEnumFontName :: FunPtr (Ptr () -> FunPtr (Ptr () -> LPCWSTR -> IO ()) -> IO ()) -> Ptr () -> FunPtr (Ptr () -> LPCWSTR -> IO ()) -> IO ()
foreign import ccall safe "dynamic"
  mkEnumPaletteName :: FunPtr (Ptr () -> FunPtr (Ptr () -> LPCWSTR -> IO ()) -> IO ()) -> Ptr () -> FunPtr (Ptr () -> LPCWSTR -> IO ()) -> IO ()
foreign import ccall "dynamic"
  mkGetHostAppWindow :: FunPtr (IO HWND) -> IO HWND
foreign import ccall "dynamic"
  mkGetEditState :: FunPtr (IO CInt) -> IO CInt
foreign import ccall "dynamic"
  mkCreateObjectFromAlias :: FunPtr (LPCSTR -> CInt -> CInt -> CInt -> IO OBJECT_HANDLE) -> LPCSTR -> CInt -> CInt -> CInt -> IO OBJECT_HANDLE
foreign import ccall "dynamic"
  mkFindObject :: FunPtr (CInt -> CInt -> IO OBJECT_HANDLE) -> CInt -> CInt -> IO OBJECT_HANDLE
foreign import ccall "dynamic"
  mkCountObjectEffect :: FunPtr (OBJECT_HANDLE -> LPCWSTR -> IO CInt) -> OBJECT_HANDLE -> LPCWSTR -> IO CInt
foreign import ccall "dynamic"
  mkGetObjectLayerFrame :: FunPtr (Ptr OBJECT_LAYER_FRAME -> OBJECT_HANDLE -> IO ()) -> Ptr OBJECT_LAYER_FRAME -> OBJECT_HANDLE -> IO ()
foreign import ccall "dynamic"
  mkGetObjectAlias :: FunPtr (OBJECT_HANDLE -> IO LPCSTR) -> OBJECT_HANDLE -> IO LPCSTR
foreign import ccall "dynamic"
  mkGetObjectItemValue :: FunPtr (OBJECT_HANDLE -> LPCWSTR -> LPCWSTR -> IO LPCSTR) -> OBJECT_HANDLE -> LPCWSTR -> LPCWSTR -> IO LPCSTR
foreign import ccall "dynamic"
  mkSetObjectItemValue :: FunPtr (OBJECT_HANDLE -> LPCWSTR -> LPCWSTR -> LPCSTR -> IO BOOL_) -> OBJECT_HANDLE -> LPCWSTR -> LPCWSTR -> LPCSTR -> IO BOOL_
foreign import ccall "dynamic"
  mkMoveObject :: FunPtr (OBJECT_HANDLE -> CInt -> CInt -> IO BOOL_) -> OBJECT_HANDLE -> CInt -> CInt -> IO BOOL_
foreign import ccall "dynamic"
  mkDeleteObject :: FunPtr (OBJECT_HANDLE -> IO ()) -> OBJECT_HANDLE -> IO ()
foreign import ccall "dynamic"
  mkGetFocusObject :: FunPtr (IO OBJECT_HANDLE) -> IO OBJECT_HANDLE
foreign import ccall "dynamic"
  mkSetFocusObject :: FunPtr (OBJECT_HANDLE -> IO ()) -> OBJECT_HANDLE -> IO ()
foreign import ccall "dynamic"
  mkGetProjectFile :: FunPtr (EDIT_HANDLE -> IO (Ptr PROJECT_FILE)) -> EDIT_HANDLE -> IO (Ptr PROJECT_FILE)
foreign import ccall "dynamic"
  mkGetSelectedObject :: FunPtr (CInt -> IO OBJECT_HANDLE) -> CInt -> IO OBJECT_HANDLE
foreign import ccall "dynamic"
  mkGetSelectedObjectNum :: FunPtr (IO CInt) -> IO CInt
foreign import ccall "dynamic"
  mkGetMouseLayerFrame :: FunPtr (Ptr CInt -> Ptr CInt -> IO BOOL_) -> Ptr CInt -> Ptr CInt -> IO BOOL_
foreign import ccall "dynamic"
  mkPosToLayerFrame :: FunPtr (CInt -> CInt -> Ptr CInt -> Ptr CInt -> IO BOOL_) -> CInt -> CInt -> Ptr CInt -> Ptr CInt -> IO BOOL_
foreign import ccall "dynamic"
  mkIsSupportMediaFile :: FunPtr (LPCWSTR -> BOOL_ -> IO BOOL_) -> LPCWSTR -> BOOL_ -> IO BOOL_
foreign import ccall "dynamic"
  mkGetMediaInfo :: FunPtr (LPCWSTR -> Ptr MEDIA_INFO -> CInt -> IO BOOL_) -> LPCWSTR -> Ptr MEDIA_INFO -> CInt -> IO BOOL_
foreign import ccall "dynamic"
  mkCreateObjectFromMediaFile :: FunPtr (LPCWSTR -> CInt -> CInt -> CInt -> IO OBJECT_HANDLE) -> LPCWSTR -> CInt -> CInt -> CInt -> IO OBJECT_HANDLE
foreign import ccall "dynamic"
  mkCreateObject :: FunPtr (LPCWSTR -> CInt -> CInt -> CInt -> IO OBJECT_HANDLE) -> LPCWSTR -> CInt -> CInt -> CInt -> IO OBJECT_HANDLE
foreign import ccall "dynamic"
  mkSetCursorLayerFrame :: FunPtr (CInt -> CInt -> IO ()) -> CInt -> CInt -> IO ()
foreign import ccall "dynamic"
  mkSetDisplayLayerFrame :: FunPtr (CInt -> CInt -> IO ()) -> CInt -> CInt -> IO ()
foreign import ccall "dynamic"
  mkSetSelectRange :: FunPtr (CInt -> CInt -> IO ()) -> CInt -> CInt -> IO ()
foreign import ccall "dynamic"
  mkSetGridBpm :: FunPtr (CFloat -> CInt -> CFloat -> IO ()) -> CFloat -> CInt -> CFloat -> IO ()
foreign import ccall "dynamic"
  mkGetObjectName :: FunPtr (OBJECT_HANDLE -> IO LPCWSTR) -> OBJECT_HANDLE -> IO LPCWSTR
foreign import ccall "dynamic"
  mkSetObjectName :: FunPtr (OBJECT_HANDLE -> LPCWSTR -> IO ()) -> OBJECT_HANDLE -> LPCWSTR -> IO ()
foreign import ccall "dynamic"
  mkGetLayerName :: FunPtr (CInt -> IO LPCWSTR) -> CInt -> IO LPCWSTR
foreign import ccall "dynamic"
  mkSetLayerName :: FunPtr (CInt -> LPCWSTR -> IO ()) -> CInt -> LPCWSTR -> IO ()
foreign import ccall "dynamic"
  mkGetSceneName :: FunPtr (IO LPCWSTR) -> IO LPCWSTR
foreign import ccall "dynamic"
  mkSetSceneName :: FunPtr (LPCWSTR -> IO ()) -> LPCWSTR -> IO ()
foreign import ccall "dynamic"
  mkSetSceneSize :: FunPtr (CInt -> CInt -> IO ()) -> CInt -> CInt -> IO ()
foreign import ccall "dynamic"
  mkSetSceneFrameRate :: FunPtr (CInt -> CInt -> IO ()) -> CInt -> CInt -> IO ()
foreign import ccall "dynamic"
  mkSetSceneSampleRate :: FunPtr (CInt -> IO ()) -> CInt -> IO ()
foreign import ccall "dynamic"
  mkGetLayerEnable :: FunPtr (CInt -> IO BOOL_) -> CInt -> IO BOOL_
foreign import ccall "dynamic"
  mkSetLayerEnable :: FunPtr (CInt -> BOOL_ -> IO ()) -> CInt -> BOOL_ -> IO ()
foreign import ccall "dynamic"
  mkGetLayerLock :: FunPtr (CInt -> IO BOOL_) -> CInt -> IO BOOL_
foreign import ccall "dynamic"
  mkSetLayerLock :: FunPtr (CInt -> BOOL_ -> IO ()) -> CInt -> BOOL_ -> IO ()
foreign import ccall "dynamic"
  mkGetObjectSectionNum :: FunPtr (OBJECT_HANDLE -> IO CInt) -> OBJECT_HANDLE -> IO CInt
foreign import ccall "dynamic"
  mkGetFocusObjectSection :: FunPtr (IO CInt) -> IO CInt
foreign import ccall "dynamic"
  mkGetObjectSectionFrame :: FunPtr (OBJECT_HANDLE -> CInt -> IO CInt) -> OBJECT_HANDLE -> CInt -> IO CInt
foreign import ccall "dynamic"
  mkGetObjectTrackValue :: FunPtr (OBJECT_HANDLE -> LPCWSTR -> LPCWSTR -> CDouble -> Ptr CDouble -> IO BOOL_) -> OBJECT_HANDLE -> LPCWSTR -> LPCWSTR -> CDouble -> Ptr CDouble -> IO BOOL_
foreign import ccall "dynamic"
  mkGetObjectCheckValue :: FunPtr (OBJECT_HANDLE -> LPCWSTR -> LPCWSTR -> CInt -> Ptr BOOL_ -> IO BOOL_) -> OBJECT_HANDLE -> LPCWSTR -> LPCWSTR -> CInt -> Ptr BOOL_ -> IO BOOL_
foreign import ccall "dynamic"
  mkGetObjectTrackInfo :: FunPtr (OBJECT_HANDLE -> LPCWSTR -> LPCWSTR -> Ptr TRACK_INFO -> CInt -> IO BOOL_) -> OBJECT_HANDLE -> LPCWSTR -> LPCWSTR -> Ptr TRACK_INFO -> CInt -> IO BOOL_
foreign import ccall "dynamic"
  mkGetPaletteName :: FunPtr (IO LPCWSTR) -> IO LPCWSTR
foreign import ccall "dynamic"
  mkGetPaletteInfo :: FunPtr (LPCWSTR -> Ptr PALETTE_INFO -> CInt -> IO BOOL_) -> LPCWSTR -> Ptr PALETTE_INFO -> CInt -> IO BOOL_

callEditSection :: EDIT_HANDLE -> FunPtr (Ptr EDIT_SECTION -> IO ()) -> IO BOOL_
callEditSection edit callback = peek edit >>= \ehs -> mkCallEditSection (ehsCallEditSection ehs) callback

callEditSectionParam :: Ptr () -> EDIT_HANDLE -> FunPtr (Ptr () -> Ptr EDIT_SECTION -> IO ()) -> IO BOOL_
callEditSectionParam param edit callback = peek edit >>= \ehs -> mkCallEditSectionParam (ehsCallEditSectionParam ehs) param callback

callReadSection :: EDIT_HANDLE -> FunPtr (Ptr EDIT_SECTION -> IO ()) -> IO BOOL_
callReadSection edit callback = peek edit >>= \ehs -> mkCallReadSection (ehsCallReadSection ehs) callback

callReadSectionParam :: Ptr () -> EDIT_HANDLE -> FunPtr (Ptr () -> Ptr EDIT_SECTION -> IO ()) -> IO BOOL_
callReadSectionParam param edit callback = peek edit >>= \ehs -> mkCallReadSectionParam (ehsCallReadSectionParam ehs) param callback

getEditInfoFromHandle :: EDIT_HANDLE -> Ptr EDIT_INFO -> CInt -> IO ()
getEditInfoFromHandle edit infoPtr infoSize = peek edit >>= \ehs -> mkGetEditInfo (ehsGetEditInfo ehs) infoPtr infoSize

getEditInfo :: Ptr EDIT_SECTION -> IO EDIT_INFO
getEditInfo ptr = peekByteOff ptr 0 >>= peek

restartHostApp :: EDIT_HANDLE -> IO ()
restartHostApp edit = peek edit >>= \ehs -> mkRestartHostApp (ehsRestartHostApp ehs)

enumEffectName :: EDIT_HANDLE -> Ptr () -> FunPtr (Ptr () -> LPCWSTR -> CInt -> CInt -> IO ()) -> IO ()
enumEffectName edit param callback = peek edit >>= \ehs -> mkEnumEffectName (ehsEnumEffectName ehs) param callback

enumEffectItem :: EDIT_HANDLE -> LPCWSTR -> Ptr () -> FunPtr (Ptr () -> LPCWSTR -> CInt -> IO ()) -> IO BOOL_
enumEffectItem edit effect param callback = peek edit >>= \ehs -> mkEnumEffectItem (ehsEnumEffectItem ehs) effect param callback

enumModuleInfo :: EDIT_HANDLE -> Ptr () -> FunPtr (Ptr () -> Ptr MODULE_INFO -> IO ()) -> IO ()
enumModuleInfo edit param callback = peek edit >>= \ehs -> mkEnumModuleInfo (ehsEnumModuleInfo ehs) param callback

renderingSceneVideo :: EDIT_HANDLE -> CInt -> Ptr () -> FunPtr (Ptr () -> CInt -> Ptr () -> CInt -> CInt -> CInt -> IO ()) -> IO BOOL_
renderingSceneVideo edit frame param callback = peek edit >>= \ehs -> mkRenderingSceneVideo (ehsRenderingSceneVideo ehs) frame param callback

renderingSceneAudio :: EDIT_HANDLE -> CInt -> Ptr () -> FunPtr (Ptr () -> CInt -> Ptr CFloat -> Ptr CFloat -> CInt -> IO ()) -> IO BOOL_
renderingSceneAudio edit frame param callback = peek edit >>= \ehs -> mkRenderingSceneAudio (ehsRenderingSceneAudio ehs) frame param callback

waitRenderingTask :: EDIT_HANDLE -> IO ()
waitRenderingTask edit = peek edit >>= \ehs -> mkWaitRenderingTask (ehsWaitRenderingTask ehs)

enumFontName :: EDIT_HANDLE -> Ptr () -> FunPtr (Ptr () -> LPCWSTR -> IO ()) -> IO ()
enumFontName edit param callback = peek edit >>= \ehs -> mkEnumFontName (ehsEnumFontName ehs) param callback

enumPaletteName :: EDIT_HANDLE -> Ptr () -> FunPtr (Ptr () -> LPCWSTR -> IO ()) -> IO ()
enumPaletteName edit param callback = peek edit >>= \ehs -> mkEnumPaletteName (ehsEnumPaletteName ehs) param callback

getHostAppWindow :: EDIT_HANDLE -> IO HWND
getHostAppWindow edit = peek edit >>= \ehs -> mkGetHostAppWindow (ehsGetHostAppWindow ehs)

getEditState :: EDIT_HANDLE -> IO CInt
getEditState edit = peek edit >>= \ehs -> mkGetEditState (ehsGetEditState ehs)

createObjectFromAlias :: Ptr EDIT_SECTION -> LPCSTR -> CInt -> CInt -> CInt -> IO OBJECT_HANDLE
createObjectFromAlias ptr alias layer frame len = peek ptr >>= \es -> mkCreateObjectFromAlias (esCreateObjectFromAlias es) alias layer frame len

findObject :: Ptr EDIT_SECTION -> CInt -> CInt -> IO OBJECT_HANDLE
findObject ptr layer frame = peek ptr >>= \es -> mkFindObject (esFindObject es) layer frame

countObjectEffect :: Ptr EDIT_SECTION -> OBJECT_HANDLE -> LPCWSTR -> IO CInt
countObjectEffect ptr obj effect = peek ptr >>= \es -> mkCountObjectEffect (esCountObjectEffect es) obj effect

getObjectLayerFrame :: Ptr EDIT_SECTION -> OBJECT_HANDLE -> IO OBJECT_LAYER_FRAME
getObjectLayerFrame ptr obj = do
  es <- peek ptr
  alloca $ \out -> mkGetObjectLayerFrame (esGetObjectLayerFrame es) out obj >> peek out

getObjectAlias :: Ptr EDIT_SECTION -> OBJECT_HANDLE -> IO LPCSTR
getObjectAlias ptr obj = peek ptr >>= \es -> mkGetObjectAlias (esGetObjectAlias es) obj

getObjectItemValue :: Ptr EDIT_SECTION -> OBJECT_HANDLE -> LPCWSTR -> LPCWSTR -> IO LPCSTR
getObjectItemValue ptr obj effect item = peek ptr >>= \es -> mkGetObjectItemValue (esGetObjectItemValue es) obj effect item

setObjectItemValue :: Ptr EDIT_SECTION -> OBJECT_HANDLE -> LPCWSTR -> LPCWSTR -> LPCSTR -> IO BOOL_
setObjectItemValue ptr obj effect item val = peek ptr >>= \es -> mkSetObjectItemValue (esSetObjectItemValue es) obj effect item val

moveObject :: Ptr EDIT_SECTION -> OBJECT_HANDLE -> CInt -> CInt -> IO BOOL_
moveObject ptr obj layer frame = peek ptr >>= \es -> mkMoveObject (esMoveObject es) obj layer frame

deleteObject :: Ptr EDIT_SECTION -> OBJECT_HANDLE -> IO ()
deleteObject ptr obj = peek ptr >>= \es -> mkDeleteObject (esDeleteObject es) obj

getFocusObject :: Ptr EDIT_SECTION -> IO OBJECT_HANDLE
getFocusObject ptr = peek ptr >>= \es -> mkGetFocusObject (esGetFocusObject es)

setFocusObject :: Ptr EDIT_SECTION -> OBJECT_HANDLE -> IO ()
setFocusObject ptr obj = peek ptr >>= \es -> mkSetFocusObject (esSetFocusObject es) obj

getProjectFile :: Ptr EDIT_SECTION -> EDIT_HANDLE -> IO (Ptr PROJECT_FILE)
getProjectFile ptr edit = peek ptr >>= \es -> mkGetProjectFile (esGetProjectFile es) edit

getSelectedObject :: Ptr EDIT_SECTION -> CInt -> IO OBJECT_HANDLE
getSelectedObject ptr idx = peek ptr >>= \es -> mkGetSelectedObject (esGetSelectedObject es) idx

getSelectedObjectNum :: Ptr EDIT_SECTION -> IO CInt
getSelectedObjectNum ptr = peek ptr >>= \es -> mkGetSelectedObjectNum (esGetSelectedObjectNum es)

getMouseLayerFrame :: Ptr EDIT_SECTION -> Ptr CInt -> Ptr CInt -> IO BOOL_
getMouseLayerFrame ptr layer frame = peek ptr >>= \es -> mkGetMouseLayerFrame (esGetMouseLayerFrame es) layer frame

posToLayerFrame :: Ptr EDIT_SECTION -> CInt -> CInt -> Ptr CInt -> Ptr CInt -> IO BOOL_
posToLayerFrame ptr x y layer frame = peek ptr >>= \es -> mkPosToLayerFrame (esPosToLayerFrame es) x y layer frame

isSupportMediaFile :: Ptr EDIT_SECTION -> LPCWSTR -> BOOL_ -> IO BOOL_
isSupportMediaFile ptr file strict = peek ptr >>= \es -> mkIsSupportMediaFile (esIsSupportMediaFile es) file strict

getMediaInfo :: Ptr EDIT_SECTION -> LPCWSTR -> Ptr MEDIA_INFO -> CInt -> IO BOOL_
getMediaInfo ptr file info infoSize = peek ptr >>= \es -> mkGetMediaInfo (esGetMediaInfo es) file info infoSize

createObjectFromMediaFile :: Ptr EDIT_SECTION -> LPCWSTR -> CInt -> CInt -> CInt -> IO OBJECT_HANDLE
createObjectFromMediaFile ptr file layer frame len = peek ptr >>= \es -> mkCreateObjectFromMediaFile (esCreateObjectFromMediaFile es) file layer frame len

createObject :: Ptr EDIT_SECTION -> LPCWSTR -> CInt -> CInt -> CInt -> IO OBJECT_HANDLE
createObject ptr effect layer frame len = peek ptr >>= \es -> mkCreateObject (esCreateObject es) effect layer frame len

setCursorLayerFrame :: Ptr EDIT_SECTION -> CInt -> CInt -> IO ()
setCursorLayerFrame ptr layer frame = peek ptr >>= \es -> mkSetCursorLayerFrame (esSetCursorLayerFrame es) layer frame

setDisplayLayerFrame :: Ptr EDIT_SECTION -> CInt -> CInt -> IO ()
setDisplayLayerFrame ptr layer frame = peek ptr >>= \es -> mkSetDisplayLayerFrame (esSetDisplayLayerFrame es) layer frame

setSelectRange :: Ptr EDIT_SECTION -> CInt -> CInt -> IO ()
setSelectRange ptr start end_ = peek ptr >>= \es -> mkSetSelectRange (esSetSelectRange es) start end_

setGridBpm :: Ptr EDIT_SECTION -> CFloat -> CInt -> CFloat -> IO ()
setGridBpm ptr tempo beat offset = peek ptr >>= \es -> mkSetGridBpm (esSetGridBpm es) tempo beat offset

getObjectName :: Ptr EDIT_SECTION -> OBJECT_HANDLE -> IO LPCWSTR
getObjectName ptr obj = peek ptr >>= \es -> mkGetObjectName (esGetObjectName es) obj

setObjectName :: Ptr EDIT_SECTION -> OBJECT_HANDLE -> LPCWSTR -> IO ()
setObjectName ptr obj name = peek ptr >>= \es -> mkSetObjectName (esSetObjectName es) obj name

getLayerName :: Ptr EDIT_SECTION -> CInt -> IO LPCWSTR
getLayerName ptr layer = peek ptr >>= \es -> mkGetLayerName (esGetLayerName es) layer

setLayerName :: Ptr EDIT_SECTION -> CInt -> LPCWSTR -> IO ()
setLayerName ptr layer name = peek ptr >>= \es -> mkSetLayerName (esSetLayerName es) layer name

getSceneName :: Ptr EDIT_SECTION -> IO LPCWSTR
getSceneName ptr = peek ptr >>= \es -> mkGetSceneName (esGetSceneName es)

setSceneName :: Ptr EDIT_SECTION -> LPCWSTR -> IO ()
setSceneName ptr name = peek ptr >>= \es -> mkSetSceneName (esSetSceneName es) name

setSceneSize :: Ptr EDIT_SECTION -> CInt -> CInt -> IO ()
setSceneSize ptr w h = peek ptr >>= \es -> mkSetSceneSize (esSetSceneSize es) w h

setSceneFrameRate :: Ptr EDIT_SECTION -> CInt -> CInt -> IO ()
setSceneFrameRate ptr rate scale = peek ptr >>= \es -> mkSetSceneFrameRate (esSetSceneFrameRate es) rate scale

setSceneSampleRate :: Ptr EDIT_SECTION -> CInt -> IO ()
setSceneSampleRate ptr sampleRate = peek ptr >>= \es -> mkSetSceneSampleRate (esSetSceneSampleRate es) sampleRate

getLayerEnable :: Ptr EDIT_SECTION -> CInt -> IO BOOL_
getLayerEnable ptr layer = peek ptr >>= \es -> mkGetLayerEnable (esGetLayerEnable es) layer

setLayerEnable :: Ptr EDIT_SECTION -> CInt -> BOOL_ -> IO ()
setLayerEnable ptr layer enable = peek ptr >>= \es -> mkSetLayerEnable (esSetLayerEnable es) layer enable

getLayerLock :: Ptr EDIT_SECTION -> CInt -> IO BOOL_
getLayerLock ptr layer = peek ptr >>= \es -> mkGetLayerLock (esGetLayerLock es) layer

setLayerLock :: Ptr EDIT_SECTION -> CInt -> BOOL_ -> IO ()
setLayerLock ptr layer lock = peek ptr >>= \es -> mkSetLayerLock (esSetLayerLock es) layer lock

getObjectSectionNum :: Ptr EDIT_SECTION -> OBJECT_HANDLE -> IO CInt
getObjectSectionNum ptr obj = peek ptr >>= \es -> mkGetObjectSectionNum (esGetObjectSectionNum es) obj

getFocusObjectSection :: Ptr EDIT_SECTION -> IO CInt
getFocusObjectSection ptr = peek ptr >>= \es -> mkGetFocusObjectSection (esGetFocusObjectSection es)

getObjectSectionFrame :: Ptr EDIT_SECTION -> OBJECT_HANDLE -> CInt -> IO CInt
getObjectSectionFrame ptr obj section = peek ptr >>= \es -> mkGetObjectSectionFrame (esGetObjectSectionFrame es) obj section

getObjectTrackValue :: Ptr EDIT_SECTION -> OBJECT_HANDLE -> LPCWSTR -> LPCWSTR -> CDouble -> Ptr CDouble -> IO BOOL_
getObjectTrackValue ptr obj effect item frame value = peek ptr >>= \es -> mkGetObjectTrackValue (esGetObjectTrackValue es) obj effect item frame value

getObjectCheckValue :: Ptr EDIT_SECTION -> OBJECT_HANDLE -> LPCWSTR -> LPCWSTR -> CInt -> Ptr BOOL_ -> IO BOOL_
getObjectCheckValue ptr obj effect item frame value = peek ptr >>= \es -> mkGetObjectCheckValue (esGetObjectCheckValue es) obj effect item frame value

getObjectTrackInfo :: Ptr EDIT_SECTION -> OBJECT_HANDLE -> LPCWSTR -> LPCWSTR -> Ptr TRACK_INFO -> CInt -> IO BOOL_
getObjectTrackInfo ptr obj effect item info size = peek ptr >>= \es -> mkGetObjectTrackInfo (esGetObjectTrackInfo es) obj effect item info size

getPaletteName :: Ptr EDIT_SECTION -> IO LPCWSTR
getPaletteName ptr = peek ptr >>= \es -> mkGetPaletteName (esGetPaletteName es)

getPaletteInfo :: Ptr EDIT_SECTION -> LPCWSTR -> Ptr PALETTE_INFO -> CInt -> IO BOOL_
getPaletteInfo ptr name info size = peek ptr >>= \es -> mkGetPaletteInfo (esGetPaletteInfo es) name info size

foreign import ccall "dynamic"
  mkPfGetParamString :: FunPtr (LPCSTR -> IO LPCSTR) -> LPCSTR -> IO LPCSTR
foreign import ccall "dynamic"
  mkPfSetParamString :: FunPtr (LPCSTR -> LPCSTR -> IO ()) -> LPCSTR -> LPCSTR -> IO ()
foreign import ccall "dynamic"
  mkPfGetParamBinary :: FunPtr (LPCSTR -> Ptr () -> CInt -> IO BOOL_) -> LPCSTR -> Ptr () -> CInt -> IO BOOL_
foreign import ccall "dynamic"
  mkPfSetParamBinary :: FunPtr (LPCSTR -> Ptr () -> CInt -> IO ()) -> LPCSTR -> Ptr () -> CInt -> IO ()
foreign import ccall "dynamic"
  mkPfClearParams :: FunPtr (IO ()) -> IO ()
foreign import ccall "dynamic"
  mkPfGetProjectFilePath :: FunPtr (IO LPCWSTR) -> IO LPCWSTR

pfGetParamString :: Ptr PROJECT_FILE -> LPCSTR -> IO LPCSTR
pfGetParamString ptr key = peek ptr >>= \pf -> mkPfGetParamString (pfFuncGetParamString pf) key

pfSetParamString :: Ptr PROJECT_FILE -> LPCSTR -> LPCSTR -> IO ()
pfSetParamString ptr key val = peek ptr >>= \pf -> mkPfSetParamString (pfFuncSetParamString pf) key val

pfGetParamBinary :: Ptr PROJECT_FILE -> LPCSTR -> Ptr () -> CInt -> IO BOOL_
pfGetParamBinary ptr key data_ size = peek ptr >>= \pf -> mkPfGetParamBinary (pfFuncGetParamBinary pf) key data_ size

pfSetParamBinary :: Ptr PROJECT_FILE -> LPCSTR -> Ptr () -> CInt -> IO ()
pfSetParamBinary ptr key data_ size = peek ptr >>= \pf -> mkPfSetParamBinary (pfFuncSetParamBinary pf) key data_ size

pfClearParams :: Ptr PROJECT_FILE -> IO ()
pfClearParams ptr = peek ptr >>= \pf -> mkPfClearParams (pfFuncClearParams pf)

pfGetProjectFilePath :: Ptr PROJECT_FILE -> IO LPCWSTR
pfGetProjectFilePath ptr = peek ptr >>= \pf -> mkPfGetProjectFilePath (pfFuncGetProjectFilePath pf)
