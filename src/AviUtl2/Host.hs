{-|
Module      : AviUtl2.Host
Description : 汎用プラグインからAviUtl2本体へ登録処理を行うホストAPIです。

汎用プラグインはホストから 'HOST_APP_TABLE' を受け取り、このテーブル経由で
各種プラグインの登録、メニュー追加、ウィンドウクライアント登録、
プロジェクトロード・セーブコールバック登録などを行います。

このモジュールはそれらの登録口を生のFFI形状のまま公開し、
Haskell側から呼び出しやすい小さなラッパーを加えています。
-}
module AviUtl2.Host
  ( HOST_APP_TABLE(..)
  , setPluginInformation
  , registerInputPlugin
  , registerOutputPlugin
  , registerFilterPlugin
  , registerScriptModule
  , registerImportMenu
  , registerExportMenu
  , registerWindowClient
  , createEditHandle
  , registerProjectLoadHandler
  , registerProjectSaveHandler
  , registerLayerMenu
  , registerObjectMenu
  , registerConfigMenu
  , registerEditMenu
  , registerClearCacheHandler
  , registerChangeSceneHandler
  , registerImportMenuParam
  , registerExportMenuParam
  , registerLayerMenuParam
  , registerObjectMenuParam
  , registerEditMenuParam
  , registerFileDropHandler
  , registerFileDropParamHandler
  ) where

import Foreign.Ptr (Ptr, FunPtr)
import Foreign.Storable (Storable(..))
import AviUtl2.Types (LPCWSTR, HWND, HINSTANCE)
import AviUtl2.Input (INPUT_PLUGIN_TABLE)
import AviUtl2.Output (OUTPUT_PLUGIN_TABLE)
import AviUtl2.Filter (FILTER_PLUGIN_TABLE)
import AviUtl2.Module (SCRIPT_MODULE_TABLE)
import AviUtl2.Edit (EDIT_SECTION, EDIT_HANDLE, PROJECT_FILE)

-- | AviUtl2本体が汎用プラグインへ渡すホスト関数テーブルです。
-- |
-- | 各種プラグイン登録、メニュー登録、ウィンドウ登録、編集ハンドル生成、
-- | プロジェクトイベント登録などの入口がここに集約されています。
data HOST_APP_TABLE = HOST_APP_TABLE
  { hatSetPluginInformation         :: FunPtr (LPCWSTR -> IO ())
  , hatRegisterInputPlugin          :: FunPtr (Ptr INPUT_PLUGIN_TABLE -> IO ())
  , hatRegisterOutputPlugin         :: FunPtr (Ptr OUTPUT_PLUGIN_TABLE -> IO ())
  , hatRegisterFilterPlugin         :: FunPtr (Ptr FILTER_PLUGIN_TABLE -> IO ())
  , hatRegisterScriptModule         :: FunPtr (Ptr SCRIPT_MODULE_TABLE -> IO ())
  , hatRegisterImportMenu           :: FunPtr (LPCWSTR -> FunPtr (Ptr EDIT_SECTION -> IO ()) -> IO ())
  , hatRegisterExportMenu           :: FunPtr (LPCWSTR -> FunPtr (Ptr EDIT_SECTION -> IO ()) -> IO ())
  , hatRegisterWindowClient         :: FunPtr (LPCWSTR -> HWND -> IO ())
  , hatCreateEditHandle             :: FunPtr (IO EDIT_HANDLE)
  , hatRegisterProjectLoadHandler   :: FunPtr (FunPtr (Ptr PROJECT_FILE -> IO ()) -> IO ())
  , hatRegisterProjectSaveHandler   :: FunPtr (FunPtr (Ptr PROJECT_FILE -> IO ()) -> IO ())
  , hatRegisterLayerMenu            :: FunPtr (LPCWSTR -> FunPtr (Ptr EDIT_SECTION -> IO ()) -> IO ())
  , hatRegisterObjectMenu           :: FunPtr (LPCWSTR -> FunPtr (Ptr EDIT_SECTION -> IO ()) -> IO ())
  , hatRegisterConfigMenu           :: FunPtr (LPCWSTR -> FunPtr (HWND -> HINSTANCE -> IO ()) -> IO ())
  , hatRegisterEditMenu             :: FunPtr (LPCWSTR -> FunPtr (Ptr EDIT_SECTION -> IO ()) -> IO ())
  , hatRegisterClearCacheHandler    :: FunPtr (FunPtr (Ptr EDIT_SECTION -> IO ()) -> IO ())
  , hatRegisterChangeSceneHandler   :: FunPtr (FunPtr (Ptr EDIT_SECTION -> IO ()) -> IO ())
  , hatRegisterImportMenuParam      :: FunPtr (LPCWSTR -> Ptr () -> FunPtr (Ptr () -> IO ()) -> IO ())
  , hatRegisterExportMenuParam      :: FunPtr (LPCWSTR -> Ptr () -> FunPtr (Ptr () -> IO ()) -> IO ())
  , hatRegisterLayerMenuParam       :: FunPtr (LPCWSTR -> Ptr () -> FunPtr (Ptr () -> IO ()) -> IO ())
  , hatRegisterObjectMenuParam      :: FunPtr (LPCWSTR -> Ptr () -> FunPtr (Ptr () -> IO ()) -> IO ())
  , hatRegisterEditMenuParam        :: FunPtr (LPCWSTR -> Ptr () -> FunPtr (Ptr () -> IO ()) -> IO ())
  , hatRegisterFileDropHandler      :: FunPtr (LPCWSTR -> LPCWSTR -> FunPtr (Ptr EDIT_SECTION -> LPCWSTR -> IO ()) -> IO ())
  , hatRegisterFileDropParamHandler :: FunPtr (LPCWSTR -> LPCWSTR -> Ptr () -> FunPtr (Ptr () -> LPCWSTR -> IO ()) -> IO ())
  }

