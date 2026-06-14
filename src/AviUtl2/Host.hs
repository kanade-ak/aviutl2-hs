{-|
Module      : AviUtl2.Host
Description : 汎用プラグインからAviUtl2本体へ登録処理を行うホストAPIです。
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
  , registerObjectItemMenu
  , registerObjectItemMenuParam
  , registerScriptModuleName
  , registerFontCollection
  , registerEventListener
  ) where

import Foreign.Ptr (FunPtr, Ptr)
import Foreign.Storable (Storable(..))
import Foreign.C.Types (CBool(..), CInt(..))

import AviUtl2.Edit (EDIT_HANDLE, EDIT_SECTION, PROJECT_FILE)
import AviUtl2.Filter (FILTER_PLUGIN_TABLE)
import AviUtl2.Input (INPUT_PLUGIN_TABLE)
import AviUtl2.Module (SCRIPT_MODULE_TABLE)
import AviUtl2.Output (OUTPUT_PLUGIN_TABLE)
import AviUtl2.Types (BOOL_, EVENT_TYPE, HINSTANCE, HWND, LPCWSTR, OBJECT_HANDLE)

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
  , hatRegisterObjectItemMenu       :: FunPtr (LPCWSTR -> BOOL_ -> FunPtr (Ptr EDIT_SECTION -> OBJECT_HANDLE -> LPCWSTR -> LPCWSTR -> IO ()) -> IO ())
  , hatRegisterObjectItemMenuParam  :: FunPtr (LPCWSTR -> BOOL_ -> Ptr () -> FunPtr (Ptr () -> OBJECT_HANDLE -> LPCWSTR -> LPCWSTR -> IO ()) -> IO ())
  , hatRegisterScriptModuleName     :: FunPtr (Ptr SCRIPT_MODULE_TABLE -> LPCWSTR -> IO ())
  , hatRegisterFontCollection       :: FunPtr (Ptr () -> IO ())
  , hatRegisterEventListener        :: FunPtr (EVENT_TYPE -> Ptr () -> FunPtr (Ptr () -> IO ()) -> IO ())
  }

instance Storable HOST_APP_TABLE where
  sizeOf _ = 232
  alignment _ = 8
  peek ptr = HOST_APP_TABLE
    <$> peekByteOff ptr 0 <*> peekByteOff ptr 8 <*> peekByteOff ptr 16 <*> peekByteOff ptr 24
    <*> peekByteOff ptr 32 <*> peekByteOff ptr 40 <*> peekByteOff ptr 48 <*> peekByteOff ptr 56
    <*> peekByteOff ptr 64 <*> peekByteOff ptr 72 <*> peekByteOff ptr 80 <*> peekByteOff ptr 88
    <*> peekByteOff ptr 96 <*> peekByteOff ptr 104 <*> peekByteOff ptr 112 <*> peekByteOff ptr 120
    <*> peekByteOff ptr 128 <*> peekByteOff ptr 136 <*> peekByteOff ptr 144 <*> peekByteOff ptr 152
    <*> peekByteOff ptr 160 <*> peekByteOff ptr 168 <*> peekByteOff ptr 176 <*> peekByteOff ptr 184
    <*> peekByteOff ptr 192 <*> peekByteOff ptr 200 <*> peekByteOff ptr 208 <*> peekByteOff ptr 216
    <*> peekByteOff ptr 224
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
    pokeByteOff ptr 192 (hatRegisterObjectItemMenu v)
    pokeByteOff ptr 200 (hatRegisterObjectItemMenuParam v)
    pokeByteOff ptr 208 (hatRegisterScriptModuleName v)
    pokeByteOff ptr 216 (hatRegisterFontCollection v)
    pokeByteOff ptr 224 (hatRegisterEventListener v)

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
foreign import ccall "dynamic"
  mkRegisterObjectItemMenu :: FunPtr (LPCWSTR -> BOOL_ -> FunPtr (Ptr EDIT_SECTION -> OBJECT_HANDLE -> LPCWSTR -> LPCWSTR -> IO ()) -> IO ()) -> LPCWSTR -> BOOL_ -> FunPtr (Ptr EDIT_SECTION -> OBJECT_HANDLE -> LPCWSTR -> LPCWSTR -> IO ()) -> IO ()
foreign import ccall "dynamic"
  mkRegisterObjectItemMenuParam :: FunPtr (LPCWSTR -> BOOL_ -> Ptr () -> FunPtr (Ptr () -> OBJECT_HANDLE -> LPCWSTR -> LPCWSTR -> IO ()) -> IO ()) -> LPCWSTR -> BOOL_ -> Ptr () -> FunPtr (Ptr () -> OBJECT_HANDLE -> LPCWSTR -> LPCWSTR -> IO ()) -> IO ()
foreign import ccall "dynamic"
  mkRegisterScriptModuleName :: FunPtr (Ptr SCRIPT_MODULE_TABLE -> LPCWSTR -> IO ()) -> Ptr SCRIPT_MODULE_TABLE -> LPCWSTR -> IO ()
