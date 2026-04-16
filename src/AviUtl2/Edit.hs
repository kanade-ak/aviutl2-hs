{-|
Module      : AviUtl2.Edit
Description : AviUtl2の編集ハンドル、編集セクション、プロジェクト保存領域を扱うAPIです。

このモジュールはAviUtl2の編集面に直接触れるための入口です。
オブジェクト生成、移動、削除、名前変更、シーン設定変更、選択範囲変更など、
タイムライン編集に関わる多くの操作がここに集まっています。

多くの関数は 'callEditSection' 経由で一時的に渡される 'EDIT_SECTION' を通じて
呼び出します。これはC SDKそのままの寿命規約を持つ低水準APIなので、
セクションポインタやその配下の文字列ポインタをコールバック外へ持ち出さないよう注意してください。
-}
module AviUtl2.Edit
  ( EDIT_SECTION(..)
  , EDIT_HANDLE_STRUCT(..)
  , EDIT_HANDLE
  , PROJECT_FILE(..)
  , callEditSection
  , callEditSectionParam
  , getEditInfoFromHandle
  , getEditInfo
  , restartHostApp
  , enumEffectName
  , enumModuleInfo
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
  , pfGetParamString
  , pfSetParamString
  , pfGetParamBinary
  , pfSetParamBinary
  , pfClearParams
  , pfGetProjectFilePath
  ) where

import Foreign.C.Types (CInt(..), CFloat(..), CBool(..))
import Foreign.Marshal.Alloc (alloca)
import Foreign.Ptr (Ptr, FunPtr)
import Foreign.Storable (Storable(..))
import AviUtl2.Types
  ( LPCWSTR, LPCSTR, OBJECT_HANDLE, EDIT_INFO, MEDIA_INFO
  , OBJECT_LAYER_FRAME, BOOL_, HWND, MODULE_INFO
  )

-- | 編集セクション呼び出しや編集情報取得の入口となるホスト所有ハンドルです。
-- |
-- | 一部の機能はこのハンドルから直接呼び出し、詳細な編集操作は
-- | ここから取得する 'EDIT_SECTION' 内で実行します。
data EDIT_HANDLE_STRUCT = EDIT_HANDLE_STRUCT
  { ehsCallEditSection      :: FunPtr (FunPtr (Ptr EDIT_SECTION -> IO ()) -> IO BOOL_)
  , ehsCallEditSectionParam :: FunPtr (Ptr () -> FunPtr (Ptr () -> Ptr EDIT_SECTION -> IO ()) -> IO BOOL_)
  , ehsGetEditInfo          :: FunPtr (Ptr EDIT_INFO -> CInt -> IO ())
  , ehsRestartHostApp       :: FunPtr (IO ())
  , ehsEnumEffectName       :: FunPtr (Ptr () -> FunPtr (Ptr () -> LPCWSTR -> CInt -> CInt -> IO ()) -> IO ())
  , ehsEnumModuleInfo       :: FunPtr (Ptr () -> FunPtr (Ptr () -> Ptr MODULE_INFO -> IO ()) -> IO ())
  , ehsGetHostAppWindow     :: FunPtr (IO HWND)
  , ehsGetEditState         :: FunPtr (IO CInt)
  }

-- | 'EDIT_HANDLE_STRUCT' への不透明ポインタです。
type EDIT_HANDLE = Ptr EDIT_HANDLE_STRUCT

instance Storable EDIT_HANDLE_STRUCT where
  sizeOf _ = 64
  alignment _ = 8
  peek ptr = EDIT_HANDLE_STRUCT
    <$> peekByteOff ptr 0
    <*> peekByteOff ptr 8
    <*> peekByteOff ptr 16
    <*> peekByteOff ptr 24
    <*> peekByteOff ptr 32
    <*> peekByteOff ptr 40
    <*> peekByteOff ptr 48
    <*> peekByteOff ptr 56
  poke ptr v = do
    pokeByteOff ptr 0 (ehsCallEditSection v)
    pokeByteOff ptr 8 (ehsCallEditSectionParam v)
    pokeByteOff ptr 16 (ehsGetEditInfo v)
    pokeByteOff ptr 24 (ehsRestartHostApp v)
    pokeByteOff ptr 32 (ehsEnumEffectName v)
    pokeByteOff ptr 40 (ehsEnumModuleInfo v)
    pokeByteOff ptr 48 (ehsGetHostAppWindow v)
    pokeByteOff ptr 56 (ehsGetEditState v)