instance Storable HOST_APP_TABLE where
  sizeOf _ = 192
  alignment _ = 8
  peek ptr = HOST_APP_TABLE
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
  poke ptr v = do
    pokeByteOff ptr 0 (hatSetPluginInformation v)
    pokeByteOff ptr 8 (hatRegisterInputPlugin v)
    pokeByteOff ptr 16 (hatRegisterOutputPlugin v)
    pokeByteOff ptr 24 (hatRegisterFilterPlugin v)
    pokeByteOff ptr 32 (hatRegisterScriptModule v)
    pokeByteOff ptr 40 (hatRegisterImportMenu v)
    pokeByteOff ptr 48 (hatRegisterExportMenu v)
    pokeByteOff ptr 56 (hatRegisterWindowClient v)
    pokeByteOff ptr 64 (hatCreateEditHandle v)
    pokeByteOff ptr 72 (hatRegisterProjectLoadHandler v)
    pokeByteOff ptr 80 (hatRegisterProjectSaveHandler v)
    pokeByteOff ptr 88 (hatRegisterLayerMenu v)
    pokeByteOff ptr 96 (hatRegisterObjectMenu v)
    pokeByteOff ptr 104 (hatRegisterConfigMenu v)
    pokeByteOff ptr 112 (hatRegisterEditMenu v)
    pokeByteOff ptr 120 (hatRegisterClearCacheHandler v)
    pokeByteOff ptr 128 (hatRegisterChangeSceneHandler v)
    pokeByteOff ptr 136 (hatRegisterImportMenuParam v)
    pokeByteOff ptr 144 (hatRegisterExportMenuParam v)
    pokeByteOff ptr 152 (hatRegisterLayerMenuParam v)
    pokeByteOff ptr 160 (hatRegisterObjectMenuParam v)
    pokeByteOff ptr 168 (hatRegisterEditMenuParam v)
    pokeByteOff ptr 176 (hatRegisterFileDropHandler v)
    pokeByteOff ptr 184 (hatRegisterFileDropParamHandler v)