foreign import ccall "dynamic"
  mkRegisterFontCollection :: FunPtr (Ptr () -> IO ()) -> Ptr () -> IO ()
foreign import ccall "dynamic"
  mkRegisterEventListener :: FunPtr (EVENT_TYPE -> Ptr () -> FunPtr (Ptr () -> IO ()) -> IO ()) -> EVENT_TYPE -> Ptr () -> FunPtr (Ptr () -> IO ()) -> IO ()

setPluginInformation :: Ptr HOST_APP_TABLE -> LPCWSTR -> IO ()
setPluginInformation ptr info = peek ptr >>= \h -> mkSetPluginInformation (hatSetPluginInformation h) info

registerInputPlugin :: Ptr HOST_APP_TABLE -> Ptr INPUT_PLUGIN_TABLE -> IO ()
registerInputPlugin ptr table = peek ptr >>= \h -> mkRegisterInputPlugin (hatRegisterInputPlugin h) table

registerOutputPlugin :: Ptr HOST_APP_TABLE -> Ptr OUTPUT_PLUGIN_TABLE -> IO ()
registerOutputPlugin ptr table = peek ptr >>= \h -> mkRegisterOutputPlugin (hatRegisterOutputPlugin h) table

registerFilterPlugin :: Ptr HOST_APP_TABLE -> Ptr FILTER_PLUGIN_TABLE -> IO ()
registerFilterPlugin ptr table = peek ptr >>= \h -> mkRegisterFilterPlugin (hatRegisterFilterPlugin h) table

registerScriptModule :: Ptr HOST_APP_TABLE -> Ptr SCRIPT_MODULE_TABLE -> IO ()
registerScriptModule ptr table = peek ptr >>= \h -> mkRegisterScriptModule (hatRegisterScriptModule h) table

registerImportMenu :: Ptr HOST_APP_TABLE -> LPCWSTR -> FunPtr (Ptr EDIT_SECTION -> IO ()) -> IO ()
registerImportMenu ptr name callback = peek ptr >>= \h -> mkRegisterImportMenu (hatRegisterImportMenu h) name callback

registerExportMenu :: Ptr HOST_APP_TABLE -> LPCWSTR -> FunPtr (Ptr EDIT_SECTION -> IO ()) -> IO ()
registerExportMenu ptr name callback = peek ptr >>= \h -> mkRegisterExportMenu (hatRegisterExportMenu h) name callback

registerWindowClient :: Ptr HOST_APP_TABLE -> LPCWSTR -> HWND -> IO ()
registerWindowClient ptr name hwnd = peek ptr >>= \h -> mkRegisterWindowClient (hatRegisterWindowClient h) name hwnd

createEditHandle :: Ptr HOST_APP_TABLE -> IO EDIT_HANDLE
createEditHandle ptr = peek ptr >>= \h -> mkCreateEditHandle (hatCreateEditHandle h)

registerProjectLoadHandler :: Ptr HOST_APP_TABLE -> FunPtr (Ptr PROJECT_FILE -> IO ()) -> IO ()
registerProjectLoadHandler ptr callback = peek ptr >>= \h -> mkRegisterProjectLoadHandler (hatRegisterProjectLoadHandler h) callback

registerProjectSaveHandler :: Ptr HOST_APP_TABLE -> FunPtr (Ptr PROJECT_FILE -> IO ()) -> IO ()
registerProjectSaveHandler ptr callback = peek ptr >>= \h -> mkRegisterProjectSaveHandler (hatRegisterProjectSaveHandler h) callback

registerLayerMenu :: Ptr HOST_APP_TABLE -> LPCWSTR -> FunPtr (Ptr EDIT_SECTION -> IO ()) -> IO ()
registerLayerMenu ptr name callback = peek ptr >>= \h -> mkRegisterLayerMenu (hatRegisterLayerMenu h) name callback

registerObjectMenu :: Ptr HOST_APP_TABLE -> LPCWSTR -> FunPtr (Ptr EDIT_SECTION -> IO ()) -> IO ()
registerObjectMenu ptr name callback = peek ptr >>= \h -> mkRegisterObjectMenu (hatRegisterObjectMenu h) name callback

registerConfigMenu :: Ptr HOST_APP_TABLE -> LPCWSTR -> FunPtr (HWND -> HINSTANCE -> IO ()) -> IO ()
registerConfigMenu ptr name callback = peek ptr >>= \h -> mkRegisterConfigMenu (hatRegisterConfigMenu h) name callback

registerEditMenu :: Ptr HOST_APP_TABLE -> LPCWSTR -> FunPtr (Ptr EDIT_SECTION -> IO ()) -> IO ()
registerEditMenu ptr name callback = peek ptr >>= \h -> mkRegisterEditMenu (hatRegisterEditMenu h) name callback