-- | プラグイン固有のプロジェクト保存領域を読み書きするための関数群です。
-- |
-- | プロジェクト保存・読込時に、文字列やバイナリをプラグイン単位の領域へ
-- | 保存・取得するために使います。
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
    <$> peekByteOff ptr 0
    <*> peekByteOff ptr 8
    <*> peekByteOff ptr 16
    <*> peekByteOff ptr 24
    <*> peekByteOff ptr 32
    <*> peekByteOff ptr 40
  poke ptr v = do
    pokeByteOff ptr 0 (pfFuncGetParamString v)
    pokeByteOff ptr 8 (pfFuncSetParamString v)
    pokeByteOff ptr 16 (pfFuncGetParamBinary v)
    pokeByteOff ptr 24 (pfFuncSetParamBinary v)
    pokeByteOff ptr 32 (pfFuncClearParams v)
    pokeByteOff ptr 40 (pfFuncGetProjectFilePath v)

-- | 編集セクション内で利用できる操作群です。
-- |
-- | オブジェクト検索、作成、移動、削除、名称変更、シーン設定変更など、
-- | 編集画面に対する実操作の多くがこの構造体に集約されています。
data EDIT_SECTION = EDIT_SECTION
  { esInfo                      :: Ptr EDIT_INFO
  , esCreateObjectFromAlias     :: FunPtr (LPCSTR -> CInt -> CInt -> CInt -> IO OBJECT_HANDLE)
  , esFindObject                :: FunPtr (CInt -> CInt -> IO OBJECT_HANDLE)
  , esCountObjectEffect         :: FunPtr (OBJECT_HANDLE -> LPCWSTR -> IO CInt)
  , esGetObjectLayerFrame       :: FunPtr (OBJECT_HANDLE -> IO OBJECT_LAYER_FRAME)
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
  }

instance Storable EDIT_SECTION where
  sizeOf _ = 272
  alignment _ = 8
  peek ptr = EDIT_SECTION
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
    <*> peekByteOff ptr 88
    <*> peekByteOff ptr 96
    <*> peekByteOff ptr 104
    <*> peekByteOff ptr 112
    <*> peekByteOff ptr 120
    <*> peekByteOff ptr 128
    <*> peekByteOff ptr 136
    <*> peekByteOff ptr 144
    <*> peekByteOff ptr 152
    <*> peekByteOff ptr 160
    <*> peekByteOff ptr 168
    <*> peekByteOff ptr 176
    <*> peekByteOff ptr 184
    <*> peekByteOff ptr 192
    <*> peekByteOff ptr 200
    <*> peekByteOff ptr 208
    <*> peekByteOff ptr 216
    <*> peekByteOff ptr 224
    <*> peekByteOff ptr 232
    <*> peekByteOff ptr 240
    <*> peekByteOff ptr 248
    <*> peekByteOff ptr 256
    <*> peekByteOff ptr 264
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

foreign import ccall safe "dynamic"
  mkCallEditSection :: FunPtr (FunPtr (Ptr EDIT_SECTION -> IO ()) -> IO BOOL_) -> FunPtr (Ptr EDIT_SECTION -> IO ()) -> IO BOOL_

foreign import ccall "dynamic"
  mkCreateObjectFromAlias :: FunPtr (LPCSTR -> CInt -> CInt -> CInt -> IO OBJECT_HANDLE) -> LPCSTR -> CInt -> CInt -> CInt -> IO OBJECT_HANDLE

foreign import ccall "dynamic"
  mkFindObject :: FunPtr (CInt -> CInt -> IO OBJECT_HANDLE) -> CInt -> CInt -> IO OBJECT_HANDLE

foreign import ccall "dynamic"
  mkCountObjectEffect :: FunPtr (OBJECT_HANDLE -> LPCWSTR -> IO CInt) -> OBJECT_HANDLE -> LPCWSTR -> IO CInt

foreign import ccall unsafe "hs_aviutl2_get_object_layer_frame"
  cGetObjectLayerFrame :: FunPtr (OBJECT_HANDLE -> IO OBJECT_LAYER_FRAME) -> OBJECT_HANDLE -> Ptr OBJECT_LAYER_FRAME -> IO ()

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
  mkRestartHostApp :: FunPtr (IO ()) -> IO ()