foreign import ccall "dynamic"
  mkSetPluginInformation :: FunPtr (LPCWSTR -> IO ()) -> LPCWSTR -> IO ()

foreign import ccall "dynamic"
  mkRegisterInputPlugin :: FunPtr (Ptr INPUT_PLUGIN_TABLE -> IO ()) -> Ptr INPUT_PLUGIN_TABLE -> IO ()

foreign import ccall "dynamic"
  mkRegisterOutputPlugin :: FunPtr (Ptr OUTPUT_PLUGIN_TABLE -> IO ()) -> Ptr OUTPUT_PLUGIN_TABLE -> IO ()

foreign import ccall "dynamic"
  mkRegisterFilterPlugin :: FunPtr (Ptr FILTER_PLUGIN_TABLE -> IO ()) -> Ptr FILTER_PLUGIN_TABLE -> IO ()

foreign import ccall "dynamic"
  mkRegisterScriptModule :: FunPtr (Ptr SCRIPT_MODULE_TABLE -> IO ()) -> Ptr SCRIPT_MODULE_TABLE -> IO ()

foreign import ccall "dynamic"
  mkRegisterImportMenu :: FunPtr (LPCWSTR -> FunPtr (Ptr EDIT_SECTION -> IO ()) -> IO ()) -> LPCWSTR -> FunPtr (Ptr EDIT_SECTION -> IO ()) -> IO ()

foreign import ccall "dynamic"
  mkRegisterExportMenu :: FunPtr (LPCWSTR -> FunPtr (Ptr EDIT_SECTION -> IO ()) -> IO ()) -> LPCWSTR -> FunPtr (Ptr EDIT_SECTION -> IO ()) -> IO ()

foreign import ccall "dynamic"
  mkRegisterWindowClient :: FunPtr (LPCWSTR -> HWND -> IO ()) -> LPCWSTR -> HWND -> IO ()

foreign import ccall "dynamic"
  mkCreateEditHandle :: FunPtr (IO EDIT_HANDLE) -> IO EDIT_HANDLE

foreign import ccall "dynamic"
  mkRegisterProjectLoadHandler :: FunPtr (FunPtr (Ptr PROJECT_FILE -> IO ()) -> IO ()) -> FunPtr (Ptr PROJECT_FILE -> IO ()) -> IO ()

foreign import ccall "dynamic"
  mkRegisterProjectSaveHandler :: FunPtr (FunPtr (Ptr PROJECT_FILE -> IO ()) -> IO ()) -> FunPtr (Ptr PROJECT_FILE -> IO ()) -> IO ()

foreign import ccall "dynamic"
  mkRegisterLayerMenu :: FunPtr (LPCWSTR -> FunPtr (Ptr EDIT_SECTION -> IO ()) -> IO ()) -> LPCWSTR -> FunPtr (Ptr EDIT_SECTION -> IO ()) -> IO ()

foreign import ccall "dynamic"
  mkRegisterObjectMenu :: FunPtr (LPCWSTR -> FunPtr (Ptr EDIT_SECTION -> IO ()) -> IO ()) -> LPCWSTR -> FunPtr (Ptr EDIT_SECTION -> IO ()) -> IO ()

foreign import ccall "dynamic"
  mkRegisterConfigMenu :: FunPtr (LPCWSTR -> FunPtr (HWND -> HINSTANCE -> IO ()) -> IO ()) -> LPCWSTR -> FunPtr (HWND -> HINSTANCE -> IO ()) -> IO ()

foreign import ccall "dynamic"
  mkRegisterEditMenu :: FunPtr (LPCWSTR -> FunPtr (Ptr EDIT_SECTION -> IO ()) -> IO ()) -> LPCWSTR -> FunPtr (Ptr EDIT_SECTION -> IO ()) -> IO ()

foreign import ccall "dynamic"
  mkRegisterClearCacheHandler :: FunPtr (FunPtr (Ptr EDIT_SECTION -> IO ()) -> IO ()) -> FunPtr (Ptr EDIT_SECTION -> IO ()) -> IO ()