registerClearCacheHandler :: Ptr HOST_APP_TABLE -> FunPtr (Ptr EDIT_SECTION -> IO ()) -> IO ()
registerClearCacheHandler ptr callback = peek ptr >>= \h -> mkRegisterClearCacheHandler (hatRegisterClearCacheHandler h) callback

registerChangeSceneHandler :: Ptr HOST_APP_TABLE -> FunPtr (Ptr EDIT_SECTION -> IO ()) -> IO ()
registerChangeSceneHandler ptr callback = peek ptr >>= \h -> mkRegisterChangeSceneHandler (hatRegisterChangeSceneHandler h) callback

registerImportMenuParam :: Ptr HOST_APP_TABLE -> LPCWSTR -> Ptr () -> FunPtr (Ptr () -> IO ()) -> IO ()
registerImportMenuParam ptr name param callback = peek ptr >>= \h -> mkRegisterImportMenuParam (hatRegisterImportMenuParam h) name param callback

registerExportMenuParam :: Ptr HOST_APP_TABLE -> LPCWSTR -> Ptr () -> FunPtr (Ptr () -> IO ()) -> IO ()
registerExportMenuParam ptr name param callback = peek ptr >>= \h -> mkRegisterExportMenuParam (hatRegisterExportMenuParam h) name param callback

registerLayerMenuParam :: Ptr HOST_APP_TABLE -> LPCWSTR -> Ptr () -> FunPtr (Ptr () -> IO ()) -> IO ()
registerLayerMenuParam ptr name param callback = peek ptr >>= \h -> mkRegisterLayerMenuParam (hatRegisterLayerMenuParam h) name param callback

registerObjectMenuParam :: Ptr HOST_APP_TABLE -> LPCWSTR -> Ptr () -> FunPtr (Ptr () -> IO ()) -> IO ()
registerObjectMenuParam ptr name param callback = peek ptr >>= \h -> mkRegisterObjectMenuParam (hatRegisterObjectMenuParam h) name param callback

registerEditMenuParam :: Ptr HOST_APP_TABLE -> LPCWSTR -> Ptr () -> FunPtr (Ptr () -> IO ()) -> IO ()
registerEditMenuParam ptr name param callback = peek ptr >>= \h -> mkRegisterEditMenuParam (hatRegisterEditMenuParam h) name param callback

registerFileDropHandler :: Ptr HOST_APP_TABLE -> LPCWSTR -> LPCWSTR -> FunPtr (Ptr EDIT_SECTION -> LPCWSTR -> IO ()) -> IO ()
registerFileDropHandler ptr name filefilter callback = peek ptr >>= \h -> mkRegisterFileDropHandler (hatRegisterFileDropHandler h) name filefilter callback

registerFileDropParamHandler :: Ptr HOST_APP_TABLE -> LPCWSTR -> LPCWSTR -> Ptr () -> FunPtr (Ptr () -> LPCWSTR -> IO ()) -> IO ()
registerFileDropParamHandler ptr name filefilter param callback = peek ptr >>= \h -> mkRegisterFileDropParamHandler (hatRegisterFileDropParamHandler h) name filefilter param callback

registerObjectItemMenu :: Ptr HOST_APP_TABLE -> LPCWSTR -> BOOL_ -> FunPtr (Ptr EDIT_SECTION -> OBJECT_HANDLE -> LPCWSTR -> LPCWSTR -> IO ()) -> IO ()
registerObjectItemMenu ptr name allowEffectOnly callback = peek ptr >>= \h -> mkRegisterObjectItemMenu (hatRegisterObjectItemMenu h) name allowEffectOnly callback

registerObjectItemMenuParam :: Ptr HOST_APP_TABLE -> LPCWSTR -> BOOL_ -> Ptr () -> FunPtr (Ptr () -> OBJECT_HANDLE -> LPCWSTR -> LPCWSTR -> IO ()) -> IO ()
registerObjectItemMenuParam ptr name allowEffectOnly param callback = peek ptr >>= \h -> mkRegisterObjectItemMenuParam (hatRegisterObjectItemMenuParam h) name allowEffectOnly param callback

registerScriptModuleName :: Ptr HOST_APP_TABLE -> Ptr SCRIPT_MODULE_TABLE -> LPCWSTR -> IO ()
registerScriptModuleName ptr table name = peek ptr >>= \h -> mkRegisterScriptModuleName (hatRegisterScriptModuleName h) table name

registerFontCollection :: Ptr HOST_APP_TABLE -> Ptr () -> IO ()
registerFontCollection ptr collection = peek ptr >>= \h -> mkRegisterFontCollection (hatRegisterFontCollection h) collection

registerEventListener :: Ptr HOST_APP_TABLE -> EVENT_TYPE -> Ptr () -> FunPtr (Ptr () -> IO ()) -> IO ()
registerEventListener ptr eventType param callback = peek ptr >>= \h -> mkRegisterEventListener (hatRegisterEventListener h) eventType param callback