foreign import ccall "dynamic"
  mkGetHostAppWindow :: FunPtr (IO HWND) -> IO HWND

foreign import ccall "dynamic"
  mkGetEditState :: FunPtr (IO CInt) -> IO CInt

-- | 一時的な 'EDIT_SECTION' を受け取り、その中で編集操作を行います。
-- |
-- | コールバックはAviUtl2本体が適切な文脈を用意したうえで呼び出します。
callEditSection :: EDIT_HANDLE -> FunPtr (Ptr EDIT_SECTION -> IO ()) -> IO BOOL_
callEditSection edit callback = do
  ehs <- peek edit
  mkCallEditSection (ehsCallEditSection ehs) callback

-- | 任意パラメータ付きで 'EDIT_SECTION' コールバックを呼び出します。
-- |
-- | C側コールバックへ追加状態を渡したい場合に使います。
callEditSectionParam :: Ptr () -> EDIT_HANDLE -> FunPtr (Ptr () -> Ptr EDIT_SECTION -> IO ()) -> IO BOOL_
callEditSectionParam param edit callback = do
  ehs <- peek edit
  mkCallEditSectionParam (ehsCallEditSectionParam ehs) param callback

-- | 指定した編集ハンドルから現在の 'EDIT_INFO' を取得します。
-- |
-- | 呼び出し側が確保したバッファへ直接書き込ませる低水準版です。
getEditInfoFromHandle :: EDIT_HANDLE -> Ptr EDIT_INFO -> CInt -> IO ()
getEditInfoFromHandle edit infoPtr infoSize = do
  ehs <- peek edit
  mkGetEditInfo (ehsGetEditInfo ehs) infoPtr infoSize

foreign import ccall safe "dynamic"
  mkCallEditSectionParam :: FunPtr (Ptr () -> FunPtr (Ptr () -> Ptr EDIT_SECTION -> IO ()) -> IO BOOL_) -> Ptr () -> FunPtr (Ptr () -> Ptr EDIT_SECTION -> IO ()) -> IO BOOL_

foreign import ccall "dynamic"
  mkGetEditInfo :: FunPtr (Ptr EDIT_INFO -> CInt -> IO ()) -> Ptr EDIT_INFO -> CInt -> IO ()

-- | 'EDIT_SECTION' から現在の 'EDIT_INFO' を簡便に取得します。
getEditInfo :: Ptr EDIT_SECTION -> IO EDIT_INFO
getEditInfo ptr = do
  infoPtr <- peekByteOff ptr 0
  peek infoPtr

-- | エイリアス名からオブジェクトを生成します。
createObjectFromAlias :: Ptr EDIT_SECTION -> LPCSTR -> CInt -> CInt -> CInt -> IO OBJECT_HANDLE
createObjectFromAlias ptr alias layer frame len = do
  es <- peek ptr
  mkCreateObjectFromAlias (esCreateObjectFromAlias es) alias layer frame len

-- | 指定レイヤーとフレーム位置のオブジェクトを検索します。
findObject :: Ptr EDIT_SECTION -> CInt -> CInt -> IO OBJECT_HANDLE
findObject ptr layer frame = do
  es <- peek ptr
  mkFindObject (esFindObject es) layer frame

-- | 指定オブジェクトが持つ特定エフェクトの個数を数えます。
countObjectEffect :: Ptr EDIT_SECTION -> OBJECT_HANDLE -> LPCWSTR -> IO CInt
countObjectEffect ptr obj effect = do
  es <- peek ptr
  mkCountObjectEffect (esCountObjectEffect es) obj effect

-- | オブジェクトのレイヤー番号とフレーム範囲を取得します。
-- |
-- | レイヤー番号とフレーム番号は0始まりです。
getObjectLayerFrame :: Ptr EDIT_SECTION -> OBJECT_HANDLE -> IO OBJECT_LAYER_FRAME
getObjectLayerFrame ptr obj = do
  es <- peek ptr
  alloca $ \out -> do
    cGetObjectLayerFrame (esGetObjectLayerFrame es) obj out
    peek out

-- | オブジェクトに紐づくエイリアス名を取得します。
getObjectAlias :: Ptr EDIT_SECTION -> OBJECT_HANDLE -> IO LPCSTR
getObjectAlias ptr obj = do
  es <- peek ptr
  mkGetObjectAlias (esGetObjectAlias es) obj