foreign import ccall "dynamic"
  mkRegisterChangeSceneHandler :: FunPtr (FunPtr (Ptr EDIT_SECTION -> IO ()) -> IO ()) -> FunPtr (Ptr EDIT_SECTION -> IO ()) -> IO ()

foreign import ccall "dynamic"
  mkRegisterImportMenuParam :: FunPtr (LPCWSTR -> Ptr () -> FunPtr (Ptr () -> IO ()) -> IO ()) -> LPCWSTR -> Ptr () -> FunPtr (Ptr () -> IO ()) -> IO ()

foreign import ccall "dynamic"
  mkRegisterExportMenuParam :: FunPtr (LPCWSTR -> Ptr () -> FunPtr (Ptr () -> IO ()) -> IO ()) -> LPCWSTR -> Ptr () -> FunPtr (Ptr () -> IO ()) -> IO ()

foreign import ccall "dynamic"
  mkRegisterLayerMenuParam :: FunPtr (LPCWSTR -> Ptr () -> FunPtr (Ptr () -> IO ()) -> IO ()) -> LPCWSTR -> Ptr () -> FunPtr (Ptr () -> IO ()) -> IO ()

foreign import ccall "dynamic"
  mkRegisterObjectMenuParam :: FunPtr (LPCWSTR -> Ptr () -> FunPtr (Ptr () -> IO ()) -> IO ()) -> LPCWSTR -> Ptr () -> FunPtr (Ptr () -> IO ()) -> IO ()

foreign import ccall "dynamic"
  mkRegisterEditMenuParam :: FunPtr (LPCWSTR -> Ptr () -> FunPtr (Ptr () -> IO ()) -> IO ()) -> LPCWSTR -> Ptr () -> FunPtr (Ptr () -> IO ()) -> IO ()

foreign import ccall "dynamic"
  mkRegisterFileDropHandler :: FunPtr (LPCWSTR -> LPCWSTR -> FunPtr (Ptr EDIT_SECTION -> LPCWSTR -> IO ()) -> IO ()) -> LPCWSTR -> LPCWSTR -> FunPtr (Ptr EDIT_SECTION -> LPCWSTR -> IO ()) -> IO ()

foreign import ccall "dynamic"
  mkRegisterFileDropParamHandler :: FunPtr (LPCWSTR -> LPCWSTR -> Ptr () -> FunPtr (Ptr () -> LPCWSTR -> IO ()) -> IO ()) -> LPCWSTR -> LPCWSTR -> Ptr () -> FunPtr (Ptr () -> LPCWSTR -> IO ()) -> IO ()

-- | 汎用プラグイン自身の説明文をホストへ登録します。
setPluginInformation :: Ptr HOST_APP_TABLE -> LPCWSTR -> IO ()
setPluginInformation ptr info = do
  h <- peek ptr
  mkSetPluginInformation (hatSetPluginInformation h) info

-- | 入力プラグインをホストへ登録します。
registerInputPlugin :: Ptr HOST_APP_TABLE -> Ptr INPUT_PLUGIN_TABLE -> IO ()
registerInputPlugin ptr table = do
  h <- peek ptr
  mkRegisterInputPlugin (hatRegisterInputPlugin h) table

-- | 出力プラグインをホストへ登録します。
registerOutputPlugin :: Ptr HOST_APP_TABLE -> Ptr OUTPUT_PLUGIN_TABLE -> IO ()
registerOutputPlugin ptr table = do
  h <- peek ptr
  mkRegisterOutputPlugin (hatRegisterOutputPlugin h) table

-- | フィルタプラグインをホストへ登録します。
registerFilterPlugin :: Ptr HOST_APP_TABLE -> Ptr FILTER_PLUGIN_TABLE -> IO ()
registerFilterPlugin ptr table = do
  h <- peek ptr
  mkRegisterFilterPlugin (hatRegisterFilterPlugin h) table

-- | スクリプトモジュールをホストへ登録します。
registerScriptModule :: Ptr HOST_APP_TABLE -> Ptr SCRIPT_MODULE_TABLE -> IO ()
registerScriptModule ptr table = do
  h <- peek ptr
  mkRegisterScriptModule (hatRegisterScriptModule h) table

