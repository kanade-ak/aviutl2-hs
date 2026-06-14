{-# LANGUAGE ForeignFunctionInterface #-}
module UsernameModule where

import Foreign.C.Types (CBool(..), CULong(..))
import Foreign.Marshal.Alloc (malloc)
import Foreign.Marshal.Array (newArray)
import Foreign.Ptr (FunPtr, Ptr, nullFunPtr, nullPtr)
import Foreign.Storable (peek, poke)
import System.Environment (lookupEnv)
import System.IO.Unsafe (unsafePerformIO)
import AviUtl2.Module
  ( SCRIPT_MODULE_FUNCTION(..)
  , SCRIPT_MODULE_PARAM(..)
  , SCRIPT_MODULE_TABLE(..)
  )
import AviUtl2.Types (BOOL_, DWORD, LPCSTR, LPCWSTR)
import PluginSupport (newUtf8String, newWideString, requiredVersion)

foreign import ccall "wrapper"
  mkScriptFunc :: (Ptr SCRIPT_MODULE_PARAM -> IO ()) -> IO (FunPtr (Ptr SCRIPT_MODULE_PARAM -> IO ()))

foreign import ccall "dynamic"
  mkPushResultString :: FunPtr (LPCSTR -> IO ()) -> LPCSTR -> IO ()

foreign import ccall "dynamic"
  mkSetError :: FunPtr (LPCSTR -> IO ()) -> LPCSTR -> IO ()

foreign export ccall "RequiredVersion"
  requiredVersionExport :: IO DWORD

foreign export ccall "InitializePlugin"
  initializePlugin :: DWORD -> IO BOOL_

foreign export ccall "UninitializePlugin"
  uninitializePlugin :: IO ()

foreign export ccall "GetScriptModuleTable"
  getScriptModuleTable :: IO (Ptr SCRIPT_MODULE_TABLE)

moduleInfo, functionName :: LPCWSTR
moduleInfo = unsafePerformIO (newWideString "aviutl2-rs username-module port for Haskell")
functionName = unsafePerformIO (newWideString "get_username")
{-# NOINLINE moduleInfo #-}
{-# NOINLINE functionName #-}

scriptFuncPtr :: FunPtr (Ptr SCRIPT_MODULE_PARAM -> IO ())
scriptFuncPtr = unsafePerformIO (mkScriptFunc getUsername)
{-# NOINLINE scriptFuncPtr #-}

functionsPtr :: Ptr SCRIPT_MODULE_FUNCTION
functionsPtr = unsafePerformIO $ newArray
  [ SCRIPT_MODULE_FUNCTION functionName scriptFuncPtr
  , SCRIPT_MODULE_FUNCTION nullPtr nullFunPtr
  ]
{-# NOINLINE functionsPtr #-}

scriptModuleTablePtr :: Ptr SCRIPT_MODULE_TABLE
scriptModuleTablePtr = unsafePerformIO $ do
  ptr <- malloc
  poke ptr (SCRIPT_MODULE_TABLE moduleInfo functionsPtr)
  pure ptr
{-# NOINLINE scriptModuleTablePtr #-}

requiredVersionExport :: IO DWORD
requiredVersionExport = pure requiredVersion

initializePlugin :: DWORD -> IO BOOL_
initializePlugin _ = pure 1

uninitializePlugin :: IO ()
uninitializePlugin = pure ()

getScriptModuleTable :: IO (Ptr SCRIPT_MODULE_TABLE)
getScriptModuleTable = pure scriptModuleTablePtr

getUsername :: Ptr SCRIPT_MODULE_PARAM -> IO ()
getUsername param = do
  p <- peek param
  envValue <- lookupEnv "USERNAME"
  case envValue of
    Just username -> do
      cstr <- newUtf8String username
      mkPushResultString (smpPushResultString p) cstr
    Nothing -> do
      err <- newUtf8String "USERNAME is not set"
      mkSetError (smpSetError p) err