-- | オブジェクト内のエフェクト項目値を文字列として取得します。
getObjectItemValue :: Ptr EDIT_SECTION -> OBJECT_HANDLE -> LPCWSTR -> LPCWSTR -> IO LPCSTR
getObjectItemValue ptr obj effect item = do
  es <- peek ptr
  mkGetObjectItemValue (esGetObjectItemValue es) obj effect item

-- | オブジェクト内のエフェクト項目値を文字列で設定します。
setObjectItemValue :: Ptr EDIT_SECTION -> OBJECT_HANDLE -> LPCWSTR -> LPCWSTR -> LPCSTR -> IO BOOL_
setObjectItemValue ptr obj effect item val = do
  es <- peek ptr
  mkSetObjectItemValue (esSetObjectItemValue es) obj effect item val

-- | オブジェクトを別レイヤー・別フレームへ移動します。
moveObject :: Ptr EDIT_SECTION -> OBJECT_HANDLE -> CInt -> CInt -> IO BOOL_
moveObject ptr obj layer frame = do
  es <- peek ptr
  mkMoveObject (esMoveObject es) obj layer frame

-- | オブジェクトを削除します。
deleteObject :: Ptr EDIT_SECTION -> OBJECT_HANDLE -> IO ()
deleteObject ptr obj = do
  es <- peek ptr
  mkDeleteObject (esDeleteObject es) obj

-- | 現在フォーカスされているオブジェクトを取得します。
getFocusObject :: Ptr EDIT_SECTION -> IO OBJECT_HANDLE
getFocusObject ptr = do
  es <- peek ptr
  mkGetFocusObject (esGetFocusObject es)

-- | 指定オブジェクトへフォーカスを移します。
setFocusObject :: Ptr EDIT_SECTION -> OBJECT_HANDLE -> IO ()
setFocusObject ptr obj = do
  es <- peek ptr
  mkSetFocusObject (esSetFocusObject es) obj

-- | この編集文脈に対応するプロジェクト保存領域ハンドルを取得します。
getProjectFile :: Ptr EDIT_SECTION -> EDIT_HANDLE -> IO (Ptr PROJECT_FILE)
getProjectFile ptr edit = do
  es <- peek ptr
  mkGetProjectFile (esGetProjectFile es) edit

-- | 選択中オブジェクトをインデックス指定で取得します。
getSelectedObject :: Ptr EDIT_SECTION -> CInt -> IO OBJECT_HANDLE
getSelectedObject ptr idx = do
  es <- peek ptr
  mkGetSelectedObject (esGetSelectedObject es) idx

-- | 現在選択されているオブジェクト数を取得します。
getSelectedObjectNum :: Ptr EDIT_SECTION -> IO CInt
getSelectedObjectNum ptr = do
  es <- peek ptr
  mkGetSelectedObjectNum (esGetSelectedObjectNum es)

-- | 現在のマウス位置に対応するレイヤー番号とフレーム番号を取得します。
getMouseLayerFrame :: Ptr EDIT_SECTION -> Ptr CInt -> Ptr CInt -> IO BOOL_
getMouseLayerFrame ptr layer frame = do
  es <- peek ptr
  mkGetMouseLayerFrame (esGetMouseLayerFrame es) layer frame

-- | 画面座標からレイヤー番号とフレーム番号へ変換します。
posToLayerFrame :: Ptr EDIT_SECTION -> CInt -> CInt -> Ptr CInt -> Ptr CInt -> IO BOOL_
posToLayerFrame ptr x y layer frame = do
  es <- peek ptr
  mkPosToLayerFrame (esPosToLayerFrame es) x y layer frame

-- | 指定メディアファイルが読み込み可能かを調べます。
-- |
-- | 第2引数のブール値は厳密判定の有無としてSDK側へ渡されます。
isSupportMediaFile :: Ptr EDIT_SECTION -> LPCWSTR -> BOOL_ -> IO BOOL_
isSupportMediaFile ptr file strict = do
  es <- peek ptr
  mkIsSupportMediaFile (esIsSupportMediaFile es) file strict

-- | 指定メディアファイルの情報を取得します。
getMediaInfo :: Ptr EDIT_SECTION -> LPCWSTR -> Ptr MEDIA_INFO -> CInt -> IO BOOL_
getMediaInfo ptr file info infoSize = do
  es <- peek ptr
  mkGetMediaInfo (esGetMediaInfo es) file info infoSize