-- | インポートメニュー項目を登録します。
-- |
-- | 選択時には 'EDIT_SECTION' を受け取るコールバックが呼ばれます。
registerImportMenu :: Ptr HOST_APP_TABLE -> LPCWSTR -> FunPtr (Ptr EDIT_SECTION -> IO ()) -> IO ()
registerImportMenu ptr name callback = do
  h <- peek ptr
  mkRegisterImportMenu (hatRegisterImportMenu h) name callback

-- | エクスポートメニュー項目を登録します。
registerExportMenu :: Ptr HOST_APP_TABLE -> LPCWSTR -> FunPtr (Ptr EDIT_SECTION -> IO ()) -> IO ()
registerExportMenu ptr name callback = do
  h <- peek ptr
  mkRegisterExportMenu (hatRegisterExportMenu h) name callback

-- | ホストウィンドウ配下にクライアントウィンドウを登録します。
registerWindowClient :: Ptr HOST_APP_TABLE -> LPCWSTR -> HWND -> IO ()
registerWindowClient ptr name hwnd = do
  h <- peek ptr
  mkRegisterWindowClient (hatRegisterWindowClient h) name hwnd

-- | 編集操作用の 'EDIT_HANDLE' を生成します。
-- |
-- | 生成したハンドルを使って、後続の編集APIへアクセスできます。
createEditHandle :: Ptr HOST_APP_TABLE -> IO EDIT_HANDLE
createEditHandle ptr = do
  h <- peek ptr
  mkCreateEditHandle (hatCreateEditHandle h)

-- | プロジェクト読込時に呼ばれるコールバックを登録します。
registerProjectLoadHandler :: Ptr HOST_APP_TABLE -> FunPtr (Ptr PROJECT_FILE -> IO ()) -> IO ()
registerProjectLoadHandler ptr callback = do
  h <- peek ptr
  mkRegisterProjectLoadHandler (hatRegisterProjectLoadHandler h) callback

-- | プロジェクト保存時に呼ばれるコールバックを登録します。
registerProjectSaveHandler :: Ptr HOST_APP_TABLE -> FunPtr (Ptr PROJECT_FILE -> IO ()) -> IO ()
registerProjectSaveHandler ptr callback = do
  h <- peek ptr
  mkRegisterProjectSaveHandler (hatRegisterProjectSaveHandler h) callback

-- | レイヤーメニュー項目を登録します。
registerLayerMenu :: Ptr HOST_APP_TABLE -> LPCWSTR -> FunPtr (Ptr EDIT_SECTION -> IO ()) -> IO ()
registerLayerMenu ptr name callback = do
  h <- peek ptr
  mkRegisterLayerMenu (hatRegisterLayerMenu h) name callback

-- | オブジェクトメニュー項目を登録します。
registerObjectMenu :: Ptr HOST_APP_TABLE -> LPCWSTR -> FunPtr (Ptr EDIT_SECTION -> IO ()) -> IO ()
registerObjectMenu ptr name callback = do
  h <- peek ptr
  mkRegisterObjectMenu (hatRegisterObjectMenu h) name callback

-- | 設定メニュー項目を登録します。
-- |
-- | 選択時には親ウィンドウとDLLインスタンスを受け取る設定コールバックが呼ばれます。
registerConfigMenu :: Ptr HOST_APP_TABLE -> LPCWSTR -> FunPtr (HWND -> HINSTANCE -> IO ()) -> IO ()
registerConfigMenu ptr name callback = do
  h <- peek ptr
  mkRegisterConfigMenu (hatRegisterConfigMenu h) name callback

-- | 編集メニュー項目を登録します。
registerEditMenu :: Ptr HOST_APP_TABLE -> LPCWSTR -> FunPtr (Ptr EDIT_SECTION -> IO ()) -> IO ()
registerEditMenu ptr name callback = do
  h <- peek ptr
  mkRegisterEditMenu (hatRegisterEditMenu h) name callback