-- | メディアファイルから新しいオブジェクトを生成します。
createObjectFromMediaFile :: Ptr EDIT_SECTION -> LPCWSTR -> CInt -> CInt -> CInt -> IO OBJECT_HANDLE
createObjectFromMediaFile ptr file layer frame len = do
  es <- peek ptr
  mkCreateObjectFromMediaFile (esCreateObjectFromMediaFile es) file layer frame len

-- | エフェクト名を指定して新しいオブジェクトを生成します。
createObject :: Ptr EDIT_SECTION -> LPCWSTR -> CInt -> CInt -> CInt -> IO OBJECT_HANDLE
createObject ptr effect layer frame len = do
  es <- peek ptr
  mkCreateObject (esCreateObject es) effect layer frame len

-- | カーソル位置を指定レイヤー・フレームへ移動します。
setCursorLayerFrame :: Ptr EDIT_SECTION -> CInt -> CInt -> IO ()
setCursorLayerFrame ptr layer frame = do
  es <- peek ptr
  mkSetCursorLayerFrame (esSetCursorLayerFrame es) layer frame

-- | 表示開始位置を指定レイヤー・フレームへ変更します。
setDisplayLayerFrame :: Ptr EDIT_SECTION -> CInt -> CInt -> IO ()
setDisplayLayerFrame ptr layer frame = do
  es <- peek ptr
  mkSetDisplayLayerFrame (esSetDisplayLayerFrame es) layer frame

-- | 選択範囲の開始・終了フレームを設定します。
setSelectRange :: Ptr EDIT_SECTION -> CInt -> CInt -> IO ()
setSelectRange ptr start end_ = do
  es <- peek ptr
  mkSetSelectRange (esSetSelectRange es) start end_

-- | グリッドBPM設定を更新します。
setGridBpm :: Ptr EDIT_SECTION -> CFloat -> CInt -> CFloat -> IO ()
setGridBpm ptr tempo beat offset = do
  es <- peek ptr
  mkSetGridBpm (esSetGridBpm es) tempo beat offset

-- | オブジェクトの表示名を取得します。
getObjectName :: Ptr EDIT_SECTION -> OBJECT_HANDLE -> IO LPCWSTR
getObjectName ptr obj = do
  es <- peek ptr
  mkGetObjectName (esGetObjectName es) obj

-- | オブジェクトの表示名を設定します。
setObjectName :: Ptr EDIT_SECTION -> OBJECT_HANDLE -> LPCWSTR -> IO ()
setObjectName ptr obj name = do
  es <- peek ptr
  mkSetObjectName (esSetObjectName es) obj name

-- | 指定レイヤーの表示名を取得します。
getLayerName :: Ptr EDIT_SECTION -> CInt -> IO LPCWSTR
getLayerName ptr layer = do
  es <- peek ptr
  mkGetLayerName (esGetLayerName es) layer

-- | 指定レイヤーの表示名を設定します。
setLayerName :: Ptr EDIT_SECTION -> CInt -> LPCWSTR -> IO ()
setLayerName ptr layer name = do
  es <- peek ptr
  mkSetLayerName (esSetLayerName es) layer name

-- | 現在シーンの名前を取得します。
getSceneName :: Ptr EDIT_SECTION -> IO LPCWSTR
getSceneName ptr = do
  es <- peek ptr
  mkGetSceneName (esGetSceneName es)

-- | 現在シーンの名前を設定します。
setSceneName :: Ptr EDIT_SECTION -> LPCWSTR -> IO ()
setSceneName ptr name = do
  es <- peek ptr
  mkSetSceneName (esSetSceneName es) name

-- | 現在シーンの画面サイズを設定します。
setSceneSize :: Ptr EDIT_SECTION -> CInt -> CInt -> IO ()
setSceneSize ptr w h = do
  es <- peek ptr
  mkSetSceneSize (esSetSceneSize es) w h

-- | 現在シーンのフレームレートを設定します。
-- |
-- | 分子 'rate' と分母 'scale' の形で指定します。
setSceneFrameRate :: Ptr EDIT_SECTION -> CInt -> CInt -> IO ()
setSceneFrameRate ptr rate scale = do
  es <- peek ptr
  mkSetSceneFrameRate (esSetSceneFrameRate es) rate scale

-- | 現在シーンの音声サンプルレートを設定します。
setSceneSampleRate :: Ptr EDIT_SECTION -> CInt -> IO ()
setSceneSampleRate ptr sampleRate = do
  es <- peek ptr
  mkSetSceneSampleRate (esSetSceneSampleRate es) sampleRate

-- | ホストアプリケーションの再起動を要求します。
restartHostApp :: EDIT_HANDLE -> IO ()
restartHostApp edit = do
  ehs <- peek edit
  mkRestartHostApp (ehsRestartHostApp ehs)

-- | 利用可能なエフェクト名を列挙します。
-- |
-- | コールバックには名前に加えて種別情報も渡されます。
enumEffectName :: EDIT_HANDLE -> Ptr () -> FunPtr (Ptr () -> LPCWSTR -> CInt -> CInt -> IO ()) -> IO ()
enumEffectName edit param callback = do
  ehs <- peek edit
  mkEnumEffectName (ehsEnumEffectName ehs) param callback

foreign import ccall safe "dynamic"
  mkEnumEffectName :: FunPtr (Ptr () -> FunPtr (Ptr () -> LPCWSTR -> CInt -> CInt -> IO ()) -> IO ()) -> Ptr () -> FunPtr (Ptr () -> LPCWSTR -> CInt -> CInt -> IO ()) -> IO ()

-- | 利用可能なモジュール情報を列挙します。
enumModuleInfo :: EDIT_HANDLE -> Ptr () -> FunPtr (Ptr () -> Ptr MODULE_INFO -> IO ()) -> IO ()
enumModuleInfo edit param callback = do
  ehs <- peek edit
  mkEnumModuleInfo (ehsEnumModuleInfo ehs) param callback

foreign import ccall safe "dynamic"
  mkEnumModuleInfo :: FunPtr (Ptr () -> FunPtr (Ptr () -> Ptr MODULE_INFO -> IO ()) -> IO ()) -> Ptr () -> FunPtr (Ptr () -> Ptr MODULE_INFO -> IO ()) -> IO ()

-- | ホストアプリケーションのメインウィンドウハンドルを取得します。
getHostAppWindow :: EDIT_HANDLE -> IO HWND
getHostAppWindow edit = do
  ehs <- peek edit
  mkGetHostAppWindow (ehsGetHostAppWindow ehs)

-- | 現在の編集状態を取得します。
-- |
-- | 戻り値は 'EDIT_STATE' として解釈できます。
getEditState :: EDIT_HANDLE -> IO CInt
getEditState edit = do
  ehs <- peek edit
  mkGetEditState (ehsGetEditState ehs)

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

-- | プロジェクト保存領域から文字列値を取得します。
pfGetParamString :: Ptr PROJECT_FILE -> LPCSTR -> IO LPCSTR
pfGetParamString ptr key = do
  pf <- peek ptr
  mkPfGetParamString (pfFuncGetParamString pf) key

-- | プロジェクト保存領域へ文字列値を保存します。
pfSetParamString :: Ptr PROJECT_FILE -> LPCSTR -> LPCSTR -> IO ()
pfSetParamString ptr key val = do
  pf <- peek ptr
  mkPfSetParamString (pfFuncSetParamString pf) key val

-- | プロジェクト保存領域からバイナリ値を取得します。
-- |
-- | 'data_' は呼び出し側が確保した受け取りバッファです。
pfGetParamBinary :: Ptr PROJECT_FILE -> LPCSTR -> Ptr () -> CInt -> IO BOOL_
pfGetParamBinary ptr key data_ size = do
  pf <- peek ptr
  mkPfGetParamBinary (pfFuncGetParamBinary pf) key data_ size

-- | プロジェクト保存領域へバイナリ値を保存します。
pfSetParamBinary :: Ptr PROJECT_FILE -> LPCSTR -> Ptr () -> CInt -> IO ()
pfSetParamBinary ptr key data_ size = do
  pf <- peek ptr
  mkPfSetParamBinary (pfFuncSetParamBinary pf) key data_ size

-- | プラグイン用の保存パラメータをすべて消去します。
pfClearParams :: Ptr PROJECT_FILE -> IO ()
pfClearParams ptr = do
  pf <- peek ptr
  mkPfClearParams (pfFuncClearParams pf)

-- | 現在のプロジェクトファイルパスを取得します。
pfGetProjectFilePath :: Ptr PROJECT_FILE -> IO LPCWSTR
pfGetProjectFilePath ptr = do
  pf <- peek ptr
  mkPfGetProjectFilePath (pfFuncGetProjectFilePath pf)