-- | キャッシュクリア時に呼ばれるハンドラを登録します。
registerClearCacheHandler :: Ptr HOST_APP_TABLE -> FunPtr (Ptr EDIT_SECTION -> IO ()) -> IO ()
registerClearCacheHandler ptr callback = do
  h <- peek ptr
  mkRegisterClearCacheHandler (hatRegisterClearCacheHandler h) callback

-- | シーン変更時に呼ばれるハンドラを登録します。
registerChangeSceneHandler :: Ptr HOST_APP_TABLE -> FunPtr (Ptr EDIT_SECTION -> IO ()) -> IO ()
registerChangeSceneHandler ptr callback = do
  h <- peek ptr
  mkRegisterChangeSceneHandler (hatRegisterChangeSceneHandler h) callback

-- | 任意パラメータ付きのインポートメニュー項目を登録します。
registerImportMenuParam :: Ptr HOST_APP_TABLE -> LPCWSTR -> Ptr () -> FunPtr (Ptr () -> IO ()) -> IO ()
registerImportMenuParam ptr name param callback = do
  h <- peek ptr
  mkRegisterImportMenuParam (hatRegisterImportMenuParam h) name param callback

-- | 任意パラメータ付きのエクスポートメニュー項目を登録します。
registerExportMenuParam :: Ptr HOST_APP_TABLE -> LPCWSTR -> Ptr () -> FunPtr (Ptr () -> IO ()) -> IO ()
registerExportMenuParam ptr name param callback = do
  h <- peek ptr
  mkRegisterExportMenuParam (hatRegisterExportMenuParam h) name param callback

-- | 任意パラメータ付きのレイヤーメニュー項目を登録します。
registerLayerMenuParam :: Ptr HOST_APP_TABLE -> LPCWSTR -> Ptr () -> FunPtr (Ptr () -> IO ()) -> IO ()
registerLayerMenuParam ptr name param callback = do
  h <- peek ptr
  mkRegisterLayerMenuParam (hatRegisterLayerMenuParam h) name param callback

-- | 任意パラメータ付きのオブジェクトメニュー項目を登録します。
registerObjectMenuParam :: Ptr HOST_APP_TABLE -> LPCWSTR -> Ptr () -> FunPtr (Ptr () -> IO ()) -> IO ()
registerObjectMenuParam ptr name param callback = do
  h <- peek ptr
  mkRegisterObjectMenuParam (hatRegisterObjectMenuParam h) name param callback

-- | 任意パラメータ付きの編集メニュー項目を登録します。
registerEditMenuParam :: Ptr HOST_APP_TABLE -> LPCWSTR -> Ptr () -> FunPtr (Ptr () -> IO ()) -> IO ()
registerEditMenuParam ptr name param callback = do
  h <- peek ptr
  mkRegisterEditMenuParam (hatRegisterEditMenuParam h) name param callback

-- | ファイルドロップ処理ハンドラを登録します。
-- |
-- | 指定したファイルフィルタに一致するファイルがドロップされた際に呼ばれます。
registerFileDropHandler :: Ptr HOST_APP_TABLE -> LPCWSTR -> LPCWSTR -> FunPtr (Ptr EDIT_SECTION -> LPCWSTR -> IO ()) -> IO ()
registerFileDropHandler ptr name filefilter callback = do
  h <- peek ptr
  mkRegisterFileDropHandler (hatRegisterFileDropHandler h) name filefilter callback

-- | 任意パラメータ付きのファイルドロップ処理ハンドラを登録します。
registerFileDropParamHandler :: Ptr HOST_APP_TABLE -> LPCWSTR -> LPCWSTR -> Ptr () -> FunPtr (Ptr () -> LPCWSTR -> IO ()) -> IO ()
registerFileDropParamHandler ptr name filefilter param callback = do
  h <- peek ptr
  mkRegisterFileDropParamHandler (hatRegisterFileDropParamHandler h) name filefilter param callback
